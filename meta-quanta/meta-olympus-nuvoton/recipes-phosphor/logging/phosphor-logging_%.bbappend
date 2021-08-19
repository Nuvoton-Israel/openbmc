FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/files:"

SRC_URI_append_olympus-nuvoton = " file://0001-build-meson-fix-python-command-parameter.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-logging-test-report-a-redfish-event-success-when-add.patch"

