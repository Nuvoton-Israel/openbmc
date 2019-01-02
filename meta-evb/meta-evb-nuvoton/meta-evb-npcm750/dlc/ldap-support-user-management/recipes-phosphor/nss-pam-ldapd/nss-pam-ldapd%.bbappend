
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LDAP_DN := "dc=ldap,dc=example,dc=com"

NUVO_ROOTPWMODDN ?= "uid=proxyuser,ou=people,dc=ldap,dc=example,dc=com"
NUVO_ROOTPWMODPW ?= "123"

SRC_URI += "file://nslcd.conf \
            file://user-manage-ldap.patch \
			"

do_install_prepend() {

    sed -i -e 's/^rootpwmoddn uid=proxyuser,ou=people,dc=ldap,dc=example,dc=com/rootpwmoddn ${NUVO_ROOTPWMODDN}/;' ${WORKDIR}/nslcd.conf

    sed -i -e 's/^rootpwmodpw 123/rootpwmodpw ${NUVO_ROOTPWMODPW}/;' ${WORKDIR}/nslcd.conf

	install -m 0600 ${WORKDIR}/nslcd.conf ${WORKDIR}/${PN}-${PV}/nslcd.conf

}
