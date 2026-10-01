// Copyright (c) Nuvoton technology. All rights reserved.
// Licensed under the MIT license.

#include <filesystem>
#include <memory>
#include <stdlib.h>
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <linux/types.h>
#include <i3c/i3cdev.h>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <nlohmann/json.hpp>
#include <sdbusplus/bus.hpp>


/**
 * The maximum amount of aligned data that can be read from or written to a CMS.
 */
#define	MAX_CMS_BLOCK_SIZE 252

#define MAX_RCRY_I3C_BLOCK_SIZE 256

/**
 * The maximum amount of aligned data that can be written to a CMS.
 * Maximum byte number for an i3c transfer is 256.
 * For a recovery i3c interface block write, the private write command (1 byte),
 * length lsb (1 byte), length msb (1 byte) and pec (1 byte) occupy 4 bytes.
 */
#define	MAX_CMS_WRITE_BLOCK_SIZE 252

/**
 * The maximum amount of aligned data that can be read from a CMS.
 * Maximum byte number for an i3c transfer is 256.
 * For a recovery i3c interface block read, length lsb (1 byte),
 * length msb (1 byte) and pec (1 byte) occupy 3 bytes.
 */
#define	MAX_CMS_READ_BLOCK_SIZE	253

#define BIT(n)  (1 << (n))

/*
 * I3C sysfs device directory, BCR virtual-target bit (BCR[4]) and BCR
 * IBI-request-capable bit (BCR[1]).
 */
#define I3C_SYSFS_DEVICES "/sys/bus/i3c/devices/"
#define I3C_BCR_VIRTUAL_TARGET BIT(4)
#define I3C_BCR_IBI_REQUEST_CAPABLE BIT(1)

/*
 * How long to keep re-running discovery while waiting for the recovery target,
 * and how often.  When the service is started by the GPIO pulse the NPCM500
 * may still be booting, so its I3C targets are not necessarily on the bus yet.
 */
#define TARGET_WAIT_TIMEOUT_S 10
#define TARGET_DISCOVER_INTERVAL_S 1

#define PROT_CAP2_DEVICE_ID_SUPPORT BIT(0)
#define PROT_CAP2_DEVICE_STATUS_SUPPORT BIT(4)
#define PROT_CAP2_PUSH_C_IMAGE_SUPPORT BIT(7)
#define PROT_CAP2_FLASHLESS_BOOT_VALUE BIT(11)
#define PROT_CAP2_FIFO_CMS_SUPPORT BIT(12)

/*
 * PROT_CAP response payload length per the OCP recovery spec: magic (8) +
 * version (2) + capabilities (2) + CMS count (1) + max response time (1) +
 * heartbeat period (1).
 */
#define PROT_CAP_RESPONSE_LENGTH 15

#define NEED_WAIT true
#define WAIT_TIME 1000*1000
#define WAIT \
	if (NEED_WAIT) { \
		usleep(WAIT_TIME); \
	}

/* DEVICE_STATUS */
#define STATUS_PENDING 0x0
#define DEVICE_HEALTHY 0x1
#define DEVICE_ERROR 0x2
#define READY_TO_ACCEPT_RECOVERY_IMAGE 0x3
#define RECOVERY_PENDING 0x4
#define RUNNING_RECOVERY_IMAGE 0x5
#define BOOT_FAILURE 0xe
#define FATAL_ERROR 0xf

#define NO_PROTOCOL_ERROR 0x0
#define UNSUPPORTED_WRITE_COMMAND 0x1
#define UNSUPPORTED_PARAMETER 0x2
#define LENGTH_WRITE_ERROR 0x3
#define CRC_ERROR 0x4
#define GENERAL_PROTOCOL_ERROR 0xff

#define FORCED_RECOVERY 0x11
#define FLASHLESS_STREAMING_BOOT 0x12

/* RECOVERY_STATUS */
#define NOT_IN_RECOVERY_MODE 0x0
#define AWAITING_RECOVERY_IMAGE 0x1
#define BOOTING_RECOVERY_IMAGE 0x2
#define RECOVERY_SUCCESSFUL 0x3
#define RECOVERY_FAILED 0xc
#define RECOVERY_IMAGE_AUTHENTICATION_ERROR 0xd
#define ERROR_ENTERING_RECOVERY_MODE 0xe
#define INVALID_COMPONENT_ADDRESS_SPACE 0xf

#define FW_IMAGE_INDEX 0x0
#define SOC_MANIFEST_INDEX 0x1
#define MCU_FIRMWARE_INDEX 0x2

/**
 * File descriptor for the I3C bus connected to the device.
 */
int i3c;

/**
 * The I3C address of the target device.
 */
uint8_t addr = 0x9;

/**
 * The CMS to use for the operation.
 */
uint8_t cms_id = 0;

/**
 * Offset within the CMS to access.
 */
uint32_t cms_offset = 0x0;

/**
 * Maximum block size for CMS write.
 *
 * Kept below the INDIRECT FIFO size (256 bytes) so each streamed chunk leaves
 * headroom for the device to drain, reducing FIFO-full NACKs during streaming.
 */
uint32_t cms_block_write = 128;

/**
 * Flag to ignore validation errors when processing commands.  Protocol and bus errors still
 * trigger a failure.
 */
bool ignore_errors = false;

/**
 * Enable and disable PEC on reads/writes.
 */
bool pec = true;

/**
 * Force a PEC error on a raw write transaction.  This is only applicable if a PEC byte is being
 * generated for the command.
 */
bool force_pec_error = false;

/**
 * Suppress the per-retry "i3c read transfer failed" message.  The device
 * legitimately NACKs reads for a few seconds while it is busy processing a
 * streamed image, so callers that poll across that window set this to avoid
 * flooding the log with expected transient failures.
 */
bool quiet_i3c_retry = false;

/**
 * Flag indicating a read or write operation.
 */
bool is_read = true;

/**
 * Flag indicating that raw bytes of the command should be displayed.
 */
bool raw_bytes = false;

/**
 * For reset commands, force the device into recovery mode.
 */
bool force_recovery = false;

/**
 * The command to execute.
 */
const char *command = NULL;
char *device_name = NULL;

/**
 * The file name provided with the command.
 */
const char *file_name = NULL;
const char *soc_man_file_name = NULL;
const char *mcu_rt_file_name = NULL;

/**
 * Indicate the specified file should be used to output messages.
 */
bool file_out = false;

/**
 * Number of raw data entries provided.
 */
size_t raw_data_count = 0;

/**
 * Add a delay after sending block write commands before issuing another command.
 */
bool use_write_delay = false;

/**
 * The delay to add after a block write, in microseconds.
 */
uint32_t write_delay = 1000;

/**
 * Output verbosity.
 */
int verbose = 2;

/**
 * Dbus object path for device.
*/
char* dbus_object = NULL;

/**
 * The file name provided with the command.
 */
 const char *alt_file_name = NULL;

/**
 * config.
 */
int device_bus = -1;
uint8_t mctp_addr = 0xFF;
uint8_t ocp_addr = 0xFF;
uint32_t recovery_mode_gpio_line_num = 0xFF;
uint8_t recovery_mode_gpio_chip = 0xFF;
uint32_t reset_gpio_line_num = 0xFF;
uint8_t reset_gpio_chip = 0xFF;

/**
 * Path to the JSON recovery config (set via -j).  When provided, BusNumber and
 * the three image paths are read from it, and the target I3C device is
 * auto-discovered from the bus number using the BCR virtual-target bit.
 */
const char *config_name = NULL;

/* Persistent storage backing the const char* image and device path globals. */
static std::string cfg_fw_image;
static std::string cfg_soc_manifest;
static std::string cfg_mcu_rt;
static std::string cfg_device_path;

uint8_t buffer[MAX_RCRY_I3C_BLOCK_SIZE] = {0};

/**
 * Determine if an entry marker indicates the start of a valid log entry.
 */
#define	LOGGING_IS_ENTRY_START(x)	(((x) & 0xF0) == 0xC0)

/**
 * Header added to every log entry.  It is important for backwards compatibility that future
 * versions of this header only add fields and not modify the order or size of existing fields.
 */
struct logging_entry_header {
	uint8_t log_magic;				/**< Start of entry marker. */
	uint16_t length;				/**< Length of the entry. */
	uint32_t entry_id;				/**< Unique entry identifier. */
};

/**
 * Format for an entry in the debug log.
 */
struct debug_log_entry_info {
	uint16_t format;			/**< Format of the log entry. */
	uint8_t severity;			/**< Severity level of the entry. */
	uint8_t component;			/**< System competent that generated the entry. */
	uint8_t msg_index;			/**< Identifier for the entry message. */
	uint32_t arg1;				/**< Message specific argument. */
	uint32_t arg2;				/**< Message specific argument. */
	uint64_t time;				/**< Elapsed time in milliseconds since boot. */
};

/**
 * Format of the debug log entry as stored in the log.
 */
struct debug_log_entry {
	struct logging_entry_header header;		/**< Standard logging header. */
	struct debug_log_entry_info entry;		/**< Information for the log entry. */
};

/**
 * OCP recovery command codes.
 */
enum {
	/**< Recovery capabilities command */
	PROT_CAP = 34,
	/**< Device Identifier */
	DEVICE_ID = 35,
	/**< Current device status */
	DEVICE_STATUS = 36,
	/**< Device reset control */
	RESET = 37,
	/**< Recovery image control */
	RECOVERY_CTRL = 38,
	/**< Recovery image status */
	RECOVERY_STATUS = 39,
	/**< Hardware status information. */
	HW_STATUS = 40,
	/**< Control indirect access to memory regions. */
	INDIRECT_CTRL = 41,
	/**< Status of indirect memory access. */
	INDIRECT_STATUS = 42,
	/**< Data access to indirect memory regions. */
	INDIRECT_DATA = 43,
	/**< Vendor-defined command. */
	VENDOR = 44,
	/**< Indirect FIFO memory access configuration. */
	INDIRECT_FIFO_CTRL = 45,
	/**< Status of indirect FIFO memory access. */
	INDIRECT_FIFO_STATUS = 46,
	/**< Data access to indirect FIFO memory regions. */
	INDIRECT_FIFO_DATA = 47,
};

