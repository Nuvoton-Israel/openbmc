FILESEXTRAPATHS:prepend:olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI:olympus-nuvoton := "git://github.com/Nuvoton-Israel/libmctp.git;protocol=https"
SRCREV:olympus-nuvoton := "09a11109c694b3c690370f640e84983ae6e2db7e"

TARGET_CFLAGS:append:olympus-nuvoton = " -DMCTP_HAVE_FILEIO"


