FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " file://0001-Correctly-detect-failure-to-initialize-boottime.patch"
