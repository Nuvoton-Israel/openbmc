/********************************************************************************
* Description   : AST JTAG driver header file
*
* Copyright (C) 2017 Intel Corporation
* Copyright (C) 2012-2020  ASPEED Technology Inc.
* Copyright (C) 2018 NuvoTon Corporation
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by the Free Software Foundation;
* either version 2 of the License, or (at your option) any later version.
* This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY;
* without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#ifndef __JTAG_DRV_H__
#define __JTAG_DRV_H__

#define TDI_DATA_SIZE	    256
#define TDO_DATA_SIZE	    256

struct tck_bitbang {
	unsigned char     tms;
	unsigned char     tdi;        // TDI bit value to write
	unsigned char     tdo;        // TDO bit value to read
};

struct scan_xfer {
	unsigned int     length;      // number of bits to clock
	unsigned char    tdi[TDI_DATA_SIZE];        // data to write to tap (optional)
	unsigned int     tdi_bytes;
	unsigned char    tdo[TDO_DATA_SIZE];        // data to read from tap (optional)
	unsigned int     tdo_bytes;
	unsigned int     end_tap_state;
};

typedef enum {
	JtagTLR,
	JtagRTI,
	JtagSelDR,
	JtagCapDR,
	JtagShfDR,
	JtagEx1DR,
	JtagPauDR,
	JtagEx2DR,
	JtagUpdDR,
	JtagSelIR,
	JtagCapIR,
	JtagShfIR,
	JtagEx1IR,
	JtagPauIR,
	JtagEx2IR,
	JtagUpdIR
} JtagStates;

enum JTAG_PIN {
	/* pin_TRST, */ // this is optional
	pin_TDI,
	pin_TMS,
	pin_TCK,
	pin_TDO,
	pin_NUM,
};


#define JTAGIOC_BASE    'T'

/* ioctl definitions */
#define JTAG_DRIVER_NAME "jtag_drv"

#define AST_JTAG_SIOCFREQ         _IOW( JTAGIOC_BASE, 3, unsigned int)
#define AST_JTAG_GIOCFREQ         _IOR( JTAGIOC_BASE, 4, unsigned int)
#define AST_JTAG_BITBANG          _IOWR(JTAGIOC_BASE, 5, struct tck_bitbang)
#define AST_JTAG_SET_TAPSTATE     _IOW( JTAGIOC_BASE, 6, unsigned int)
#define AST_JTAG_READWRITESCAN    _IOWR(JTAGIOC_BASE, 7, struct scan_xfer)
#define AST_JTAG_SLAVECONTLR      _IOW( JTAGIOC_BASE, 8, unsigned int)

#endif
