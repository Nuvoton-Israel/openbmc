
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nsswitch.conf \
			"

do_install_append() {

    if [ "${@bb.utils.filter('DISTRO_FEATURES', 'ldap', d)}" ]; then
        install -D -m 600 ${WORKDIR}/nsswitch.conf ${D}/${sysconfdir}/nsswitch.conf
    fi

}
