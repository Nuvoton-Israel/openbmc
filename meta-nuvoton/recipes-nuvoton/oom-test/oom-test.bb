SUMMARY = "oom test"
DESCRIPTION = "oom test tool"
PR = "r1"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

TARGET_CC_ARCH += "${LDFLAGS}"

S = "${WORKDIR}"

SRC_URI = "file://Makefile \
           file://oom_test.c \
           file://COPYING.MIT \
          "

do_install() {
        install -Dm755 ${S}/oom-test ${D}/${sbindir}/oom-test
}
