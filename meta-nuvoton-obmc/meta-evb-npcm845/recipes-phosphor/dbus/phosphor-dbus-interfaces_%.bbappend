# NVIDIA's SPDM stack (meta-evb-npcm845/recipes-phosphor/spdm) requires the
# xyz.openbmc_project.SPDM.Responder and
# xyz.openbmc_project.Inventory.Item.SPDMResponder interfaces, which are not
# part of upstream openbmc/phosphor-dbus-interfaces.
#
# NVIDIA's own fork (github.com/NVIDIA/phosphor-dbus-interfaces,
# Core-26.05-1_br) carries these plus ~1100 unrelated changed/removed files
# relative to the version pinned by meta-phosphor -- swapping SRC_URI to it
# wholesale broke unrelated consumers elsewhere in this image (e.g.
# phosphor-network's EthernetInterface.fullDuplex, which that fork drops).
# Instead, cherry-pick just the two new interface YAML files (and their
# meson registration) as a patch on top of the pinned upstream version, so
# every other phosphor-dbus-interfaces consumer is unaffected.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:df-composite-eat = " file://0001-add-spdm-responder-interfaces.patch"