/**
 * List of protocol error messages for the device.
 */
const char *PROTOCOL_ERROR_STR[] = {
	[0x0] = "No Error",
	[0x1] = "Unsupported Command",
	[0x2] = "Unsupported Paramater",
	[0x3] = "Length Write Error",
	[0x4] = "CRC Error",
	[0x5] = "Reserved",
	[0x6] = "Reserved",
	[0x7] = "Reserved",
	[0x8] = "Reserved",
	[0x9] = "Reserved",
	[0xa] = "Reserved",
	[0xb] = "Reserved",
	[0xc] = "Reserved",
	[0xd] = "Reserved",
	[0xe] = "Reserved",
	[0xf] = "Reserved",
};

/**
 * List of status messages for the device.
 */
const char *DEVICE_STATUS_STR[] = {
	[0x0] = "Status Pending",
	[0x1] = "Device Healthy",
	[0x2] = "Device Error",
	[0x3] = "Recovery Mode",
	[0x4] = "Recovery Pending",
	[0x5] = "Running Recovery Image",
	[0x6] = "Reserved",
	[0x7] = "Reserved",
	[0x8] = "Reserved",
	[0x9] = "Reserved",
	[0xa] = "Reserved",
	[0xb] = "Reserved",
	[0xc] = "Reserved",
	[0xd] = "Reserved",
	[0xe] = "Boot Failure",
	[0xf] = "Fatal Error"
};

/**
 * List of recovery reason codes.
 */
const char *RECOVERY_REASON_STR[] = {
	[0x00] = "No boot failure",
	[0x01] = "Generic hardware error",
	[0x02] = "Generic hardware soft error",
	[0x03] = "Self-test failure",
	[0x04] = "Missing or corrupt critical data",
	[0x05] = "Missing or corrupt key manifest",
	[0x06] = "Authentication failure on key manifest",
	[0x07] = "Anti-rollback failure on key manifest",
	[0x08] = "Missing or corrupt boot loader firmware image",
	[0x09] = "Authentication failure on boot loader firmware image",
	[0x0a] = "Anti-Rollback failure on boot loader firmware image",
	[0x0b] = "Missing or corrupt main firmware image",
	[0x0c] = "Authentication failure on main firmware image",
	[0x0d] = "Anti-Rollback failure on main firmware image",
	[0x0e] = "Missing or corrupt recovery firmware",
	[0x0f] = "Authentication failure on recovery firmware",
	[0x10] = "Anti-rollback failure on recovery firmware",
	[0x11] = "Forced recovery",
	[0x12] = "Flashless/Streaming Boot (FSB)"
};

/**
 * List of recovery status messages for the device.
 */
const char *RECOVERY_STATUS_STR[] = {
	[0x0] = "Not in recovery mode",
	[0x1] = "Awaiting recovery image",
	[0x2] = "Booting recovery image",
	[0x3] = "Recovery successful",
	[0x4] = "Reserved",
	[0x5] = "Reserved",
	[0x6] = "Reserved",
	[0x7] = "Reserved",
	[0x8] = "Reserved",
	[0x9] = "Reserved",
	[0xa] = "Reserved",
	[0xb] = "Reserved",
	[0xc] = "Recovery failed",
	[0xd] = "Recovery image authentication error",
	[0xe] = "Error entering recovery mode",
	[0xf] = "Invalid component address space"
};

uint8_t checksum_init_smbus_crc8 (uint8_t smbus_addr);
uint8_t checksum_update_smbus_crc8 (uint8_t crc, const uint8_t *data, uint8_t len);

/**
 * Initialize an SMBus CRC8 calculation.
 *
 * @param smbus_addr SMBus address of the target device.
 *
 * @return The intermediate CRC8 value that can be extended with additional data.
 */
uint8_t checksum_init_smbus_crc8 (uint8_t smbus_addr)
{
	return checksum_update_smbus_crc8 (0, &smbus_addr, 1);
}

/**
 * Continue an SMBus CRC8 calculation.
 *
 * @param crc The initial CRC8 value to use for the calculation.
 * @param data Buffer that contains the data to use for the calculation.
 * @param len The number of bytes in the buffer.
 *
 * @return The resulting CRC8.  This can be used as the initial CRC value in subsequent operations,
 * if necessary.
 */
uint8_t checksum_update_smbus_crc8 (uint8_t crc, const uint8_t *data, uint8_t len)
{
	int i;
	int j;

	if (data == NULL) {
		return crc;
	}

	for (i = 0; i < len; ++i) {
		crc ^= data[i];

		for (j = 0; j < 8; ++j) {
			if ((crc & 0x80) != 0) {
				crc = (uint8_t) ((crc << 1) ^ 0x07);
			}
			else {
				crc <<= 1;
			}
		}
	}

	return crc;
}

/**
 * Get the current monotonic clock count value.
 *
 * @param current Output for the current system time.
 */
static void get_current_time (struct timespec *current)
{
	int status;

	status = clock_gettime (CLOCK_MONOTONIC, current);
	if (status != 0) {
		fprintf (stderr, "Failed to get the current time: %s\n", strerror (errno));
		exit (1);
	}
}

/**
 * Get the duration between two time values.
 *
 * @param start The start time for the time duration.
 * @param end The end time for the time duration.
 *
 * @return The elapsed time, in microseconds.  If either clock is null, the elapsed time will be 0.
 */
uint32_t get_time_duration (const struct timespec *start, const struct timespec *end)
{
	if ((end == NULL) || (start == NULL)) {
		return 0;
	}

	if (start->tv_sec > end->tv_sec) {
		return 0;
	}
	else if (start->tv_sec == end->tv_sec) {
		if (start->tv_nsec > end->tv_nsec) {
			return 0;
		}
		else {
			return (end->tv_nsec - start->tv_nsec) / 1000ULL;
		}
	}
	else {
		uint32_t duration = end->tv_nsec / 1000ULL;

		duration += (1000000000ULL - start->tv_nsec) / 1000ULL;
		duration += (end->tv_sec - start->tv_sec) * 1000000;

		return duration;
	}
}

/**
 * Execute a recovery i3c block read command against the target device.
 *
 * @param cmd The command code to send to the device.
 * @param payload Output buffer to the command payload.
 * @param min_length The minimum amount of data that is required from the device.  Less than this is
 * considered a failure.
 * @param length The amount of data to read from the device.  It may not all be valid if the device
 * doesn't have a full amount of data to send.
 *
 * @return The number of bytes returned by the device.
 */
uint8_t i3c_block_read(uint8_t cmd, uint8_t *payload, uint16_t min_length, uint16_t length)
{
	struct i3c_ioc_priv_xfer xfers[2];
	uint8_t crc_addr = addr << 1;
	int i3c_read_overhead = 3;
	struct timespec start;
	struct timespec end;
	uint16_t rx_length;
	uint8_t w_data[2];
	int ret, loop;
	uint8_t crc;

	if (length > MAX_CMS_READ_BLOCK_SIZE) {
		fprintf(stderr, "i3c read length should not be greater than MAX_CMS_READ_BLOCK_SIZE\n");
		return 0;
	}

	/* Write */
	crc = checksum_init_smbus_crc8(crc_addr);
	crc = checksum_update_smbus_crc8 (crc, &cmd, 1);
#ifdef DBG_DUMP
	fprintf(stderr, "%s i3c write crc 0x%x\n", __func__, crc);
#endif

	w_data[0] = cmd;
	w_data[1] = crc;

	xfers[0].rnw = 0;
	xfers[0].len = 2;
	xfers[0].data = (uintptr_t)w_data;

	xfers[1].rnw = 1;
	xfers[1].len = length + i3c_read_overhead;
	xfers[1].data = (uintptr_t)buffer;

	get_current_time (&start);
	for (loop = 0; loop < 3; loop++) {
		ret = ioctl(i3c, I3C_IOC_PRIV_XFER(2), xfers);
		if (!ret) {
			break;
		}
		sleep(1);
		ret = ioctl(i3c, I3C_IOC_PRIV_XFER(2), xfers);
		if (ret) {
			if (!quiet_i3c_retry) {
				fprintf(stderr, "i3c read transfer failed 2nd time %s\n", strerror(errno));
			}
		} else {
			break;
		}
	}
	get_current_time (&end);

	/*
	 * Printed for every read, including each FIFO poll while streaming an
	 * image; at a lower level this floods the journal past its rate limit.
	 */
	if (verbose >= 3) {
		fprintf(stderr, "Read Cmd (%d us): %d\n", get_time_duration (&start, &end), cmd);
#if 0
		if (verbose >= 2) {
			//todo
			//print_byte_array (rx_smbus, 0, length + smbus_overhead - 1, "SMBus Rx", "");
			//printf ("\n");
		}
#endif
	}

	if (ret) {
		return 0;
	}

	rx_length = (uint16_t)buffer[0];
	rx_length |= (uint16_t)(((uint16_t)buffer[1]) << 8);

#ifdef DBG_DUMP
	fprintf(stderr, "rx_length %d\r\n", rx_length);
#endif

	/*
	 * rx_length comes from the device and is not covered by PEC until after the
	 * copy below.  Reject anything longer than requested: the payload buffer is
	 * only sized for 'length' bytes, and a longer response was truncated by the
	 * transfer, so its PEC byte was never received anyway.
	 */
	if (length < rx_length) {
		fprintf(stderr, "Invalid response length for command %d.  Rx %d bytes, requested at most %d.\n",
				cmd, rx_length, length);
		return 0;
	}
	else if (min_length > rx_length) {
		fprintf (stderr, "Invalid response length for command %d.  Rx %d bytes.\n", cmd, rx_length);
		return 0;
	}

	length = rx_length;
	memcpy(payload, &buffer[2], length);

	/* Read */
	crc_addr |= 1;
	crc = checksum_init_smbus_crc8(crc_addr);
	crc = checksum_update_smbus_crc8(crc, buffer, 2 + length);
#ifdef DBG_DUMP
	for (int i = 0 ; i < (length + 3) ; i++) {
		fprintf(stderr, "read buf 0x%x\r\n", buffer[i]);
	}
#endif
	if (crc != buffer[length + 2]) {
		fprintf (stderr, "PEC failed: CRC=0x%x, Rx=%x\n", crc, buffer[length + 2]);
		return 0;
	}

	return length;
}

