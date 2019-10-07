FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://dropbear-pam-sesssion-support.patch \
           "

do_install_append() {
    echo "session  include  common-session" >> ${D}${sysconfdir}/pam.d/dropbear
}
