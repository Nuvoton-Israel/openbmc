// OpenBMC-side OCP recovery image-push tool.
//
// Drives the full OCP Secure Firmware Recovery v1.1 flow over USB EP0 control
// transfers: read PROT_CAP, then for each image file push it into a CMS region
// (indirect memory-window by default, or FIFO with --fifo) and activate it.
// The caliptra hw-2-1 recovery boot is a 3-stage streaming boot
// (caliptra_fw, soc_manifest, mcu_runtime), so pass the images in that order.
//
// Uses USBDEVFS_CONTROL directly, so it needs only Linux userspace headers.
//
// usage: usb_ocp_recovery [--fifo] /dev/bus/usb/BBB/DDD IMG0 [IMG1 ...]
//
// Demo presentation (optional):
//   OCP_DEMO_BIG=0        plain banners instead of DEC double-height lines,
//                         for terminals that do not support ESC#3/ESC#4

#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <linux/usbdevice_fs.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

// OCP recovery command codes (wValue low byte). See common/ocp/src/protocol.rs.
#define CMD_PROT_CAP          0x22
#define CMD_DEVICE_STATUS     0x24
#define CMD_RECOVERY_CTRL     0x26
#define CMD_RECOVERY_STATUS   0x27
#define CMD_INDIRECT_CTRL     0x29
#define CMD_INDIRECT_DATA     0x2B
#define CMD_INDIRECT_FIFO_CTRL 0x2D
#define CMD_INDIRECT_FIFO_DATA 0x2F

#define REQTYPE_WRITE 0x21 // H2D, Class, Interface
#define REQTYPE_READ  0xA1 // D2H, Class, Interface

// RECOVERY_STATUS byte0 low nibble.
#define REC_AWAITING_IMAGE 0x1
#define REC_BOOTING_IMAGE  0x2
#define REC_SUCCESS        0x3

// DEVICE_STATUS byte0.
#define DEV_RECOVERY_MODE        0x3
#define DEV_RUNNING_RECOVERY_IMG 0x5

// Max control-transfer data phase (OCP functional descriptor advertises 1024).
#define CHUNK_INDIRECT 1024
#define CHUNK_FIFO      256 // match the device FIFO block size to avoid overflow

// Wall-clock cap on how long to wait for the device to report AwaitingImage.
#define AWAIT_TIMEOUT_SEC 120
#define AWAIT_DELAY_US 5000

#define C_RESET "\033[0m"
#define C_TITLE "1;36" // bold cyan: step banners
#define C_OK    "1;32" // bold green: step completed
#define C_INFO  "1;33" // bold yellow: details

static int demo_big = 1;
static int use_color;

// Print a step banner. With DEC double-height enabled the text is emitted
// twice (top half ESC#3, bottom half ESC#4), which renders it at 2x size on
// xterm, PuTTY and Windows Terminal. Double-height lines are also double-width,
// so keep the text under 40 characters.
static void banner(const char *color, const char *fmt, ...) {
    char text[128];
    va_list ap;

    va_start(ap, fmt);
    vsnprintf(text, sizeof(text), fmt, ap);
    va_end(ap);

    if (!use_color) {
        printf("\n==> %s\n", text);
    } else if (demo_big) {
        printf("\n\033[%sm\033#3%s\n\033#4%s" C_RESET "\n", color, text, text);
    } else {
        printf("\n\033[%sm>> %s" C_RESET "\n", color, text);
    }
    fflush(stdout);
}

static void note(const char *color, const char *fmt, ...) {
    va_list ap;

    printf("   ");
    if (use_color) {
        printf("\033[%sm", color);
    }
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
    printf("%s\n", use_color ? C_RESET : "");
    fflush(stdout);
}

static void show_progress(size_t done, size_t total) {
    static const char hashes[] = "########################################";
    const int width = sizeof(hashes) - 1;
    int pct = total ? (int)(done * 100 / total) : 100;
    int fill = pct * width / 100;

    printf("\r   [%s%.*s%s%*s] %3d%%  %zu / %zu bytes",
           use_color ? "\033[1;32m" : "", fill, hashes,
           use_color ? C_RESET : "", width - fill, "", pct, done, total);
    fflush(stdout);
}

