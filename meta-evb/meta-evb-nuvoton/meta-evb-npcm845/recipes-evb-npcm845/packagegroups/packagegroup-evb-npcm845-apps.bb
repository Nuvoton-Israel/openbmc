SUMMARY = "OpenBMC for EVB NPCM845 system - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-chassis \
        ${PN}-fans \
        ${PN}-flash \
        ${PN}-system \
        "

RPROVIDES_${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES_${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES_${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES_${PN}-system += "virtual-obmc-system-mgmt"

SUMMARY_${PN}-chassis = "EVB NPCM845 Chassis"
RDEPENDS_${PN}-chassis = " \
        x86-power-control \
        "

SUMMARY_${PN}-fans = "EVB NPCM845 Fans"
RDEPENDS_${PN}-fans = " \
        phosphor-pid-control \
        "

SUMMARY_${PN}-flash = "EVB NPCM845 Flash"
RDEPENDS_${PN}-flash = " \
        phosphor-ipmi-flash \
        "

SUMMARY_${PN}-system = "EVB NPCM845 System"
RDEPENDS_${PN}-system = " \
        phosphor-webui \
        obmc-ikvm \
        iperf3 \
        usb-emmc-storage \
        usb-network \
        nmon \
        memtester \
        htop \
        ipmitool \
        phosphor-ipmi-ipmb \
        openssl-bin \
        openssl-engines \
        phosphor-host-postd \
        phosphor-sel-logger \
        rsyslog \
        loadsvf \
        pciutils \
        cpfw \
        dhrystone \
        ent \
        rw-perf \
        loadmcu \
        phosphor-ecc \
        i3c-tools \
        phosphor-ipmi-blobs \
        phosphor-image-signing \
        "