/**
 * Execute a recovery i3c private write command against the target device.
 *
 */
int i3c_block_write(uint8_t cmd, uint8_t *payload, uint16_t length)
{
	struct i3c_ioc_priv_xfer xfers[1];
	int i3c_write_overhead = 4;
	struct timespec start;
	struct timespec end;
	int ret, loop;
	uint8_t crc;

	if (length > MAX_CMS_WRITE_BLOCK_SIZE) {
		fprintf(stderr, "i3c write length should not \
				be greater than MAX_CMS_WRITE_BLOCK_SIZE\n");
		return 0;
	}

	buffer[0] = cmd;
	buffer[1] = (uint8_t)(length & 0xff);
	buffer[2] = (uint8_t)((length & 0xff00) >> 8);
	memcpy(&buffer[3], payload, length);

	crc = checksum_init_smbus_crc8(addr << 1);
	crc = checksum_update_smbus_crc8(crc, buffer, length + 3);
#ifdef DBG_DUMP
	fprintf(stderr, "i3c write crc 0x%x\n", crc);
#endif
	buffer[length + 3] = crc;

	xfers[0].rnw = 0;
	xfers[0].len = length + i3c_write_overhead;
	xfers[0].data = (uintptr_t)buffer;

	get_current_time (&start);
	for (loop = 0; loop < 20; loop++) {
		ret = ioctl(i3c, I3C_IOC_PRIV_XFER(1), xfers);

		if (!ret) {
			break;
		}

		/*
		 * A write can be NACKed when the device's INDIRECT FIFO is
		 * momentarily full.  Wait before retrying so the consumer side
		 * can drain, instead of hammering the bus with instant retries.
		 */
		if (verbose >= 1) {
			fprintf(stderr, "i3c write retry %d (cmd %d): %s\n",
					loop + 1, cmd, strerror(errno));
		}
		usleep(use_write_delay ? write_delay : 5000);
	}
	get_current_time (&end);

	/* Printed for every write, including each image chunk; see i3c_block_read(). */
	if (verbose >= 3) {
		fprintf(stderr, "Write Cmd (%d us): %d, Length: %d\n",
				get_time_duration(&start, &end), cmd, length);

#if 0
		//todo
		if (verbose >= 2) {
			//todo
			//print_byte_array (tx_smbus, 0, length + smbus_overhead - 1, "SMBus Tx", "");
			//printf ("\n");
		}
#endif
	}

	if (ret) {
		fprintf(stderr, "i3c write transfer failed %s\n", strerror(errno));
	}

	return ret;
}

/**
 * Send the DEVICE_STATUS command to the device and parse the response.
 *
 * @param raw Flag indicating the raw response data should be printed.
 */
uint8_t read_device_status(bool raw, uint8_t *data)
{
	int bytes;
	uint16_t reason;

	bytes = i3c_block_read(DEVICE_STATUS, data, 7, MAX_CMS_READ_BLOCK_SIZE);

	if (!bytes) {
		return -1;
	}

	if (data[6] > 249) {
		fprintf(stderr, "%s: Response malformed.  Vendor data too long (%d)\n", __func__, data[6]);
		return -1;
	}
	else if (bytes != (7 + data[6])) {
		fprintf(stderr, "%s: Invalid response length %d, with vender length %d.\n", __func__, bytes,
			data[1]);
		return -1;
	}

	reason = *((uint16_t*) &data[2]);

	fprintf(stderr, "DEVICE_STATUS:\n");
	fprintf(stderr, "\tStatus: 0x%02x%s%s\n", data[0], (data[0] <= 0xf) ? " -> " : "",
		(data[0] <= 0xf) ? DEVICE_STATUS_STR[data[0]] : "");
	fprintf(stderr, "\tProtocol Error: 0x%02x%s%s\n", data[1], (data[1] <= 0xf) ? " -> " : "",
		(data[1] <= 0xf) ? PROTOCOL_ERROR_STR[data[1]] : "");
	fprintf(stderr, "\tRecovery Reason Code: 0x%04x%s%s\n", reason, (reason <= 0x12) ? " -> " : "",
		(reason <= 0x12) ? RECOVERY_REASON_STR[reason] : "");
	fprintf(stderr, "\tHeartbeat: 0x%04x\n", *((uint16_t*) &data[4]));
	fprintf(stderr, "\tVendor Status Length: 0x%02x\n", data[6]);

	if (data[6] != 0) {
		fprintf(stderr, "\tVendor:\n");
		if (data[6] == 5) {
			/* Assume a vender message formatted per the Cerberus code. */
			fprintf(stderr, "\t\tFailure ID: 0x%02x\n", data[7]);
			fprintf(stderr, "\t\tError Code: 0x%08x\n", *((uint32_t*) &data[8]));
		}
		else {
			//todo
			//print_byte_array (data, 7, bytes - 1, "Status", "\t\t");
		}
	}

	fprintf(stderr, "\n");
//todo
#if 0
	if (raw) {
		print_byte_array (data, 0, bytes - 1, "Raw Data", "\t");
		printf ("\n");
	}
#endif

	return 0;
}

/**
 * Send the RECOVERY_STATUS command to the device and parse the response.
 *
 * @param raw Flag indicating the raw response data should be printed.
 */
uint8_t read_recovery_status(bool raw, uint8_t *data)
{
	if(!i3c_block_read(RECOVERY_STATUS, data, 2, 2)) {
		return -1;
	}

	fprintf(stderr, "RECOVERY_STATUS:\n");
	fprintf(stderr, "\tStatus: 0x%02x%s%s\n", data[0], ((data[0] & 0x0f) <= 0xf) ? " -> " : "",
		((data[0] & 0x0f) <= 0xf) ? RECOVERY_STATUS_STR[(data[0] & 0x0f)] : "");
	fprintf(stderr, "\tVendor specific status: 0x%02x\n", data[1]);
	fprintf(stderr, "\n");

//todo
#if 0
	if (raw) {
		print_byte_array (data, 0, 1, "Raw Data", "\t");
		printf ("\n");
	}
#endif
	return 0;
}

/**
 * Retrieve the capabilites bitmask from the device.
 *
 * @return The device capabilities.
 */
uint16_t get_device_capabilities(void)
{
	uint8_t data[15];

	if(!i3c_block_read(PROT_CAP, data, sizeof (data), sizeof (data))) {
		return 0;
	}

	if (strncmp ("OCP RECV", (char*) data, 8) == 0) {
		return (data[11] << 8) | data[10];
	}
	else {
		return 0;
	}
}

/**
 * Check the device for any protocol errors.
 *
 * Right after streaming an image the device is busy processing it: reads can
 * NACK for a few seconds, and it may report a *transient* Protocol Error (e.g.
 * 0x01 "Unsupported Command") that clears once it settles.  A single read that
 * happens to land in that window would wrongly fail the whole load.  Poll a few
 * times and treat the status as good as soon as we read a clean value; only
 * report an error if it *persists* across every retry (a real error, e.g. a CRC
 * failure, stays set).
 *
 * @param quiet_busy_nack When true, suppress the per-retry i3c read-failure
 * warning during this poll because the caller expects the device to NACK while
 * it is busy (e.g. right after streaming an image).  Defaults to false so that
 * unexpected NACKs in any other context are still reported.
 */
int8_t check_protocol_error(bool quiet_busy_nack = false)
{
	uint8_t data[MAX_CMS_READ_BLOCK_SIZE];
	uint8_t perr = 0;
	bool got_status = false;
	bool prev_quiet = quiet_i3c_retry;
	int8_t rc = -1;
	int tries;

	/*
	 * Only silence the per-retry read-failure message when the caller knows
	 * the device is in its expected post-stream busy window (it NACKs reads
	 * for a few seconds).  In any other context a NACK is unexpected, so the
	 * warning should still be printed.
	 */
	if (quiet_busy_nack)
		quiet_i3c_retry = true;

	for (tries = 0; tries < 8; tries++) {
		memset(buffer, 0, sizeof(buffer));
		if (i3c_block_read (DEVICE_STATUS, data, 7, sizeof(data))) {
			got_status = true;
			perr = data[1];
			if (perr == 0) {
				rc = 0;		/* clean status -> no protocol error */
				break;
			}
		}
		/* busy read (NACK) or a transient error -> wait and re-check */
		usleep (200 * 1000);
	}

	quiet_i3c_retry = prev_quiet;

	if (rc == 0)
		return 0;

	if (!got_status) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return -1;
	}

	fprintf(stderr, "%s: protocol error persisted across retries\n", __func__);
	fprintf (stderr, "Protocol Error: 0x%02x%s%s\n", perr, (perr <= 0xf) ? " -> " : "",
	(perr <= 0xf) ? PROTOCOL_ERROR_STR[perr] : "");
	return -1;
}

/**
 * Send an RECOVERY_STATUS command to check the device for any recovery image errors.
 */
