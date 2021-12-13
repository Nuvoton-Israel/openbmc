/*
   Copyright (c) 2017, Intel Corporation

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Intel Corporation nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#include "SoftwareJTAGHandler.h"
#include "asd_common.h"
#include "logging.h"
#include <sys/mman.h>


STATUS JTAG_set_cntlr_mode(int handle, const JTAGDriverState setMode);
STATUS JTAG_clock_cycle(int handle, unsigned char tms, unsigned char tdi);
STATUS perform_shift(int handle, unsigned int number_of_bits,
		unsigned int input_bytes, unsigned char* input,
		unsigned int output_bytes, unsigned char* output,
		JtagStates current_tap_state, JtagStates end_tap_state);

JTAG_Handler* SoftwareJTAGHandler()
{
	JTAG_Handler* state = (JTAG_Handler*)malloc(sizeof(JTAG_Handler));
	if (state == NULL) {
		return NULL;
	}

	state->shift_padding.drPre = 0;
	state->shift_padding.drPost = 0;
	state->shift_padding.irPre = 0;
	state->shift_padding.irPost = 0;

	state->tap_state = JtagTLR;
	memset(state->padDataOne, ~0, sizeof(state->padDataOne));
	memset(state->padDataZero, 0, sizeof(state->padDataZero));
	state->scan_state = JTAGScanState_Done;

	state->JTAG_driver_handle = open("/dev/jtag_drv", O_RDWR);
	if (state->JTAG_driver_handle == -1) {
		ASD_log(LogType_Error, "Can't open /dev/jtag_drv, please install driver");
		free(state);
		return NULL;
	}

	if (JTAG_set_cntlr_mode(state->JTAG_driver_handle, JTAGDriverState_Slave) != ST_OK) {
		ASD_log(LogType_Error, "Failed to set JTAG mode to slave.");
		close(state->JTAG_driver_handle);
		free(state);
		return NULL;
	}
	return state;
}

STATUS JTAG_clock_cycle(int handle, unsigned char tms, unsigned char tdi)
{
	struct tck_bitbang bitbang = {0};

	bitbang.tms = tms;
	bitbang.tdi = tdi;

	if (ioctl(handle, AST_JTAG_BITBANG, &bitbang) < 0) {
		ASD_log(LogType_Error, "ioctl AST_JTAG_BITBANG failed");
		return ST_ERR;
	}
	return ST_OK;
}

// user level access to set the AST2500 JTAG controller in slave or master mode
STATUS JTAG_set_cntlr_mode(int handle, const JTAGDriverState setMode)
{
	if ((setMode < JTAGDriverState_Master) || (setMode > JTAGDriverState_Slave)) {
		ASD_log(LogType_Error, "An invalid JTAG controller state was used");
		return ST_ERR;
	}
	ASD_log(LogType_Debug, "Setting JTAG controller mode to %s.",
			setMode == JTAGDriverState_Master ? "MASTER" : "SLAVE");
	if (ioctl(handle, AST_JTAG_SLAVECONTLR, setMode) < 0) {
		ASD_log(LogType_Error, "ioctl AST_JTAG_SLAVECONTLR failed");
		return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_initialize(JTAG_Handler* state)
{
	if (state == NULL)
		return ST_ERR;

	if (JTAG_set_cntlr_mode(state->JTAG_driver_handle, JTAGDriverState_Master) != ST_OK) {
		ASD_log(LogType_Error, "Failed to set JTAG mode to master.");
		return ST_ERR;
	}
	if (JTAG_set_tap_state(state, JtagTLR) != ST_OK ||
			JTAG_set_tap_state(state, JtagRTI) != ST_OK) {
		ASD_log(LogType_Error, "Failed to set initial TAP state.");
		return ST_ERR;
	}
	if (JTAG_set_padding(state, JTAGPaddingTypes_DRPre, 0) != ST_OK ||
			JTAG_set_padding(state, JTAGPaddingTypes_DRPost, 0) != ST_OK ||
			JTAG_set_padding(state, JTAGPaddingTypes_IRPre, 0) != ST_OK ||
			JTAG_set_padding(state, JTAGPaddingTypes_IRPost, 0) != ST_OK) {
		ASD_log(LogType_Error, "Failed to set initial padding states.");
		return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_deinitialize(JTAG_Handler* state)
{
	if (state == NULL)
		return ST_ERR;

	STATUS result = JTAG_set_cntlr_mode(state->JTAG_driver_handle, JTAGDriverState_Slave);
	if (result != ST_OK) {
		ASD_log(LogType_Error, "Failed to set JTAG mode to slave.");
	}
	return result;
}

STATUS JTAG_set_padding(JTAG_Handler* state, const JTAGPaddingTypes padding, const int value)
{
	if (state == NULL)
		return ST_ERR;

	if (padding == JTAGPaddingTypes_DRPre) {
		state->shift_padding.drPre = value;
	} else if (padding == JTAGPaddingTypes_DRPost) {
		state->shift_padding.drPost = value;
	} else if (padding == JTAGPaddingTypes_IRPre) {
		state->shift_padding.irPre = value;
	} else if (padding == JTAGPaddingTypes_IRPost) {
		state->shift_padding.irPost = value;
	} else {
		ASD_log(LogType_Error, "Unknown padding value: %d", value);
		return ST_ERR;
	}
	return ST_OK;
}

//
// Reset the Tap and wait in idle state
//
STATUS JTAG_tap_reset(JTAG_Handler* state)
{
	if (state == NULL)
		return ST_ERR;
	return JTAG_set_tap_state(state, JtagTLR);
}

//
// Request the TAP to go to the target state
//
STATUS JTAG_set_tap_state(JTAG_Handler* state, JtagStates tap_state)
{
	if (state == NULL)
		return ST_ERR;

	if (ioctl(state->JTAG_driver_handle, AST_JTAG_SET_TAPSTATE, tap_state) < 0) {
		ASD_log(LogType_Error, "ioctl AST_JTAG_SET_TAPSTATE failed");
		return ST_ERR;
	}

	// move the [soft] state to the requested tap state.
	state->tap_state = tap_state;
#if 0
	if ((tap_state == JtagRTI) || (tap_state == JtagPauDR))
		if (JTAG_wait_cycles(state, 5) != ST_OK)
			return ST_ERR;
#endif
	ASD_log(LogType_IRDR, "TapState: %d", state->tap_state);
	return ST_OK;
}

//
// Retrieve the current the TAP state
//
STATUS JTAG_get_tap_state(JTAG_Handler* state, JtagStates* tap_state)
{
	if (state == NULL || tap_state == NULL)
		return ST_ERR;
	*tap_state = state->tap_state;
	return ST_OK;
}

//
//  Optionally write and read the requested number of
//  bits and go to the requested target state
//
STATUS JTAG_shift(JTAG_Handler* state, unsigned int number_of_bits,
		unsigned int input_bytes, unsigned char* input,
		unsigned int output_bytes, unsigned char* output,
		JtagStates end_tap_state)
{
	if (state == NULL)
		return ST_ERR;

	unsigned int preFix = 0;
	unsigned int postFix = 0;
	unsigned char* padData = state->padDataOne;

	if (state->tap_state == JtagShfIR) {
		preFix = state->shift_padding.irPre;
		postFix = state->shift_padding.irPost;
		padData = state->padDataOne;
	} else if (state->tap_state == JtagShfDR) {
		preFix = state->shift_padding.drPre;
		postFix = state->shift_padding.drPost;
		padData = state->padDataZero;
	} else {
		ASD_log(LogType_Error, "Shift called but the tap is not in a ShiftIR/DR tap state");
		return ST_ERR;
	}

	if (state->scan_state == JTAGScanState_Done) {
		state->scan_state = JTAGScanState_Run;
		if (preFix) {
			if (perform_shift(state->JTAG_driver_handle, preFix, MAXPADSIZE, padData,
						0, NULL, state->tap_state, state->tap_state) != ST_OK)
				return ST_ERR;
		}
	}

	if ((postFix) && (state->tap_state != end_tap_state)) {
		state->scan_state = JTAGScanState_Done;
		if (perform_shift(state->JTAG_driver_handle, number_of_bits, input_bytes, input,
					output_bytes, output, state->tap_state, state->tap_state) != ST_OK)
			return ST_ERR;
		if (perform_shift(state->JTAG_driver_handle, postFix, MAXPADSIZE, padData, 0,
					NULL, state->tap_state, end_tap_state) != ST_OK)
			return ST_ERR;
	} else {
		if (perform_shift(state->JTAG_driver_handle, number_of_bits, input_bytes, input,
					output_bytes, output, state->tap_state, end_tap_state) != ST_OK)
			return ST_ERR;
		if (state->tap_state != end_tap_state) {
			state->scan_state = JTAGScanState_Done;
		}
	}
	return ST_OK;
}

//
//  Optionally write and read the requested number of
//  bits and go to the requested target state
//
STATUS perform_shift(int handle, unsigned int number_of_bits,
		unsigned int input_bytes, unsigned char* input,
		unsigned int output_bytes, unsigned char* output,
		JtagStates current_tap_state, JtagStates end_tap_state)
{
	struct scan_xfer scan_xfer = {0};
	scan_xfer.length = number_of_bits;
	scan_xfer.tdi_bytes = input_bytes;
	//scan_xfer.tdi = input;
	memcpy(scan_xfer.tdi, input, input_bytes);
	scan_xfer.tdo_bytes = output_bytes;
	//scan_xfer.tdo = output;
	scan_xfer.end_tap_state = end_tap_state;

	if (ioctl(handle, AST_JTAG_READWRITESCAN, &scan_xfer) < 0) {
		ASD_log(LogType_Error, "ioctl AST_JTAG_READWRITESCAN failed!");
		return ST_ERR;
	}

	memcpy(output, scan_xfer.tdo, output_bytes);

	if (prnt_irdr) {
		unsigned int number_of_bytes = (number_of_bits + 7) / 8;
		const char* shiftStr = (current_tap_state == JtagShfDR) ? "DR" : "IR";
		ASD_log(LogType_IRDR, "%s size: %d", shiftStr, number_of_bits);
		if (input != NULL && number_of_bytes <= input_bytes) {
			ASD_log_buffer(LogType_IRDR, input, number_of_bytes,
					(current_tap_state == JtagShfDR) ? "DR TDI" : "IR TDI");
		}
		if (output != NULL && number_of_bytes <= output_bytes) {
			ASD_log_buffer(LogType_IRDR, output, number_of_bytes,
					(current_tap_state == JtagShfDR) ? "DR TDO" : "IR TDO");
		}
		ASD_log(LogType_IRDR, "%s: End tap state: %d", shiftStr, end_tap_state);
	}
	return ST_OK;
}

//
// Wait for the requested cycles.
//
// Note: It is the responsibility of the caller to make sure that
// this call is made from RTI, PauDR, PauIR states only. Otherwise
// will have side effects !!!
//
STATUS JTAG_wait_cycles(JTAG_Handler* state, unsigned int number_of_cycles)
{
	if (state == NULL)
		return ST_ERR;
	for (unsigned int i = 0; i < number_of_cycles; i++) {
		if (JTAG_clock_cycle(state->JTAG_driver_handle, 0, 0) != ST_OK)
			return ST_ERR;
	}
	return ST_OK;
}

STATUS JTAG_set_clock_frequency(JTAG_Handler* state, unsigned int frequency)
{
	if (state == NULL)
		return ST_ERR;
	if (ioctl(state->JTAG_driver_handle, AST_JTAG_SIOCFREQ, frequency) < 0) {
		ASD_log(LogType_Error, "ioctl AST_JTAG_SIOCFREQ failed");
		return ST_ERR;
	}
	return ST_OK;
}