static int ctrl(int fd, uint8_t type, uint16_t value, void *data, uint16_t len) {
    struct usbdevfs_ctrltransfer x = {
        .bRequestType = type,
        .bRequest = 0x00, // all OCP recovery transfers use bRequest 0
        .wValue = value,  // low byte = OCP command code
        .wIndex = 0,
        .wLength = len,
        .timeout = 2000,
        .data = data,
    };
    return ioctl(fd, USBDEVFS_CONTROL, &x);
}

static void put_u32_le(uint8_t *p, uint32_t v) {
    p[0] = v & 0xff;
    p[1] = (v >> 8) & 0xff;
    p[2] = (v >> 16) & 0xff;
    p[3] = (v >> 24) & 0xff;
}

// Poll RECOVERY_STATUS until the device is AwaitingImage. Returns 0 on success,
// -1 on timeout, -2 on a recovery failure status (>= 0xC).
//
// Per OCP v1.1 §7.6 the device reports "Awaiting recovery image" (with the
// image index incremented) before every stage, including between stages of a
// multi-image streaming boot, so the same wait covers stage 0 and all later
// stages. Between stages the RoT verifies the prior image and stops servicing
// EP0, so reads fail (rc < 0) during that window; that is expected, keep
// polling until the deadline.
static int wait_awaiting(int fd) {
    time_t deadline = time(NULL) + AWAIT_TIMEOUT_SEC;
    do {
        uint8_t st[2] = {0};
        int rc = ctrl(fd, REQTYPE_READ, CMD_RECOVERY_STATUS, st, sizeof(st));
        if (rc >= 2) {
            uint8_t status = st[0] & 0x0f;
            if (status == REC_AWAITING_IMAGE) {
                return 0;
            }
            if (status >= 0x0C) {
                fprintf(stderr, "RECOVERY_STATUS failure 0x%x\n", status);
                return -2;
            }
        }
        usleep(AWAIT_DELAY_US);
    } while (time(NULL) < deadline);
    return -1;
}

// Stream a buffer in chunk-sized control writes of the given OCP command.
// Chunks must be 4-byte aligned (except the final one) because the device
// rounds the write pointer up to a 4-byte boundary per transfer.
static int stream(int fd, uint8_t cmd, const uint8_t *buf, size_t len, size_t chunk) {
    size_t off = 0;
    int last_pct = -1;
    while (off < len) {
        size_t n = len - off;
        if (n > chunk) {
            n = chunk;
        }
        int rc = ctrl(fd, REQTYPE_WRITE, cmd, (void *)(buf + off), (uint16_t)n);
        if (rc < 0) {
            fprintf(stderr, "\nstream cmd 0x%02x @%zu len %zu: %s\n",
                    cmd, off, n, strerror(errno));
            return -1;
        }
        off += n;
        int pct = (int)(off * 100 / len);
        if (pct != last_pct) {
            show_progress(off, len);
            last_pct = pct;
        }
    }
    printf("\n");
    return 0;
}

// Push a full image into CMS 0 via the indirect memory window, then activate.
static int push_indirect(int fd, const uint8_t *buf, size_t len) {
    uint8_t ictrl[6] = {0, 0, 0, 0, 0, 0}; // CMS 0, IMO 0
    if (ctrl(fd, REQTYPE_WRITE, CMD_INDIRECT_CTRL, ictrl, sizeof(ictrl)) < 0) {
        perror("INDIRECT_CTRL");
        return -1;
    }
    if (stream(fd, CMD_INDIRECT_DATA, buf, len, CHUNK_INDIRECT) < 0) {
        return -1;
    }
    uint8_t rctrl[3] = {0, 0x01, 0x0F}; // CMS 0, MemoryWindow, Activate
    if (ctrl(fd, REQTYPE_WRITE, CMD_RECOVERY_CTRL, rctrl, sizeof(rctrl)) < 0) {
        perror("RECOVERY_CTRL");
        return -1;
    }
    return 0;
}