int8_t check_recovery_status(void)
{
	uint8_t data[2];

	memset(buffer, 0, sizeof(buffer));
	if (!i3c_block_read(RECOVERY_STATUS, data, sizeof(data), sizeof(data))) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return -1;
	}

	if (data[0] == 0xf) {
		fprintf(stderr, "Not a valid recovery image region\n");

		if (!ignore_errors) {
			return -1;
		}
	}

	return 0;
}

/**
 * Send the RECOVERY_CTRL command to configure the recovery CMS.
 *
 * @param cms The CMS region to enable for recovery
 * @param activate Flag indicating if the recovery image should be activated.
 */
int send_recovery_ctrl(uint8_t cms, bool activate)
{
	uint8_t data[3];
	memset(buffer, 0, sizeof(buffer));

	data[0] = cms;
	data[1] = 0x1;
	data[2] = (activate) ? 0xf : 0x0;

	return i3c_block_write(RECOVERY_CTRL, data, sizeof(data));
}

/**
 * Read the INDIRECT_CTRL information and parse the response.
 *
 * @param raw Flag indicating the raw response data should be printed.
 */
int8_t read_indirect_ctrl(bool raw)
{
	uint8_t data[6];

	memset(buffer, 0, sizeof(buffer));
	if (!i3c_block_read(INDIRECT_CTRL, data, sizeof(data), sizeof(data))) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return -1;
	}

	fprintf(stderr, "INDIRECT_CTRL:\n");
	fprintf(stderr, "\tComponent Memory Space: 0x%02x\n", data[0]);
	fprintf(stderr, "\tReserved: 0x%02x\n", data[1]);
	fprintf(stderr, "\tIndirect Memory Offset: 0x%08x\n", *((uint32_t*) &data[2]));
	fprintf(stderr, "\n");
#if 0
	//todo
	if (raw) {
		print_byte_array (data, 0, 5, "Raw Data", "\t");
		printf ("\n");
	}
#endif
}

/**
 * Send the INDIRECT_CTRL command to configure the current CMS.
 *
 * @param cms The CMS region to enable.
 * @param offset Offset within the region.
 */
int send_indirect_ctrl(uint8_t cms, uint32_t offset)
{
	uint8_t data[6];

	memset(buffer, 0, sizeof(buffer));
	data[0] = cms;
	data[1] = 0;
	*((uint32_t*) &data[2]) = offset;

	return i3c_block_write(INDIRECT_CTRL, data, sizeof(data));
}

/**
 * Send an INDIRECT_FIFO_STATUS command to check the device for any indirect access errors and
 * confirm the expected region type.
 *
 * @param region_type An option region type code to compare against the active CMS.  If this is
 * negative, type checking will be skipped, but an unsupported region will still trigger an error.
 * @param fail_wrap Flag indicating the program should fail if a CMS wrap is detected.
 *
 * @return true if the region is the expected type or type checking was skipped.
 */
bool check_indirect_fifo_status(int region_type, bool fail_wrap)
{
	uint8_t data[20];

	memset(buffer, 0, sizeof(buffer));
	if(!i3c_block_read(INDIRECT_FIFO_STATUS, data, sizeof(data), sizeof(data))) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return false;
	}
#if 0
	if (fail_wrap && (data[0] & (1U << 0))) {
		fprintf(stderr, "Overflow memory region\n");
		return false;
	}

	if (data[0] & (1U << 1)) {
		fprintf(stderr, "Write to RO CMS\n");
		return false;
	}
#endif

	if ((data[1] & 7) == 0x7) {
		fprintf(stderr, "Unsupported CMS\n");

		if (!ignore_errors) {
			return false;
		}
	}

	return ((data[1] & 0xf) == region_type);
}

/**
 * Query INDIRECT_FIFO_STATUS to get the total size of the active CMS.
 *
 * @return The region size, reported in 4-byte units.
 */
uint32_t get_indirect_fifo_size(void)
{
	uint8_t data[20];

	memset(buffer, 0, sizeof(buffer));
	if(!i3c_block_read(INDIRECT_FIFO_STATUS, data, sizeof(data), sizeof(data))) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return 0;
	}

	return *((uint32_t*) &data[12]);
}

/**
 * Read the INDIRECT_FIFO_CTRL information and parse the response.
 *
 * @param raw Flag indicating the raw response data should be printed.
 */
void read_indirect_fifo_ctrl(bool raw)
{
	uint8_t data[6];

	memset(buffer, 0, sizeof(buffer));
	if (!i3c_block_read(INDIRECT_FIFO_CTRL, data, sizeof(data), sizeof(data))) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return;
	}

	fprintf(stderr, "INDIRECT_FIFO_CTRL:\n");
	fprintf(stderr, "\tComponent Memory Space: 0x%02x\n", data[0]);
	fprintf(stderr, "\tReset: 0x%02x\n", data[1]);
	fprintf(stderr, "\tImage Size: 0x%08x\n", *((uint32_t*) &data[2]));
	fprintf(stderr, "\n");
#if 0
	//todo
	if (raw) {
		print_byte_array (data, 0, 5, "Raw Data", "\t");
		printf ("\n");
	}
#endif
}

/**
 * Send the INDIRECT_FIFO_CTRL command to configure the current CMS.
 *
 * @param cms The CMS region to enable.
 * @param offset Offset within the region.
 */
int send_indirect_fifo_ctrl(uint8_t cms, uint32_t img_size)
{
	uint8_t data[6];

	memset(buffer, 0, sizeof(buffer));
	data[0] = cms;
	data[1] = 0;
	*((uint32_t*) &data[2]) = img_size;

	return i3c_block_write(INDIRECT_FIFO_CTRL, data, sizeof(data));
}

/* INDIRECT_FIFO_STATUS byte-0 flags. */
#define IFS_EMPTY  (1U << 0)
#define IFS_FULL   (1U << 1)

/*
 * Block until the device's INDIRECT FIFO has room for at least need_words
 * 4-byte words, using INDIRECT_FIFO_STATUS for flow control.
 *
 * INDIRECT_FIFO_STATUS layout (DWORD based):
 *   data[0]      : flags (bit0 = Empty, bit1 = Full)
 *   data[4..7]   : Write Index (DWORDs written by host)
 *   data[8..11]  : Read Index  (DWORDs consumed by device)
 *   data[12..15] : FIFO Size   (DWORDs)
 *
 * The Empty flag is used as a safe fallback: when the FIFO reports empty the
 * whole FIFO is free, so progress is guaranteed even if the index offsets need
 * adjusting for a given device.  Run with verbose >= 3 to dump the raw fields
 * and confirm the Write/Read Index offsets on the target.
 */
static int wait_indirect_fifo_room(uint32_t need_words)
{
	uint8_t data[20];
	uint32_t size, wr, rd, used, avail;
	int tries;

	for (tries = 0; tries < 2000; tries++) {          /* up to ~2s at 1ms poll */
		memset(buffer, 0, sizeof(buffer));
		if (!i3c_block_read(INDIRECT_FIFO_STATUS, data, sizeof(data), sizeof(data))) {
			fprintf(stderr, "wait_indirect_fifo_room: INDIRECT_FIFO_STATUS read failed\n");
			return -1;
		}

		size = *(uint32_t *)&data[12];
		wr   = *(uint32_t *)&data[4];
		rd   = *(uint32_t *)&data[8];

		/*
		 * wr/rd are ring pointers (0..size); when they are equal the FIFO
		 * is either empty or full, disambiguated by the flags.  Trust the
		 * flags first, and only fall back to the pointer delta otherwise.
		 */
		if (data[0] & IFS_FULL)
			avail = 0;                             /* full => no room, wait */
		else if (data[0] & IFS_EMPTY)
			avail = size;                          /* empty => whole FIFO free */
		else {
			used = (wr >= rd) ? (wr - rd) : (size - (rd - wr));
			avail = (used <= size) ? (size - used) : 0;
		}

		/* Printed on every poll while streaming; see i3c_block_read(). */
		if (verbose >= 3)
			fprintf(stderr,
				"FIFO status: flags=0x%02x wr=%u rd=%u size=%u free=%u need=%u\n",
				data[0], wr, rd, size, avail, need_words);

		if (avail >= need_words)
			return 0;

		usleep(1000);                                  /* 1ms; let device drain */
	}

	fprintf(stderr, "timeout waiting for FIFO room (need %u words)\n", need_words);
	return -1;
}

int command_load_image(int index, const char *file, bool check_size)
{
	struct stat stat;
	int fd;
	bool valid;
	uint32_t max_length;
	uint8_t data[MAX_CMS_BLOCK_SIZE] = {0};
	uint8_t reg_value[MAX_CMS_READ_BLOCK_SIZE] = {0};
	uint16_t capabilities, reg16;
	int bytes, ret = 0;
	uint32_t total_bytes = 0;

	fprintf(stderr, "Loading image index %d: %s\n", index, file);

	fd = open(file, O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "Failed to open input file %s: %s\n", file, strerror (errno));
		return -1;
	}

	if (fstat(fd, &stat) < 0) {
		fprintf(stderr, "Failed to check size of input file %s: %s\n", file,
				strerror (errno));

		close (fd);
		return -1;
	}

	if (stat.st_size == 0) {
		fprintf(stderr, "Input file %s is empty; a valid recovery image is required.\n",
				file);
		close (fd);
		return -1;
	}
#if 0
	if (send_indirect_ctrl(cms_id, cms_offset)) {
		fprintf(stderr, "%s send_indirect_ctrl fail\n", __func__);
		close (fd);
		return -1;
	}
	WAIT

	if (check_protocol_error()) {
		fprintf(stderr, "%s check_protocol_error fail\n", __func__);
		close (fd);
		return -1;
	}
	WAIT
