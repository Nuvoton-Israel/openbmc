
FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " \
           file://pam_succeed_if_support_ldap_user_login.patch \
           "
