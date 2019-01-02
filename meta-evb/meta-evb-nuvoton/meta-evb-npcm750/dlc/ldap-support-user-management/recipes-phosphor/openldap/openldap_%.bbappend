FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://ldap.conf"

do_install_prepend() {

	install -m 0600 ${WORKDIR}/ldap.conf ${WORKDIR}/${PN}-${PV}/libraries/libldap/ldap.conf

}
