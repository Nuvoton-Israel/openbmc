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

## Platforms and Distros

| SoC | Platform | Layer | Setup | Distros |
|-----|----------|-------|-------|---------|
| NPCM750 | EVB | `meta-evb-npcm750` | `. setup evb-npcm750-stage` | default, `poleg-evb-entity`, `poleg-evb-emmc`, `poleg-evb-emmc-entity` |
| NPCM750 | RunBMC + BUV | `meta-buv-runbmc` | `. setup buv-runbmc` | default, `buv-entity`, `buv-runbmc-emmc`, `buv-runbmc-emmc-entity` |
| NPCM750 | Olympus | `meta-olympus-nuvoton` | `. setup olympus-nuvoton-stage` | default, `olympus-entity`, `olympus-emmc`, `olympus-emmc-entity` |
| NPCM845 | EVB | `meta-evb-npcm845` | `. setup evb-npcm845-stage` | default, `arbel-evb-entity`, `arbel-evb-emmc`, `arbel-evb-emmc-entity`, `arbel-evb-composite-eat`, `arbel-evb-obmf`, `arbel-evb-satellite` |
| NPCM845 | DC-SCM | `meta-scm-npcm845` | `. setup scm-npcm845` | `arbel-scm-entity`, `arbel-scm-emmc-entity` |

Shared distro features live in `meta-common` (`conf/distro/include/`):

| Feature | Include | Description |
|---------|---------|-------------|
| `composite-eat` | `composite-eat.inc` | BMC-mediated Composite EAT attestation over SPDM/MCTP (off by default) |
| `obmf` | `obmf.inc` | OBMF (Open Boot and Management Framework) over USB: kernel `NPCM-6.12-OBMF-dev` branch, OBMF class drivers, board DT overlay, OBMF MCTP link config and entity-manager MCTP I2C endpoint on the OBMF bus |
| `satellite` | `arbel-evb-satellite.conf` | Redfish satellite BMC: USB device towards an aggregator BMC with a CDC ECM link (`sat0`, 192.168.7.1, Redfish/bmcweb); `obmc-ikvm` and RNDIS are removed |
| `mctp`, `spdm` | `mctp.inc`, `spdm.inc` | MCTP stack and SPDM responder/requester support |

## Latest Status

### NPCM845 EVB

- Compatible with the Yocto `whinlatter` and `wrynose` release series.
- Composite EAT attestation: `arbel-evb-composite-eat` distro, with Redfish
  `ComponentIntegrity` and the `OpenBMCCompositeEATBundle` OEM API. See the
  [Composite EAT README](meta-evb-npcm845/README-COMPOSITE-EAT.md) for details.
- OBMF over USB: `arbel-evb-obmf` distro uses the 6.12 OBMF kernel branch,
  channel handlers for I2C, I3C, GPIO, SPI, Serial and IPMI, and a dedicated
  `mctp-config-obmf` (MTU 243 on `mctpi3c2` / `mctpi2c27`) so MCTP packets
  fit the OBMF I2C request buffer. PLDM firmware update over the OBMF I2C
  bridge relies on this MTU. The NPCM400 MCTP I2C endpoint behind the SMC is
  set up by mctpreactor from the entity-manager config on `i2c-27`. See the
  [OBMF README](meta-evb-npcm845/README-OBMF.md) for details.
- Redfish satellite BMC: `arbel-evb-satellite` distro exposes the EVB to an
  aggregator BMC over a USB device port with a CDC ECM link (`sat0`,
  192.168.7.1, Redfish). An aggregator BMC with bmcweb Redfish aggregation
  enabled can register the satellite, so the satellite Chassis and sensors
  appear on the aggregator. The satellite is updated by pushing the
  `*.static.mtd.tar` image to the satellite bmcweb `UpdateService/update`
  (aggregation does not forward updates).
- eMMC boot images (`arbel-evb-emmc`, `arbel-evb-emmc-entity`), TIP firmware
  (pre-signed by default, optional build from source), and QEMU support for
  the NPCM845 EVB.

For build, flash and module documentation see the
[NPCM845 EVB README](meta-evb-npcm845/README.md).

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

Make OBMF (Open Boot and Management Framework) target
     DISTRO=arbel-evb-obmf bitbake obmc-phosphor-image

Make Redfish satellite BMC target (USB device link to an aggregator BMC)
     DISTRO=arbel-evb-satellite bitbake obmc-phosphor-image

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
