Nuvoton NPCM845 Evaluation Board
================

This is the Nuvoton NPCM845 evaluation board layer.
The NPCM845 is an ARM based SoC with external DDR RAM and 
supports a large set of peripherals made by Nuvoton. 

# Dependencies
This layer depends on:

```
  URI: github.com/Nuvoton-Israel/openbmc.git
  branch: npcm-v2.10
```

# Contacts for Patches

Please submit any patches against the meta-evb-npcm845 layer to the maintainer of nuvoton:
* Joseph Liu, <KWLIU@nuvoton.com>
* Stanley Chu, <YSCHU@nuvoton.com>
* Tyrone Ting, <KFTING@nuvoton.com>
* Medad Cchien, <CTCCHIEN@nuvoton.com>

# Table of Contents

- [Dependencies](#dependencies)
- [Contacts for Patches](#contacts-for-patches)
- [Getting Started](#getting-started)
  * [Setting up EVB](#setting-up-evb)
  * [Building your OpenBMC project](#building-your-openbmc-project)
  * [Programming Firmware for the first time](#programming-firmware-for-the-first-time)
    + [Bootloader](#bootloader)
    + [OpenBMC](#openbmc)
- [Interfaces](#interfaces)
  * [UART](#uart)
  * [Network](#network)
  * [I3C](#i3c)
  * [JTag Master](#jtag-master)
  * [SMB](#smb)
  * [ESPI](#espi)

# Getting Started

## Setting up EVB

### 1) Strap settings
* By default, only turn on strap 5 of the SW_STRAP1_8 dip switch.
* The other straps remain off.

### 2) Power Source selector
* JP_5V_SEL set to 1-2, If On-Board VR(12V->5V) is used to power the EVB (<span style="color: green">Remcommanded)
* JP_5V_SEL set to 2-3, If USB VBUS is used to power the EVB

### 3) BMC Console

* Connect a Mini-USB cable to J_USB_TO_UART
* You will get 4 serial port options from your terminal settings.
* Please select second serial port and set baud rate to 115200.
* After EVB is powered on, you will get BMC logs from the terminal.

### 4) Secure boot status
* When you see the following BMC message, it means that secure boot is enabled.
```ruby
Nuvoton Technologies: BMC NPCM8XX
.....
.....
TipROM 0x104 ** Secure boot is enabled
.....
.....
```

## Building your OpenBMC project

### 1) Target EVB NPCM845
Source the setup script as follows:
```ruby
. setup evb-npcm845
```

### 2) Configuration

If secure boot is enabled, please enable [SECURED TIPFW](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.10/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/conf/machine/evb-npcm845.conf#L8)
```ruby
SECURED_TIPFW = "True"
```

To enable memory ECC function, please enable [MC_CAPABILITY_ECC_EN](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.10/meta-nuvoton/recipes-bsp/images/npcm8xx-igps/BootBlockAndHeader_ArbelEVB.xml#L181)
```ruby
<BinField>
	<!-- MC_CONFIG. 
		Bit 0: MC_CAPABILITY_ECC_EN (0x01)
		 -->
	<name>MC_CONFIG</name>          
	<config>
		<offset>0x134</offset>       
		<size>0x1</size> 
	</config>
	<content format='32bit'>0x01</content>  
</BinField>
```
### 3) Build
[Inventory manager distro](https://github.com/openbmc/phosphor-inventory-manager)
```
bitbake obmc-phosphor-image
```

[Entity manager distro](https://github.com/openbmc/entity-manager)
```
DISTRO=arbel-evb-entity bitbake obmc-phosphor-image
```

### 4) Output Images
* You will find images in path build/evb-npcm845/tmp/deploy/images/evb-npcm845

Type          | Description                                                                                                     |
:-------------|:-------------------------------------------------------------------------------------------------------- |
image-bmc   |  includes image-u-boot and image-kernel and image-rofs                                                                     |
image-uboot   |  tipfw + bootlock + u-boot                                                                     |
image-kernel  |  Fit Image(Linux kernel + dtb+ initramfs)                                                                                     |
image-rofs    |  OpenBMC Root Filesystem                                                          |

## Programming Firmware for the first time

### Bootloader

#### Flashing through IGPS
Python 2.7 is required.<br/>

1. Setting up:
* Connect a Mini-USB cable to J_USB_TO_UART 
* Turn on strap 9 of the SW_STRAP9-16 dip switch and issue power-on reset

2. Image programming:
* Non scure boot
```
python ./ProgramAll_Basic.py
```

* Secure boot is enabled
```
python ./ProgramAll_Secure.py
```
### OpenBMC

#### Flash in UBOOT

* User can program bootloader or openbmc image in u-boot.
* Because the flash 0 size of EVB is smaller than the openbmc image, so the full openbmc image will be programmed to EVB flash 1.
* Therefore, the openbmc is booted from flash 1.

1. Setting up:
* Power on your EVB and stop BMC at u-boot stage.
* Prepare an ethernet cable and connect to J_SGMII

* Set BMC ip and tftp server ip in uboot env
```ruby
setenv gatewayip            192.168.0.254
setenv serverip             192.168.0.128
setenv ipaddr               192.168.0.12
setenv netmask              255.255.255.0
```
* Set bootargs in uboot env
```ruby
setenv autoload  no
setenv autostart no
setenv baudrate 115200
setenv bootcmd 'run romboot'
setenv bootdelay 2
setenv common_bootargs 'setenv bootargs earlycon=${earlycon} root=/dev/ram0 console=${console} mem=${mem}'
setenv console 'ttyS0,115200n8'
setenv earlycon 'uart8250,mmio32,0xf0000000'
setenv mem 880M
setenv romboot 'sf probe 0:1; run common_bootargs; echo Booting Kernel from flash; echo +++ uimage at 0x${uimage_flash_addr}; echo Using bootargs: ${bootargs};bootm ${uimage_flash_addr}'
setenv stderr serial
setenv stdin serial
setenv stdout serial
setenv uimage_flash_addr 0x88200000
```
* Save uboot env to flash
```ruby
saveenv
```

2. Image programming:

* Flash full openbmc image
```ruby
sf probe 0:1
setenv ethact gmac2
tftp 10000000 image-bmc
cp.b 0x10000000 0x88000000 ${filesize}
```

* Flash linux kernel
```ruby
sf probe 0:1
setenv ethact gmac2
tftp 10000000 image-kernel
cp.b 0x10000000 0x88200000 ${filesize}
```

* Flash bootloader
```ruby
/* BMC is booted from flsh0, please flash bootloader to flash0 */
setenv ethact gmac2
tftp 10000000 image-u-boot
cp.b 0x10000000 0x80000000 ${filesize}
```

3. Booting to OpenBMC:

* Enter boot command
```ruby
run romboot
```

4. OpenBMC Login Prompts.

* User: root
* Password: 0penBmc
```ruby
[  OK  ] Reached target Login Prompts.

Phosphor OpenBMC (Phosphor OpenBMC Project Reference Distro) 0.1.0 evb-npcm845 ttyS0

evb-npcm845 login:
```

# Interfaces

## UART

The EVB has FTDI USB_TO_UART and UART Headers, the user can select the UART rotue through the dip switch.

1. Strap Settings

- Strap 5 of the SW_STRAP1_8 dip switch
  * Turn on strap 5 that BMC UART can rout via SI2 pins.
  * Aslo, all logs can be rout to the same UART port.

- Strap 7 of the SW1 dip switch
  * Turn on strap 7 to isolate USB FTDI.
  * UART headers can be used when FTDI is isolated.

2. FTDI USB_TO_UART

- Connects a Mini-USB cable to J_USB_TO_UART
  * You will get 4 serial port options from your terminal settings.
  * Please select second serial port and set baud rate to 115200.

3. UART Headers

- Connects a USB FTDI cable to J_SI2_BU0
  * Turn on strap 7 of the SW1 dip switch
  * Set baud rate to 115200.

## Network

The EVB has 3 RJ45 headers and 1 NCSI header

- J_SGMII: 1000/100/10Mbps SGMII, eth0
- J_RGMII: 1000/100/10Mbps RGMII, eth1
- J_RMII:  100/10Mbps RMII, eth3
- J_EMC: NCSI header, eth2

## I3C

The EVB has I3C0~I3C5 interfaces on the J_I3C header.

### SPD5118 device
- Connect a Renesas SPD5118 moudule to EVB I3C1 interface
  * connect J_I3C.3 to device SCL
  * connect J_I3C.4 to device SDA
  * connect TP_3.3V to device 3V3
  * connect GND to device GND
- Edit nuvoton-npcm845-evb.dts. (The slave static address 0x57 depends on HSA pin of DIMM)
```
    i3c1: i3c@fff11000 {
        status = "okay";
        i2c-scl-hz = <400000>;
        i3c-scl-hz = <4000000>;
        static-address;
        eeprom@0x57 {
            reg = <0x57 0x4CC 0x51180000>;
        };

    };
```
- Enable Kernel config
```
CONFIG_I3C=y
CONFIG_SVC_I3C_MASTER=y
CONFIG_EEPROM_SPD5118=y
```
- Boot EVB to Openbmc, there is a sysfs interface that allow to do read/write access to the eeprom of the DIMM.  The size of eeprom is 1024 bytes
```
/sys/bus/i3c/devices/1-4cc51180000/eeprom
```
## JTAG Master

The EVB has JTAG Master 1 interface on the J_JTAGM header.

### Onboard CPLD
- Route JTAG Master 1 interface to onboard CPLD.
```
echo 70 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio70/direction
echo 1 > /sys/class/gpio/gpio70/value
```
- Program CPLD, arbelevb_cpld.svf is the firmware file.
```
loadsvf -d /dev/jtag0 -s arbelevb_cpld.svf
```
- After CPLD is programmed, three LEDs (blue/yellow/red, near to SW1) are turned on.

- The CPLD SVF can be downloaded from here:
[arbelevb_cpld.svf](https://github.com/Nuvoton-Israel/openbmc/tree/npcm-v2.10/meta-evb/meta-evb-nuvoton/meta-evb-npcm845/recipes-evb-npcm845/loadsvf/files/arbelevb_cpld.svf )
## SMB

The EVB has 27 SMB interfaces on J3 and J4 headers.

There is a TMP100 sensor (0x48) connected to SMB module 6.

### TMP100 sensor
- The following example in EVB debug console is to detect TMP100.
```
i2cdetect -y -q 6
```
- Or one can use the linux dts and driver configurations below.  
> _Edit nuvoton-npcm845-evb.dts_  
```
  &i2c6 {
    status = "okay";
    tmp100@48 {
      compatible = "tmp100";
      reg = <0x48>;
      status = "okay";
    };
  };
```
- Enable kernel configuration
```
CONFIG_REGMAP_I2C=y
CONFIG_I2C=y
CONFIG_I2C_BOARDINFO=y
CONFIG_I2C_COMPAT=y
CONFIG_I2C_CHARDEV=y
CONFIG_I2C_HELPER_AUTO=y
CONFIG_I2C_NPCM7XX=y
CONFIG_SENSORS_LM75=y
```
- Boot EVB to Openbmc, there is a sysfs path that shows a hwmon interface.
```
/sys/class/hwmon/hwmon0/
```
### SMB acts as a slave emulated EEPROM

The SMB module's slave functionality could be tested by the following
procedure.

Wire the SMB0 module and SMB1 module. The SMB1 module acts as a slave eeprom.

- Enable kernel configuration
```
CONFIG_REGMAP_I2C=y
CONFIG_I2C=y
CONFIG_I2C_BOARDINFO=y
CONFIG_I2C_COMPAT=y
CONFIG_I2C_CHARDEV=y
CONFIG_I2C_HELPER_AUTO=y
CONFIG_I2C_NPCM7XX=y
CONFIG_I2C_SLAVE=y
CONFIG_I2C_SLAVE_EEPROM=y
```
- Build-time (linux dts) configuration or 
> _Edit nuvoton-npcm845-evb.dts_  
```
  &i2c1 {
    status = "okay";
    slave_eeprom:slave_eeprom@40000064 {
      compatible = "slave-24c02";
      reg = <0x40000064>;
      status = "okay";
    };
  };
```
- Runtime configuration  
Input the following command in the EVB debug console.  
```
echo slave-24c02 0x1064 > /sys/bus/i2c/devices/i2c-1/new_device
```
- The emulated eeprom device (0x64) is detected by the following command in the
EVB debug console.
```
i2cdetect -y -q 0
```
- The following commands could be used to validate the access to the emulated
eeprom.
```
i2ctransfer -f -y 0 w2@0x64 0 0 r2
i2ctransfer -f -y 0 w4@0x64 0 0 1 3 r0
i2ctransfer -f -y 0 w2@0x64 0 0 r2
```
## ESPI

The EVB has the J_eSPI header to support ESPI transactions.

### Wiring
- Connected to the host ESPI interface.
  * eSPI_ALERT_N (optional): ESPI alert pin.  
  * eSPI_RST_N: ESPI reset pin.  
  * eSPI_IO0: ESPI IO[0] pin.  
  * eSPI_IO1: ESPI IO[1] pin.  
  * eSPI_IO2: ESPI IO[2] pin.  
  * eSPI_IO3: ESPI IO[3] pin.  
  * eSPI_CLK: ESPI clock pin.  
  * eSPI_CS_N: ESPI chip select pin.  

> _If _eSPI_ALERT_N is connected, please configure the alert mode accordingly on the host side._  
> _To connect the external power 1.8V or 1.0V, please short the pin 2 only on the JP_ESPI_PWR header on EVB._  

### ESPI channel support declaration in u-boot configuration
- Enable u-boot configuration
> _Edit nuvoton-npcm850-evb.dts in u-boot_  
```
  config {
    espi-channel-support = <0xf>;
  };
```
> _The configuration above claims that all channels would be supported._  
- Rebuild and flash the u-boot binary.  

### Validate ESPI
- Boot EVB into u-boot first and then the host device.  
- Check if values of the following registers are configured properly.  
  * Bits **24~27** of **ESPICFG** register are set to **1** to support all four
    channels.  
  * The value of **ESPIHINDP** register is expected to be **0x0001111f**.
  * Bit **8** of **MFSEL4** register is set to **1**.  
- Issue ESPI request packets from the host.

