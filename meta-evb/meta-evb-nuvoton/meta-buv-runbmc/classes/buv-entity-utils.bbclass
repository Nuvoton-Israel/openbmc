# Helper function for check buv-entity distro

# Usage example:
# EXTRA_OECONF_append = " \
#    ${@entity_enabled(d, '--enable-configure-dbus=yes')}"

def distro_enabled(d, distro, truevalue, falsevalue=""):
    return bb.utils.contains('DISTRO_FEATURES', distro, truevalue,
        falsevalue, d)

def entity_enabled(d, val, fval=""):
    return bb.utils.contains('DISTRO_FEATURES',
        'entity-manager', val, fval, d)