// Push a full image into CMS 1 via the FIFO stream, then activate. `buf`/`len`
// must be 4-byte aligned (the caller pads).
static int push_fifo(int fd, const uint8_t *buf, size_t len) {
    uint8_t fctrl[6] = {1, 0, 0, 0, 0, 0}; // CMS 1, no reset
    put_u32_le(&fctrl[2], (uint32_t)(len / 4)); // size in 4-byte units
    if (ctrl(fd, REQTYPE_WRITE, CMD_INDIRECT_FIFO_CTRL, fctrl, sizeof(fctrl)) < 0) {
        perror("INDIRECT_FIFO_CTRL");
        return -1;
    }
    if (stream(fd, CMD_INDIRECT_FIFO_DATA, buf, len, CHUNK_FIFO) < 0) {
        return -1;
    }
    uint8_t rctrl[3] = {1, 0x01, 0x0F}; // CMS 1, MemoryWindow, Activate
    if (ctrl(fd, REQTYPE_WRITE, CMD_RECOVERY_CTRL, rctrl, sizeof(rctrl)) < 0) {
        perror("RECOVERY_CTRL");
        return -1;
    }
    return 0;
}

// Read a whole file into a malloc'd buffer padded up to 4 bytes with zeros.
// ponytail: pad here so both transports get 4-byte-aligned data; the device
// rounds writes up to 4 bytes anyway, so the trailing zeros are harmless.
static uint8_t *read_file(const char *path, size_t *out_len) {
    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        perror(path);
        return NULL;
    }
    struct stat sb;
    if (fstat(fd, &sb) < 0) {
        perror("fstat");
        close(fd);
        return NULL;
    }
    size_t raw = (size_t)sb.st_size;
    size_t padded = (raw + 3) & ~(size_t)3;
    uint8_t *buf = calloc(padded ? padded : 4, 1);
    if (!buf) {
        fprintf(stderr, "out of memory for %s\n", path);
        close(fd);
        return NULL;
    }
    size_t got = 0;
    while (got < raw) {
        ssize_t n = read(fd, buf + got, raw - got);
        if (n <= 0) {
            perror("read");
            free(buf);
            close(fd);
            return NULL;
        }
        got += (size_t)n;
    }
    close(fd);
    *out_len = padded;
    return buf;
}

static int read_prot_cap(int fd) {
    uint8_t cap[15] = {0};
    int rc = ctrl(fd, REQTYPE_READ, CMD_PROT_CAP, cap, sizeof(cap));
    if (rc < 0) {
        perror("PROT_CAP");
        return -1;
    }
    if (rc < 13 || memcmp(cap, "OCP RECV", 8) != 0) {
        fprintf(stderr, "bad PROT_CAP magic (rc=%d)\n", rc);
        return -1;
    }
    uint16_t caps = (uint16_t)cap[10] | ((uint16_t)cap[11] << 8);
    if (!(caps & (1u << 7))) { // push_c_image_support
        fprintf(stderr, "device does not support host-pushed image (caps=0x%04x)\n", caps);
        return -1;
    }
    note(C_INFO, "Protocol      : OCP Secure Firmware Recovery v%u.%u",
         cap[8], cap[9]);
    note(C_INFO, "Capabilities  : 0x%04x (host-pushed image supported)", caps);
    note(C_INFO, "CMS regions   : %u", cap[12]);
    return 0;
}

#ifdef SELFCHECK
// Verify the chunk splitter never emits an unaligned non-final chunk — the one
// piece of logic that silently corrupts an image if wrong.
#include <assert.h>
static void selfcheck(void) {
    const size_t sizes[] = {0, 1, 3, 4, 255, 256, 257, 1024, 1025, 4096, 5000};
    const size_t chunks[] = {CHUNK_FIFO, CHUNK_INDIRECT};
    for (unsigned s = 0; s < sizeof(sizes) / sizeof(sizes[0]); s++) {
        for (unsigned c = 0; c < 2; c++) {
            size_t chunk = chunks[c];
            size_t len = (sizes[s] + 3) & ~(size_t)3; // read_file pads to 4
            size_t off = 0;
            while (off < len) {
                size_t n = len - off > chunk ? chunk : len - off;
                int final = (off + n == len);
                assert(final || n % 4 == 0);      // non-final chunks stay aligned
                assert(n <= chunk && n > 0);
                off += n;
            }
            assert(off == len);
        }
    }
    printf("selfcheck ok\n");
}
#endif

