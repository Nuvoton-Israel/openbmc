# OBMF (Open Boot and Management Framework over USB)

This document describes OBMF support on the Nuvoton NPCM845 EVB
(`meta-evb-npcm845`). For general board setup, build and flash instructions,
see the [NPCM845 EVB README](README.md).

## Table of Contents

- [Build the OBMF Image](#build-the-obmf-image)
- [What the OBMF Distro Enables](#what-the-obmf-distro-enables)
- [MCTP Link Configuration and MTU](#mctp-link-configuration-and-mtu)
- [Kernel Config Matrix](#kernel-config-matrix)
- [USB Topology and Hierarchical DTS Design](#usb-topology-and-hierarchical-dts-design)
- [Channel Type to Linux Device Mapping](#channel-type-to-linux-device-mapping)
- [What You Should See on the BMC](#what-you-should-see-on-the-bmc)
- [Channel Test Guide](#channel-test-guide)

OBMF-ICP lets the BMC use a USB-attached SMC (OpenBIC / OBMF device) as a
bridge to remote I/O: GPIO, UART, IPMI, SPI, eSPI flash, I2C and I3C. The
BMC-side implementation is the OBMF USB class driver in the Nuvoton Linux
kernel (`drivers/usb/class/obmf/`). The OBMF-related `linux-nuvoton` patches
are integrated in the
[NPCM-6.1-OBMF-dev](https://github.com/Nuvoton-Israel/linux/tree/NPCM-6.1-OBMF-dev)
and
[NPCM-6.12-OBMF-dev](https://github.com/Nuvoton-Israel/linux/tree/NPCM-6.12-OBMF-dev)
kernel branches. This layer uses the 6.12 branch.

The generic driver sections below follow the OBMF kernel driver README
(`drivers/usb/class/obmf/README.md`, also published as
[obmf-kernel-driver](https://github.com/Nuvoton-Israel/obmf-kernel-driver/tree/obmf-0.9)).

## Build the OBMF Image

```bash
$ . setup evb-npcm845-stage
$ DISTRO=arbel-evb-obmf bitbake obmc-phosphor-image
```

Or set it in `conf/local.conf`:

```
DISTRO = "arbel-evb-obmf"
```

The distro is defined in `conf/distro/arbel-evb-obmf.conf`. It is based on
`openbmc-phosphor`, uses entity-manager, and requires
`conf/distro/include/obmf.inc` from `meta-common`.

To confirm the selected kernel source and configuration:

```bash
$ bitbake -e virtual/kernel | grep -E '^(SRC_URI|SRCREV|KBRANCH|B)='
$ kernel_build_dir=$(bitbake -e virtual/kernel | sed -n 's/^B="\(.*\)"/\1/p')
$ grep -E '^CONFIG_USB_OBMF(=|_)' "$kernel_build_dir/.config"
```

## What the OBMF Distro Enables

`obmf.inc` adds `obmf` to `DISTRO_FEATURES` and the `df-obmf` override.
Recipes use the override to add the following only for this distro:

| Component | Change |
|---|---|
| Kernel | `KBRANCH = "NPCM-6.12-OBMF-dev"` (pinned `SRCREV`), `PREFERRED_VERSION_linux-nuvoton = "6.12.%"`, `0016-hwmon-add-nct7363.patch` |
| Kernel config | `obmf.cfg`: USB OBMF core and I2C/GPIO/SPI/Serial/IPMI/I3C channel handlers, I3C + `i3cdev`, MCTP I3C transport, PCA953x GPIO expander, PCA954x I2C mux, NCT7363 hwmon, `usbmon`, NPCM eSPI flash |
| Device Tree | `nuvoton-npcm845-evb-obmf.dtso` is applied on `nuvoton-npcm845-evb.dtb` at build time to produce `nuvoton-npcm845-evb-obmf.dtb` (`KERNEL_DEVICETREE`) |
| mctp | `mctp-config-obmf` replaces the default `mctp-config` (see below) |
| entity-manager | `nuvoton_npcm400_evb_i2c-obmf.json` replaces the default `nuvoton_npcm400_evb_i2c.json`: the NPCM400 MCTP I2C device is on bus 27 (the OBMF I2C channel) with `"Probe": "TRUE"`, so `xyz.openbmc_project.mctpreactor.service` sets up the endpoint at boot |

Other distros (`arbel-evb-entity`, `arbel-evb-emmc`, ...) do not get any of
these changes.

The OBMF overlay describes one SMC on `ehci1` port 1 (USB path `1-1`) with
these channels, plus the reserved memory that backs the eSPI flash:

| Channel | DT node | Use on the EVB |
|---:|---|---|
| 4 | `spi@4` (`nuvoton,flash-type = "espi"`) | eSPI flash, MTD `npcm-espi-flash` |
| 5 | `smc-gpio@5` | SMC GPIO (`SMC1GPIO*`) |
| 6, 7 | `sgpio0@6`, `sgpio1@7` | SMC SGPIO (`SMC1SGPIO0GPIO*`, `SMC1SGPIO1GPIO*`) |
| 8 | `vwgpio@8` | eSPI virtual wire GPIO (`SMC1VWGPIO*`) |
| 10 | `i2c-ch@10` -> `i2c-27` | MCTP over I2C, BMC own address `0x12` |
| 11 | `i2c-ch@11` -> `i2c-28` | MCTP over I2C, BMC own address `0x14` |
| 12 | `i2c-ch@12` -> `i2c-29` | Plain I2C controller |
| 13 | `i2c-ch@13` -> `i2c-30` | TCA6416 (`0x20`), NCT7363 (`0x23`), PCA9848 mux (`0x71`) with TMP75 sensors |
| 14 | `i2c-tgt@14` | I2C Target paired with `i2c-27` |
| 15 | `i2c-tgt@15` | I2C Target paired with `i2c-28` |
| 17 | `spi@17` (`spi-nor`) | SMC SPI NOR flash, MTD `npcm-spi-flash` |
| 18 | `i3c-ch@18` | I3C controller with MCTP |

The overlay adds `/aliases` entries `i2c27`..`i2c30` for channels 10..13, so
the OBMF I2C adapter numbers are fixed at `i2c-27`..`i2c-30` (and the MCTP
links at `mctpi2c27`/`mctpi2c28`). The I3C bus number has no alias and is
still assigned dynamically.

## MCTP Link Configuration and MTU

The OBMF I2C channel request buffer is 256 bytes plus a 4-byte header, while
the MCTP I2C transport can build a packet of up to 258 bytes. To keep every
I2C packet within the OBMF limit, the OBMF distro installs
`recipes-phosphor/mctp/mctp/mctp-config-obmf` as `/usr/libexec/mctp/mctp-config`
instead of the default `mctp-config`:

```sh
#!/bin/sh

localEid=8

mctp addr add ${localEid} dev mctpi3c2
mctp link set mctpi3c2 up
mctp link set mctpi3c2 mtu 243

mctp addr add ${localEid} dev mctpi2c27
mctp link set mctpi2c27 up
mctp link set mctpi2c27 mtu 243

mctp addr add ${localEid} dev mctpusb0
mctp link set mctpusb0 up
```

Notes:

- The selection is made by `MCTP_CONFIG_SRC:df-obmf` in `mctp_%.bbappend`.
- `mctpi2c27` is the MCTP link of OBMF I2C channel 10. Its number is pinned
  by the `i2c27` alias in the overlay.
- `mctpi3c2` is the MCTP link of the OBMF I3C channel (I3C bus 2). The I3C bus
  number is assigned dynamically; verify it with `mctp link show` and adjust
  the script if your system differs.
- An MCTP MTU of 243 bounds the PLDM `RequestFirmwareData` length, which is
  what PLDM firmware update over the OBMF I2C bridge needs.
- The script only sets the local EID, link state and MTU. Remote I2C
  endpoints are not configured by hand: entity-manager publishes the
  `MCTPI2CTarget` from `npcm400_evb_i2c.json` and
  `xyz.openbmc_project.mctpreactor.service` asks `mctpd` to set it up (see
  [I2C Target test](#9-i2c-target-test)).

## Kernel Config Matrix

Check the effective kernel configuration before following the
[Channel Test Guide](#channel-test-guide). The OBMF channel switches default
to `y` only when their dependencies and `CONFIG_USB_OBMF` are enabled. A
disabled handler does not prevent channel discovery, but it does prevent
that channel's Linux device from being registered.

| Feature you want to use | Required kernel config | Configuration note |
|---|---|---|
| OBMF core, discovery, MMIO and IO channels | `CONFIG_USB_OBMF=y` | Select built-in for boot-time bring-up, or `m` for a module. |
| GPIO channel | `CONFIG_USB_OBMF_GPIO=y`, `CONFIG_GPIOLIB=y` | OBMF switch defaults to `y` if dependencies are met. |
| Serial channel | `CONFIG_USB_OBMF_SERIAL=y`, `CONFIG_TTY=y` | OBMF switch defaults to `y` if dependencies are met. |
| IPMI channel | `CONFIG_USB_OBMF_IPMI=y` | OBMF switch defaults to `y` if core is enabled. |
| SPI Controller channel | `CONFIG_USB_OBMF_SPI=y`, `CONFIG_MTD=y` | OBMF switch defaults to `y` if dependencies are met. |
| Memory Device channel | `CONFIG_USB_OBMF_MEM_DEV=y`, `CONFIG_MTD=y` | OBMF switch defaults to `y` if dependencies are met. |
| eSPI-backed flash behind the Memory Device channel | `CONFIG_SPI_NPCM_FLASH=y` | Enable separately if the board uses NPCM eSPI flash as the backing MTD device. |
| I2C Controller channel | `CONFIG_USB_OBMF_I2C=y`, `CONFIG_I2C=y` | OBMF switch defaults to `y` if dependencies are met. |
| I2C Target channel | `CONFIG_USB_OBMF_I2C=y`, `CONFIG_I2C_SLAVE=y` | I2C target support is configured separately. |
| I3C Controller channel | `CONFIG_USB_OBMF_I3C=y`, `CONFIG_I3C=y` | OBMF switch defaults to `y` if dependencies are met. |
| MCTP over the OBMF I2C channel | `CONFIG_MCTP=y`, `CONFIG_MCTP_TRANSPORT_I2C=y` | Enable separately for MCTP tests. |
| MCTP over the OBMF I3C channel | `CONFIG_MCTP=y`, `CONFIG_MCTP_TRANSPORT_I3C=y` | Enable separately for MCTP tests. |
| USB packet tracing with `usbmon` | `CONFIG_USB_MON=y`, `CONFIG_DEBUG_FS=y` | Enable separately for tracing. |

## USB Topology and Hierarchical DTS Design

An OBMF device does not have to sit directly on a BMC USB root port. It may
be attached behind one or more USB hubs (for example, a hub board that fans
out a single BMC USB host port to several SMC targets). This section explains
how the driver locates the Device Tree node for a given USB device, and how
to write the DTS for direct, one-hub, and two-hub topologies. These are board
DTS examples, not patches to copy as-is.

### 1. Where the DTS lives and how it is applied

In this layer the OBMF topology lives in
`recipes-kernel/linux/linux-nuvoton-612/nuvoton-npcm845-evb-obmf.dtso`. If
your physical topology differs, edit that overlay. Describe exactly one
physical topology per host port; do not combine the direct-device and hub
examples under the same `reg`.

After changing the DTS, rebuild the kernel:

```bash
$ DISTRO=arbel-evb-obmf bitbake virtual/kernel
```

### 2. How the driver matches a USB device to a DT node

The driver does not require any special "USB device" compatible string. It
walks the physical USB port chain and mirrors it in the DT:

1. Starting from the OBMF USB device, it walks `udev->parent` up to the root
   hub, recording each `portnum` it passes through.
2. It starts from the host controller's own OF node (e.g. `&ehci1`) and
   descends the DT one level per USB tier, at each level picking the child
   node whose `reg` equals the recorded port number.
3. The final node reached is the DT node for that USB device; its channel
   sub-nodes are then matched the same way, by `reg` equal to the OBMF
   `channel_id`.

This means:

- The DTS structure must mirror the physical USB wiring one-for-one: one DT
  node per USB tier (root port, hub port, hub port, ...).
- Node **names** (`smc@1`, `hub@1`, ...) are for readability only; only the
  `reg` value is used for matching.
- Every node that has USB/channel children needs
  `#address-cells = <1>; #size-cells = <0>;`, including the host-controller
  node itself (`&ehci1`).

### 3. Determining the port numbers

Before writing the DTS, find the real USB path of the target device:

```bash
lsusb -t
ls /sys/bus/usb/devices/
```

The kernel names devices using the `bus-port.port.port` convention, e.g.
`1-1.2.1`. Each dash- or dot-separated number after the bus number is one
tier, and maps to one `reg` value at one DT nesting level.

| USB path | Meaning | DTS nesting |
|---|---|---|
| `1-1` | Directly on root port 1 (Case A) | `&ehci1 { smc@1 { reg = <1>; ... } }` |
| `1-1.1` | Root port 1 -> hub port 1 (Case B, SMC1) | `&ehci1 { hub@1 { reg = <1>; smc@1 { reg = <1>; ... } } }` |
| `1-1.2.1` | Root port 1 -> hub port 2 -> hub port 1 (Case C, SMC1) | `&ehci1 { hub@1 { reg = <1>; hub@2 { reg = <2>; smc@1 { reg = <1>; ... } } } }` |

### 4. Case A: device directly on the root port (no hub)

Topology: `BMC(ehci1) -- smc@1 (SMC1, 1-1)`

```dts
&ehci1 {
	status = "okay";
	#address-cells = <1>;
	#size-cells = <0>;

	/* SMC1: OBMF device directly on root port 1 (USB path 1-1) */
	smc@1 {
		reg = <1>;
		#address-cells = <1>;
		#size-cells = <0>;

		mem-dev@4 {
			reg = <4>;
			nuvoton,mtd-name = "npcm-espi-flash";
		};

		smc-gpio@5 {
			reg = <5>;
			/* gpio-line-names = "SMC1GPIO0", ... ; */
		};
	};
};
```

### 5. Case B: device behind one hub

Topology:

```text
BMC(ehci1) -- hub@1 -- port1: smc@1 (SMC1, 1-1.1)
                    \- port2: smc@2 (SMC2, 1-1.2)
```

```dts
&ehci1 {
	status = "okay";
	#address-cells = <1>;
	#size-cells = <0>;

	/* USB hub at root port 1 */
	hub@1 {
		reg = <1>;
		#address-cells = <1>;
		#size-cells = <0>;

		/* SMC1: OBMF device at hub port 1 (USB path 1-1.1) */
		smc@1 {
			reg = <1>;
			#address-cells = <1>;
			#size-cells = <0>;

			mem-dev@4 {
				reg = <4>;
				nuvoton,mtd-name = "npcm-espi-flash";
			};
		};

		/* SMC2: OBMF device at hub port 2 (USB path 1-1.2) */
		smc@2 {
			reg = <2>;
			#address-cells = <1>;
			#size-cells = <0>;

			mem-dev@4 {
				reg = <4>;
				nuvoton,mtd-name = "npcm-espi-flash1";
			};
		};
	};
};
```

Each OBMF device needs its own unique resources where the SoC side is
shared, e.g. distinct `nuvoton,mtd-name` values and a separate
`memory-region` per device on `&espi_flash`:

```dts
&espi_flash {
	memory-region = <&espi_flash_memory>, <&espi_flash_memory1>;
	status = "okay";
};
```

### 6. Case C: device behind two hubs

Topology:

```text
BMC(ehci1) -- hub@1 -- hub@2 -- port1: smc@1 (SMC1, 1-1.2.1)
                             \- port3: smc@3 (SMC2, 1-1.2.3)
```

The rule is simply "one nested hub node per USB tier":

```dts
&ehci1 {
	status = "okay";
	#address-cells = <1>;
	#size-cells = <0>;

	/* First-tier USB hub at root port 1 */
	hub@1 {
		reg = <1>;
		#address-cells = <1>;
		#size-cells = <0>;

		/* Second-tier USB hub at hub@1 port 2 */
		hub@2 {
			reg = <2>;
			#address-cells = <1>;
			#size-cells = <0>;

			/* SMC1: OBMF device at hub@2 port 1 (USB path 1-1.2.1) */
			smc@1 {
				reg = <1>;
				#address-cells = <1>;
				#size-cells = <0>;

				mem-dev@4 {
					reg = <4>;
					nuvoton,mtd-name = "npcm-espi-flash";
				};
			};

			/* SMC2: OBMF device at hub@2 port 3 (USB path 1-1.2.3) */
			smc@3 {
				reg = <3>;
				#address-cells = <1>;
				#size-cells = <0>;

				mem-dev@4 {
					reg = <4>;
					nuvoton,mtd-name = "npcm-espi-flash1";
				};
			};
		};
	};
};
```

A third hub simply adds one more nested `hubN@<port>` level following the
same pattern, up to the USB spec limit of 7 tiers.

### 7. Rules and pitfalls

- Add one DT node per physical USB tier; do not skip levels even if a hub
  itself needs no configuration.
- Every node with children (host controller, hub, OBMF device) needs
  `#address-cells = <1>; #size-cells = <0>;`.
- `reg` on a hub/device node is the 1-based port number on its *immediate
  parent*, not a global USB address and not the OBMF `device_index`.
- Node names (`hub@1`, `smc@1`, ...) are cosmetic; only `reg` is matched
  against the live USB topology.
- OBMF channel sub-nodes (`mem-dev@4`, `smc-gpio@5`, `i2c-ch@10`, ...) must be
  children of the OBMF device node (`smc@N`), never of a `hub@N` node.
- `device_index` is derived from the OBMF device node's own `reg`
  (`device_index = reg - 1`) and is pinned with `ida_alloc_range()`. Two OBMF
  devices that reuse the same port number under different hubs (e.g.
  `hub@1/smc@1` and `hub@2/smc@1`) collide: the second probe fails with
  `-ENOSPC`. Use distinct final port numbers for stable indices. Dynamic index
  allocation only applies when no matching DT node exists or its `reg` is
  invalid.
- The port-chain buffer supports up to 8 entries; the USB specification
  limits topology depth to 7 tiers total, not 7 hubs plus a device.

### 8. Verifying the topology

```bash
lsusb -t
ls -l /sys/bus/usb/devices/1-1.2.1/of_node
dmesg | grep -i obmf
```

- `lsusb -t` / `/sys/bus/usb/devices/` confirm the real port path matches what
  the DTS encodes.
- The `of_node` symlink under the device's `/sys/bus/usb/devices/<path>/`
  confirms that USB core associated that USB device with a DT node.
- `dmesg` should show `OBMF-ICP obmf<device> ready: ...` without a
  `"DT node has no valid 'reg'; falling back to dynamic index"` warning or an
  index-allocation failure.

Example from `dmesg | grep -i obmf` with the OBMF device directly on the root
port (Case A, no hub):

```text
obmf 1-1:1.1: OBMF-ICP device detected
obmf 1-1:1.1: OBMF functional: wr=512 rd=512 wr_int=0 rd_int=0 ver=0x0080
obmf 1-1:1.1: OBMF_VER = 0x0100
obmf 1-1:1.1: Vendor=0xffff Device=0x0001 Role=2
obmf 1-1:1.1: Device Name: OpenBIC-OBMF
obmf 1-1:1.1: NUM_OF_CHANNELS = 18
obmf 1-1:1.1: ch1: type=0x01 name="MMIO" config_offset=0x00000078 config_size=4
...
obmf 1-1:1.1: OBMF-ICP obmf0 ready: 18 channels, ver 0x0080
```

With a USB hub between the BMC and the SMC (Case B), the OBMF device
enumerates at `1-1.1` (hub port 1) instead of `1-1`:

```text
usb 1-1: new high-speed USB device number 3 using npcm7xx-ehci
usb 1-1: New USB device found, idVendor=05e3, idProduct=0610, bcdDevice= 6.63
usb 1-1: Product: USB2.1 Hub
usb 1-1: Manufacturer: GenesysLogic
hub 1-1:1.0: USB hub found
hub 1-1:1.0: 4 ports detected
usb 1-1.1: new high-speed USB device number 4 using npcm7xx-ehci
usb 1-1.1: New USB device found, idVendor=1d6b, idProduct=0104, bcdDevice= 2.06
usb 1-1.1: Product: NPCM400 USBD
usb 1-1.1: Manufacturer: ZEPHYR
obmf 1-1.1:1.1: OBMF-ICP device detected
...
obmf 1-1.1:1.1: OBMF-ICP obmf0 ready: 18 channels, ver 0x0080
```

With two hubs in the chain (Case C), the OBMF device enumerates at `1-1.2.1`:

```text
obmf 1-1.2.1:1.1: OBMF-ICP device detected
...
obmf 1-1.2.1:1.1: OBMF-ICP obmf0 ready: 18 channels, ver 0x0080
```

If the SMC is moved to a different hub port (or a second hub tier is added),
the trailing segment(s) of the `obmf <path>:1.1` prefix change accordingly, and
the matching `smc@N` / `hub@N` `reg` values in the DTS must be updated.

## Channel Type to Linux Device Mapping

The kernel driver discovers Channel 0 first, then registers each discovered
channel into the corresponding Linux subsystem.

| Channel Type | OBMF Type Code | What it means | Linux representation on the BMC |
|---|---:|---|---|
| Config / Discovery | `0x00` | Mandatory Channel 0 for discovery and channel config reads | No standalone device node; visible through kernel logs and OBMF sysfs hierarchy |
| MMIO | `0x01` | Generic MMIO channel | `/dev/obmf<device>-mmio-<channel>` miscdevice |
| GPIO | `0x02` | Optimized GPIO channel | `gpiochipN` device with label like `obmf<device>-gpio-ch<channel>` |
| Serial | `0x03` | Optimized UART/serial channel | `/dev/ttyOBMF*` |
| I2C Controller | `0x04` | Optimized I2C master/controller channel | `/dev/i2c-*` adapter named `OBMF<device> I2C ch<channel>` |
| I2C Target | `0x05` | Protocol-defined target mode | Requires `obmf,paired-controller` pointing at the I2C Controller adapter node |
| I3C Controller | `0x06` | Optimized I3C controller channel | I3C bus exposed to the MCTP stack as an `mctpi3c*` link |
| IPMI | `0x07` | Optimized IPMI/SSIF bridge | `/dev/ipmi-obmf<device>-<channel>` miscdevice |
| SPI Controller | `0x08` | Optimized SPI controller channel | Host-initiated, virtual MTD device named by `nuvoton,mtd-name` (for example `npcm-spi-flash`) |
| IO | `0x09` | Optimized IO channel | `/dev/obmf<device>-io-<channel>` miscdevice |
| Memory Device | `0x0A` | Byte-addressable device-initiated memory channel | MTD device named by `nuvoton,mtd-name` (default `npcm-espi-flash`), linked as `mtd` under the channel's sysfs directory |
| OEM | `0xF8-0xFF` | OEM-specific extension space | Framework exists, but device shape depends on OEM handler implementation |

Notes:

- GPIO, Serial, IPMI, and IO are the most visible channels because they
  create direct Linux device nodes or subsystem devices.
- SPI (`0x08`) is always host-initiated: the BMC forwards SPI NOR opcodes to
  the SMC over a virtual MTD device backed by `nuvoton,mtd-name`.
  Device-initiated byte-addressable access lives on the separate Memory Device
  channel (`0x0A`).

## What You Should See on the BMC

Once the BMC boots with the OBMF kernel and the OBMF device is attached, you
can confirm bring-up in several places.

### Kernel logs

```bash
dmesg | grep -i obmf
```

Typical messages include:

- `OBMF-ICP device detected`
- `OBMF_VER = 0x....`
- `Vendor=0x.... Device=0x.... Role=...`
- `Device Name: ...`
- `NUM_OF_CHANNELS = ...`
- `chX: type=0x.. name="..." config_offset=... config_size=...`
- `chX: registered GPIO chip (...)`
- `chX: registered /dev/ipmi-obmf...`
- `chX: registered SPI Controller (MTD: <mtd-name>)`
- `chX: registered Memory Device (MTD: <mtd-name>, <size> bytes, erasesize <n>)`
- `OBMF-ICP obmf<device> ready: <count> channels, ver 0x....`

### USB driver binding

```bash
ls /sys/bus/usb/drivers/obmf
```

### OBMF sysfs hierarchy

The OBMF driver creates a per-channel sysfs tree under the USB interface
device:

```bash
find /sys/devices -path '*/obmf/channel/*' | sort
```

Expected structure:

```text
.../usbX/Y-Z/obmf/channel/1
.../usbX/Y-Z/obmf/channel/2
.../usbX/Y-Z/obmf/channel/3
```

Depending on channel type, the channel directory may contain links such as:

- `device` for GPIO, I2C, Serial, and IPMI-backed Linux devices
- `mmio` for MMIO channel miscdevices
- `mtd` for the backing MTD device used by the Memory Device channel

### Device nodes and subsystem devices

```bash
ls /dev | grep -E 'obmf|ttyOBMF|ipmi-obmf'
gpiodetect | grep -i obmf
gpioinfo
cat /proc/mtd
i2cdetect -l
```

## Channel Test Guide

This section lists practical sanity tests that match the current kernel
interfaces. The exact approach may vary with the firmware's OBMF
implementation and the channels it exposes. The goal is to confirm that the
BMC can see the expected devices, that basic read/write operations work, and
that device-initiated events are visible on the BMC side.

All tests share the same physical shape; only the channel type and which side
originates the traffic differ:

```text
                +----------------------------+
  Remote side   |             SMC            |   BMC side (this guide)
                |  (OpenBIC / OBMF device)   |
 Host / eSPI ---+  GPIO / UART / I2C / I3C / +--- USB ---> BMC (obmf driver)
 TEMP IC     ---+  SPI / KCS / Port80 pins   |             |
 Peer BMC    ---+                            |             +-- /dev, gpiochip, mtd, i2c-N, ...
                +----------------------------+
```

Unless a test says otherwise, run every command on the **BMC**; "remote /
host side" actions must be triggered on the SMC or on whatever platform it is
wired to.

| Test | Hardware topology | Who initiates | BMC-side interface |
|---|---|---|---|
| 1. Base bring-up | BMC — (USB) — SMC | BMC | `dmesg`, sysfs |
| 2. GPIO | GPIO pins — SMC — (USB) — BMC | either side | `gpiochipN` |
| 3. IPMI | Host — (eSPI / KCS) — SMC — (USB) — BMC | host | `/dev/ipmi-obmf*` |
| 4. SPI flash | BMC — (USB) — SMC — (SPI) — NOR flash | BMC | MTD (`npcm-spi-flash`) |
| 5. Memory Device | Host — (eSPI flash) — SMC — (USB) — BMC | host | MTD (`npcm-espi-flash`) |
| 6. UART / Serial | UART peer — SMC — (USB) — BMC | either side | `/dev/ttyOBMF*` |
| 7. Port 80 / POST | Host — (eSPI IO) — SMC — (USB) — BMC | host | `/dev/obmf*-io-*` |
| 8. I2C Controller | TEMP IC — (I2C) — SMC — (USB) — BMC | BMC | `/dev/i2c-N` |
| 9. I2C Target | BMC — (OBMF I2C via USB) — SMC — (I2C) — MCTP device | BMC | `i2c-27` + `mctpi2c27`, mctpreactor |
| 10. I3C Controller | BMC — (USB) — SMC1 — (I3C) — SMC2 | BMC | `i3c-N` + `mctpi3cN` |

### 1. Base bring-up test

Prerequisites: `CONFIG_USB_OBMF=y` and a DTS topology matching the physical
USB wiring.

```bash
dmesg | grep -i obmf
ls /sys/bus/usb/drivers/obmf
ls /dev | grep -E 'obmf|ttyOBMF|ipmi-obmf'
```

Pass criteria:

- The OBMF USB interface is detected and bound to the `obmf` driver.
- The driver prints discovery information and the final `ready` line.
- At least the expected device nodes for your enabled channels appear.

### 2. GPIO test

Prerequisites: `CONFIG_USB_OBMF_GPIO=y`, `CONFIG_GPIOLIB=y`

The GPIO channel is exposed as a normal Linux GPIO chip. Use `libgpiod` tools.

```bash
gpiodetect | grep -i obmf
gpioinfo gpiochipN

# Read an input line
gpioget gpiochipN <offset>

# Write an output line
gpioset gpiochipN <offset>=1
gpioset gpiochipN <offset>=0

# Monitor edges (if firmware exposes IRQ notifications)
gpiomon --rising-edge --falling-edge gpiochipN <offset>
```

Suggested checks:

- The chip label matches `obmf<device>-gpio-ch<channel>`.
- Line names defined by firmware appear in `gpioinfo`.
- Reads reflect the expected input state.
- Writes succeed only on output-capable lines.

### 3. IPMI channel test

Prerequisites: `CONFIG_USB_OBMF_IPMI=y`; `CONFIG_USB_MON=y` and
`CONFIG_DEBUG_FS=y` to trace with `usbmon`.

The IPMI channel is exposed as an OBMF miscdevice, typically
`/dev/ipmi-obmf<device>-<channel>`. Treat it as a low-level bridge endpoint,
not the host IPMI stack device.

```bash
dmesg | grep -i -E 'obmf|ipmi'
ls /dev/ipmi-obmf*
ls -al /sys/bus/usb/devices/*/obmf/channel/*

# Start a responder on the OBMF IPMI node
/usr/libexec/kcsbridged -c ipmi-obmf<device>-<channel> &
```

Then trigger IPMI traffic from the remote platform side (for example an eSPI
KCS Get Device ID) and observe BMC-side behavior.

Protocol reminder for userspace handlers:

- `read()` returns `[NetFn/LUN, IPMI_Cmd, Data...]`
- `write()` expects `[NetFn/LUN, IPMI_Cmd, CC, Data...]`

### 4. SPI flash test

Prerequisites: `CONFIG_USB_OBMF_SPI=y`, `CONFIG_MTD=y`

> **Warning:** the commands in this section write to raw MTD devices. Writing
> to the wrong `/dev/mtdX` will destroy the BMC's own U-Boot, environment or
> rootfs and can brick the board. Always resolve the number from
> `cat /proc/mtd` by the `nuvoton,mtd-name` you configured, and prefer the
> by-name path (`/dev/mtd/<name>`) over a hard-coded number.

The SPI Controller channel is always host-initiated: the BMC registers a
virtual MTD device from the `nuvoton,flash-size` / `nuvoton,flash-erasesize`
DTS properties, and forwards each MTD op as a single SPI NOR opcode (READ /
PP / SE / BE) to the SMC, which drives the real SPI bus.

- TX is not fragmented on the BMC side; max transfer unit is 448 bytes
  (`OBMF_SPI_MAX_XFER`).
- The SMC owns the full bus sequence (CS assert -> WREN before PP/Erase -> WIP
  polling -> CS deassert). The BMC does not issue WREN / RDSR and uses no local
  RAM or flash backing.

DTS example:

```dts
spi@17 {
    reg = <17>;
    #address-cells = <1>;
    #size-cells = <0>;

    nuvoton,flash-size = <0x4000000>;
    nuvoton,flash-erasesize = <0x1000>;
    nuvoton,flash-cs = <0x1>;
    nuvoton,mtd-name = "npcm-spi-flash";
};
```

The SMC-side SPI flash is currently fixed to `spi_fiu0_cs1`.

```bash
dmesg | grep -i -E 'obmf|spi|mtd|npcm-spi-flash'
cat /proc/mtd | grep npcm-spi-flash    # note the mtdN on the left

dd if=/dev/urandom of=/tmp/test.bin bs=1M count=5
flashcp -v /tmp/test.bin /dev/mtdN     # replace N with the matching MTD number
```

Suggested checks:

- The configured MTD node (for example `npcm-spi-flash`) appears in `/proc/mtd`.
- `flashcp -v` completes with a successful verify pass.

### 5. Memory Device test

Prerequisites: `CONFIG_USB_OBMF_MEM_DEV=y`, `CONFIG_MTD=y`,
`CONFIG_SPI_NPCM_FLASH=y` for the eSPI-backed MTD device.

> **Warning:** the commands in this section read/write raw MTD devices. See
> the warning in the SPI flash test; always resolve the MTD device by name.

The Memory Device channel (OBMF-ICP v1.0.0 RC1 section 4.12, Channel Type
`0x0A`) is always device-initiated (Producer/Responder): the SMC pushes
Memory Read/Write/Erase commands, and the BMC maps them onto the MTD device
named by `nuvoton,mtd-name` (default `npcm-espi-flash`). This channel replaces
the SPI Controller channel's former `espi` mode.

> **Note:** the EVB overlay in this layer currently declares the eSPI flash
> as `spi@4` with `nuvoton,flash-type = "espi"` (the former `espi` mode).
> Which form the kernel accepts depends on the pinned `SRCREV` of the
> `NPCM-6.12-OBMF-dev` branch; use `mem-dev@4` as shown below once the
> kernel revision includes the Memory Device channel.

Request format (device -> BMC):

| Field | Description |
|---|---|
| Command | `0`=Read, `1`=Write, `2`=Erase |
| Address (4B LE) | Byte offset into the device address space |
| Data Size (2B LE) | Bytes for Read/Write; KB for Erase (must align to the MTD erase block size) |
| Data | Write payload, Write only |

Channel-specific status codes: `0x40` access denied, `0x41` unsupported size,
`0x42` erase not aligned, `0x43` write protected. Capability bits reported in
`MEM_DEV_CFG` (`CAPABILITIES` at offset `0x00`): `WRITEABLE` (bit 0) and
`NO_ERASE` (bit 1).

DTS example:

```dts
mem-dev@4 {
    reg = <4>;
    nuvoton,mtd-name = "npcm-espi-flash";
};
```

```bash
dmesg | grep -i -E 'obmf|mtd|npcm-espi-flash'
ls -la /sys/bus/usb/devices/*/obmf/channel/*/mtd
cat /proc/mtd

# After the remote host performs read/write/erase operations:
hexdump -C /dev/mtd/npcm-espi-flash
```

Suggested checks:

- `npcm-espi-flash` (or equivalent mapped MTD node) appears in `/proc/mtd`.
- After remote write, hexdump shows the expected updated values.
- After remote erase, hexdump shows the `0xff` fill pattern in the erased region.
- Requests that violate size/alignment/write-protect constraints get the
  matching `0x41`/`0x42`/`0x43` status instead of being silently applied.

### 6. UART / Serial test

Prerequisites: `CONFIG_USB_OBMF_SERIAL=y`, `CONFIG_TTY=y`

The Serial channel appears as `/dev/ttyOBMF*` and can be used by normal Linux
tty tools.

```bash
dmesg | grep -i -E 'obmf|ttyOBMF|serial'
ls /dev/ttyOBMF*

stty -F /dev/ttyOBMF<device>_<channel> 115200 raw -echo
cat /dev/ttyOBMF<device>_<channel>
```

Suggested checks:

- `/dev/ttyOBMF*` appears after OBMF discovery and remains available.
- RX path: remote-originated data is visible on the BMC.
- TX path: BMC-written data is accepted and forwarded.

### 7. Port 80 / POST code test

Prerequisites: `CONFIG_USB_OBMF=y` (the IO channel is part of the OBMF core).

```bash
dmesg | grep -i -E 'obmf|io|post|port 80'
ls /dev/obmf*-io-*
ls -al /sys/bus/usb/devices/*/obmf/channel/*

# Capture POST codes (1-byte and 4-byte streams)
snoopd -v -b 1 -d /dev/obmf<device>-io-<channel> &
snoopd -v -b 4 -d /dev/obmf<device>-io-<channel> &
```

Trigger boot progress on the remote platform and observe POST code changes on
the BMC. Captured codes should change in sequence during remote boot.

### 8. I2C Controller test

Prerequisites: `CONFIG_USB_OBMF_I2C=y` and `CONFIG_I2C=y`; SMC firmware
(OpenBIC) with I2C Controller Optimized Channel support; DTS with the OBMF I2C
channel declaration.

DTS configuration (excerpt of the EVB overlay, OBMF I2C channel 13):

```dts
&ehci1 {
    smc@1 {
        reg = <1>;
        #address-cells = <1>;
        #size-cells = <0>;

        i2c-ch@13 {
            reg = <13>; // channel_id = 13 = OBMF I2C channel
            #address-cells = <1>;
            #size-cells = <0>;

            i2c30: i2c {
                #address-cells = <1>;
                #size-cells = <0>;

                gpio@20 { compatible = "ti,tca6416"; reg = <0x20>; ... };
                hwmon@23 { compatible = "nuvoton,nct7363"; reg = <0x23>; ... };

                i2c-mux@71 {
                    compatible = "nxp,pca9848";
                    reg = <0x71>;
                    ...
                    i2c@0 {
                        reg = <0>;
                        tmp75@48 { compatible = "ti,tmp75"; reg = <0x48>; };
                    };
                    ...
                };
            };
        };
    };
};
```

Verify OBMF I2C adapter registration:

```bash
i2cdetect -l | grep -i obmf
```

Expected output:

```
i2c-27  i2c             OBMF0 I2C ch10                          I2C adapter
i2c-28  i2c             OBMF0 I2C ch11                          I2C adapter
i2c-29  i2c             OBMF0 I2C ch12                          I2C adapter
i2c-30  i2c             OBMF0 I2C ch13                          I2C adapter
```

> The adapter numbers `27`..`30` are pinned by the `i2c27`..`i2c30` aliases in
> the EVB overlay. Without such aliases (for example on your own board DTS)
> the kernel assigns the number dynamically; read it from `i2cdetect -l`. The
> PCA9848 mux channels behind `i2c-30` get dynamically numbered adapters;
> find them with `i2cdetect -l | grep i2c-30-mux`.

Read the devices on `i2c-30` and a TMP75 behind the mux:

```bash
i2cdetect -y 30                              # expect 0x20, 0x23, 0x71 (UU when bound)
i2cdetect -l | grep i2c-30-mux               # note the bus N for mux chan_id 0
i2ctransfer -y -f N w1@0x48 0x0 r2           # TMP75 temperature register
cat /sys/bus/i2c/devices/N-0048/hwmon/hwmon*/temp1_input   # e.g. 33187 = 33.187 C
```

`i2cdetect` reports `UU` for addresses that a kernel driver has bound; use
`i2ctransfer -f` (as above) to access them anyway.

Suggested checks:

- OBMF I2C adapters appear in `i2cdetect -l` with the correct channel names.
- Target devices are visible at the expected addresses.
- `i2ctransfer` reads return valid data without errors.
- hwmon sysfs entries are accessible and return sensible values.

### 9. I2C Target test

Hardware topology: BMC — (OBMF I2C via USB) — SMC — (I2C) — MCTP device

The BMC is the MCTP bus owner of the SMC's physical I2C bus. MCTP over I2C
uses controller writes in both directions, so the two OBMF channels work as a
pair:

- BMC -> device: `mctpi2c27` writes through the I2C Controller channel 10
  (`i2c-27`), and the SMC drives the frame onto its I2C bus to the device at
  `0x10`.
- Device -> BMC: the device writes its response to the BMC's own address
  `0x12`. The SMC receives it as an I2C target and forwards it over the I2C
  Target channel 14, which delivers it to the paired adapter `i2c-27`, where
  the `mctp-i2c-controller` client hands it to `mctpi2c27`.

Prerequisites: `CONFIG_USB_OBMF_I2C=y`, `CONFIG_I2C_SLAVE=y`, `CONFIG_MCTP=y`
and `CONFIG_MCTP_TRANSPORT_I2C=y` (all enabled for the OBMF distro); kernel
support for the I2C Target channel (`obmf,paired-controller`); an MCTP
endpoint at 7-bit address `0x10` on the SMC I2C bus served by OBMF channel
10.

DTS configuration (already in the EVB overlay):

```dts
&ehci1 {
    smc@1 {
        reg = <1>;
        #address-cells = <1>;
        #size-cells = <0>;

        // I2C controller
        i2c-ch@10 {
            reg = <10>;
            #address-cells = <1>;
            #size-cells = <0>;

            i2c27: i2c {
                #address-cells = <1>;
                #size-cells = <0>;

                mctp-controller;
                mctp@12 {
                    compatible = "mctp-i2c-controller";
                    reg = <(0x12 | I2C_OWN_SLAVE_ADDRESS)>;
                };
            };
        };

        // I2C target
        i2c-tgt@14 {
            reg = <14>;
            obmf,paired-controller = <&i2c27>;
        };
    };
};
```

- `i2c-tgt@<channel_id>` declares the I2C Target channel.
- `obmf,paired-controller` links the target channel to its controller adapter.
- `mctp@12` with `I2C_OWN_SLAVE_ADDRESS` is the BMC's own MCTP address on
  that bus and creates the `mctpi2c27` link.

entity-manager configuration: the OBMF distro installs
`nuvoton_npcm400_evb_i2c-obmf.json` as
`/usr/share/entity-manager/configurations/nuvoton/npcm400_evb_i2c.json`:

```json
{
    "Exposes": [
        {
            "Address": "0x10",
            "Bus": "27",
            "Name": "MCTP I2C Device 0",
            "Type": "MCTPI2CTarget"
        }
    ],
    "Name": "NPCM400 SMC EVB with MCTP I2C (OBMF)",
    "Probe": "TRUE",
    ...
}
```

`Bus` is the Linux I2C bus number; mctpreactor maps it to the MCTP link
`mctpi2c<Bus>`. Other distros keep the default file (`"Bus": "0"`,
`"Probe": "FALSE"`).

No manual MCTP network configuration is needed. At boot:

1. `mctpd` starts, and its `ExecStartPost` runs `mctp-config`
   (`mctp-config-obmf`), which assigns local EID 8 to `mctpi2c27`, brings the
   link up and sets the MTU to 243.
2. entity-manager probes `npcm400_evb_i2c.json` and publishes the
   `MCTPI2CTarget`.
3. `xyz.openbmc_project.mctpreactor.service` asks `mctpd` to set up the
   endpoint at `0x10` on `mctpi2c27`. `mctpd` assigns the EID, adds the route
   and neighbour, and publishes the endpoint on D-Bus.

Verify on the BMC:

```bash
i2cdetect -l | grep -i obmf                 # expect i2c-27 "OBMF0 I2C ch10"
mctp link show mctpi2c27                    # up, mtu 243
mctp addr show dev mctpi2c27                # local EID 8
systemctl status xyz.openbmc_project.mctpreactor.service
journalctl -u xyz.openbmc_project.mctpreactor.service -u mctpd
busctl tree au.com.codeconstruct.MCTP1      # .../networks/1/endpoints/<EID>
mctp neigh show                             # <EID> dev mctpi2c27 lladdr 0x10
mctp route show
```

Use the EID that `mctpd` assigned (from `busctl tree` or `mctp neigh show`)
to check connectivity through the SMC bridge:

```bash
pldmtool base GetTID -m <EID>
pldmtool base GetPLDMTypes -m <EID>
```

Suggested checks:

- `mctpd` publishes an endpoint for the device under
  `/au/com/codeconstruct/mctp1/networks/1/endpoints/<EID>` without manual
  `mctp addr`/`route`/`neigh` commands.
- `mctp neigh show` lists the endpoint on `mctpi2c27` with `lladdr 0x10`.
- `pldmtool` commands return `SUCCESS` from the endpoint.

To trace the OBMF I2C Controller and Target channel frames on USB:

```bash
cat /sys/kernel/debug/usb/usbmon/1u &
```

### 10. I3C Controller test

Hardware topology: BMC (OBMF host) — (USB) — SMC1 (i3c5 controller) — (I3C) — (i3c5 target) SMC2

Prerequisites: `CONFIG_USB_OBMF_I3C=y` and `CONFIG_I3C=y`; `CONFIG_MCTP=y` and
`CONFIG_MCTP_TRANSPORT_I3C=y`; `CONFIG_USB_OBMF_I2C=y` as well if the channel
reports an associated I2C channel (`SET_ASSOC_I2C`); SMC1 as the I3C
controller and SMC2 attached as an I3C target.

DTS configuration (OBMF host side):

```dts
&ehci1 {
    smc@1 { /* Topology: BMC(ehci1) -- smc@1 (SMC1, 1-1) */
        reg = <1>;
        #address-cells = <1>;
        #size-cells = <0>;

        i3c-ch@18 {
            reg = <18>; // channel_id of this I3C channel
            i3c {
                #address-cells = <3>;
                #size-cells = <0>;
                mctp-controller;
            };
        };
    };
};
```

Confirm the channel came up and note the I3C bus number:

```bash
dmesg | grep -i -E 'obmf|i3c'
```

```text
obmf 1-1:1.1: ch18: I3C bus_init() called
obmf 1-1:1.1: ch18 I3C config: pp=12500kHz od=400kHz max_ops=16 payload=256 ibi=128 feat=0x01
obmf 1-1:1.1: ch18: SET_ASSOC_I2C(ch10)
obmf 1-1:1.1: ch18: registered I3C master (bus-2) with assoc I2C
```

`bus-2` means the channel was registered as I3C bus 2:

```bash
ls /sys/bus/i3c/devices/
# 2-63212345607/ i3c-0/ i3c-1/ i3c-2/
```

`i3c-2` is the OBMF I3C master, and `2-63212345607` is the SMC2 target on that
bus (bus number followed by the device PID).

> The bus number (`bus-2` / `i3c-2`) and the derived MCTP link name
> (`mctpi3c2`) are assigned dynamically, and the PID comes from the SMC2
> firmware. **Your numbers will differ**; take them from your own `dmesg`,
> `ls /sys/bus/i3c/devices/` and `mctp link show` output.

On the OBMF distro, `mctp-config-obmf` has already brought `mctpi3c2` up with
local EID 8 and MTU 243 when `mctpd` started. Check it:

```bash
mctp link show mctpi3c2
mctp addr show dev mctpi3c2
```

If your I3C bus number is not 2, run `mctp link set mctpi3cN up` and
`mctp addr add 8 dev mctpi3cN` by hand (and fix `mctp-config-obmf`).

Add the route and neighbour entry for the remote endpoint on SMC2.
`0x06:32:12:34:56:07` is the PID (link-layer address) of the SMC2 I3C target
(`2-63212345607`):

```bash
mctp route add 10 via mctpi3c2
mctp neigh add 10 dev mctpi3c2 lladdr 0x06:32:12:34:56:07
```

Learn the remote endpoint:

```bash
busctl call au.com.codeconstruct.MCTP1 \
    /au/com/codeconstruct/mctp1/interfaces/mctpi3c2 \
    au.com.codeconstruct.MCTP.BusOwner1 LearnEndpoint ay 6 0x06 0x32 0x12 0x34 0x56 0x07
```

Expected output:

```
yisb 10 1 "/au/com/codeconstruct/mctp1/networks/1/endpoints/10" true
```

Verify MCTP/PLDM connectivity over the I3C channel:

```bash
pldmtool base GetTID -m 10
```

```json
{
    "Response": 134
}
```

Suggested checks:

- The driver log reports `registered I3C master (bus-N)` and the matching
  `i3c-N` entry exists under `/sys/bus/i3c/devices/`.
- The remote target appears as an `<bus>-<PID>` device node.
- The OBMF I3C channel appears as an `mctpi3c*` link in `mctp link show`.
- `LearnEndpoint` returns the assigned EID and a valid endpoint object path.
- `pldmtool base GetTID` returns a valid TID from the remote endpoint on SMC2.
