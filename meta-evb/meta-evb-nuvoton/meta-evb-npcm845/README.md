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
- [Features of NPCM845 EVB](#features-of-npcm845-evb)
  * [MCU Firmware Update](#mcu-firmware-update)
  * [iKVM](#ikvm)
  * [Virtual Media](#virtual-media)

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

## Features of NPCM845 EVB
### MCU Firmware Update

There is a MCU (ATtiny1634) connected to NPCM845 SMB4. The fimrware can be programmed via the following pins.
```
GPIO29: MCU SCLK
GPIO28: MCU MOSI
GPIO76: MCU MISO
GPIO77: MCU RESET#
```

- kernel dts
```
    mcu_flash {
        compatible = "nuvoton,npcm845-mcu-flash";
        status = "okay";
        #address-cells = <1>;
        #size-cells = <1>;
        dev-num = <0>;    /* /dev/mcu0 */
        mfsel-offset = <0x260>; /* MFSEL1 */
        smb-offset = <1>; /* SMBSEL offset of MFSEL */
        mcu-gpios = <&gpio0 29 GPIO_ACTIVE_HIGH>,     /* GPIO29: SCLK */
            <&gpio0 28 GPIO_ACTIVE_HIGH>,     /* GPIO28: MOSI */
            <&gpio2 12 GPIO_ACTIVE_HIGH>,      /* GPIO76: MISO */
            <&gpio2 13 GPIO_ACTIVE_LOW>;      /* GPIO77: RESET# */
    };
```
- Enable kernel config
```
CONFIG_NPCM7XX_MCU_FLASH=y
```
- Build programming tool [loadmcu](https://github.com/Nuvoton-Israel/loadmcu)
```
bitbake loadmcu
```
- Programming
```
loadmcu -d /dev/mcu0 -s mcu_fw.bin
```

### iKVM
<img align="right" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/ipkvm-2.10.png">

This is a Virtual Network Computing (VNC) server program using [LibVNCServer](https://github.com/LibVNC/libvncserver).
1. Support Video Capture and Differentiation(VCD), compare frames by hardware.
2. Support Encoding Compression Engine(ECE), 16-bit hextile compression hardware encoding.
3. Support USB HID, support Keyboard and Mouse.

**Source URL**

* [https://github.com/Nuvoton-Israel/obmc-ikvm](https://github.com/Nuvoton-Israel/obmc-ikvm)

**How to use**

1. Install Arbel EVB on a host PC via PCIE socket
2. Connect USB1_DEV and host PC with a USB cable
3. Power on host PC and Arbel EVB
4. Make sure your workstation and Arbel EVB are in the same network.
5. Launch a browser in your workstation and you will see the entry page.
    ```
    /* BMCWeb Server */
    https://<arbel ip>
    ```
4. Login to OpenBMC home page
    ```
    Username: root
    Password: 0penBmc
    ```
5. Navigate to OpenBMC WebUI viewer
    ```
    https://<arbel ip>/#/control/kvm
    ```
**Performance**

* Host OS: Windows Server 2012 R2

|Playing video: [AQUAMAN](https://www.youtube.com/watch?v=2wcj6SrX4zw)|[Real VNC viewer](https://www.realvnc.com/en/connect/download/viewer/) | noVNC viewer
:-------------|:--------|:-----------|
Host Resolution    | FPS    | FPS |
1024x768  |  25    | 8 |
1280x1024   |  20  | 4 |
1600x1200   |  14   | 3 |

|Scrolling bar: [Demo video](https://drive.google.com/file/d/1H71_H6yjO8NU4Qu_ZL4F59FQ0PQmEo2n/view)|[Real VNC viewer](https://www.realvnc.com/en/connect/download/viewer/) | noVNC viewer
:-------------|:--------|:-----------|
Host Resolution    | FPS    | FPS |
1024x768  |  31    | 15 |
1280x1024   |  24  | 12 |
1600x1200   |  20   | 7 |

**The preferred settings of RealVNC Viewer**
```
Picture quality: Custom
ColorLevel: rgb565
PreferredEncoding: Hextile
```

**Maintainer**

* Joseph Liu

### Virtual Media
<img align="right" width="20%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/vm_app_win.png">
<img align="right" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/virtual-media-2.10.png">

Virtual Media (VM) is to emulate an USB drive on remote host PC via Network Block Device(NBD) and Mass Storage(MSTG).

**Source URL**

* [https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-phosphor/nuvoton-layer/recipes-connectivity/jsnbd](https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-phosphor/nuvoton-layer/recipes-connectivity/jsnbd)
* [https://github.com/Nuvoton-Israel/openbmc-util/tree/master/virtual_media_openbmc2.6](https://github.com/Nuvoton-Israel/openbmc-util/tree/master/virtual_media_openbmc2.6)

**How to use**

1. Clone a physical USB drive to an image file
    * For Linux - use tool like **dd**
      ```
      dd if=/dev/sda of=usb.img bs=1M count=100
      ```
      > _**bs** here is block size and **count** is block count._
      >
      > _For example, if the size of your USB drive is 1GB, then you could set "bs=1M" and "count=1024"_

    * For Windows - use tool like **Win32DiskImager.exe**

      > _NOTICE : A simple *.iso file cannot work for this._

2. Enable Virtual Media

    2.1 VM-WEB
    1. Login and switch to webpage of VM on your browser
        ```
        https://XXX.XXX.XXX.XXX/#/control/virtual-media
        ```

    2. Operations of Virtual Media
        * After `Choose File`, click `Start` to start VM network service
        * After clicking `Start`, you will see a new USB device on HOST OS
        * If you want to stop this service, just click `Stop` to stop VM network service.

    2.2 VM standalone application
    * Download [application source code](https://github.com/Nuvoton-Israel/openbmc-util/tree/master/virtual_media_openbmc2.6)
    * Follow the [readme](https://github.com/Nuvoton-Israel/openbmc-util/blob/master/virtual_media_openbmc2.6/NBDServerWSWindows/README) instructions install QT and Openssl
    * Start QT creator, open project **VirtualMedia.pro**, then build all
    * Launch windows/linux application
        > _NOTICE : use `sudo` to launch app in linux and install `nmap` first_
    *  Operations
        + After `Chose an Image File` or `Select an USB Drive`, click `Search` to check which BMCs are on line
        + Select any on line BMC and key in `Account/Password`, choose the `Export Type` to Image, and click `Start VM` to start VM network service (still not hook USB disk to host platform)
        + After `Start VM`, click `Mount USB` to hook the emulated USB disk to host platform, or click `Stop VM` to stop VM network service.
        + After `Mount USB`, click `UnMount USB` to emulate unplugging the USB disk from host platform
        + After `UnMount USB`, click `Stop VM` to stop VM network service, or click `Mount USB` to hook USB disk to host platform.

3. Performance

|Client |MountType |Encryption |Speed KB/s
:---------------------|:----------------------------------------------|:---|:---------|
Client WebUI(HTML5)  | CentOS-8.2.2004-x86_64-dvd1.iso (8GB Size)    |Yes| ~7800KB/s |

**Maintainer**
* Medad CChien
