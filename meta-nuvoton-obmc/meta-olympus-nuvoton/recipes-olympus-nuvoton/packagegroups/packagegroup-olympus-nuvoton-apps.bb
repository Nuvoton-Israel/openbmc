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

RPROVIDES:${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES:${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system += "virtual-obmc-system-mgmt"

SUMMARY:${PN}-chassis = "OLYMPUS NUVOTON Chassis"
RDEPENDS:${PN}-chassis = " \
        x86-power-control \
        "

SUMMARY:${PN}-fans = "OLYMPUS NUVOTON Fans"
RDEPENDS:${PN}-fans = " \
        phosphor-pid-control \
        "

SUMMARY:${PN}-flash = "OLYMPUS NUVOTON Flash"
RDEPENDS:${PN}-flash = " \
        ipmi-bios-update \
        ipmi-bmc-update \
        "

SUMMARY:${PN}-system = "OLYMPUS NUVOTON System"
RDEPENDS:${PN}-system = " \
        obmc-ikvm \
        obmc-console \
        "