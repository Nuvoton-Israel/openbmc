S = "${WORKDIR}/git"

FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/openbmc/ipmbbridge.git"
SRCREV = "a642a9480d348bb6677f4badb635ebf881f3bcd0"
SRC_URI += "file://i2c-dev.h"

do_configure_prepend() {
	install -m 0644 ${WORKDIR}/i2c-dev.h ${STAGING_INCDIR}/linux/i2c-dev-user.h
}


