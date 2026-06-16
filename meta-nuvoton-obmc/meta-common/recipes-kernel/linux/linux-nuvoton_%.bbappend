FILESEXTRAPATHS:prepend := "${THISDIR}/linux-upstream:"

# --- DTS: Device Tree (core DTSI, EVB enable, flash layout) ---
SRC_URI:append = " file://01_dts/0001-arm64-dts-adding-NPCM8xx-modules-node.patch"
SRC_URI:append = " file://01_dts/0002-arm64-dts-enable-new-NPCM8XX-modules-is-the-NPCM8XX-.patch"

# --- Watchdog: DT restart priority, reset status, NPCM8xx support ---
SRC_URI:append = " file://02_watchdog/0001-watchdog-npcm-Add-DT-restart-priority-and-reset-type.patch"
SRC_URI:append = " file://02_watchdog/0002-watchdog-npcm-save-reset-status.patch"
SRC_URI:append = " file://02_watchdog/0003-watchdog-npcm-Add-Nuvoton-NPCM8xx-support.patch"

# --- Pinctrl: pin mux, GPIO irq fixes, drive strength ---
SRC_URI:append = " file://03_pinctrl/0001-pinctrl-npcm8xx-remove-CTS-and-RTS-pins-from-bmcuart.patch"
SRC_URI:append = " file://03_pinctrl/0002-pinctrl-nuvoton-npcm8xx-add-rmii-enable-support.patch"
SRC_URI:append = " file://03_pinctrl/0003-pinctrl-nuvoton-npcm8xx-add-rgmii2-drive-strength-su.patch"
SRC_URI:append = " file://03_pinctrl/0004-pinctrl-nuvoton-clear-status-and-disable-GPIO.patch"
SRC_URI:append = " file://03_pinctrl/0005-pinctrl-nuvoton-npcm8xx-modify-GPIO7-pin-naming.patch"
SRC_URI:append = " file://03_pinctrl/0006-pinctrl-nuvoton-npcm8xx-Fix-lockdep-error-in-npcmgpi.patch"
SRC_URI:append = " file://03_pinctrl/0007-pinctrl-nuvoton-npcm8xx-add-irq_request_resources-su.patch"
SRC_URI:append = " file://03_pinctrl/0008-pinctrl-nuvoton-npcm8xx-modify-pin-configuration-fla.patch"
SRC_URI:append = " file://03_pinctrl/0009-pinctrl-npcm8xx-Fix-debounce-register-offset-calcula.patch"

# --- I2C: BER/SLVRSTR fixes ---
SRC_URI:append = " file://04_i2c/0003-i2c-npcm-clear-the-FIFO-in-master-ber-case.patch"
SRC_URI:append = " file://04_i2c/0004-i2c-npcm-unexpected-SLVRSTR-IRQ-in-master-mode.patch"

# --- USB: PHY reset delay, hub reset, ChipIdea SRAM ---
SRC_URI:append = " file://05_usb/0001-reset-npcm8xx-add-50-us-delay-for-usb-phy-clock-stab.patch"
SRC_URI:append = " file://05_usb/0002-reset-npcm-reset-USB-hub.patch"
SRC_URI:append = " file://05_usb/0003-usb-chipidea-add-SRAM-allocation-support.patch"
SRC_URI:append = " file://05_usb/0004-usb-chipidea-udc-enforce-write-to-the-memory.patch"

# --- FIU ---
SRC_URI:append = " file://06_fiu/0001-spi-npcm-fiu-add-dual-and-quad-write-support.patch"


# --- EVB845 DTS: Device Tree (EVB enable, flash layout) ---
SRC_URI:append = " file://01_dts/0005-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
SRC_URI:append = " file://01_dts/0006-dts-update-flash-layout-for-TIP-2M.patch"