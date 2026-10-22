# OBMF (Open Boot and Management Framework over USB)

This document describes OBMF support on the Nuvoton NPCM845 EVB
(`meta-evb-npcm845`). For general board setup, build and flash instructions,
see the [NPCM845 EVB README](README.md).

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

## Table of Contents

**Build and configuration**

1. [Build the OBMF Image](#1-build-the-obmf-image)
2. [What the OBMF Distro Enables](#2-what-the-obmf-distro-enables)
   - [2.1 Recipe changes](#21-recipe-changes)
   - [2.2 EVB channel map](#22-evb-channel-map)
3. [MCTP Link Configuration and MTU](#3-mctp-link-configuration-and-mtu)
4. [Kernel Config Matrix](#4-kernel-config-matrix)

**Device Tree design**

5. [USB Topology and Hierarchical DTS Design](#5-usb-topology-and-hierarchical-dts-design)
   - [5.1 Where the DTS lives and how it is applied](#51-where-the-dts-lives-and-how-it-is-applied)
   - [5.2 How the driver matches a USB device to a DT node](#52-how-the-driver-matches-a-usb-device-to-a-dt-node)
   - [5.3 Determining the port numbers](#53-determining-the-port-numbers)
   - [5.4 Case A: device directly on the root port (no hub)](#54-case-a-device-directly-on-the-root-port-no-hub)
   - [5.5 Case B: device behind one hub](#55-case-b-device-behind-one-hub)
   - [5.6 Case C: device behind two hubs](#56-case-c-device-behind-two-hubs)
   - [5.7 Rules and pitfalls](#57-rules-and-pitfalls)
   - [5.8 Verifying the topology](#58-verifying-the-topology)

**Runtime reference**

6. [Channel Type to Linux Device Mapping](#6-channel-type-to-linux-device-mapping)
7. [What You Should See on the BMC](#7-what-you-should-see-on-the-bmc)
   - [7.1 Kernel logs](#71-kernel-logs)
   - [7.2 USB driver binding](#72-usb-driver-binding)
   - [7.3 OBMF sysfs hierarchy](#73-obmf-sysfs-hierarchy)
   - [7.4 Device nodes and subsystem devices](#74-device-nodes-and-subsystem-devices)

**Testing**

8. [Channel Test Guide](#8-channel-test-guide) (overview and test index)
   - [Test 1: Base bring-up](#test-1-base-bring-up)
   - [Test 2: GPIO](#test-2-gpio)
   - [Test 3: IPMI](#test-3-ipmi)
   - [Test 4: SPI flash](#test-4-spi-flash)
   - [Test 5: Memory Device (eSPI flash)](#test-5-memory-device-espi-flash)
   - [Test 6: UART / Serial](#test-6-uart--serial)
     - [Host console (obmc-console)](#host-console-obmc-console)
   - [Test 7: Port 80 / POST code](#test-7-port-80--post-code)
   - [Test 8: I2C Controller](#test-8-i2c-controller)
   - [Test 9: I2C Target (MCTP over I2C)](#test-9-i2c-target-mctp-over-i2c)
   - [Test 10: I3C Controller (MCTP over I3C)](#test-10-i3c-controller-mctp-over-i3c)
     - [MCTP over I3C data flow (IBI)](#mctp-over-i3c-data-flow-ibi)
     - [Hot-Join](#hot-join)

Every section and test ends with a [Back to contents](#table-of-contents)
link.

## 1. Build the OBMF Image

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

[Back to contents](#table-of-contents)

## 2. What the OBMF Distro Enables

### 2.1 Recipe changes

`obmf.inc` adds `obmf` to `DISTRO_FEATURES` and the `df-obmf` override.
Recipes use the override to add the following only for this distro:

| Component | Change |
|---|---|
| Kernel | `KBRANCH = "NPCM-6.12-OBMF-dev"` (pinned `SRCREV`), `PREFERRED_VERSION_linux-nuvoton = "6.12.%"`, `0016-hwmon-add-nct7363.patch` |
| Kernel config | `obmf.cfg`: USB OBMF core and I2C/GPIO/SPI/Serial/IPMI/I3C channel handlers, I3C + `i3cdev`, MCTP I3C transport, PCA953x GPIO expander, PCA954x I2C mux, NCT7363 hwmon, `usbmon`, NPCM eSPI flash. The Memory Device handler (`CONFIG_USB_OBMF_MEM_DEV`) is enabled by its Kconfig default. |
| Device Tree | `nuvoton-npcm845-evb-obmf.dtso` is applied on `nuvoton-npcm845-evb.dtb` at build time to produce `nuvoton-npcm845-evb-obmf.dtb` (`KERNEL_DEVICETREE`) |
| mctp | `mctp-config-obmf` replaces the default `mctp-config` (see [section 3](#3-mctp-link-configuration-and-mtu)) |
| entity-manager | `nuvoton_npcm400_evb_i2c-obmf.json` replaces the default `nuvoton_npcm400_evb_i2c.json`: the NPCM400 MCTP I2C device is on bus 27 (the OBMF I2C channel) with `"Probe": "TRUE"`, so `xyz.openbmc_project.mctpreactor.service` sets up the endpoint at boot. `npcm400_evb_i3c_obmf.json` is added only on this distro and does the same for the MCTP I3C target (SMC2) on I3C bus 2 (see [Test 10](#test-10-i3c-controller-mctp-over-i3c)) |
| obmc-console | Adds the `ttyOBMF0_0` and `ttyOBMF0_1` host consoles, reachable over SSH on ports 2230 and 2231 (see [Host console (obmc-console)](#host-console-obmc-console)) |

Other distros (`arbel-evb-entity`, `arbel-evb-emmc`, ...) do not get any of
these changes.

### 2.2 EVB channel map

The OBMF overlay describes one SMC on `ehci1` port 1 (USB path `1-1`, OBMF
device index 0, so device nodes are named `obmf0-*` / `OBMF0 *`) with these
channels, plus the reserved memory that backs the eSPI flash:

| Channel | DT node | Use on the EVB | Test |
|---:|---|---|---|
| 4 | `spi@4` | Memory Device (eSPI flash), MTD `npcm-espi-flash` | [Test 5](#test-5-memory-device-espi-flash) |
| 5 | `smc-gpio@5` | SMC GPIO (`SMC1GPIO*`) | [Test 2](#test-2-gpio) |
| 6, 7 | `sgpio0@6`, `sgpio1@7` | SMC SGPIO (`SMC1SGPIO0GPIO*`, `SMC1SGPIO1GPIO*`) | [Test 2](#test-2-gpio) |
| 8 | `vwgpio@8` | eSPI virtual wire GPIO (`SMC1VWGPIO*`) | [Test 2](#test-2-gpio) |
| 10 | `i2c-ch@10` -> `i2c-27` | MCTP over I2C, BMC own address `0x12` | [Test 9](#test-9-i2c-target-mctp-over-i2c) |
| 11 | `i2c-ch@11` -> `i2c-28` | MCTP over I2C, BMC own address `0x14` | [Test 9](#test-9-i2c-target-mctp-over-i2c) |
| 12 | `i2c-ch@12` -> `i2c-29` | Plain I2C controller | [Test 8](#test-8-i2c-controller) |
| 13 | `i2c-ch@13` -> `i2c-30` | TCA6416 (`0x20`), NCT7363 (`0x23`), PCA9848 mux (`0x71`) with TMP75 sensors | [Test 8](#test-8-i2c-controller) |
| 14 | `i2c-tgt@14` | I2C Target paired with `i2c-27` | [Test 9](#test-9-i2c-target-mctp-over-i2c) |
| 15 | `i2c-tgt@15` | I2C Target paired with `i2c-28` | [Test 9](#test-9-i2c-target-mctp-over-i2c) |
| 17 | `spi@17` | SPI Controller to the SMC SPI NOR flash, MTD `npcm-spi-flash` | [Test 4](#test-4-spi-flash) |
| 18 | `i3c-ch@18` | I3C controller with MCTP, driven by SMC `i3c4` (datasheet I3C5, balls A9/B9, 3.3 V) | [Test 10](#test-10-i3c-controller-mctp-over-i3c) |

The SMC firmware (OpenBIC `smc-npcm400-obmf`) also reports these channels,
which have no node in the overlay:

| Channel | SMC side | BMC device | Test |
|---:|---|---|---|
| 1 | MMIO | `/dev/obmf0-mmio-1` | - |
| 2 | Serial 0: `uart1` (CR_UART2), externally looped back to eSPI UARTB | `/dev/ttyOBMF0_0` | [Test 6](#test-6-uart--serial) |
| 3 | IPMI (KCS) | `/dev/ipmi-obmf0-3` | [Test 3](#test-3-ipmi) |
| 9 | IO (Port 80) | `/dev/obmf0-io-9` | [Test 7](#test-7-port-80--post-code) |
| 16 | Serial 1: `uart2` (CR_UART3) on the CR_SIN3/CR_SOUT3 pins (GPIOC0/GPIOC1) | `/dev/ttyOBMF0_1` | [Test 6](#test-6-uart--serial) |

Notes:

- The driver matches channel nodes by `reg` only; node names are cosmetic.
  Channel 4 is still named `spi@4`, and both `spi@4` and `spi@17` carry a
  leftover `nuvoton,flash-type` property. The current kernel ignores
  `nuvoton,flash-type`: the channel type reported by the SMC decides which
  handler runs.
- Channels that need no DT data (Serial, IPMI, IO, MMIO, OEM) are not in the
  overlay. They are registered from discovery alone, so their device nodes
  depend on what the SMC firmware reports.

The overlay adds `/aliases` entries `i2c27`..`i2c30` for channels 10..13, so
the OBMF I2C adapter numbers are fixed at `i2c-27`..`i2c-30` (and the MCTP
links at `mctpi2c27`/`mctpi2c28`). The I3C bus number has no alias and is
still assigned dynamically.

[Back to contents](#table-of-contents)

## 3. MCTP Link Configuration and MTU

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
  [Test 9](#test-9-i2c-target-mctp-over-i2c)).

[Back to contents](#table-of-contents)

## 4. Kernel Config Matrix

Check the effective kernel configuration before following the
[Channel Test Guide](#8-channel-test-guide). The OBMF channel switches default
to `y` only when their dependencies and `CONFIG_USB_OBMF` are enabled. A
disabled handler does not prevent channel discovery, but it does prevent
that channel's Linux device from being registered.

On the `arbel-evb-obmf` distro every option below is enabled, from
`obmf.cfg`, `af_mctp.cfg` and the EVB defconfig.

| Feature you want to use | Required kernel config | Configuration note |
|---|---|---|
| OBMF core, discovery, MMIO, IO and OEM channels | `CONFIG_USB_OBMF=y` | Select built-in for boot-time bring-up, or `m` for a module. |
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

[Back to contents](#table-of-contents)

## 5. USB Topology and Hierarchical DTS Design

An OBMF device does not have to sit directly on a BMC USB root port. It may
be attached behind one or more USB hubs (for example, a hub board that fans
out a single BMC USB host port to several SMC targets). This section explains
how the driver locates the Device Tree node for a given USB device, and how
to write the DTS for direct, one-hub, and two-hub topologies. These are board
DTS examples, not patches to copy as-is.

### 5.1 Where the DTS lives and how it is applied

In this layer the OBMF topology lives in
`recipes-kernel/linux/linux-nuvoton-612/nuvoton-npcm845-evb-obmf.dtso`. The
`linux-nuvoton_6.12.bbappend` copies it into the kernel tree in
`do_patch:append:df-obmf` and adds a Makefile rule that builds
`nuvoton-npcm845-evb-obmf.dtb` from `nuvoton-npcm845-evb.dtb` plus the
overlay. If your physical topology differs, edit that overlay. Describe
exactly one physical topology per host port; do not combine the
direct-device and hub examples under the same `reg`.

After changing the DTS, rebuild the kernel:

```bash
$ DISTRO=arbel-evb-obmf bitbake virtual/kernel
```

### 5.2 How the driver matches a USB device to a DT node

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

### 5.3 Determining the port numbers

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

### 5.4 Case A: device directly on the root port (no hub)

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

### 5.5 Case B: device behind one hub

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

### 5.6 Case C: device behind two hubs

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

### 5.7 Rules and pitfalls

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

### 5.8 Verifying the topology

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

[Back to contents](#table-of-contents)

## 6. Channel Type to Linux Device Mapping

The kernel driver discovers Channel 0 first, then registers each discovered
channel into the corresponding Linux subsystem.

| Channel Type | OBMF Type Code | What it means | Linux representation on the BMC |
|---|---:|---|---|
| Config / Discovery | `0x00` | Mandatory Channel 0 for discovery and channel config reads | No standalone device node; visible through kernel logs and OBMF sysfs hierarchy |
| MMIO | `0x01` | Generic MMIO channel | `/dev/obmf<device>-mmio-<channel>` miscdevice |
| GPIO | `0x02` | Optimized GPIO channel | `gpiochipN` device with label like `obmf<device>-gpio-ch<channel>` |
| Serial | `0x03` | Optimized UART/serial channel | `/dev/ttyOBMF<device>_<n>`, where `<n>` is the serial port index (0, 1, ... in channel order), not the channel ID |
| I2C Controller | `0x04` | Optimized I2C master/controller channel | `/dev/i2c-*` adapter named `OBMF<device> I2C ch<channel>` |
| I2C Target | `0x05` | Protocol-defined target mode | Requires `obmf,paired-controller` pointing at the I2C Controller adapter node |
| I3C Controller | `0x06` | Optimized I3C controller channel | I3C bus exposed to the MCTP stack as an `mctpi3c*` link |
| IPMI | `0x07` | Optimized IPMI/SSIF bridge | `/dev/ipmi-obmf<device>-<channel>` miscdevice |
| SPI Controller | `0x08` | Optimized SPI controller channel | Host-initiated, virtual MTD device named by `nuvoton,mtd-name` (for example `npcm-spi-flash`) |
| IO | `0x09` | Optimized IO channel | `/dev/obmf<device>-io-<channel>` miscdevice |
| Memory Device | `0x0A` | Byte-addressable device-initiated memory channel | MTD device named by `nuvoton,mtd-name` (default `npcm-espi-flash`), linked as `mtd` under the channel's sysfs directory |
| OEM | `0xF8-0xFF` | OEM-specific extension space | `/dev/obmf<device>-oem-<channel>` miscdevice; payload format depends on the OEM firmware |

Notes:

- GPIO, Serial, IPMI, and IO are the most visible channels because they
  create direct Linux device nodes or subsystem devices.
- SPI (`0x08`) is always host-initiated: the BMC forwards SPI NOR opcodes to
  the SMC over a virtual MTD device backed by `nuvoton,mtd-name`.
  Device-initiated byte-addressable access lives on the separate Memory Device
  channel (`0x0A`).

[Back to contents](#table-of-contents)

## 7. What You Should See on the BMC

Once the BMC boots with the OBMF kernel and the OBMF device is attached, you
can confirm bring-up in several places.

### 7.1 Kernel logs

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
- `chX: registered GPIO chip (<n> lines)`
- `chX: registered ttyOBMF<n>`
- `chX: registered /dev/ipmi-obmf<device>-<channel>`
- `chX: registered /dev/obmf<device>-io-<channel> (I/O Port)`
- `chX: registered I2C adapter OBMF<device> I2C ch<channel>`
- `chX: registered I2C target (paired with i2c-<n>)`
- `chX: registered I3C master (bus-<n>) with assoc I2C`
- `chX: registered virtual SPI-NOR MTD '<mtd-name>' (<size> bytes, erasesize <n>, cs<n>)`
- `chX: registered Memory Device (MTD: <mtd-name>, <size> bytes, erasesize <n>)`
- `OBMF-ICP obmf<device> ready: <count> channels, ver 0x....`

### 7.2 USB driver binding

```bash
ls /sys/bus/usb/drivers/obmf
```

### 7.3 OBMF sysfs hierarchy

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

- `device` for GPIO, I2C, Serial, IPMI and other subsystem-backed Linux devices
- `mmio` for MMIO channel miscdevices
- `io` for IO channel miscdevices
- `mtd` for the backing MTD device used by the Memory Device channel

### 7.4 Device nodes and subsystem devices

```bash
ls /dev | grep -E 'obmf|ttyOBMF|ipmi-obmf'
gpiodetect | grep -i obmf
gpioinfo
cat /proc/mtd
i2cdetect -l
```

[Back to contents](#table-of-contents)

## 8. Channel Test Guide

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

Test index (click a test name to jump to it):

| Test | Hardware topology | Who initiates | BMC-side interface | EVB channel |
|---|---|---|---|---|
| [1. Base bring-up](#test-1-base-bring-up) | BMC — (USB) — SMC | BMC | `dmesg`, sysfs | all |
| [2. GPIO](#test-2-gpio) | GPIO pins — SMC — (USB) — BMC | either side | `gpiochipN` | 5, 6, 7, 8 |
| [3. IPMI](#test-3-ipmi) | Host — (eSPI / KCS) — SMC — (USB) — BMC | host | `/dev/ipmi-obmf*` | from discovery |
| [4. SPI flash](#test-4-spi-flash) | BMC — (USB) — SMC — (SPI) — NOR flash | BMC | MTD (`npcm-spi-flash`) | 17 |
| [5. Memory Device](#test-5-memory-device-espi-flash) | Host — (eSPI flash) — SMC — (USB) — BMC | host | MTD (`npcm-espi-flash`) | 4 |
| [6. UART / Serial](#test-6-uart--serial) | UART peer — SMC — (USB) — BMC | either side | `/dev/ttyOBMF*`, obmc-console | from discovery |
| [7. Port 80 / POST](#test-7-port-80--post-code) | Host — (eSPI IO) — SMC — (USB) — BMC | host | `/dev/obmf*-io-*` | from discovery |
| [8. I2C Controller](#test-8-i2c-controller) | TEMP IC — (I2C) — SMC — (USB) — BMC | BMC | `/dev/i2c-N` | 12, 13 |
| [9. I2C Target](#test-9-i2c-target-mctp-over-i2c) | BMC — (OBMF I2C via USB) — SMC — (I2C) — MCTP device | BMC | `i2c-27` + `mctpi2c27`, mctpreactor | 10 + 14 |
| [10. I3C Controller](#test-10-i3c-controller-mctp-over-i3c) | BMC — (USB) — SMC1 — (I3C) — SMC2 | BMC (SMC2 for IBI and Hot-Join) | `i3c-2` + `mctpi3c2`, mctpreactor | 18 |

"from discovery" means the channel has no node in the EVB overlay; it exists
only if the SMC firmware reports it.

### Test 1: Base bring-up

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

[Back to contents](#table-of-contents)

### Test 2: GPIO

Prerequisites: `CONFIG_USB_OBMF_GPIO=y`, `CONFIG_GPIOLIB=y`

The GPIO channel is exposed as a normal Linux GPIO chip. Use `libgpiod` tools.
On the EVB, channels 5..8 register four chips (`obmf0-gpio-ch5` ..
`obmf0-gpio-ch8`) with the line names from the overlay (`SMC1GPIO*`,
`SMC1SGPIO0GPIO*`, `SMC1SGPIO1GPIO*`, `SMC1VWGPIO*`).

```bash
gpiodetect | grep -i obmf
gpioinfo gpiochipN

# Find a line by its overlay name
gpiofind SMC1GPIO0

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
- Line names defined in the overlay appear in `gpioinfo`.
- Reads reflect the expected input state.
- Writes succeed only on output-capable lines.

[Back to contents](#table-of-contents)

### Test 3: IPMI

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

[Back to contents](#table-of-contents)

### Test 4: SPI flash

Prerequisites: `CONFIG_USB_OBMF_SPI=y`, `CONFIG_MTD=y`

> **Warning:** the commands in this section write to raw MTD devices. Writing
> to the wrong `/dev/mtdX` will destroy the BMC's own U-Boot, environment or
> rootfs and can brick the board. Always resolve the number from
> `cat /proc/mtd` by the `nuvoton,mtd-name` you configured, and prefer the
> by-name path (`/dev/mtd/<name>`) over a hard-coded number.

The SPI Controller channel is always host-initiated: the BMC registers a
virtual MTD device from the channel DT node, and forwards each MTD op as a
single SPI NOR opcode (READ / PP / SE / BE) to the SMC, which drives the real
SPI bus.

| DT property | Required | Default | EVB value |
|---|---|---|---|
| `nuvoton,flash-size` | yes | - | `0x4000000` (64 MiB) |
| `nuvoton,flash-erasesize` | no | `0x1000`; `0x10000` selects block erase (BE) | `0x1000` |
| `nuvoton,flash-cs` | no | `0` | `0x1` (SMC `spi_fiu0_cs1`) |
| `nuvoton,mtd-name` | no | `npcm-spi-flash` | `npcm-spi-flash` |

- TX is not fragmented on the BMC side; max transfer unit is 448 bytes
  (`OBMF_SPI_MAX_XFER`).
- The SMC owns the full bus sequence (CS assert -> WREN before PP/Erase -> WIP
  polling -> CS deassert). The BMC does not issue WREN / RDSR and uses no local
  RAM or flash backing.
- A flash size above 16 MiB (as on the EVB) selects 4-byte addressing. The
  driver does not send EN4B, so the SMC flash must already be in 4-byte
  address mode.

DTS on the EVB (channel 17):

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

```bash
dmesg | grep -i -E 'obmf|spi|mtd|npcm-spi-flash'
cat /proc/mtd | grep npcm-spi-flash    # note the mtdN on the left

dd if=/dev/urandom of=/tmp/test.bin bs=1M count=5
flashcp -v /tmp/test.bin /dev/mtdN     # replace N with the matching MTD number
```

Suggested checks:

- `dmesg` shows `registered virtual SPI-NOR MTD 'npcm-spi-flash'`.
- The configured MTD node (for example `npcm-spi-flash`) appears in `/proc/mtd`.
- `flashcp -v` completes with a successful verify pass.

[Back to contents](#table-of-contents)

### Test 5: Memory Device (eSPI flash)

Prerequisites: `CONFIG_USB_OBMF_MEM_DEV=y`, `CONFIG_MTD=y`,
`CONFIG_SPI_NPCM_FLASH=y` for the eSPI-backed MTD device.

> **Warning:** the commands in this section read/write raw MTD devices. See
> the warning in [Test 4](#test-4-spi-flash); always resolve the MTD device by
> name.

The Memory Device channel (OBMF-ICP v1.0.0 RC1 section 4.12, Channel Type
`0x0A`) is always device-initiated (Producer/Responder): the SMC pushes
Memory Read/Write/Erase commands, and the BMC maps them onto the MTD device
named by `nuvoton,mtd-name` (default `npcm-espi-flash`). This channel replaces
the SPI Controller channel's former `espi` mode.

On the EVB, the backing MTD device is the NPCM eSPI flash driver
(`&espi_flash`) using the 64 MiB reserved memory at `0x10000000`. The
channel 4 node in the overlay is named `spi@4` and still carries
`nuvoton,flash-type = "espi"`; the kernel ignores both the name and that
property and reads only `reg` and `nuvoton,mtd-name`.

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

DTS example (equivalent to the EVB `spi@4` node):

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

- `dmesg` shows `registered Memory Device (MTD: npcm-espi-flash, ...)`.
- `npcm-espi-flash` (or equivalent mapped MTD node) appears in `/proc/mtd`.
- After remote write, hexdump shows the expected updated values.
- After remote erase, hexdump shows the `0xff` fill pattern in the erased region.
- Requests that violate size/alignment/write-protect constraints get the
  matching `0x41`/`0x42`/`0x43` status instead of being silently applied.

[Back to contents](#table-of-contents)

### Test 6: UART / Serial

Prerequisites: `CONFIG_USB_OBMF_SERIAL=y`, `CONFIG_TTY=y`

Each Serial channel appears as `/dev/ttyOBMF<device>_<n>` and can be used by
normal Linux tty tools. `<n>` is the serial port index on that OBMF device
(the first Serial channel reported by the SMC is `_0`, the second `_1`, ...),
not the channel ID; `dmesg` shows the mapping as `chX: registered ttyOBMF<n>`.
Serial channels need no DT node. Ports default to 115200 8N1.

On the EVB the SMC bridges two UARTs:

| BMC tty | OBMF channel | SMC UART | Where the UART peer connects |
|---|---|---|---|
| `ttyOBMF0_0` | 2 | `uart1` (CR_UART2) | Externally looped back to eSPI UARTB; no physical pins |
| `ttyOBMF0_1` | 16 | `uart2` (CR_UART3) | CR_SIN3 (GPIOC0) / CR_SOUT3 (GPIOC1) on the SMC, 3.3 V; wire a USB-serial adapter here for the RX test |

The SMC forwards UART data only while the BMC has enabled the channel; bytes
that arrive on the UART before that are dropped.

```bash
dmesg | grep -i -E 'obmf|ttyOBMF|serial'
ls /dev/ttyOBMF*

stty -F /dev/ttyOBMF<device>_<n> 115200 raw -echo
cat /dev/ttyOBMF<device>_<n>
```

#### Host console (obmc-console)

On the `arbel-evb-obmf` distro, `obmc-console` also serves `ttyOBMF0_0` and
`ttyOBMF0_1` (the first two Serial channels of OBMF device 0) as host
consoles, next to the EVB UART consoles:

| Console | Server config | SSH port |
|---|---|---|
| `ttyS1` | `/etc/obmc-console/server.ttyS1.conf` | 2200 |
| `ttyS4` | `/etc/obmc-console/server.ttyS4.conf` | 2220 |
| `ttyS5` | `/etc/obmc-console/server.ttyS5.conf` | 2222 |
| `ttyOBMF0_0` | `/etc/obmc-console/server.ttyOBMF0_0.conf` | 2230 |
| `ttyOBMF0_1` | `/etc/obmc-console/server.ttyOBMF0_1.conf` | 2231 |

Each OBMF console runs at 115200 baud and logs to
`/var/log/obmc-console-OBMF0_<n>.log`. The files are in
`recipes-phosphor/console/obmc-console/`, and the bbappend adds the two
consoles to `HOST_CONSOLE_TTY` only on the `df-obmf` override.

Check the console servers on the BMC:

```bash
systemctl status obmc-console@ttyOBMF0_0 obmc-console@ttyOBMF0_1
systemctl list-sockets | grep obmc-console
cat /var/log/obmc-console-OBMF0_0.log
```

Connect from a remote machine (`~.` closes the session):

```bash
ssh -p 2230 root@<bmc-ip>   # ttyOBMF0_0
ssh -p 2231 root@<bmc-ip>   # ttyOBMF0_1
```

Or attach on the BMC itself:

```bash
obmc-console-client -c /etc/obmc-console/server.ttyOBMF0_0.conf
```

The console server needs `/dev/ttyOBMF0_<n>` to exist when it starts. If the
OBMF device enumerates after the server has given up, restart it:

```bash
systemctl restart obmc-console@ttyOBMF0_0
```

Suggested checks:

- `/dev/ttyOBMF*` appears after OBMF discovery and remains available.
- RX path: remote-originated data is visible on the BMC (raw `cat`, the SSH
  console session and the console log).
- TX path: BMC-written data, including input typed in the SSH console session,
  is accepted and forwarded to the UART peer.

Status (2026-10-22): on channel 16, data written by the BMC reaches the SMC
`uart2` TX. The RX path (UART peer -> BMC) has not been tested yet: it needs a
peer wired to CR_SIN3/CR_SOUT3.

[Back to contents](#table-of-contents)

### Test 7: Port 80 / POST code

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

[Back to contents](#table-of-contents)

### Test 8: I2C Controller

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

[Back to contents](#table-of-contents)

### Test 9: I2C Target (MCTP over I2C)

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

Channels 11 (`i2c-28`, BMC address `0x14`) and 15 form a second pair with the
same layout; `mctp-config-obmf` and entity-manager only configure the
`i2c-27` pair.

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

- `dmesg` shows `ch14: registered I2C target (paired with i2c-27)`.
- `mctpd` publishes an endpoint for the device under
  `/au/com/codeconstruct/mctp1/networks/1/endpoints/<EID>` without manual
  `mctp addr`/`route`/`neigh` commands.
- `mctp neigh show` lists the endpoint on `mctpi2c27` with `lladdr 0x10`.
- `pldmtool` commands return `SUCCESS` from the endpoint.

To trace the OBMF I2C Controller and Target channel frames on USB:

```bash
cat /sys/kernel/debug/usb/usbmon/1u &
```

[Back to contents](#table-of-contents)

### Test 10: I3C Controller (MCTP over I3C)

Hardware topology: BMC (OBMF host) — (USB) — SMC1 (`i3c4` controller, balls
A9/B9) — (I3C, 3.3 V) — SMC2 (I3C target)

SMC1 drives the bus with its `i3c4` controller, which is I3C5 in the NPCM400F
datasheet: SCL on ball B9 (GPIO82), SDA on ball A9 (GPIO83). These pins are on
the VSB supply, so the bus runs at 3.3 V only. SMC2 is an MCTP endpoint with
PID `0x063212345607`, BCR `0x66` and DCR `0xCC`, and joins the bus with a
Hot-Join request.

Prerequisites:

- BMC: `CONFIG_USB_OBMF_I3C=y` and `CONFIG_I3C=y`; `CONFIG_MCTP=y` and
  `CONFIG_MCTP_TRANSPORT_I3C=y`; `CONFIG_USB_OBMF_I2C=y` as well if the
  channel reports an associated I2C channel (`SET_ASSOC_I2C`). All are enabled
  on the OBMF distro.
- SMC1: OpenBIC `smc-npcm400-obmf` firmware that includes these changes (all
  three are needed for IBI and Hot-Join to work):
  - `meta-nuvoton: smc-npcm400-obmf: move the OBMF I3C Controller channel to i3c4`
  - `meta-nuvoton: common: obmf: re-register I3C IBI callbacks after Hot-Join`
  - `meta-nuvoton: common: obmf: notify the BMC of I3C Hot-Join`, which needs
    `drivers: i3c: npcm4: add a Hot-Join completion callback` in
    `zephyr_nuvoton`
- SMC2: running an MCTP I3C target. It answers each request with an IBI whose
  mandatory data byte is `0xAE`, then waits for the controller to read the
  response.

DTS configuration (OBMF host side, as in the EVB overlay):

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

> The I3C bus number (`bus-2` / `i3c-2`) and the derived MCTP link name
> (`mctpi3c2`) are assigned dynamically. `mctp-config-obmf` and
> `npcm400_evb_i3c_obmf.json` both assume bus 2. If your system reports a
> different bus, fix both files.

No manual MCTP network configuration is needed. At boot:

1. `mctpd` starts, and `mctp-config-obmf` assigns local EID 8 to `mctpi3c2`,
   brings the link up and sets the MTU to 243.
2. entity-manager probes `npcm400_evb_i3c_obmf.json`, which publishes SMC2 as
   an `MCTPI3CTarget`:

   ```json
   {
       "Exposes": [
           {
               "Address": [6, 50, 18, 52, 86, 7],
               "Bus": "2",
               "Name": "MCTP I3C Device 0",
               "Type": "MCTPI3CTarget"
           }
       ],
       "Name": "NPCM400 SMC EVB with MCTP I3C (OBMF)",
       "Probe": "TRUE",
       ...
   }
   ```

   `Address` is the target PID (`0x06 0x32 0x12 0x34 0x56 0x07`), not its
   dynamic address, so the configuration still matches after a Hot-Join moves
   the device. `Bus` is the I3C bus number; mctpreactor maps it to the MCTP
   link `mctpi3c<Bus>`.
3. `xyz.openbmc_project.mctpreactor.service` calls mctpd `AssignEndpoint` with
   that PID on `mctpi3c2`. `mctpd` assigns the EID, adds the route and
   neighbour, and publishes the endpoint on D-Bus.

Verify on the BMC:

```bash
mctp link show mctpi3c2                     # up, mtu 243
mctp addr show dev mctpi3c2                 # local EID 8
journalctl -u xyz.openbmc_project.mctpreactor.service -u mctpd
busctl tree au.com.codeconstruct.MCTP1      # .../networks/1/endpoints/<EID>
mctp neigh show                             # <EID> dev mctpi3c2, lladdr = SMC2 PID
```

Use the EID that `mctpd` assigned (10 on the EVB) to check MCTP/PLDM
connectivity over the I3C channel:

```bash
pldmtool base GetTID -m 10
pldmtool base GetPLDMTypes -m 10
```

```json
{
    "Response": 134
}
```

Manual setup (only if the image has no `npcm400_evb_i3c_obmf.json`, or to
debug mctpreactor): add the route and neighbour entry for SMC2 and learn the
endpoint by hand:

```bash
mctp route add 10 via mctpi3c2
mctp neigh add 10 dev mctpi3c2 lladdr 0x06:32:12:34:56:07
busctl call au.com.codeconstruct.MCTP1 \
    /au/com/codeconstruct/mctp1/interfaces/mctpi3c2 \
    au.com.codeconstruct.MCTP.BusOwner1 LearnEndpoint ay 6 0x06 0x32 0x12 0x34 0x56 0x07
```

Expected output:

```
yisb 10 1 "/au/com/codeconstruct/mctp1/networks/1/endpoints/10" true
```

#### MCTP over I3C data flow (IBI)

Every MCTP message from SMC2 back to the BMC rides on an IBI:

```text
BMC (mctp-i3c)          SMC1 (OBMF ch18)               SMC2 (I3C target)
     |  EXECUTE_SEQUENCE:     |                               |
     |  private write ------->|-- private SDR write --------->|  MCTP request
     |                        |<-- IBI, MDB 0xAE -------------|  response ready
     |<-- IBI Notification ---|                               |
     |    (cmd 5, MDB 0xAE)   |                               |
     |  ACK {05 00} --------->|                               |
     |  EXECUTE_SEQUENCE:     |                               |
     |  private read -------->|-- private SDR read ---------->|
     |<-- response data ------|<-- MCTP response -------------|
```

- SMC1 forwards the raw IBI payload; it does not read from SMC2 by itself.
  The BMC decides to read.
- The BMC must ACK every SMC-initiated event on ch18. Until it does, SMC1
  cannot send the next IBI or Hot-Join notification on that channel.
- If `pldmtool` times out while the BMC log shows its requests going out,
  SMC1 is not forwarding IBIs. Check that SMC1 has the IBI re-registration
  change listed in the prerequisites.

#### Hot-Join

When SMC2 resets, it rejoins the bus with a Hot-Join request:

1. SMC1's `i3c4` driver ACKs the Hot-Join and runs DAA by itself. SMC2 may
   get a different dynamic address (for example `0x0a` instead of `0x09`),
   and SMC1 re-attaches it with a new descriptor.
2. SMC1 re-registers the IBI for SMC2, matching it by PID, and sends an
   `I3C_EVT_HOTJOIN_NOTIFICATION` (cmd 6) on ch18. Per OBMF-ICP v1.0.0 RC1
   section 4.8.1 the event has no parameters or payload:
   `06 00 00 00 00 00`.
3. The BMC driver ACKs it (`{06 00}`) and queues `i3c_master_do_daa()`, which
   sends DO_DAA to SMC1. SMC1 runs RSTDAA + ENTDAA and returns the device
   list. On the EVB, SMC2 ends up back at `0x09`.
4. MCTP traffic resumes on the next request without restarting any BMC
   service (verified on the EVB, where SMC2 gets `0x09` back).

Test: with MCTP traffic running (for example a `pldmtool` loop), reset SMC2.

On the SMC1 console, expect (log prefixes and timestamps omitted):

```text
<inf> i3c_npcm4: DAA: device 0 assigned to 0x0a
<inf> i3c_npcm4: Hot-join DAA done: 1 device(s) assigned
<inf> obmf: I3C Hot-Join: notified BMC
<inf> i3c_npcm4: DAA: device 0 assigned to 0x09
<inf> obmf: bus_init: DAA assigned 1 device(s)
<inf> obmf: Register an I3C device: 0x09 pid=0x63212345607 bcr=0x66 dcr=0xcc
<inf> obmf: I3C IBI registered and enabled for dev@09 on bus 4
```

A single `i3c_npcm4: priv transfer error: -5` can show up while SMC2 is at
its temporary address: a BMC write that was already on its way to the old
address gets NACKed. It is expected during the address change.

The BMC-side messages are `dev_dbg`. Enable them before the test:

```bash
echo 'file drivers/usb/class/obmf/obmf-i3c.c +p' > /sys/kernel/debug/dynamic_debug/control
dmesg -w | grep ch18
# ch18: Hot-Join received
# ch18: Hot-Join: starting DAA
# ch18: DAA found 1 device(s)
```

Suggested checks:

- The driver log reports `registered I3C master (bus-N)` and the matching
  `i3c-N` entry exists under `/sys/bus/i3c/devices/`.
- The remote target appears as an `<bus>-<PID>` device node.
- The OBMF I3C channel appears as an `mctpi3c*` link in `mctp link show`.
- `mctpd` publishes an endpoint for SMC2 without manual `mctp`/`busctl`
  commands, and `mctp neigh show` lists it on `mctpi3c2`.
- `pldmtool base GetTID` returns a valid TID from the remote endpoint on SMC2.
- After an SMC2 reset, the SMC1 console shows the Hot-Join sequence above, the
  BMC log shows `Hot-Join received`, and `pldmtool` works again without
  restarting any BMC service.

[Back to contents](#table-of-contents)
