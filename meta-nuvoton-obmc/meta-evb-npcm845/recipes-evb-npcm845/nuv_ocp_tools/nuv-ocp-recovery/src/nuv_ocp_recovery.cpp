// Copyright (c) Nuvoton technology. All rights reserved.
// Licensed under the MIT license.

#include <filesystem>
#include <memory>
#include <stdlib.h>
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

#define PROT_CAP2_DEVICE_ID_SUPPORT BIT(0)
#define PROT_CAP2_DEVICE_STATUS_SUPPORT BIT(4)
#define PROT_CAP2_PUSH_C_IMAGE_SUPPORT BIT(7)
#define PROT_CAP2_FLASHLESS_BOOT_VALUE BIT(11)
#define PROT_CAP2_FIFO_CMS_SUPPORT BIT(12)

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
 */
uint32_t cms_block_write = MAX_CMS_BLOCK_SIZE;

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
int verbose = 0;

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
		printf ("Failed to get the current time: %s\n", strerror (errno));
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
			fprintf(stderr, "i3c read transfer failed 2nd time %s\n", strerror(errno));
		} else {
			break;
		}
	}
	get_current_time (&end);

	if (verbose >= 1) {
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

	if (length < rx_length) {
		fprintf(stderr, "WARNING: Incomplete block read (%d < %d)\n", length, rx_length);
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
		printf ("PEC failed: CRC=0x%x, Rx=%x\n", crc, buffer[length + 2]);
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
	for (loop = 0; loop < 3; loop++) {
		ret = ioctl(i3c, I3C_IOC_PRIV_XFER(1), xfers);

		if (!ret) {
			break;
		}

		if (use_write_delay) {
			usleep (write_delay);
		}
	}
	get_current_time (&end);

	if (verbose >= 1) {
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
 */
int8_t check_protocol_error(void)
{
	uint8_t data[MAX_CMS_READ_BLOCK_SIZE];

	memset(buffer, 0, sizeof(buffer));
	if(!i3c_block_read (DEVICE_STATUS, data, 7, sizeof(data))) {
		fprintf(stderr, "%s i3c_block_read fail\n", __func__);
		return -1;
	}

	if (data[1] != 0) {
		printf ("Protocol Error: 0x%02x%s%s\n", data[1], (data[1] <= 0xf) ? " -> " : "",
		(data[1] <= 0xf) ? PROTOCOL_ERROR_STR[data[1]] : "");
		return -1;
	}

	return 0;
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

int command_load_image(int index, const char *file, bool check_size)
{
	struct stat stat;
	int fd;
	bool valid;
	uint32_t max_length;
	uint8_t data[MAX_CMS_BLOCK_SIZE] = {0};
	uint8_t reg_value[MAX_CMS_READ_BLOCK_SIZE] = {0};
	uint16_t capabilities, reg16;
	int bytes, ret;

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
	} else if (capabilities != (PROT_CAP2_DEVICE_ID_SUPPORT |
				PROT_CAP2_DEVICE_STATUS_SUPPORT |
				PROT_CAP2_PUSH_C_IMAGE_SUPPORT |
				PROT_CAP2_FLASHLESS_BOOT_VALUE |
				PROT_CAP2_FIFO_CMS_SUPPORT)) {
		fprintf(stderr, "recovery protocol capabilites expected 0x%x\n",
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

		fprintf(stderr, "CMS %d CMS=%u\n", cms_id, max_length);
		if ((uint32_t) ((stat.st_size + 3) / 4) > max_length) {
			fprintf(stderr, "CMS %d is not large enough for the image:  CMS=%u, file=%u\n",
					cms_id, max_length, (uint32_t) ((stat.st_size + 3) / 4));
			if (!ignore_errors) {
				close (fd);
				return -1;
			}
		}
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
		fprintf(stderr, "read_device_status() failed\n");
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
			ret = i3c_block_write(INDIRECT_FIFO_DATA, data, bytes);
			if (ret) {
				fprintf(stderr, "write file data fail\n");
				break;
			}
			WAIT
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


	if (check_protocol_error()) {
		fprintf(stderr, "%s check_protocol_error fail\n", __func__);
		close (fd);
		return -1;
	}
	WAIT

	check_indirect_fifo_status(-1, false);
	WAIT

	close (fd);

	return 0;
}

/**
 * Execute the 'activate_img' command that instructs the device to activate a previously loaded
 * recovery image.
 */
int command_activate_image(void)
{
	uint8_t reg_value[MAX_CMS_READ_BLOCK_SIZE] = {0};

	if (read_device_status(false, reg_value)) {
		fprintf(stderr, "read_device_status() failed\n");
		return -1;
	}
	WAIT

	if (reg_value[0] != RECOVERY_PENDING) {
		fprintf(stderr, "device_status not RECOVERY_PENDING 0x%02x\n", reg_value[0]);
		return -1;
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

		if(command_activate_image()) {
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
	printf ("  -d /dev/${i3c_path} :  The I3C device path.  This is required.\n");
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
	printf ("  recover <file>    : Load a binary image into the device and activate it.\n");
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
 * Entry point for the OCP recovery test application.
 *
 * @param argc Number of arguments provided to the application.
 * @param argv Argument list.
 *
 * @return 0 on success or 1 on failure.
 */
int main (int argc, char *argv[])
{
	const char *opts = "d:h";
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
			case 'h':
				print_help();
				return 0;
		}
	}

	if (optind >= argc) {
		fprintf(stderr, "nuv_ocp_recovery arguments too few\n");
		print_usage();
		return 1;
	}

	command = argv[optind++];

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
				addr = atoi(value);
			}

			pclose(fpipe);
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

	if (strcmp ("recover", command) == 0) {
		if ((optind + 2) >= argc) {
			fprintf (stderr, "files must be provided for this command.\n");
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

	if (strcmp("recover", command) == 0) {
		command_recover();
	}

	close(i3c);

	return 0;
}
