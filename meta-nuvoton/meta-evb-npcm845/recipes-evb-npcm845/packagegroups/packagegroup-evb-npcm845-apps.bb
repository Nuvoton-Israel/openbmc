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
PROVIDES += "virtual/obmc-chassis-mgmt"
PROVIDES += "virtual/obmc-fan-mgmt"
PROVIDES += "virtual/obmc-flash-mgmt"
PROVIDES += "virtual/obmc-system-mgmt"

RPROVIDES:${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES:${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system += "virtual-obmc-system-mgmt"

SUMMARY:${PN}-chassis = "EVB NPCM845 Chassis"
RDEPENDS:${PN}-chassis = " \
        x86-power-control \
        "

SUMMARY:${PN}-fans = "EVB NPCM845 Fans"
RDEPENDS:${PN}-fans = " \
        "

SUMMARY:${PN}-flash = "EVB NPCM845 Flash"
RDEPENDS:${PN}-flash = " \
        phosphor-ipmi-flash \
        "

SUMMARY:${PN}-system = "EVB NPCM845 System"
RDEPENDS:${PN}-system = " \
        iperf3 \
        nmon \
        htop \
        ipmitool \
        openssl-bin \
        openssl-engines \
        phosphor-host-postd \
        phosphor-sel-logger \
        rsyslog \
        loadsvf \
        i3c-tools \
        optee-client \
        systemd-analyze \
        pldm \
        mctp \
        persistent-net-name \
        phosphor-hostlogger \
        phosphor-post-code-manager \    
        phosphor-ipmi-host \
        host-misc-comm-manager \
        bmc-boot-done \
        "