#endif

	if (read_device_status(false, reg_value)) {
		fprintf(stderr, "read_device_status() failed\n");
		close (fd);
		return -1;
	}
	WAIT

	if (reg_value[0] == DEVICE_HEALTHY) {
		fprintf(stderr, "device_status 0x%02x\n", reg_value[0]);
		close (fd);
		return -1;
	}

	capabilities = get_device_capabilities();
	fprintf(stderr, "PROP_CAT BYTE[11-10]: 0x%x\n", capabilities);
	if (!capabilities) {
		fprintf(stderr, "recovery protocol capabilites are not available\n");
		close (fd);
		return -1;
	} else if ((capabilities & (PROT_CAP2_DEVICE_ID_SUPPORT |
				PROT_CAP2_DEVICE_STATUS_SUPPORT |
				PROT_CAP2_PUSH_C_IMAGE_SUPPORT |
				PROT_CAP2_FLASHLESS_BOOT_VALUE |
				PROT_CAP2_FIFO_CMS_SUPPORT)) !=
				(PROT_CAP2_DEVICE_ID_SUPPORT |
				PROT_CAP2_DEVICE_STATUS_SUPPORT |
				PROT_CAP2_PUSH_C_IMAGE_SUPPORT |
				PROT_CAP2_FLASHLESS_BOOT_VALUE |
				PROT_CAP2_FIFO_CMS_SUPPORT)) {
		/*
		 * Only require the mandatory recovery bits to be present; the device
		 * may advertise additional capabilities, so match the 0x1891 mask
		 * instead of requiring an exact 0x1891 value.
		 */
		fprintf(stderr, "recovery protocol capabilites 0x%x missing required bits 0x%x\n",
				capabilities,
				(PROT_CAP2_DEVICE_ID_SUPPORT |
                                PROT_CAP2_DEVICE_STATUS_SUPPORT |
                                PROT_CAP2_PUSH_C_IMAGE_SUPPORT |
                                PROT_CAP2_FLASHLESS_BOOT_VALUE |
                                PROT_CAP2_FIFO_CMS_SUPPORT));

		close (fd);
		return -1;
	}
	WAIT

	valid = check_indirect_fifo_status(0, false);
	if (!valid) {
		fprintf(stderr, "CMS %d is not a code memory region\n", cms_id);
		if (!ignore_errors) {
			close (fd);
			return -1;
		}
	}
	WAIT

	if (check_size) {
		max_length = get_indirect_fifo_size();
		if (!max_length) {
			fprintf(stderr, "CMS size is not available\n");
			close (fd);
			return -1;
		}

		fprintf(stderr, "CMS %d CMS size=%u\n", cms_id, max_length);
		/*
		 * For Flashless/Streaming Boot the image is streamed through the
		 * INDIRECT FIFO window in chunks, so the total image size may
		 * legitimately exceed the FIFO size reported here.  Skip the
		 * "image larger than FIFO" rejection.
		 */
#if 0
		if ((uint32_t) ((stat.st_size + 3) / 4) > max_length) {
			fprintf(stderr, "CMS %d is not large enough for the image:  CMS=%u, file=%u\n",
					cms_id, max_length, (uint32_t) ((stat.st_size + 3) / 4));
			if (!ignore_errors) {
				close (fd);
				return -1;
			}
		}
#endif
		WAIT
	}

	if (send_indirect_fifo_ctrl(cms_id, ((uint32_t)((stat.st_size + 3) / 4)))) {
		fprintf(stderr, "send_indirect_fifo_ctrl fail\n");
		close (fd);
		return -1;
	}
	WAIT

	if (reg_value[0] != READY_TO_ACCEPT_RECOVERY_IMAGE) {
		fprintf(stderr, "device_status 0x%02x\n", reg_value[0]);
		close (fd);
		return -1;
	}

	reg16 = *(uint16_t *)&reg_value[2];

	if (reg16 != FLASHLESS_STREAMING_BOOT) {
		fprintf(stderr, "device_status reason codes 0x%04x\n", *(uint16_t *)&reg_value[2]);
		close (fd);
		return -1;
	}

	memset(reg_value, 0, sizeof(reg_value));

	if (read_recovery_status(false, reg_value)) {
		fprintf(stderr, "read_recovery_status() failed\n");
		close (fd);
		return -1;
	}
	WAIT

	if (((reg_value[0] & 0x0f) != AWAITING_RECOVERY_IMAGE)
		|| (((reg_value[0] & 0xf0) >> 4) != index)) {
		fprintf(stderr, "recovery_status 0x%02x index 0x%02x\n", reg_value[0], index);
		close (fd);
		return -1;
	}

	do {
		bytes = read (fd, data, cms_block_write);
		if (bytes > 0) {
			if (wait_indirect_fifo_room((bytes + 3) / 4)) {
				fprintf(stderr, "indirect fifo room not available for %d bytes\n", bytes);
				ret = -1;
				break;
			}
			ret = i3c_block_write(INDIRECT_FIFO_DATA, data, bytes);
			if (ret) {
				fprintf(stderr, "write file data fail\n");
				break;
			}
			total_bytes += (uint32_t)bytes;
		}
	} while (bytes > 0);

	if (bytes < 0) {
		fprintf(stderr, "Failed to read data from input file %s: %s\n", file,
				strerror (errno));
		close (fd);
		return -1;
	}

	if (ret) {
		close (fd);
		return -1;
	}

	/*
	 * Diagnostics: the device only reports the image as available (and moves to
	 * RECOVERY_PENDING) once the bytes streamed into INDIRECT_FIFO_DATA reach
	 * INDIRECT_FIFO_CTRL image size (dwords * 4).  Log what we streamed vs the
	 * size we programmed.  (No extra bus reads here: the device is busy right
	 * after streaming and NACKs reads, which would perturb timing.)
	 */
	{
		uint32_t img_words = (uint32_t)((stat.st_size + 3) / 4);

		fprintf(stderr,
			"image streamed: %u bytes (file=%ld, fifo_ctrl size=%u words = %u bytes)\n",
			total_bytes, (long)stat.st_size, img_words, img_words * 4);
	}


	if (check_protocol_error(true)) {
		fprintf(stderr, "%s check_protocol_error fail\n", __func__);
		close (fd);
		return -1;
	}
	WAIT

	close (fd);

	return 0;
}

/**
 * Execute the 'activate_img' command that instructs the device to activate a previously loaded
 * recovery image.
 */
int command_activate_image(bool wait_recovery_pending)
{
	uint8_t reg_value[MAX_CMS_READ_BLOCK_SIZE] = {0};
	int tries;

	/*
	 * Once the whole image has been ingested from the INDIRECT FIFO, the device
	 * advances DEVICE_STATUS to RECOVERY_PENDING (0x4) and then waits for the
	 * host to write RECOVERY_CTRL 'Activate Recovery Image'.  This matches both
	 * Caliptra Core's wait_for_activation() (drivers/src/dma.rs) and the MCU ROM
	 * recovery agent (rom/src/recovery.rs), which gate activation on the
	 * RECOVERY_PENDING hand-off.  Poll DEVICE_STATUS until it appears; a device
	 * that stays at READY_TO_ACCEPT_RECOVERY_IMAGE (0x3) means it is still
	 * draining the FIFO (i.e. the image was not fully received) rather than
	 * ready to activate.  Poll quietly (raw block read) to avoid dumping the
	 * full DEVICE_STATUS block on every iteration.
	 *
	 * When wait_recovery_pending is false the caller wants to activate the
	 * image immediately after streaming, so the RECOVERY_PENDING poll is
	 * skipped and RECOVERY_CTRL is sent right away.
	 */
	if (wait_recovery_pending) {
		for (tries = 0; tries < 300; tries++) {          /* up to ~30s at 100ms */
			memset(buffer, 0, sizeof(buffer));
			if (!i3c_block_read(DEVICE_STATUS, reg_value, 7, MAX_CMS_READ_BLOCK_SIZE)) {
				fprintf(stderr, "read_device_status() failed\n");
				return -1;
			}

			if (reg_value[0] == RECOVERY_PENDING)
				break;

			if (reg_value[0] == DEVICE_ERROR ||
			    reg_value[0] == BOOT_FAILURE ||
			    reg_value[0] == FATAL_ERROR) {
				fprintf(stderr, "device_status error 0x%02x\n", reg_value[0]);
				read_recovery_status(false, reg_value);
				return -1;
			}

			usleep(100 * 1000);
		}

		if (reg_value[0] != RECOVERY_PENDING) {
			fprintf(stderr, "device_status not RECOVERY_PENDING 0x%02x (timeout)\n",
					reg_value[0]);
			/* Show where the device actually is to help diagnose. */
			read_recovery_status(false, reg_value);
			return -1;
		}
		WAIT
	}

	if (send_recovery_ctrl(cms_id, false)) {
		fprintf(stderr, "%s send_recovery_ctrl false fail\r\n", __func__);
		return -1;
	}
	WAIT

	if (check_protocol_error()) {
		fprintf(stderr, "%s check_protocol_error fail\r\n", __func__);
		return -1;
	}
	WAIT

	if (check_recovery_status()) {
		fprintf(stderr, "%s check_recovery_status fail\r\n", __func__);
		return -1;
	}
	WAIT

	if (send_recovery_ctrl(cms_id, true)) {
		fprintf(stderr, "%s send_recovery_ctrl true fail\r\n", __func__);
		return -1;
	}
	WAIT

	return 0;
}

/**
 * Execute the 'recover' command that sends a recovery image to the device and activates it.
 */
