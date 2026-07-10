SUMMARY = "Software L2 switch (Linux bridge) for the NPCM845 EVB"
DESCRIPTION = "Creates a Linux bridge (br0) acting as a pure L2 switch. The \
RGMII/SGMII port (eth0) is the physical upstream; vport0 (veth) is the BMC OOB \
NIC (V-Port 0) and vport1 (USB CDC-ECM) is the Host Ethernet NIC (V-Port 1). \
Configured via systemd-networkd."

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

RDEPENDS:${PN} += "bash iproute2 iproute2-bridge"

SRC_URI += "file://05-br0.netdev \
            file://06-vport0.netdev \
            file://10-eth0-bridge.network \
            file://10-vport0br-bridge.network \
            file://10-vport1-bridge.network \
            file://20-br0.network \
            file://20-vport0.network \
            file://l2-bridge-ignore-phosphor.conf \
            file://l2_bridge_check.sh"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/05-br0.netdev             ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/06-vport0.netdev          ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/10-eth0-bridge.network    ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/10-vport0br-bridge.network ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/10-vport1-bridge.network  ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/20-br0.network            ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/20-vport0.network         ${D}${sysconfdir}/systemd/network/

    # Tell phosphor-networkd to leave the whole L2 switch fabric alone so those
    # interfaces are owned solely by our systemd-networkd static config.
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.Network.service.d
    install -m 0644 ${UNPACKDIR}/l2-bridge-ignore-phosphor.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.Network.service.d/ignore-phosphor.conf

    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/l2_bridge_check.sh        ${D}${sbindir}/l2_bridge_check.sh
}

FILES:${PN} += "${sysconfdir}/systemd/network/05-br0.netdev"
FILES:${PN} += "${sysconfdir}/systemd/network/06-vport0.netdev"
FILES:${PN} += "${sysconfdir}/systemd/network/10-eth0-bridge.network"
FILES:${PN} += "${sysconfdir}/systemd/network/10-vport0br-bridge.network"
FILES:${PN} += "${sysconfdir}/systemd/network/10-vport1-bridge.network"
FILES:${PN} += "${sysconfdir}/systemd/network/20-br0.network"
FILES:${PN} += "${sysconfdir}/systemd/network/20-vport0.network"
FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.Network.service.d/ignore-phosphor.conf"
FILES:${PN} += "${sbindir}/l2_bridge_check.sh"

inherit allarch