int main(int argc, char **argv) {
#ifdef SELFCHECK
    selfcheck();
    return 0;
#endif
    int use_fifo = 0;
    int argi = 1;

    use_color = isatty(STDOUT_FILENO);
    if (getenv("OCP_DEMO_BIG") && strcmp(getenv("OCP_DEMO_BIG"), "0") == 0) {
        demo_big = 0;
    }

    if (argi < argc && strcmp(argv[argi], "--fifo") == 0) {
        use_fifo = 1;
        argi++;
    }
    if (argc - argi < 2) {
        fprintf(stderr, "usage: %s [--fifo] /dev/bus/usb/BBB/DDD IMG0 [IMG1 ...]\n", argv[0]);
        return 2;
    }
    const char *dev = argv[argi++];

    int fd = open(dev, O_RDWR);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    unsigned int iface = 0;
    if (ioctl(fd, USBDEVFS_CLAIMINTERFACE, &iface) < 0 && errno != EBUSY) {
        perror("USBDEVFS_CLAIMINTERFACE");
        close(fd);
        return 1;
    }

    banner(C_TITLE, "Reading OCP Recovery Capability");
    if (read_prot_cap(fd) < 0) {
        close(fd);
        return 1;
    }
    note(C_OK, "[OK] OCP recovery device ready");

    int nstages = argc - argi;
    banner(C_TITLE, "Start Streaming Boot over USB");
    note(C_INFO, "Transport     : USB EP0 control transfers");
    note(C_INFO, "Image path    : %s",
         use_fifo ? "Indirect FIFO (CMS 1)" : "Indirect memory window (CMS 0)");
    note(C_INFO, "Images        : %d", nstages);

    for (int s = 0; s < nstages; s++) {
        const char *path = argv[argi + s];
        char name[256];

        snprintf(name, sizeof(name), "%s", path);
        banner(C_TITLE, "Stage %d/%d: %s", s + 1, nstages, basename(name));
        note(C_INFO, "Waiting for device to request recovery image ...");
        if (wait_awaiting(fd) < 0) {
            fprintf(stderr, "stage %d/%d: device never reached AwaitingImage\n",
                    s + 1, nstages);
            close(fd);
            return 1;
        }

        size_t len = 0;
        uint8_t *buf = read_file(path, &len);
        if (!buf) {
            close(fd);
            return 1;
        }

        note(C_INFO, "Device is awaiting image, streaming %zu bytes over USB",
             len);

        int rc = use_fifo ? push_fifo(fd, buf, len) : push_indirect(fd, buf, len);
        free(buf);
        if (rc < 0) {
            fprintf(stderr, "stage %d/%d push failed\n", s + 1, nstages);
            close(fd);
            return 1;
        }
        note(C_OK, "[OK] Image delivered and activated, device verifying");
    }

    // Best-effort completion check. After the final activate the device boots
    // the recovered firmware and may drop off the USB bus, so a read failure
    // here is expected and not treated as an error.
    uint8_t dev_st[7] = {0};
    int rc = ctrl(fd, REQTYPE_READ, CMD_DEVICE_STATUS, dev_st, sizeof(dev_st));
    if (rc >= 1) {
        note(C_INFO, "Final DEVICE_STATUS=0x%02x%s", dev_st[0],
             dev_st[0] == DEV_RUNNING_RECOVERY_IMG ? " (RunningRecoveryImage)" : "");
    } else {
        note(C_INFO, "Device left recovery mode and is booting the new firmware");
    }

    banner(C_OK, "Streaming Boot Complete");
    note(C_OK, "[OK] %d image(s) recovered over USB", nstages);
    close(fd);
    return 0;
}
