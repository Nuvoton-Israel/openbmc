SUMMARY = "OpenBMC for BUV Nuvoton system - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
    ${PN}-buv-system \
    ${PN}-buv-common-utils \
    ${PN}-buv-dev \
    "

SUMMARY_${PN}-buv-common-utils = "BUV NUVOTON common utils"
RDEPENDS_${PN}-buv-common-utils = " \
    ipmitool \
    phosphor-webui \
    phosphor-host-postd \
    loadsvf \
    obmc-console \
    phosphor-sel-logger \
    rsyslog \
    phosphor-host-postd \
    obmc-ikvm \
    iperf3 \
    iperf2 \
    dhcpcd \
    phosphor-ipmi-fru \
    usb-network \
    nmon \
    memtester \
    usb-emmc-storage \
    mctpd \
    pldmsensors \
    "

SUMMARY_${PN}-buv-system = "BUV NUVOTON System"
RDEPENDS_${PN}-buv-system = " \
    intel-ipmi-oem \
    "

SUMMARY_${PN}-buv-dev = "BUV NUVOTON development tools"
RDEPENDS_${PN}-buv-dev = " \
    ent \
    dhrystone \
    rw-perf \
    "

