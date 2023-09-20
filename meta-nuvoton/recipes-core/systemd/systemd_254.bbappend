FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append:nuvoton = " \
    file://0001-shutdown-disable-recursive-mount-of-run-on-switching.patch \
    file://0002-shutdown-do-not-umount-recursively-before-MS_MOVE.patch \
    file://0003-switch-root-reopen-target-directory-after-it-is-moun.patch \
"