int command_recover(void)
{
	const char *rec_file[] = {
		file_name,
		soc_man_file_name,
		mcu_rt_file_name
	};
	bool check_size[3] = {true, true, false};
	int image_index[3] = {FW_IMAGE_INDEX, SOC_MANIFEST_INDEX, MCU_FIRMWARE_INDEX};
	int loop;

	for (loop = 0; loop < 3; loop++) {
		if(command_load_image(image_index[loop], rec_file[loop], check_size[loop])) {
			fprintf(stderr, "%s command_load_image fail\r\n", __func__);
			return -1;
		}

		if(command_activate_image(true)) {
			fprintf(stderr, "%s command_activate_image fail\r\n", __func__);
			return -1;
		}
	}

	return 0;
}


/**
 * Print the application usage.
 */
void print_usage(void)
{
	printf ("Usage: nuv_ocp_recovery -d /dev/${i3c_path} [OPTIONS] COMMAND [ARGS]\n");
}

/**
 * Print the detailed help for the command.
 */
void print_help(void)
{
	printf ("This tool provides a way to communicate with and test devices that implement the\n");
	printf ("firmware recovery protocol specified by the OCP Security workgroup.  Details\n");
	printf ("about the protocol can be found at the OCP Security wiki.\n");
	printf ("\n");
	printf ("https://www.opencompute.org/wiki/Security\n");
	printf ("\n\n");

	print_usage ();

	printf ("\n");
	printf ("OPTIONS\n");
#if 0
	printf ("  -b       :  Show raw response bytes in addition to parsed data.\n");
	printf ("  -c <num> :  The CMS to use for the operation.  Defaults to 0.\n");
#endif
	printf ("  -d /dev/${i3c_path} :  The I3C device path.  Required unless -j is used.\n");
	printf ("  -j <config>         :  JSON config with BusNumber and image paths.  When set,\n");
	printf ("                         the I3C device is auto-discovered from the bus number.\n");
#if 0
	printf ("  -e       :  Force a PEC error on a raw write command.\n");
	printf ("  -f       :  Ignore failed error checks during operation validation.\n");
	printf ("  -l       :  Indicate a vendor RO CMS region uses Cerberus logging format.\n");
	printf ("  -o <hex> :  The offset in a CMS to start reading or writing.  Defaults to 0x68.\n");
	printf ("  -p       :  Disable PEC bytes on block reads and writes.\n");
	printf ("  -r       :  Force the device into recovery mode during reset commands.\n");
	printf ("  -R       :  Maximum number of bytes to read from a CMS in each command.  Defaults to 252 bytes.\n");
	printf ("  -s       :  Add a delay after every write transaction.\n");
	printf ("  -S       :  Specify the amount of time, in usec, to delay after write transactions.  Defaults to 1000.\n");
	printf ("  -v       :  Verbose output for command processing.  Specify multiple times to increase.\n");
	printf ("  -w       :  Execute a raw write transaction.  Default is to execute a read.\n");
	printf ("  -W       :  Maximum number of bytes to write to a CMS in each command.  Defaults to 252 bytes.\n");
	printf ("  -j       :  config file name. Example: /usr/share/lion-recover/lion-recover-config.json\n");
	printf ("  -D       :  Device recovery dbus object, example: /xyz/openbmc_project/device/LION.  Default is empty.\n");
	printf ("  -t       :  Target to update, it could be either \"LION\" or \"HSP#\" where \"#\" is the 1-based indexing for the HSP device.  Default: \"LION\".\n");
#endif
	printf ("  -h       :  Displays the help menu.\n");
	printf ("\n");
	printf ("COMMANDS\n");
	printf ("  recover <fw_image> <soc_manifest> <mcu_rt> :\n");
	printf ("                      Load the FW image, SoC manifest, and MCU runtime images\n");
	printf ("                      into the device and activate each one.\n");
#if 0
	printf ("  load_img <file>   : Write a binary file to device memory.\n");
	printf ("  verify_img <file> : Read CMS data and compare it to a specified file.\n");
	printf ("  activate_img      : Activate an image loaded into device memory.\n");
	printf ("  read_log [file]   : Read and parse contents of a CMS log.  Optionally output to a file.\n");
	printf ("  read_data [file]  : Raw CMS data read.  Optionally output to a file.\n");
	printf ("  reset_device      : Issue a device reset.\n");
	printf ("  reset_mgmt        : Issue a management reset for the device.\n");
	printf ("  show_all          : Send a read request for every command supported by the device.\n");
	printf ("  auto_recover <file> : Set lion's GPIO to enter recovery mode and do recovery.\n");
	printf ("  auto_recover <recovery image> <golden image>: Do HSP recovery.\n");
#endif
	printf ("\n");
#if 0
	printf ("RAW COMMANDS\n");
	printf ("  prot_cap        :  The PROT_CAP command.\n");
	printf ("  device_id       :  The DEVICE_ID command.\n");
	printf ("  device_status   :  The DEVICE_STATUS command.\n");
	printf ("  reset           :  The RESET command.\n");
	printf ("  recovery_ctrl   :  The RECOVERY_CTRL command.\n");
	printf ("  recovery_status :  The RECOVERY_STATUS command.\n");
	printf ("  hw_status       :  The HW_STATUS command.\n");
	printf ("  indirect_ctrl   :  The INDIRECT_CTRL command.\n");
	printf ("  indirect_status :  The INDIRECT_STATUS command.\n");
	printf ("  indirect_data   :  The INDIRECT_DATA command.\n");
	printf ("  vendor          :  The VENDOR command.\n");
	printf ("\n");
	printf ("  Raw commands give direct access to the associated OCP command.  On write\n");
	printf ("  requests, a series of hex values must be provided, one for each field of the\n");
	printf ("  command.  For indirect_data, it would take a list of bytes to write.\n");
	printf ("  Examples:\n");
	printf ("    reset 0x02 0x0f 0x00\n");
	printf ("    indirect_ctrl 0x01 0x00 0x1234\n");
	printf ("    indirect_data 0x00 0x01 0x02 0x03\n");
	printf ("\n");
	printf ("  Raw commands do not use the CMS arguments provided for the normal commands.\n");
	printf ("  This means that INDIRECT or RECOVERY commands will not recognize the CMS or\n");
	printf ("  offset arguments provided.  There is also no checking or protection against\n");
	printf ("  executing unsupported actions, such as writing to read only commands and\n");
	printf ("  regions.\n");
#endif
}

/**
 * Load recovery parameters from a JSON config file.
 *
 * Reads the target I3C bus number and the three recovery image paths, storing
 * them in the globals consumed by command_recover().
 *
 * @param path Path to the JSON config file.
 *
 * @return 0 on success or -1 on failure.
 */
static int load_recovery_config(const char *path)
{
	std::ifstream in(path);
	if (!in.is_open()) {
		fprintf(stderr, "cannot open config %s\n", path);
		return -1;
	}

	nlohmann::json cfg;
	try {
		in >> cfg;
	} catch (const std::exception &e) {
		fprintf(stderr, "failed to parse config %s: %s\n", path, e.what());
		return -1;
	}

	if (!cfg.contains("BusNumber") || !cfg.contains("FwImage") ||
	    !cfg.contains("SocManifest") || !cfg.contains("McuRuntime")) {
		fprintf(stderr, "config %s missing required field(s) "
			"(BusNumber, FwImage, SocManifest, McuRuntime)\n", path);
		return -1;
	}

	device_bus = cfg["BusNumber"].get<int>();
	cfg_fw_image = cfg["FwImage"].get<std::string>();
	cfg_soc_manifest = cfg["SocManifest"].get<std::string>();
	cfg_mcu_rt = cfg["McuRuntime"].get<std::string>();

	file_name = cfg_fw_image.c_str();
	soc_man_file_name = cfg_soc_manifest.c_str();
	mcu_rt_file_name = cfg_mcu_rt.c_str();

	return 0;
}

/**
 * Trigger I3C target discovery on the given bus.
 *
 * Equivalent to "echo 1 > /sys/bus/i3c/devices/i3c-<bus>/discover", this asks
 * the controller to (re)enumerate its targets so a virtual recovery target that
 * was not present at the first scan can appear.
 *
 * @param bus_number I3C bus number from the config.
 *
 * @return 0 on success or -1 if the discover node cannot be written.
 */
static int trigger_i3c_discovery(int bus_number)
{
	std::string path = std::string(I3C_SYSFS_DEVICES) + "i3c-" +
		std::to_string(bus_number) + "/discover";

	std::ofstream out(path);
	if (!out.is_open()) {
		fprintf(stderr, "cannot open %s to trigger discovery: %s\n",
			path.c_str(), strerror(errno));
		return -1;
	}

	out << "1\n";
	out.flush();
	if (out.fail()) {
		fprintf(stderr, "failed to write discover node %s\n", path.c_str());
		return -1;
	}

	fprintf(stderr, "triggered i3c discovery on bus %d (%s)\n",
		bus_number, path.c_str());
	return 0;
}

/**
 * Detach every I3C target currently registered on the given bus.
 *
 * For each "<bus>-<pid>" entry under /sys/bus/i3c/devices/ this is equivalent
 * to "echo 0x<pid> > /sys/bus/i3c/devices/i3c-<bus>/detach".  The kernel
 * detach handler parses the PID with kstrtoull(buf, 0, ...), so the "0x"
 * prefix is required: the sysfs name carries the PID as bare hex ("%llx"),
 * which base 0 would reject as an invalid decimal number.
 *
 * Detach issues RSTDAA and unregisters the device, so its /dev char node goes
 * away and the target may get a different dynamic address at the next
 * discovery.
 *
 * @param bus_number I3C bus number.
 *
 * @return 0 on success (including a bus with no targets) or -1 on failure.
 */
