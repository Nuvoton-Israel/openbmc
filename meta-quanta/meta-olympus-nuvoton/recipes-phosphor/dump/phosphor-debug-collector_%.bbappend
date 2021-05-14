FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

EXTRA_OECONF += "BMC_DUMP_TOTAL_SIZE=500 "
SRC_URI += "file://0001-fix-bmc-dump-cannot-accept-no-additional-parameters.patch"
SRC_URI += "file://0002-return-dump-entry-id-number-instead-of-object-path.patch"
