SUMMARY = "vdm test"
DESCRIPTION = "vmd test tool"
PR = "r1"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

TARGET_CC_ARCH += "${LDFLAGS}"

S = "${UNPACKDIR}/sources"



SRC_URI = "file://Makefile \
           file://vdm_test.cpp \
           file://vdm_module.h \
           file://COPYING.MIT \
          "

do_install() {
        install -Dm755 ${S}/vdm-test ${D}/${sbindir}/vdm-test
}