static int detach_i3c_bus_devices(int bus_number)
{
	namespace fs = std::filesystem;
	std::error_code ec;
	std::string prefix = std::to_string(bus_number) + "-";
	std::string detach_path = std::string(I3C_SYSFS_DEVICES) + "i3c-" +
		std::to_string(bus_number) + "/detach";
	std::vector<std::string> pids;

	fs::directory_iterator dir(I3C_SYSFS_DEVICES, ec);
	if (ec) {
		fprintf(stderr, "cannot scan %s: %s\n", I3C_SYSFS_DEVICES,
			ec.message().c_str());
		return -1;
	}

	/*
	 * Collect the PIDs first: every detach removes an entry from the
	 * directory, and it is not specified whether a directory iterator sees
	 * entries removed while it is iterating.
	 */
	for (const auto &entry : dir) {
		std::string name = entry.path().filename().string();

		/* I3C targets are named "<bus>-<provisional_id>", e.g. "2-fffe005a10a5". */
		if (name.rfind(prefix, 0) != 0) {
			continue;
		}

		std::string pid = name.substr(prefix.size());
		if (pid.empty() ||
		    pid.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos) {
			fprintf(stderr, "i3c device %s: unexpected name, not detaching\n",
				name.c_str());
			continue;
		}

		pids.push_back(pid);
	}

	/*
	 * Write with open()/write() rather than std::ofstream: the kernel
	 * reports the result of the detach as the errno of write(), and ENXIO
	 * has to be told apart from real failures below.
	 */
	for (const auto &pid : pids) {
		std::string value = "0x" + pid + "\n";
		int fd = open(detach_path.c_str(), O_WRONLY);
		if (fd < 0) {
			fprintf(stderr, "cannot open %s to detach %s%s: %s\n",
				detach_path.c_str(), prefix.c_str(), pid.c_str(),
				strerror(errno));
			return -1;
		}

		ssize_t written = write(fd, value.data(), value.size());
		int write_errno = errno;
		close(fd);

		if (written < 0) {
			/*
			 * ENXIO: the target is no longer on the bus, e.g.
			 * someone else detached it after we scanned the
			 * directory.  It is already detached, which is what
			 * we want.
			 */
			if (write_errno == ENXIO) {
				fprintf(stderr, "i3c device %s%s already detached\n",
					prefix.c_str(), pid.c_str());
				continue;
			}

			fprintf(stderr, "failed to detach i3c device %s%s via %s: %s\n",
				prefix.c_str(), pid.c_str(), detach_path.c_str(),
				strerror(write_errno));
			return -1;
		}

		fprintf(stderr, "detached i3c device %s%s\n", prefix.c_str(), pid.c_str());
	}

	return 0;
}

/**
 * Read PROT_CAP from an I3C target with a single transfer.
 *
 * Used to confirm that the recovery target candidate supports streaming boot;
 * it is never called for Caliptra's main target (see
 * find_i3c_virtual_device()).  It does not go through
 * get_device_capabilities()/i3c_block_read() for two reasons:
 *
 * - i3c_block_read() retries a failed transfer up to six times with a 1s
 *   sleep in between.  A failed probe is already covered by the caller
 *   rescanning the bus, so the retries would only stall that loop.
 * - i3c_block_read() works on the global i3c fd and addr, which belong to the
 *   device selected for recovery; probing uses its own fd and address.
 *
 * @param cdev     i3cdev character node of the target.
 * @param dyn_addr Dynamic address of the target, used for the PEC.
 *
 * @return The PROT_CAP capabilities (payload bytes 10-11), or 0 if the target
 * did not return a valid PROT_CAP response.
 */
static uint16_t probe_prot_cap(const std::string &cdev, uint8_t dyn_addr)
{
	struct i3c_ioc_priv_xfer xfers[2];
	uint8_t w_data[2];
	/* length (2) + payload + PEC (1) */
	uint8_t r_data[2 + PROT_CAP_RESPONSE_LENGTH + 1] = {0};
	uint8_t cmd = PROT_CAP;
	uint16_t rx_length;
	uint8_t crc;
	int fd, ret, xfer_errno;

	fd = open(cdev.c_str(), O_RDWR);
	if (fd < 0) {
		fprintf(stderr, "PROT_CAP probe: cannot open %s: %s\n", cdev.c_str(),
			strerror(errno));
		return 0;
	}

	/* Write the command code and its PEC, then read the response. */
	crc = checksum_init_smbus_crc8(dyn_addr << 1);
	crc = checksum_update_smbus_crc8(crc, &cmd, 1);
	w_data[0] = cmd;
	w_data[1] = crc;

	memset(xfers, 0, sizeof(xfers));
	xfers[0].rnw = 0;
	xfers[0].len = sizeof(w_data);
	xfers[0].data = (uintptr_t)w_data;
	xfers[1].rnw = 1;
	xfers[1].len = sizeof(r_data);
	xfers[1].data = (uintptr_t)r_data;

	ret = ioctl(fd, I3C_IOC_PRIV_XFER(2), xfers);
	xfer_errno = errno;
	close(fd);

	if (ret) {
		fprintf(stderr, "PROT_CAP probe: no response from %s: %s\n", cdev.c_str(),
			strerror(xfer_errno));
		return 0;
	}

	/*
	 * PROT_CAP has a fixed length.  Any other length also means the PEC is
	 * not where it is expected in r_data, so the response cannot be
	 * verified.
	 */
	rx_length = (uint16_t)r_data[0] | ((uint16_t)r_data[1] << 8);
	if (rx_length != PROT_CAP_RESPONSE_LENGTH) {
		fprintf(stderr, "PROT_CAP probe: %s returned length %u, expected %u\n",
			cdev.c_str(), (unsigned int)rx_length,
			(unsigned int)PROT_CAP_RESPONSE_LENGTH);
		return 0;
	}

	crc = checksum_init_smbus_crc8((dyn_addr << 1) | 1);
	crc = checksum_update_smbus_crc8(crc, r_data, 2 + PROT_CAP_RESPONSE_LENGTH);
	if (crc != r_data[2 + PROT_CAP_RESPONSE_LENGTH]) {
		fprintf(stderr, "PROT_CAP probe: %s PEC failed: CRC=0x%02x, Rx=0x%02x\n",
			cdev.c_str(), crc, r_data[2 + PROT_CAP_RESPONSE_LENGTH]);
		return 0;
	}

	if (memcmp(&r_data[2], "OCP RECV", 8) != 0) {
		fprintf(stderr, "PROT_CAP probe: %s has no OCP recovery magic\n",
			cdev.c_str());
		return 0;
	}

	return (uint16_t)r_data[2 + 10] | ((uint16_t)r_data[2 + 11] << 8);
}

/**
 * Locate the I3C recovery target device for a given bus number.
 *
 * Scans /sys/bus/i3c/devices/ for a target named "<bus>-<provisional_id>" with
 * the virtual-target bit (BCR[4]) set.  Caliptra puts two such targets on the
 * bus: the recovery (virtual) target with BCR 0x30 and the main target with
 * BCR 0x36, which only carries MCTP.  The main target is told apart by its
 * IBI-request-capable bit (BCR[1]) and is never sent anything; the remaining
 * candidate is asked for PROT_CAP and taken if it supports streaming
 * (flashless) boot.  The matching character device path is returned.
 *
 * @param bus_number      I3C bus number.
 * @param only_name       Sysfs name ("<bus>-<provisional_id>") of the one
 *                        target to consider, or empty to consider every
 *                        target on the bus.
 * @param dev_path        Output: "/dev/i3c-<bus>-<provisional_id>" on success.
 * @param targets_present Output: true if the bus has any enumerated target at
 *                        all, whether or not it qualifies.
 *
 * @return 0 on success or -1 if no matching virtual device is found.
 */
static int find_i3c_virtual_device(int bus_number, const std::string &only_name,
				   std::string &dev_path, bool &targets_present)
{
	namespace fs = std::filesystem;
	std::error_code ec;
	std::string prefix = std::to_string(bus_number) + "-";

	targets_present = false;

	fs::directory_iterator dir(I3C_SYSFS_DEVICES, ec);
	if (ec) {
		fprintf(stderr, "cannot scan %s: %s\n", I3C_SYSFS_DEVICES,
			ec.message().c_str());
		return -1;
	}

	for (const auto &entry : dir) {
		std::string name = entry.path().filename().string();

		/* I3C targets are named "<bus>-<provisional_id>", e.g. "2-fffe005a10a5". */
		if (name.rfind(prefix, 0) != 0) {
			continue;
		}

		targets_present = true;

		if (!only_name.empty() && name != only_name) {
			continue;
		}

		std::ifstream bcr_in(entry.path() / "bcr");
		if (!bcr_in.is_open()) {
			continue;
		}

		std::string bcr_str;
		std::getline(bcr_in, bcr_str);
		if (bcr_str.empty()) {
			continue;
		}

		/* sysfs prints bcr as hex (e.g. "0x33"); base 16 handles the optional 0x. */
		unsigned long bcr = strtoul(bcr_str.c_str(), NULL, 16);

		/*
		 * Never send a private transfer to Caliptra's main target: it
		 * sets BCR[4] too, but unlike the recovery target it is IBI
		 * capable (BCR[1]).  On the NPCM500, a single private write
		 * addressed to the main target during recovery was observed to
		 * corrupt the image size the ROM reads from INDIRECT_FIFO_CTRL
		 * of the recovery target, failing the whole recovery.
		 */
		if ((bcr & I3C_BCR_VIRTUAL_TARGET) && (bcr & I3C_BCR_IBI_REQUEST_CAPABLE)) {
			fprintf(stderr,
				"i3c device %s: bcr 0x%02lx is the IBI-capable main target, not probing\n",
				name.c_str(), bcr);
			continue;
		}

		if (bcr & I3C_BCR_VIRTUAL_TARGET) {
			std::string cdev = std::string("/dev/i3c-") + name;

			/*
			 * The bcr match only proves the sysfs entry exists; a
			 * stale/half-attached target can advertise the virtual
			 * bit while lacking a dynamic address and an i3cdev
			 * character node (open()/dynamic_address then fail).
			 * Require the device to be fully usable before accepting
			 * it, otherwise skip it so the caller re-triggers
			 * discovery to re-enumerate the target.
			 */
			std::ifstream da_in(entry.path() / "dynamic_address");
			std::string da_str;
			if (da_in.is_open()) {
				std::getline(da_in, da_str);
			}

			if (da_str.empty()) {
				fprintf(stderr,
					"i3c device %s: bcr 0x%02lx but no dynamic_address, skipping\n",
					name.c_str(), bcr);
				continue;
			}

			if (access(cdev.c_str(), F_OK) != 0) {
				fprintf(stderr,
					"i3c device %s: char node %s not ready, skipping\n",
					name.c_str(), cdev.c_str());
				continue;
			}

			/*
			 * Confirm that the candidate really is a recovery
			 * target with streaming boot support.  sysfs exports
			 * dynamic_address as bare hex digits ("0a"), hence
			 * base 16.
			 */
			uint8_t dyn_addr = (uint8_t)strtoul(da_str.c_str(), NULL, 16);
			uint16_t caps = probe_prot_cap(cdev, dyn_addr);

			if (!(caps & PROT_CAP2_FLASHLESS_BOOT_VALUE)) {
				fprintf(stderr,
					"i3c device %s: PROT_CAP 0x%04x has no streaming boot support, skipping\n",
					name.c_str(), caps);
				continue;
			}

			dev_path = cdev;
			fprintf(stderr,
				"found i3c recovery device %s (bcr 0x%02lx, dynamic_address 0x%s, PROT_CAP 0x%04x)\n",
				dev_path.c_str(), bcr, da_str.c_str(), caps);
			return 0;
		}
	}

	/*
	 * Tell "nothing on the bus" apart from "targets that do not qualify":
	 * the first means the NPCM500 has not been enumerated (yet).
	 */
	if (!targets_present) {
		fprintf(stderr, "no i3c targets enumerated on bus %d\n", bus_number);
	} else {
		fprintf(stderr, "no i3c recovery device with streaming boot support found for bus %d\n",
			bus_number);
	}
	return -1;
}

