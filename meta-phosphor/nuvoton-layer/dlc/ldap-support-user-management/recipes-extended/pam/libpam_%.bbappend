
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}/files:"

SRC_URI += "file://common-password \
            file://common-session \
           "
RDEPENDS_${PN}-runtime += "${MLPREFIX}pam-plugin-mkhomedir-${libpam_suffix} \
                          "

do_install_prepend() {

  install -m 0644 ${WORKDIR}/common-password ${WORKDIR}/pam.d/common-password
  install -m 0644 ${WORKDIR}/common-session  ${WORKDIR}/pam.d/common-session
}
