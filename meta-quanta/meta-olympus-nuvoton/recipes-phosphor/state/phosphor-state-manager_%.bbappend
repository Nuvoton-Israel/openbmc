FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://0001-fix-host-power-state-inconsisent-issue.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-add-default-state-for-ProgressStages-and-OSStatus.patch"