/**
 * Get the recovery target on a bus ready for the recovery transfer.
 *
 * 1. If the bus already has enumerated targets, ask them for PROT_CAP and use
 *    the one that supports streaming boot.  Nothing is detached or
 *    re-discovered in that case.
 * 2. If targets are enumerated but none of them qualifies, they are treated
 *    as stale (e.g. the NPCM500 was reset and lost its dynamic address while
 *    the kernel still holds the old one) and all of them are detached, once.
 * 3. Trigger discovery and look again, repeating both until the timeout: the
 *    NPCM500 may not be on the bus yet, and right after it joins it may not
 *    serve PROT_CAP yet.  The targets are not detached again inside this
 *    loop, since that would remove a target that has just joined.
 *
 * @param bus_number I3C bus number.
 * @param only_name  Sysfs name ("<bus>-<provisional_id>") of the one target to
 *                   accept, or empty to accept any target on the bus.
 * @param dev_path   Output: "/dev/i3c-<bus>-<provisional_id>" on success.
 *
 * @return 0 on success or -1 on failure.
 */
static int acquire_recovery_device(int bus_number, const std::string &only_name,
				   std::string &dev_path)
{
	bool targets_present = false;
	int elapsed;

	if (find_i3c_virtual_device(bus_number, only_name, dev_path, targets_present) == 0) {
		return 0;
	}

	if (targets_present) {
		fprintf(stderr, "no usable recovery target among the i3c targets on bus %d, "
			"detaching them\n", bus_number);
		if (detach_i3c_bus_devices(bus_number) != 0) {
			return -1;
		}
	}

	for (elapsed = 0; elapsed < TARGET_WAIT_TIMEOUT_S;
	     elapsed += TARGET_DISCOVER_INTERVAL_S) {
		if (trigger_i3c_discovery(bus_number) != 0) {
			return -1;
		}

		if (find_i3c_virtual_device(bus_number, only_name, dev_path,
					    targets_present) == 0) {
			return 0;
		}

		sleep(TARGET_DISCOVER_INTERVAL_S);
	}

	fprintf(stderr, "no i3c recovery device on bus %d after %d s of discovery\n",
		bus_number, TARGET_WAIT_TIMEOUT_S);
	return -1;
}

/**
 * Entry point for the OCP recovery test application.
 *
 * @param argc Number of arguments provided to the application.
 * @param argv Argument list.
 *
 * @return 0 on success or 1 on failure.
 */
int main (int argc, char *argv[])
{
	const char *opts = "d:j:h";
	char sys_path[256];
	char value[32];
	char tmp[128];
	char *result;
	int opt;

	while ((opt = getopt (argc, argv, opts)) != -1) {
		switch (opt) {
			case 'd':
				device_name = optarg;
				break;
			case 'j':
				config_name = optarg;
				break;
			case 'h':
				print_help();
				return 0;
		}
	}

	if (config_name != NULL) {
		if (load_recovery_config(config_name) != 0) {
			return 1;
		}

		/*
		 * Find the recovery target on the config's bus before any i3c
		 * transfer; the bus is detached and re-discovered only when
		 * needed (see acquire_recovery_device()).
		 */
		if (acquire_recovery_device(device_bus, "", cfg_device_path) != 0) {
			return 1;
		}

		device_name = cfg_device_path.data();
		command = "recover";
	} else {
		if (optind >= argc) {
			fprintf(stderr, "nuv_ocp_recovery arguments too few\n");
			print_usage();
			return 1;
		}

		command = argv[optind++];
	}

	if (device_name != NULL) {

		result = strstr(device_name, "-");
		if (result != NULL) {
			FILE *fpipe;

			if (verbose >= 1) {
				fprintf(stderr, "found at %ld\n", (result - device_name));
			}

			strncpy(tmp, (device_name + (result - device_name) + 1), (strlen(device_name) - 
						(result - device_name) - 1));
			tmp[(strlen(device_name) - (result - device_name) - 1)] = '\0';

			if (verbose >= 1) {
				fprintf(stderr, "tmp string:%s\n", tmp);
			}

			/*
			 * Manual -d path: before any i3c transfer, make sure the
			 * given target is on the bus and answers PROT_CAP, the
			 * same way the -j path does for the config's bus.  tmp is
			 * "<bus>-<pid>", so the bus number is its leading digits.
			 * A detach and rediscovery may change the target's
			 * dynamic address, so this must run before
			 * dynamic_address is read below.
			 *
			 * The -j path has already done this for the device it
			 * found, so it is skipped there.
			 */
			if (config_name == NULL) {
				char *bus_end;
				long bus = strtol(tmp, &bus_end, 10);
				std::string found_path;

				/*
				 * Refuse to guess the bus: a wrong bus number would
				 * detach the targets of an unrelated bus.
				 */
				if (bus_end == tmp || *bus_end != '-' || bus < 0 || bus > INT_MAX) {
					fprintf(stderr, "cannot derive i3c bus number from %s\n",
							device_name);
					return 1;
				}

				if (acquire_recovery_device((int)bus, tmp, found_path) != 0) {
					return 1;
				}
			}

			snprintf(sys_path, sizeof(sys_path), 
					"cat /sys/bus/i3c/devices/%s/dynamic_address", tmp);

			if (verbose >= 1) {
				fprintf(stderr, "sys_path :%s\n", sys_path);
			}

			fpipe = popen(sys_path, "r");
			if (fpipe == NULL) {
				fprintf(stderr, "popen failed\n");
				return 1;
			}

			if (fgets(value, sizeof(value), fpipe) != NULL) {
				/*
				 * sysfs exports dynamic_address as bare hex
				 * digits without a 0x prefix ("0a\n"), so parse
				 * with base 16.  atoi() or strtol() base 0/10
				 * would stop at the first hex letter and return
				 * 0, producing a wrong PEC and a NACKed transfer.
				 */
				addr = (uint8_t)strtol(value, NULL, 16);
			}

			pclose(fpipe);

			if (verbose >= 1) {
				fprintf(stderr, "i3c addr 0x%02x\n", addr);
			}
		} else {
			fprintf(stderr, " i3c device path is faulty\n");
			return 1;
		}

		i3c = open(device_name, O_RDWR);
		if (i3c < 0) {
			fprintf(stderr, "i3c open %s failed\n", device_name);
			return 1;
		}

	} else {
		fprintf(stderr, "No i3c device is specified\n");
		print_usage();
		return 1;
	}

	if (strcmp ("recover", command) == 0 && config_name == NULL) {
		if ((optind + 2) >= argc) {
			fprintf (stderr, "files must be provided for this command.\n");
			fprintf (stderr, "Usage: nuv_ocp_recovery -d /dev/${i3c_path} recover "
					"<fw_image> <soc_manifest> <mcu_rt>\n");
			close(i3c);
			return 1;
		}

		file_name = argv[optind++];
		fprintf(stderr, "file name %s\n", file_name);
		soc_man_file_name = argv[optind++];
		fprintf(stderr, "soc manifest file name %s\n", soc_man_file_name);
		mcu_rt_file_name = argv[optind++];
		fprintf(stderr, "mcu rt file name %s\n", mcu_rt_file_name);
	}

	/*
	 * Report a failed recovery through the exit code, so that systemd
	 * marks the service as failed instead of finished.
	 */
	int rc = 0;

	if (strcmp("recover", command) == 0) {
		if (command_recover() != 0) {
			fprintf(stderr, "recovery failed\n");
			rc = 1;
		}
	} else {
		fprintf(stderr, "unknown command: %s\n", command);
		print_usage();
		rc = 1;
	}

	close(i3c);

	return rc;
}
