# meta-nuvoton-obmc

This layer contains the layers and recipes which have not yet been submitted to the upstream.

# Dependencies
This layer depends on:

```
  URI: github.com/openbmc/openbmc.git
  branch: master
```

# Contact

For more product questions, please contact us at:
* bmc_marketing@nuvoton.com

## How to build OpenBMC with this layer

### NPCM7XX

1. [NPCM750 EVB](https://github.com/Nuvoton-Israel/openbmc/tree/npcm-master/meta-nuvoton-obmc/meta-evb-npcm750)
```sh
. setup evb-npcm750-stage

Make inventory-manager target
     bitbake obmc-phosphor-image

Make entity-manager target
     DISTRO=poleg-evb-entity bitbake obmc-phosphor-image

Make emmc image with inventory-manager (boot linux/openbmc from emmc)
     DISTRO=poleg-evb-emmc bitbake obmc-phosphor-image

Make emmc image with entity-manager (boot linux/openbmc from emmc)
     DISTRO=poleg-evb-emmc-entity  bitbake obmc-phosphor-image
```

2. [RunBMC card with BUV board](https://github.com/Nuvoton-Israel/openbmc/tree/npcm-master/meta-nuvoton-obmc/meta-buv-runbmc)
```sh
. setup buv-runbmc

Make buv inventory-manager image by following command:
     bitbake obmc-phosphor-image

Make buv entity-manager image by following command:
     DISTRO=buv-entity bitbake obmc-phosphor-image

Make emmc image with inventory-manager (boot linux/openbmc from emmc)
     DISTRO=buv-runbmc-emmc bitbake obmc-phosphor-image

Make emmc image with entity-manager (boot linux/openbmc from emmc)
     DISTRO=buv-runbmc-emmc-entity  bitbake obmc-phosphor-image
```

3. [Olympus platform](https://github.com/Nuvoton-Israel/openbmc/tree/npcm-master/meta-nuvoton-obmc/meta-olympus-nuvoton)
```sh
. setup olympus-nuvoton-stage
Make olympus inventory-manager image by following command:
     bitbake obmc-phosphor-image

Make olympus entity-manager image by following command:
     DISTRO=olympus-entity bitbake obmc-phosphor-image

Make emmc image with inventory-manager (boot linux/openbmc from emmc)
     DISTRO=olympus-emmc bitbake obmc-phosphor-image

Make emmc image with entity-manager (boot linux/openbmc from emmc)
     DISTRO=olympus-emmc-entity  bitbake obmc-phosphor-image
```

### NPCM8XX

1. [NPCM845 EVB](https://github.com/Nuvoton-Israel/openbmc/tree/npcm-master/meta-nuvoton-obmc/meta-evb-npcm845)
```sh
. setup evb-npcm845-stage

Make inventory-manager target
     bitbake obmc-phosphor-image

Make BMC-mediated Composite EAT attestation target
     DISTRO=arbel-evb-composite-eat bitbake obmc-phosphor-image

Make entity-manager target
     DISTRO=arbel-evb-entity bitbake obmc-phosphor-image

Make emmc image with inventory-manager (boot linux/openbmc from emmc)
     DISTRO=arbel-evb-emmc bitbake obmc-phosphor-image

Make emmc image with entity-manager (boot linux/openbmc from emmc)
     DISTRO=arbel-evb-emmc-entity  bitbake obmc-phosphor-image
```
2. [NPCM845 DC-SCM](https://github.com/Nuvoton-Israel/openbmc/tree/npcm-master/meta-nuvoton-obmc/meta-scm-npcm845)
```sh
. setup scm-npcm845

Make entity-manager target
     DISTRO=arbel-scm-entity bitbake obmc-phosphor-image

Make emmc image with entity-manager (boot linux/openbmc from emmc)
     DISTRO=arbel-scm-emmc-entity  bitbake obmc-phosphor-image

```
