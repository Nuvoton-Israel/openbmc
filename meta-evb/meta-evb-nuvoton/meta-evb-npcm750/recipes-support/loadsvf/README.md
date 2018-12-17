# loadsvf

Takes a image in SVF format and download to FPGA or CPLD device through JTAG interface on NPCM750 BMC.

## Building

```bash
bitbake loadsvf
```

## Usage

```bash
loadsvf -d <jtag_device> -s <svf_file>
        [-l <log_level> -m <transfer_mode> -f <frequency> -g]
```

**-d jtag_device:**  
specify the jtag device node <ex: /dev/jtag_drv>

**-s svf_file:**  
specify the svf file path  

**-l loglevel:**  
display the log whose level is large or equal to the specified loglevel
LOG LEVEL:  
1: Debug  
2: Info  
3: Error  

**-m transfer mode:**  
enable PSPI mode if bit 0 is set  
enable directGPIO if bit 1 is set  

**-f frequency:**  
force running at specific frequency in Mhz for PSPI mode.  
the accepted frequency is 1 ~ 25  

**-g:**  
execute svf command line by line  


