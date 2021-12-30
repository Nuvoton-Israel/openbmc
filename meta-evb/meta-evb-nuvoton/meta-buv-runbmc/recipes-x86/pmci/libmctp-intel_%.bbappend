FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:buv-runbmc := "git://github.com/Nuvoton-Israel/libmctp.git"
SRCREV:buv-runbmc := "09a11109c694b3c690370f640e84983ae6e2db7e"

TARGET_CFLAGS:append:buv-runbmc = " -DMCTP_HAVE_FILEIO"

