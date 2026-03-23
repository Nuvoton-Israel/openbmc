DESCRIPTION = "NPCM400 SMC firmware programmer"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

# use proper git URL:
#inherit meson
#SRC_URI = "git://${HOME}/NpcmFwProg;protocol=file;branch=main"
#SRCREV = "efe2304881e36a1bcaa5eccf668b6358b19c75d3"
#PV = "1.0+git${SRCPV}"
S = "${UNPACKDIR}"


# Or use direct download approach:
FILENAME = "NpcmFwProg_${PV}.bmc"
SRC_URI = "https://github.com/Nuvoton-Israel/npcmFwProg/releases/download/v${PV}/${FILENAME};name=bin"
SRC_URI[bin.sha256sum] = "73a0100ec906dcea6871700dd5c8ee0199a05a9a6a1aed1a118e2d37f7db0b25"

SRC_URI += "file://smc-fw-update.sh"
RDEPENDS:${PN} += "bash"

do_install() {
    install -d ${D}${bindir}

    # For direct download approach:
    install -m 755 ${UNPACKDIR}/${FILENAME} ${D}${bindir}/NpcmFwProg

    # Install helper script (correct path)
    install -m 755 ${UNPACKDIR}/smc-fw-update.sh ${D}${bindir}/smc-fw-update.sh
}

INSANE_SKIP:${PN} = "already-stripped"
