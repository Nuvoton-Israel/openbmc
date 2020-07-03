inherit buv-entity-utils

OBMC_IMAGE_EXTRA_INSTALL += " \
    ${@entity_enabled(d, 'packagegroup-buv-runbmc-apps-buv-system')} \
    packagegroup-buv-runbmc-apps-buv-common-utils \
    "
