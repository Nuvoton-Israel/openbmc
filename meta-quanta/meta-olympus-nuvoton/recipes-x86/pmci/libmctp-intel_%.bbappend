FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_olympus-nuvoton := "git://github.com/Nuvoton-Israel/libmctp.git"
SRCREV_olympus-nuvoton := "5271b25962bb8df0d8c89c0295ac26c30e0f1ef5"

TARGET_CFLAGS += "-DMCTP_HAVE_FILEIO"


