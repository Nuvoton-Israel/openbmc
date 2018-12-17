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

#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>

#define BUFFER_SIZE 256
#define MAX_REG_NAME 256
#define BROADCAST_MESSAGE_ORIGIN_ID 7

// ASD Protocol Event IDs
typedef enum {
	ASD_EVENT_PLRSTDEASSRT = 1,
	ASD_EVENT_PLRSTASSERT,
	ASD_EVENT_PRDY_EVENT,
	ASD_EVENT_PWRRESTORE,
	ASD_EVENT_PWRFAIL
} ASD_EVENT;

typedef enum {
	ST_OK,
	ST_ERR
} STATUS;

typedef enum {
	JTAG_FREQ = 1,    // Size: 1 Byte
	DR_PREFIX,        // Size: 1 Byte
	DR_POSTFIX,       // Size: 1 Byte
	IR_PREFIX,        // Size: 2 Bytes, LSB first
	IR_POSTFIX,       // Size: 2 Bytes, LSB first
	PRDY_TIMEOUT      // Size: 1 Byte
} writeCfg;

typedef enum {
	AGENT_CONTROL_TYPE = 0,
	JTAG_TYPE,
	PROBE_MODE_TYPE,
	DMA_TYPE
} headerType;

// The protocol spec states the following:
//    the status code that either contains 0x00 for successful completion
//    of a command, or an error code from 0x01 to 0x7f
typedef enum {
	ASD_SUCCESS = 0,
	ASD_UNKNOWN_ERROR = 0x7f
} ASDError;

struct message_header {
	uint32_t origin_id : 3;
	uint32_t reserved  : 1;
	uint32_t enc_bit   : 1;
	uint32_t type      : 3;
	uint32_t size_lsb  : 8;
	uint32_t size_msb  : 5;
	uint32_t tag       : 3;
	uint32_t cmd_stat  : 8;
} __attribute__((packed));

struct spi_message {
	struct message_header header;
	unsigned char* buffer;
} __attribute__((packed));


//  At Scale Debug Commands
//
//  NAME            COMMAND MASK    NOTES
//
//  WriteEventCfg   00000000
#define WRITE_EVENT_CONFIG      0

//  WriteCfg        00000nnn        n defines the config setting
//                                  Note: Conflicts with WritePins
//                                  and WriteEventCfg!
#define WRITE_CFG_MIN           1  // +1 because of WriteEventCfg conflict
#define WRITE_CFG_MAX           6  // -1 because of WritePins conflict

// This mask is used to extract the write event index from a command byte
#define WRITE_CFG_MASK          0x7f

//  WritePins       00000111
#define WRITE_PINS              7

// This mask is used to extract the write pin from a command byte
#define WRITE_PIN_MASK          0x7f

//  ReadStatus      00001nnn        n defines the status register
#define READ_STATUS_MIN         8
#define READ_STATUS_MAX         0xf

// This mask is used to extract the read config index from a command byte
#define READ_STATUS_MASK        0x7
#define READ_STATUS_PIN_MASK    0x7f

//  WaitCycles      0001000e        If e is set to 1 enables TCK
//                                  during the wait period
#define WAIT_CYCLES_TCK_DISABLE 0x10
#define WAIT_CYCLES_TCK_ENABLE  0x11

//  WaitPRDY        00010010
#define WAIT_PRDY               0x12

//  ClearTimeout    00010011
#define CLEAR_TIMEOUT           0x13

//  TapReset        00010100
#define TAP_RESET               0x14

//  TapState        0010SSSS        S defines desired state
#define TAP_STATE_MIN           0x20
#define TAP_STATE_MAX           0x2f

//  This mask is used for extracting the desired tap state from a command
#define TAP_STATE_MASK          0xf

//  WriteScan       01LLLLLL        L is number of bits
#define WRITE_SCAN_MIN          0x40
#define WRITE_SCAN_MAX          0x7f

//  ReadScan        10LLLLLL        L is number of bits
#define READ_SCAN_MIN           0x80
#define READ_SCAN_MAX           0xbf

//  RWScan          11LLLLLL        L is number of bits
#define READ_WRITE_SCAN_MIN     0xc0
#define READ_WRITE_SCAN_MAX     0xff

//  This mask is used for extracting the length for all the scan commands
#define SCAN_LENGTH_MASK        0x3f

#endif  // COMMON_H
