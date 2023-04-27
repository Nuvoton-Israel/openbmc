inherit buv-entity-utils

OBMC_IMAGE_EXTRA_INSTALL += " \
    ${@entity_enabled(d, 'packagegroup-buv-runbmc-apps-entity')} \
    ${@distro_enabled(d, 'buv-dev', 'packagegroup-buv-runbmc-apps-devtools')} \
    "
