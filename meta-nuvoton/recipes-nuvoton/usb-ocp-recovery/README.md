# usb-ocp-recovery — Caliptra MCU USB OCP recovery + PLDM update

Bench setup for recovering the NPCM500 Caliptra MCU over USB OCP from the NPCM845 (Arbel) BMC,
then pushing a PLDM firmware package to it over MCTP-over-USB. The work is done by
`caliptra-recovery-usb.sh`, which this recipe installs in the BMC image; this README documents
what you have to provide around it. Bench-only files are in `bench/`; the recipe does not install
them.

## Bench setup

Board: NPCM500 EVB, schematic *SVB_SMC_V1_260707.pdf* (SMC_NPCM500 rev 1.0).

### Connections

| Link | Arbel (NPCM845) side      | NPCM500 EVB side           | Used for                          |
|------|---------------------------|----------------------------|-----------------------------------|
| JTAG | `J_JTAGM` (JTAG master)   | J34, JTAG1 (JP1-JP4 fitted) | OpenOCD releases the Caliptra MCU |
| USB  | USB host                  | USB device                 | OCP recovery, then MCTP-over-USB  |
| UART | -                         | J66, `CR_UART3`            | MCU ROM / runtime and M7 console  |
| UART | -                         | J80, `CR_UART5`            | Caliptra core console             |

JTAG pinout, J34 (JTAG1 slave) to Arbel `J_JTAGM`:

| NPCM500 J34 pin | Signal | Arbel `J_JTAGM` pin | Signal   |
|-----------------|--------|---------------------|----------|
| 9               | TCK    | 4                   | TCK      |
| 7               | TMS    | 2                   | TMS      |
| 5               | TDI    | 8                   | TDI_MOSI |
| 13              | TDO    | 6                   | TDO_MISO |
| 4 / 6           | GND    | 3 or 5              | GND      |

VTref comes from the Arbel side: tie Arbel `J_JTAGM` pin 1 to Arbel `J_ESPI` pin 1 (1.8 V).
`gpioset 2 6=0` enables the Arbel JTAG master; the script does this.

All UARTs run at 133000 8N1; at 115200 the output is garbage. `CR_UART3` on J66: pin 1 = SIN
(to adapter TX), pin 2 = SOUT (to adapter RX), pin 3 = GND.

### Straps

Straps are sampled only at VSB power-up, so power the board off before changing SW2/SW4.

| Strap                 | Switch                                     | Setting                                         |
|-----------------------|--------------------------------------------|-------------------------------------------------|
| JEN1# / JEN2# / JEN3# | SW2.3 / SW4.1 / SW2.2                      | `0 1 1`: JTAG1 (J34) = CPTRA_MCU, JTAG2 (J55) = ARM_M7 |
| STMB#                 | SW2.1                                      | `1`: required for USB recovery boot             |
| Mode strap2 / strap1  | SW4.2 / SW4.3                              | `0 0`: normal boot (this flow)                  |
| OTP_LC_BYP#           | J75                                        | 2-3                                             |

| strap2 (SW4.2) | strap1 (SW4.3) | Boot mode            |
|----------------|----------------|----------------------|
| 1              | 1              | FT                   |
| 1              | 0              | Minimal boot         |
| 0              | 1              | UART download mode   |
| 0              | 0              | Normal boot          |

Keep S12 position 2, J32 pin 5 and the J57 TRST# line unconnected at power-up; they share pins
with JEN3#, JEN1# and JEN4#.

USB OCP recovery boot is enabled only when all three hold:

1. The chip is bonded for Caliptra normal boot (bonding select, `STRPST2.BOOT_TYP_STRAP` = 0).
2. STMB# (SW2.1) = 1.
3. OTP `oUsbOcpRec` is enabled. The current MCU ROM reads it as OTP bytes 338..341 and treats an
   odd number of set bits as enabled.

## What you need

### 1. Firmware images on the TFTP server

The script downloads these four files by exact name. A missing or misnamed file stops it at the
TFTP step. A tested set of all four is in `bench/`; rebuild them only to test new
firmware.

| File (exact name)       | Used for                                    | How to rebuild                         |
|-------------------------|---------------------------------------------|----------------------------------------|
| `caliptra_fw.bin`       | Recovery image 0: Caliptra core FW bundle   | caliptra-mcu-sw build                  |
| `soc_manifest.bin`      | Recovery image 1: SoC manifest              | caliptra-mcu-sw build                  |
| `runtime-npcm500.bin`   | Recovery image 2: MCU runtime               | caliptra-mcu-sw `mcu-runtime-npcm500`  |
| `NPCM5_pldm.bin`        | PLDM package handed to `pldmd`              | PLDM package of the SoC FW image       |

The three recovery images must come from the same build, because the SoC manifest authorizes that
exact runtime.

The package name is hard-coded as `PLDM_PKG` in the script. If your package has another name,
rename the file or edit `PLDM_PKG`.

### 2. In the BMC image (nothing to copy)

| Item                                         | Installed by                                      |
|----------------------------------------------|---------------------------------------------------|
| `/usr/bin/caliptra-recovery-usb.sh`          | `usb-ocp-recovery` recipe                         |
| `/usr/bin/usb_ocp_recovery`                  | `usb-ocp-recovery` recipe                         |
| `/usr/share/openocd/scripts/caliptra_mcu.cfg`| `openocd` bbappend (meta-evb-npcm845)             |
| `openocd` with the `npcm_jtag` adapter       | `openocd` bbappend (meta-evb-npcm845)             |
| `tftp`, `gpioset`, `mctp`, `mctpd`, `pldmd`, `busctl` | standard image packages                  |

## Usage

1. Copy the four `.bin` files from `bench/` to the TFTP server root.
2. On the BMC console, from a writable directory:

   ```sh
   cd /tmp
   caliptra-recovery-usb.sh 192.168.1.100   # TFTP server, default 192.168.1.100
   ```

## What the script does

1. TFTP-fetches the four firmware files into the current directory.
2. `gpioset 2 6=0` enables the Arbel JTAG master; OpenOCD pulses `0x400C3069` and resumes the MCU.
3. Waits up to 30 s for a new `/dev/bus/usb/*/*` node (the recovery device has no fixed address).
4. `usb_ocp_recovery --fifo <dev> caliptra_fw.bin soc_manifest.bin runtime-npcm500.bin`.
5. Waits for `mctpusb0`, brings it up with local EID 8, and asks `mctpd` to set up the endpoint.
6. Restarts `pldmd` and calls `StartUpdate` with the PLDM package, apply time `Immediate`.

TFTP is unauthenticated, so use this only on an isolated bench network. The recovery images are
still verified by Caliptra before they run.
