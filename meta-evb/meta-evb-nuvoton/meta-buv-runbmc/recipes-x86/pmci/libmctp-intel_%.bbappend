FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI_buv-runbmc := "git://github.com/Nuvoton-Israel/libmctp.git"
SRCREV_buv-runbmc := "09a11109c694b3c690370f640e84983ae6e2db7e"

TARGET_CFLAGS += "-DMCTP_HAVE_FILEIO"


