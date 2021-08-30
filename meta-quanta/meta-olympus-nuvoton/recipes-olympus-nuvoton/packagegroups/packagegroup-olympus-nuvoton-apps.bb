inherit entity-utils
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
        x86-power-control \
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
        webui-vue \
        obmc-ikvm \
        obmc-console \
        phosphor-host-postd \
        phosphor-ipmi-ipmb \
        phosphor-ipmi-blobs \
        ipmitool \
        phosphor-sel-logger \
        phosphor-node-manager-proxy \
        phosphor-image-signing \
        openssl-bin \
        loadsvf \
        asd \
        iptables \
        bmc-time-sync \
        phosphor-post-code-manager \
        intel-dbus-interfaces \
        adm1278-hotswap-power-cycle \
        google-ipmi-sys \
        mac-address \
        smbios-mdrv2 \
        loadmcu \
        usb-network \
        nuvoton-ipmi-oem \
        olympus-nuvoton-iptable-restore \
        srvcfg-manager \
        crashdump \
        "
RDEPENDS_${PN}-system_append = " \
        ${@entity_enabled(d, '', 'first-boot-set-psu')} \
        "

#RDEPENDS_${PN}-system_append_olympus-entity = " \
#        intel-ipmi-oem \
#        "
