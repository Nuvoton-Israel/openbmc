/* Copyright (c) 2018, Nuvoton Corporation */
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>

#include "jtag.h"

extern void DBG_log(int level, const char *format, ...);

static const struct name_mapping {
    enum tap_state symbol;
    const char *name;
} tap_name_mapping[] = {
    { TAP_RESET, "RESET", },
    { TAP_IDLE, "RUN/IDLE", },
    { TAP_DRSELECT, "DRSELECT", },
    { TAP_DRCAPTURE, "DRCAPTURE", },
    { TAP_DRSHIFT, "DRSHIFT", },
    { TAP_DREXIT1, "DREXIT1", },
    { TAP_DRPAUSE, "DRPAUSE", },
    { TAP_DREXIT2, "DREXIT2", },
    { TAP_DRUPDATE, "DRUPDATE", },
    { TAP_IRSELECT, "IRSELECT", },
    { TAP_IRCAPTURE, "IRCAPTURE", },
    { TAP_IRSHIFT, "IRSHIFT", },
    { TAP_IREXIT1, "IREXIT1", },
    { TAP_IRPAUSE, "IRPAUSE", },
    { TAP_IREXIT2, "IREXIT2", },
    { TAP_IRUPDATE, "IRUPDATE", },

    /* only for input:  accept standard SVF name */
    { TAP_IDLE, "IDLE", },
};

const char *tap_state_name(tap_state_t state)
{
    unsigned i;

    for (i = 0; i < ARRAY_SIZE(tap_name_mapping); i++) {
        if (tap_name_mapping[i].symbol == state)
            return tap_name_mapping[i].name;
    }
    return "???";
}

tap_state_t tap_state_by_name(const char *name)
{
    unsigned i;

    for (i = 0; i < ARRAY_SIZE(tap_name_mapping); i++) {
        /* be nice to the human */
        if (strcasecmp(name, tap_name_mapping[i].name) == 0)
            return tap_name_mapping[i].symbol;
    }
    /* not found */
    return TAP_INVALID;
}

STATUS JTAG_set_clock_frequency(int handle, unsigned int frequency)
{
	printf("Set PSPI freq: %u\n", frequency);
	if (ioctl(handle, JTAG_SIOCFREQ, frequency) < 0) {
		DBG_log(LEV_ERROR, "ioctl JTAG_SIOCFREQ failed");
		return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_set_pspi(int handle, unsigned int enable)
{
	if (ioctl(handle, JTAG_PSPI, enable) < 0) {
		DBG_log(LEV_ERROR, "ioctl JTAG_PSPI failed");
		return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_set_directgpio(int handle, unsigned int enable)
{
	if (ioctl(handle, JTAG_DIRECTGPIO, enable) < 0) {
		DBG_log(LEV_ERROR, "ioctl JTAG_DIRECTPGIO failed");
		return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_set_cntlr_mode(int handle, const JTAGDriverState setMode)
{
	if ((setMode < JTAGDriverState_Master) || (setMode > JTAGDriverState_Slave)) {
		DBG_log(LEV_ERROR, "An invalid JTAG controller state was used");
		return ST_ERR;
	}
	DBG_log(LEV_DEBUG, "Setting JTAG controller mode to %s.",
			setMode == JTAGDriverState_Master ? "MASTER" : "SLAVE");
	if (ioctl(handle, JTAG_SLAVECONTLR, setMode) < 0) {
		DBG_log(LEV_ERROR, "ioctl JTAG_SLAVECONTLR failed");
		return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_wait_cycles(JTAG_Handler* state, unsigned int number_of_cycles)
{
	if (state == NULL)
		return ST_ERR;
    if (ioctl(state->JTAG_driver_handle, JTAG_RUNTEST, number_of_cycles) < 0) {
        DBG_log(LEV_ERROR, "ioctl JTAG_RUNTEST failed");
        perror("runtest");
        return ST_ERR;
    }

	return ST_OK;
}

//
// Request the TAP to go to the target state
//
STATUS JTAG_set_tap_state(JTAG_Handler* state, JtagStates tap_state)
{
	if (state == NULL)
		return ST_ERR;

	if (ioctl(state->JTAG_driver_handle, JTAG_SET_TAPSTATE, tap_state) < 0) {
		DBG_log(LEV_ERROR, "ioctl JTAG_SET_TAPSTATE failed");
		return ST_ERR;
	}

	// move the [soft] state to the requested tap state.
	state->tap_state = tap_state;
#if 0
	if ((tap_state == JtagRTI) || (tap_state == JtagPauDR))
		if (JTAG_wait_cycles(state, 5) != ST_OK)
			return ST_ERR;
#endif
	DBG_log(LEV_DEBUG, "TapState: %d", state->tap_state);
	return ST_OK;
}

STATUS JTAG_shift(JTAG_Handler* state, struct scan_xfer *scan_xfer)
{
	if (ioctl(state->JTAG_driver_handle, JTAG_READWRITESCAN, scan_xfer) < 0) {
		DBG_log(LEV_ERROR, "ioctl JTAG_READWRITESCAN failed!");
		return ST_ERR;
	}

	return ST_OK;
}

int JTAG_dr_scan(JTAG_Handler* handler, int num_bits, const uint8_t *out_bits, uint8_t *in_bits,
	tap_state_t state)
{
	struct scan_xfer scan_xfer = {0};
	int remaining_bits = num_bits;
	int n, bits, index = 0;

	memset(scan_xfer.tdi, 0, sizeof(scan_xfer.tdi));
	JTAG_set_tap_state(handler, JtagShfDR);
	while (remaining_bits > 0) {
		n = (remaining_bits / 8) > TDI_DATA_SIZE ? TDI_DATA_SIZE : (remaining_bits + 7) / 8;
		memcpy(scan_xfer.tdi, out_bits + index, n);

		bits = ((n * 8) > remaining_bits)? remaining_bits: (n * 8);
		remaining_bits -= bits;
		scan_xfer.length = bits;
		scan_xfer.tdi_bytes = n;
		scan_xfer.tdo_bytes = n;
		if (remaining_bits > 0)
			scan_xfer.end_tap_state = JtagShfDR;
		else
			scan_xfer.end_tap_state = state;
		if (JTAG_shift(handler, &scan_xfer) != ST_OK) {
			DBG_log(LEV_ERROR, "ShftDR error");
			return -1;
		}
		if (in_bits)
			memcpy(in_bits+index, scan_xfer.tdo, scan_xfer.tdo_bytes);
		index += n;
	}
	return 0;
}

int JTAG_ir_scan(JTAG_Handler* handler, int num_bits, const uint8_t *out_bits, uint8_t *in_bits,
	tap_state_t state)
{
	struct scan_xfer scan_xfer = {0};
	if (num_bits == 0)
		return -1;
	if ((num_bits + 7) / 8 > TDO_DATA_SIZE) {
		DBG_log(LEV_ERROR, "ir data len too long: %d bits", num_bits);
		return -1;
	}
	JTAG_set_tap_state(handler, JtagShfIR);
	scan_xfer.length = num_bits;
	scan_xfer.tdi_bytes = (num_bits + 7) / 8;
	memcpy(scan_xfer.tdi, out_bits, scan_xfer.tdi_bytes);
	scan_xfer.tdo_bytes = scan_xfer.tdi_bytes;
	scan_xfer.end_tap_state = state;
	if (JTAG_shift(handler, &scan_xfer) != ST_OK) {
		DBG_log(LEV_ERROR, "ShftIR error");
		return -1;
	}
	if (in_bits)
		memcpy(in_bits, scan_xfer.tdo, scan_xfer.tdo_bytes);

	return 0;
}

