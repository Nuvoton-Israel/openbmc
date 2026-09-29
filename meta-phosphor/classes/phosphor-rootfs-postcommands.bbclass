#
# This function is intended to add root to corresponding groups if 'allow-root-login' is in IMAGE_FEATURES.
#
update_root_user_groups () {
    if [ -e ${IMAGE_ROOTFS}/etc/group ]; then
        # Build the group pattern conditionally. ipmi is excluded when
        # phosphor-no-ipmi-rmcp is in DISTRO_FEATURES because that distro
        # feature intentionally removes the IPMI stack from the image.
        local groups="web\|redfish\|priv-admin"
        if ! echo "${DISTRO_FEATURES}" | grep -qw "phosphor-no-ipmi-rmcp"; then
            groups="ipmi\|${groups}"
        fi
        sed -i "/^\(${groups}\):/ { /:root\(,\|\$\)/! s/\$/,root/; s/:,/:/ }" \
            ${IMAGE_ROOTFS}/etc/group
    fi
}
# Add root user to the needed groups
ROOTFS_POSTPROCESS_COMMAND += '${@bb.utils.contains_any("IMAGE_FEATURES", [ 'allow-root-login' ], "update_root_user_groups", "", d)}'
