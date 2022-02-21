# OpenBMC

[![Build Status](https://openpower.xyz/buildStatus/icon?job=openbmc-build)](https://openpower.xyz/job/openbmc-build/)

OpenBMC is a Linux distribution for management controllers used in devices such
as servers, top of rack switches or RAID appliances. It uses
[Yocto](https://www.yoctoproject.org/),
[OpenEmbedded](https://www.openembedded.org/wiki/Main_Page),
[systemd](https://www.freedesktop.org/wiki/Software/systemd/), and
[D-Bus](https://www.freedesktop.org/wiki/Software/dbus/) to allow easy
customization for your platform.

## Setting up your OpenBMC project

### 1) Prerequisite
- Ubuntu 14.04

```
sudo apt-get install -y git build-essential libsdl1.2-dev texinfo gawk chrpath diffstat
```

- Fedora 28

```
sudo dnf install -y git patch diffstat texinfo chrpath SDL-devel bitbake rpcgen
sudo dnf groupinstall "C Development Tools and Libraries"
```
### 2) Download the source
```
git clone https://github.com/Nuvoton-Israel/openbmc.git
cd openbmc
git checkout -b runbmc origin/runbmc
```

### 3) Target your hardware
Any build requires an environment set up according to your hardware target.
There is a special script in the root of this repository that can be used
to configure the environment as needed. The script is called `setup` and
takes the name of your hardware target as an argument.

The script needs to be sourced while in the top directory of the OpenBMC
repository clone, and, if run without arguments, will display the list
of supported hardware targets, see the following example:

```
$ . setup <machine> [build_dir]
Target machine must be specified. Use one of:

buv-runbmc              lanyang                 romulus
centriq2400-rep         mihawk                  s2600wf
dl360poc                msn                     stardragon4800-rep2
ethanolx                neptune                 swift
evb-zx3-pm3             nicole                  tiogapass
f0b                     olympus                 vesnin
fp5280g2                olympus-nuvoton         witherspoon
g220a                   on5263m5                witherspoon-tacoma
gbs                     palmetto                yosemitev2
gsj                     qemuarm                 zaius
hr630                   quanta-q71l
hr855xg2                rainier
```

Once you know the target, source the `setup` script as follows:

As an example target Olympus Nuvoton
```
. setup olympus-nuvoton
```

As an example target BUV RunBMC
```
. setup buv-runbmc
```

### 4) Build

```
bitbake obmc-phosphor-image
```

Additional details can be found in the [docs](https://github.com/openbmc/docs)
repository.

From now on, the platform base on Runbmc: Olympus and BUV of Nuvoton are switching to eMMC image as default.
Please check the section [eMMC image](#10-emmc-image) for more information.


### 5) build images
After building finished the built Images will found at:
<OpenBMC_folder>/build/tmp/deploy/images/olympus-nuvoton/
The relevant images to use to upload the OpenBMC on the Olympus Nuvoton are:

1. image-bmc - The entire 32MB image including BootBlock, u-boot, linux kernel
               and file system, can be programmed into the beginning of flash
2. image-u-boot - Includes only BootBlock and u-boot and their headers can be
                  programmed into the beginning of flash
3. image-kernel - FIT image that includes linux kernel, device tree and an
                  initial file system, can be loaded to the linux area in flash
4. image-rofs - Main (and large) OpenBMC file system, can be loaded to the
                rofs area in flash

### 6) Programming the images
For programming the OpenBMC to the Olympus Nuvoton platform, there are two ways to update BMC firmware.
First, update BMC firmware image via OpenBMC web interface or RESTful API.
Second, flash image via UART.
In normal case we suggest user use the first method to update BMC firmware. User can follow the [firmware update readme](https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-quanta/meta-olympus-nuvoton#bmc-firmware-update) to upgrade BMC firmware.

Or program BMC firmware via UART by following instructions:

  1. Enable BMC program mode, set jump JPC6 to (2-3), and JPC7 to (1-2)
  2. Connect UART to connector JP35
  3. Follow the [NPCM7xx_OpenBMC_Programming.pdf](https://github.com/Nuvoton-Israel/nuvoton-info/blob/master/npcm7xx-poleg/evaluation-board/sw_deliverables/NPCM7xx_OpenBMC_Programming.pdf) chapter 2.2.2 to program BMC firmware.
  Additionally, the step _a_ should change to `python UpdateInputsBinaries_RunBMC.py`

### 7) OpenBMC user login
After the OpenBMC boot please enter the following login and password:

```
Phosphor OpenBMC (Phosphor OpenBMC Project Reference Distro) 0.1.0 olympus-nuvoton ttyS0

olympus-nuvoton login: root
Password: 0penBmc (first letter zero and not capital o)
```

### 8) More information
See the [readme.txt](https://github.com/Nuvoton-Israel/nuvoton-info/blob/master/npcm7xx-poleg/RunBMC/readme.txt),
there are documents about RunBMC implementation, schematics, and BOM list.

For more info follow the readme.txt in:
[ftp://ftp.nuvoton.co.il/outgoing/Eval_Board](ftp://ftp.nuvoton.co.il/outgoing/Eval_Board) at the section:
"Loading to Evaluation Board and running instructions".
In order to get a password for the ftp please contact BMC_Marketing@Nuvoton.com

### 9) Enabled features
Olympus RunBMC Platform
[https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-quanta/meta-olympus-nuvoton](https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-quanta/meta-olympus-nuvoton)


BUV RunBMC Platform
[https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-evb/meta-evb-nuvoton/meta-buv-runbmc](https://github.com/Nuvoton-Israel/openbmc/tree/runbmc/meta-evb/meta-evb-nuvoton/meta-buv-runbmc)

### 10) eMMC image
The eMMC is faster and get larger storage capacity than SPI flash. We move the Kernel image, ROFS image, and RWFS image to eMMC partition, but keep U-Boot image in SPI flash due to Poleg limitation. So we split the machine in Openbmc, one is for build SPI flash image, other one is for build eMMC flash image. User should build SPI image and flash it first, then use it flash eMMC image at the first time eMMC partition instialization. Please also take care the U-Boot and Kernel image must support ext4 filesystem which is ready in newest codebase. If user need to build SPI image for update eMMC image (first time) or other purpose, use the machine *olympus-nuvoton-spi* for Olympus, or *buv-runbmc-spi* for BUV.  Please refer the following instruction to build and flash image:

#### Build SPI image
```
$ bash  # to avoid environment dirty, we suggest use difference shell to build two image
$ source setup  olympus-nuvoton-spi
$ bitbake obmc-phosphor-image  # the image will be at build/olympus-nuvoton-spi/tmp/deploy/images/olympus-nuvoton-spi/
```

#### Build eMMC image
```
$ exit  # exit the bash for build SPI image
$ source setup  olympus-nuvoton
$ bitbake obmc-phosphor-image  # the image will be at build/olympus-nuvoton-spi/tmp/deploy/images/olympus-nuvoton/
```

#### Flash eMMC image in OpenBMC with SPI image(first time, update partition layout)
```
# update SPI image with newest codebase

# boot to Openbmc

# cp eMMC WIC image *obmc-phosphor-image-olympus-nuvoton-xxx.rootfs.wic.xz* to BMC, like scp, usb, …ect

# assume we put the WIC image in /tmp
$ xz --decompress --stdout /tmp/obmc-phosphor-image-olympus-nuvoton-xxx.rootfs.wic.xz | dd of=/dev/mmcblk0 bs=1M

# reboot to uboot
```

#### Flash eMMC image in U-Boot
Flash eMMC image in U-Boot need build image type as wic.gz. User can add *IMAGE_FSTYPES += "wic.gz"* in local.conf, then build image.
After add wic.gz in IMAGE_FSTYPES, the output image will add new one named obmc-phosphor-image-olympus-nuvoton-xxx.rootfs.wic.gz, and add a symbolic link named image-emmc.gz. User do not need update eMMC image both in SPI image and U-boot, just choose one easy way.

Here are example commands to update eMMC image in U-Boot via tftp:
```
> tftp 10000000 image-emmc.gz
> mmc dev 1
> gzwrite mmc 1 10000000 ${filesize}
```

#### Set up U-Boot bootargs for boot from eMMC
```
# set up uboot environment as following commands: 
setenv bootcmd 'setenv origbootargs ${bootargs}; run mmc_bootargs; run bootsidecmd'
setenv setmmcargs 'setenv bootargs ${bootargs} rootwait root=PARTLABEL=${rootfs}'
setenv mmc_bootargs 'setenv bootargs earlycon=${earlycon} console=${console} mem=${mem}'
setenv boota 'setenv bootpart 2; setenv rootfs rofs-a; run bootmmc'
setenv bootb 'setenv bootpart 3; setenv rootfs rofs-b; run bootmmc'
setenv bootmmc 'run setmmcargs; ext4load mmc 1:${bootpart} ${loadaddr} fitImage && bootm; echo Error loading kernel FIT image'
setenv bootsidecmd 'if test "${bootside}" = b; then run bootb; run boota; else run boota; run bootb; fi'
setenv bootside 'a'
setenv loadaddr '0x1200000'
setenv mmcboot  'run mmc_bootargs; run bootsidecmd'
saveenv

$ boot
```

#### Flash eMMC image (normal)
Note. Due to eMMC partition contains backup image, Openbmc use the activate image to update backup image, then switch new image to activate. We recommend use Web UI or Redfish API to update image.
```
Web UI:
  Operations -> Firmware -> Add file, choose the eMMC image obmc-phosphor-image-olympus-nuvoton.ext4.mmc.tar -> start update
Redfish API :
$ curl -k -H "X-Auth-Token: $token" -H "Content-Type: application/octet-stream" -X POST -T obmc-phosphor-image-olympus-nuvoton.ext4.mmc.tar https://${bmc}/redfish/v1/UpdateService 
```
Reference: https://github.com/openbmc/docs/blob/master/REDFISH-cheatsheet.md

#### Boot from SPI image
```
# boot to U-Boot
$ run common_bootargs; run romboot
```


## Contact
- Mail: tomer.maimon@nuvoton.com,  avi.fishman@nuvoton.com or BMC_Marketing@Nuvoton.com
