SUMMARY = "OpenBMC for OLYMPUS NUVOTON system - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-chassis \
        ${PN}-fans \
        ${PN}-flash \
        ${PN}-system \
        "

PROVIDES += "virtual/obmc-chassis-mgmt"
PROVIDES += "virtual/obmc-fan-mgmt"
PROVIDES += "virtual/obmc-flash-mgmt"
PROVIDES += "virtual/obmc-system-mgmt"

RPROVIDES_${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES_${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES_${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES_${PN}-system += "virtual-obmc-system-mgmt"

SUMMARY_${PN}-chassis = "OLYMPUS NUVOTON Chassis"
RDEPENDS_${PN}-chassis = " \
        obmc-op-control-power \
        "

SUMMARY_${PN}-fans = "OLYMPUS NUVOTON Fans"
RDEPENDS_${PN}-fans = " \
        phosphor-pid-control \
        "

SUMMARY_${PN}-flash = "OLYMPUS NUVOTON Flash"
RDEPENDS_${PN}-flash = " \
        phosphor-ipmi-flash \
        ipmi-bios-update \
        ipmi-bmc-update \
        "

SUMMARY_${PN}-system = "OLYMPUS NUVOTON System"
RDEPENDS_${PN}-system = " \
        phosphor-webui \
        obmc-ikvm \
        obmc-console \
        dhcpcd \
        phosphor-ipmi-fru \
        phosphor-host-postd \
        phosphor-ipmi-ipmb \
        phosphor-ipmi-blobs \
        olympus-nuvoton-powerctrl \
        ipmitool \
        phosphor-sel-logger \
        first-boot-set-psu \
        phosphor-node-manager-proxy \
        phosphor-image-signing \
        openssl-bin \
        loadsvf \
        asd \
        iptables \
        iptable-save \
        pch-time-sync \
        phosphor-post-code-manager \
        smbios-mdrv2 \
        intel-dbus-interfaces \
        adm1278-hotswap-power-cycle \
        google-ipmi-sys \
        mac-address \
        "
