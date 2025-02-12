FILESEXTRAPATHS:prepend := "${THISDIR}/linux-obmc:"

# NPCM8XX common dts
SRC_URI:append = " file://1010-dt-bindings-clock-npcm845-Add-reference-25m-clock-pr.patch"
SRC_URI:append = " file://1011-arm64-dts-modify-clock-property-in-modules-node.patch"
SRC_URI:append = " file://1012-arm64-dts-npmc8xx-move-the-clk-handler-node-to-the-r.patch"
SRC_URI:append = " file://1013-arm64-dts-nuvoton-npcm8xx-add-pin-and-gpio-controller-nodes.patch"
SRC_URI:append = " file://1014-arm64-dts-nuvoton-npcm8xx-add-modules-node.patch"

# NPCM8XX NCSI driver
SRC_URI:append = " file://1200-net-stmmac-Add-NCSI-support-for-STMMAC.patch"

# NPCM8XX FIU driver
SRC_URI:append = " file://1210-spi-npcm-fiu-add-dual-and-quad-write-support.patch"

# NPCM8XX PSPI driver
SRC_URI:append = " file://1220-spi-npcm-pspi-Add-full-duplex-support.patch"
SRC_URI:append = " file://1221-spi-npcm-pspi-Fix-transfer-bits-per-word-issue-389.patch"

# NPCM8XX UDC driver
SRC_URI:append = " file://1230-usb-chipidea-udc-enforce-write-to-the-memory.patch"
SRC_URI:append = " file://1231-usb-chipidea-add-SRAM-allocation-support.patch"

# NPCM8XX i2c driver
SRC_URI:append = " file://1240-i2c-npcm-disable-interrupt-enable-bit-before-devm_re.patch"

# NPCM8XX PCEI driver
SRC_URI:append = " file://1260-pci-npcm-Add-NPCM-PCIe-RC-driver.patch"

# NPCM8XX PCEI mailbox
SRC_URI:append = " file://1270-misc-mbox-add-npcm7xx-pci-mailbox-driver.patch"

# NPCM8XX Jtag Master driver
SRC_URI:append = " file://1280-misc-npcm8xx-jtag-master-Add-NPCM845-JTAG-master-dri.patch"
SRC_URI:append = " file://1281-misc-npcm8xx-jtag-master-deassert-TRST-for-normal-op.patch"
SRC_URI:append = " file://1282-misc-npcm8xx-jtag-master-Meet-requirements-for-AMD-r.patch"
SRC_URI:append = " file://1283-misc-npcm8xx-jtag-master-fix-initial-tlr-state.patch"
SRC_URI:append = " file://1284-misc-npcm8xx-jtag-master-add-new-JTAG_SIOCSTATE-ioct.patch"

# NPCM8XX WDT driver
SRC_URI:append = " file://1291-watchdog-npcm-Add-Nuvoton-NPCM8xx-support.patch"
SRC_URI:append = " file://1292-watchdog-npcm-Add-DT-restart-priority-and-reset-type.patch"
SRC_URI:append = " file://1293-watchdog-npcm-save-reset-status.patch"

# NPCM8XX ADC driver
SRC_URI:append = " file://1300-iio-adc-npcm-fix-inappropriate-error-log.patch"
SRC_URI:append = " file://1301-iio-adc-fix-adc-driver-issue.patch"
SRC_URI:append = " file://1302-iio-adc-npcm-cover-more-module-reset-cases.patch"
SRC_URI:append = " file://1303-iio-adc-modify-wake-up-function.patch"
SRC_URI:append = " file://1304-iio-adc-npcm-clear-interrupt-status-at-probe.patch"
SRC_URI:append = " file://1305-iio-adc-npcm-add-reset-method-to-fix-get-value-faile.patch"
SRC_URI:append = " file://1306-iio-adc-npcm-remove-reset-method-flag.patch"

# NPCM8XX network driver
SRC_URI:append = " file://1310-stmmac-Add-eee-fixup-disable.patch"
SRC_URI:append = " file://1311-net-ethernet-stmmac-add-sgmii-support.patch"

# NPCM8XX media driver
SRC_URI:append = " file://1320-media-nuvoton-Add-head1-hsync-support.patch"

