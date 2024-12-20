SUMMARY = "OpenBMC for BUV RunBMC system - Applications"
PR = "r1"

inherit packagegroup
inherit entity-utils

PROVIDES = "${PACKAGES}"
PACKAGES = " \
    ${PN}-chassis \
    ${PN}-fans \
    ${PN}-system \
    ${PN}-entity \
    ${PN}-devtools \
    "

RPROVIDES:${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES:${PN}-system = "virtual-obmc-system-mgmt"

SUMMARY:${PN}-chassis = "BUV RunBMC Chassis"
RDEPENDS:${PN}-chassis = " \
    x86-power-control \
    "

SUMMARY:${PN}-fans = "BUV RunBMC Fans"
RDEPENDS:${PN}-fans = " \
    phosphor-pid-control \
    "

SUMMARY:${PN}-system = "BUV RunBMC System"
RDEPENDS:${PN}-system = " \
    ipmitool \
    webui-vue \
    phosphor-host-postd \
    loadsvf \
    obmc-console \
    phosphor-sel-logger \
    rsyslog \
    obmc-ikvm \
    iperf3 \
    iperf2 \
    usb-network \
    nmon \
    memtester \
    usb-emmc-storage \
    loadmcu \
    openssl-bin \
    openssl-engines \
    nuvoton-ipmi-oem \
    phosphor-power-systemd-links-monitor \
    phosphor-power-utils \
    phosphor-power \
    phosphor-gpio-monitor \
    phosphor-gpio-monitor-monitor \
    nist-linux-selftest \
    "

RDEPENDS:${PN}-system:append = " \
        ${@entity_enabled(d, '', 'first-boot-set-psu')} \
        "
RDEPENDS:${PN}-system:append = " \
        ${@entity_enabled(d, 'phosphor-power-monitor-em', 'phosphor-power-monitor')} \
        "

KDUMP_PACKAGES = " \
  kexec-tools \
  vmcore-dmesg \
  kdump \
  makedumpfile \
  "

RDEPENDS:${PN}-system:append = " \
  ${@bb.utils.contains('DISTRO_FEATURES', 'kdump', '${KDUMP_PACKAGES}', '', d)}"


SUMMARY:${PN}-entity = "BUV RunBMC entity"
RDEPENDS:${PN}-entity = " \
    entity-manager \
    fru-device \
    dbus-sensors \
    "

SUMMARY:${PN}-devtools = "BUV RunBMC development tools"
RDEPENDS:${PN}-devtools = " \
    ent \
    dhrystone \
    rw-perf \
    htop \
    gptfdisk \
    parted \
    "

