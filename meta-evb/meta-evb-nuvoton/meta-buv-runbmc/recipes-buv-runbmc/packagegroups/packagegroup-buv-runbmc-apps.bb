SUMMARY = "OpenBMC for BUV Nuvoton system - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-buv-system \
        ${PN}-buv-common-utils \
        "

SUMMARY_${PN}-buv-common-utils = "BUV NUVOTON common utils"
RDEPENDS_${PN}-buv-common-utils = " \
    ipmitool \
    phosphor-webui \
    phosphor-host-postd \
    "

SUMMARY_${PN}-buv-system = "BUV NUVOTON System"
RDEPENDS_${PN}-buv-system = " \
        dhcpcd \
        phosphor-sel-logger \
        intel-ipmi-oem \
        "
