FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://chassis-cap.override.yml"
SRC_URI_append_olympus-nuvoton = " file://sol-default.override.yml"
SRC_URI_append_olympus-nuvoton = " file://chassis-poh.override.yml"
SRC_URI_append_olympus-nuvoton = " file://0001-create-thread-to-report-InvalidArgument-error.patch"