# NPCM8XX pinctrl driver
SRC_URI:append = " file://1330-pinctrl-npcm8xx-remove-CTS-and-RTS-pins-from-bmcuart.patch"
SRC_URI:append = " file://1331-driver-pinctrl-npcm8xx-Set-strict-as-true.patch"

# NPCM8XX BPC drivers
SRC_URI:append = " file://1340-soc-nuvoton-add-NPCM-BPC-driver.patch"
SRC_URI:append = " file://1341-soc-nuvoton-bpc-consider-2-bytes-in-DWCAPTURE.patch"

# NPCM8XX Serail port control driver
SRC_URI:append = " file://1350-soc-nuvoton-Add-serial-port-switch-control-driver.patch"

# NPCM8XX espi mmbi driver
SRC_URI:append = " file://1360-soc-nuvoton-Add-mmbi-driver.patch"
SRC_URI:append = " file://1361-soc-nuvoton-mmbi-modify-the-default-value-of-b2h_d-a.patch"
SRC_URI:append = " file://1362-soc-nuvoton-espi-mmbi-fix-multiple-definition-of-wak.patch"

# NPCM8XX fiu tip driver
SRC_URI:append = " file://1370-soc-nuvoton-Add-NPCM-FIU-TIP-support.patch"
SRC_URI:append = " file://1371-soc-nuvoton-tip-fiu-fix-mbox-channel-registration.patch"

# NPCM8XX cerberus mailbox driver
SRC_URI:append = " file://1380-soc-nuvoton-cerberus-add-nuvoton-cerberus-mailbox-cl.patch"

# NPCM8XX espi slave driver
SRC_URI:append = " file://1390-soc-nuvoton-add-support-for-eSPI-slave.patch"

# NPCM8XX espi flash driver
SRC_URI:append = " file://1400-spi-npcm-flash-add-support-for-eSPI-flash.patch"

# NPCM8XX espi vw gpio driver
SRC_URI:append = " file://1410-gpio-npcm-Add-eSPI-VW-GPIO-driver.patch"

# NPCM8XX i3c driver
SRC_URI:append = " file://0001-i3c-master-svc-fix-tx-issue-for-SVC-I3C-IP-1.0-versi.patch"
SRC_URI:append = " file://0002-i3c-master-svc-set-master-pid-info.patch"
SRC_URI:append = " file://0003-i3c-master-svc-set-I3C-SCL-rate-according-to-dts-con.patch"
SRC_URI:append = " file://0004-i3c-master-svc-fix-tCBP-timing-violation.patch"
SRC_URI:append = " file://0005-i3c-svc-Flush-fifo-before-DAA-process.patch"
SRC_URI:append = " file://0006-i3c-svc-Fix-wrong-bus-state-after-DAA-process.patch"
SRC_URI:append = " file://0007-i3c-svc-Fix-wrong-dynamic-address-assigned-during-DA.patch"
SRC_URI:append = " file://0008-i3c-master-svc-abort-the-transfer-if-NACKed.patch"
SRC_URI:append = " file://0009-i3c-master-svc-set-MCONFIG.HKEEP-to-3.patch"
SRC_URI:append = " file://0010-i3c-master-svc-initial-fifo-buffer-and-errwarn-statu.patch"
SRC_URI:append = " file://0011-i3c-master-svc-add-check-ibi-request-capable-bit-whe.patch"
SRC_URI:append = " file://0012-i3c-master-svc-remove-wait-i3c-bus-idle-after-emit-s.patch"
SRC_URI:append = " file://0013-npcm8xx-Reset-I3C-controller-on-probe.patch"
SRC_URI:append = " file://0014-i3c-master-svc-fix-timing-issue-during-DAA.patch"
SRC_URI:append = " file://0015-i3c-master-svc-fix-IBI-issue.patch"
SRC_URI:append = " file://0016-i3c-master-svc-fix-invalid-IBI-issue.patch"
SRC_URI:append = " file://0017-i3c-master-svc-skip-sclk.patch"
SRC_URI:append = " file://0018-i3c-master-svc-disable-set-speed-function.patch"

# npcm845 evb
SRC_URI:append = " file://2001-update-dts-for-evb.patch"
