FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI:append = " file://0002-pldm-fix-pldmtool-cmd-fail-issue.patch"

SRCREV = "b3b84b497a20c33f5c49e67e89c20638929166a3"

SRC_URI:append = " file://host_eid"
SRC_URI:append = " file://0001-platform-mc-Added-EventManager.patch"
SRC_URI:append = " file://0002-platform-mc-Support-pollForPlatFormEventMessage.patch"
SRC_URI:append = " file://0003-requester-support-multi-host-MCTP-devices-hot-plug.patch"
SRC_URI:append = " file://0004-pldm-Revise-image-path-for-update.patch"
SRC_URI:append = " file://0005-Support-OEM-META-write-file-request-for-post-code-hi.patch"
SRC_URI:append = " file://0008-oem-meta-support-ipmi-bridge-oem-command.patch"
SRC_URI:append = " file://0009-do-not-set-address-is-class-is-USB.patch"
SRC_URI:append = " file://0010-oem-meta-support-vwgpio-post-completed-event-bridge.patch"
SRC_URI:append = " file://0011-oem-meta-support-flash-access-oem-command.patch"
SRC_URI:append = " file://0012-remove-updater-debug-log.patch"
