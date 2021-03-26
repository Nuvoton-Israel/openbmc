inherit buv-entity-utils

OBMC_IMAGE_EXTRA_INSTALL += " \
    ${@entity_enabled(d, 'packagegroup-buv-runbmc-apps-buv-system')} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'buv-dev', 'packagegroup-buv-runbmc-apps-buv-dev', '', d)} \
    packagegroup-buv-runbmc-apps-buv-common-utils \
    "
