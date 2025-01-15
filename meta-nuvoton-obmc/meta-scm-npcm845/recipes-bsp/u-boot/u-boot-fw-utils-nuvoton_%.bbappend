FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-nuvoton:"

SRC_URI:append = " file://scm.cfg"
SRC_URI:append:m1120-c2195 = " file://c219b.cfg"
