FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

EXTRA_OECONF += "BMC_DUMP_TOTAL_SIZE=500 "
SRC_URI += "file://0001-fix-bmc-dump-cannot-accept-no-additional-parameters.patch"
