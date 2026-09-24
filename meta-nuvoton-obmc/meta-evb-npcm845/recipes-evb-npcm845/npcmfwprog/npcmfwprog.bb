SUMMARY = "NpcmFwProg tool for linux"
DESCRIPTION = "NpcmFwProg tool for linux"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

TARGET_CC_ARCH += "${LDFLAGS}"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

SRC_URI = "file://NpcmFwProg500.linux \
          "

# This is a prebuilt binary, so it is already stripped and cannot be
# rebuilt with debug symbols.
INSANE_SKIP:${PN} += "already-stripped"

do_install() {
        install -d ${D}/${sbindir}
        install -m 0755 ${UNPACKDIR}/NpcmFwProg500.linux ${D}/${sbindir}/NpcmFwProg500.linux
}
