FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI_append = "file://0001-Correctly-detect-failure-to-initialize-boottime.patch"
