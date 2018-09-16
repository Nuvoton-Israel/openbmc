# OpenBMC

[![Build Status](https://openpower.xyz/buildStatus/icon?job=openbmc-build)](https://openpower.xyz/job/openbmc-build/)

The OpenBMC project can be described as a Linux distribution for embedded
devices that have a BMC; typically, but not limited to, things like servers,
top of rack switches or RAID appliances. The OpenBMC stack uses technologies
such as [Yocto](https://www.yoctoproject.org/),
[OpenEmbedded](https://www.openembedded.org/wiki/Main_Page),
[systemd](https://www.freedesktop.org/wiki/Software/systemd/), and
[D-Bus](https://www.freedesktop.org/wiki/Software/dbus/) to allow easy
customization for your server platform.


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
```

### 3) Target your hardware
Any build requires an environment variable known as `TEMPLATECONF` to be set
to a hardware target.
You can see all of the known targets with
`find meta-* -name local.conf.sample`. Choose the hardware target and
then move to the next step. Additional examples can be found in the
[OpenBMC Cheatsheet](https://github.com/openbmc/docs/blob/master/cheatsheet.md)

Machine | TEMPLATECONF
--------|---------
evb-npcm750 | ```meta-evb/meta-evb-nuvoton/meta-evb-npcm750/conf```
Palmetto | ```meta-ibm/meta-palmetto/conf```
Zaius| ```meta-ingrasys/meta-zaius/conf```
Witherspoon| ```meta-ibm/meta-witherspoon/conf```
Romulus| ```meta-ibm/meta-romulus/conf```

As an example target npcm750 evaluation board
```
export TEMPLATECONF=meta-evb/meta-evb-nuvoton/meta-evb-npcm750/conf
```

### 4) Build

```
. openbmc-env
bitbake obmc-phosphor-image
```

### 5) build images
After building finished the built Images will found at:
<OpenBMC_folder>/build/tmp/deploy/images/evb-npcm750
The relvant Images to use to upload the OpenBMC on the EVB are:

1. image-bmc - The entire 32MB image including BootBlock, u-boot, linux kernel
               and file system, can be programmed into the beginning of flash
2. image-u-boot - Includes only BootBlock and u-boot and their headers can be
                  programmed into the beginning of flash
3. image-kernel - FIT image that includes linux kernel, device tree and an
                  initial file system, can be loaded to the linux area in flash
4. image-rofs - Main (and large) OpenBMC file system, can be loaded to the
                rofs area in flash

### Note
All the files above are Image links to the latest build images, 
for copy the files to SD or USB storage device please make sure 
you copying the Images and not the links

#### 6) Programming the images
For programming the OpenBMC to the EVB SPI flash go to:
[npcm7xx-poleg/evaluation-board](https://github.com/Nuvoton-Israel/nuvoton-info/tree/master/npcm7xx-poleg/evaluation-board)
See the [readme.txt](https://github.com/Nuvoton-Israel/nuvoton-info/blob/master/npcm7xx-poleg/evaluation-board/readme.txt)
and follow the [NPCM7xx_OpenBMC_Programming.pdf](https://github.com/Nuvoton-Israel/nuvoton-info/blob/master/npcm7xx-poleg/evaluation-board/sw_deliverables/NPCM7xx_OpenBMC_Programming.pdf) instructions.

#### 7) OpenBMC user login
after the OpenBMC boot please enter the following login and password:

```
Phosphor OpenBMC (Phosphor OpenBMC Project Reference Distro) 0.1.0 evb-npcm750 ttyS0

evb-npcm750 login: root
Password: 0penBmc (first letter zero and not capital o)
```

#### 8) More information
For more info follow the readme.txt in:
[ftp://ftp.nuvoton.co.il/outgoing/Eval_Board](ftp://ftp.nuvoton.co.il/outgoing/Eval_Board) at the section:
"Loading to Evaluation Board and running instructions".
In order to get a password for the ftp please contact BMC_Marketing@Nuvoton.com

## Contact
- Mail: tomer.maimon@nuvoton.com,  avi.fishman@nuvoton.com or BMC_Marketing@Nuvoton.com
