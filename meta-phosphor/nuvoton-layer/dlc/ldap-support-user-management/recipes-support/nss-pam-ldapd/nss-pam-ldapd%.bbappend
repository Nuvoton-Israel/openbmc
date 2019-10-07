
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LDAP_DN := "dc=ldap,dc=example,dc=com"

NUVO_ROOTPWMODDN ?= "uid=proxyuser,ou=people,dc=ldap,dc=example,dc=com"
NUVO_ROOTPWMODPW ?= "123"
NUVO_LDAP_SERVER ?= "10.103.152.11"

SRC_URI += "file://nslcd.conf \
            file://user-manage-ldap.patch \
            file://ipmi-login-via-ldap-support.patch \
			"

do_install_prepend() {

    sed -i -e 's/^rootpwmoddn uid=proxyuser,ou=people,dc=ldap,dc=example,dc=com/rootpwmoddn ${NUVO_ROOTPWMODDN}/;' ${WORKDIR}/nslcd.conf

    sed -i -e 's/^rootpwmodpw 123/rootpwmodpw ${NUVO_ROOTPWMODPW}/;' ${WORKDIR}/nslcd.conf

    sed -i -e 's/^uri ldap:\/\/192.168.0.101\//uri ldap:\/\/${NUVO_LDAP_SERVER}\//;' ${WORKDIR}/nslcd.conf

	install -m 0600 ${WORKDIR}/nslcd.conf ${WORKDIR}/${PN}-${PV}/nslcd.conf

}
