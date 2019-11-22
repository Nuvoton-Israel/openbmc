FILESEXTRAPATHS_append_olympus-nuvoton := ":${THISDIR}/${PN}"

SRC_URI_append_olympus-nuvoton = " \
    file://0001-Fixed-cannot-show-warning-high-and-critical-high.patch \
    file://0001-Modify-bios-update-confirm-dialogue.patch \
    file://disable_show_delete_while_activating.patch \
"
