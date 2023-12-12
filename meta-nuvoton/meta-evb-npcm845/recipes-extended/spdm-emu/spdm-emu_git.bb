SUMMARY = "SPDM Emulator"
DESCRIPTION = "DMTF SPDM emulator"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=cd2c281a3048799e5ed6d1ad8be1ebe1"

inherit cmake

EXTRA_OECMAKE = "-DARCH=aarch64 -DTOOLCHAIN=YOCTO -DTARGET=Release -DCRYPTO=mbedtls"
#EXTRA_OECMAKE = "-DARCH=aarch64 -DTOOLCHAIN=YOCTO -DTARGET=Release -DCRYPTO=openssl"
SRCREV = "c8ac4ca68137127596ff59d065bfaa046718a56b"

PV = "1.0+git${SRCPV}"
PR = "r1"
S = "${WORKDIR}/git"
KEY_DIR = "${S}/libspdm/unit_test/sample_key"
FILES:${PN}:append = " ${datadir}/spdm-emu"

SRC_URI = "gitsm://github.com/DMTF/spdm-emu;protocol=https;branch=main \
           file://0001-support-yocto-build.patch \
           file://0002-use-spdm-over-mctp-kernel-socket.patch \
           file://0003-libspdm-openssl-support-hwaes.patch;patchdir=libspdm \
           "

do_install:append () {
	install -d ${D}${datadir}/spdm-emu
	cp -r ${KEY_DIR}/ecp384 ${D}${datadir}/spdm-emu/
	cp -r ${KEY_DIR}/rsa3072 ${D}${datadir}/spdm-emu/
}

