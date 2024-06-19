inherit buv-entity-utils

DEPENDS:append:buv-runbmc= " \
    ${@entity_enabled(d, '', ' buv-runbmc-yaml-config')}"

EXTRA_OEMESON:append:buv-runbmc = " \
    ${@entity_enabled(d, '', '-Dsensor-yaml-gen=${STAGING_DIR_HOST}${datadir}/buv-runbmc-yaml-config/ipmi-sensors.yaml')} \
    ${@entity_enabled(d, '', '-Dfru-yaml-gen=${STAGING_DIR_HOST}${datadir}/buv-runbmc-yaml-config/ipmi-fru-read.yaml')} \
    ${@entity_enabled(d, '', '-Dinvsensor-yaml-gen=${STAGING_DIR_HOST}${datadir}/buv-runbmc-yaml-config/ipmi-inventory-sensors.yaml')} \
    "
PACKAGECONFIG:append:buv-entity = " dynamic-sensors"

EXTRA_OEMESON:append:buv-runbmc = " -Di2c-whitelist-check=disabled"
EXTRA_OEMESON:append:buv-runbmc = " -Dshortname-remove-suffix=disabled -Dshortname-replace-words=enabled"
