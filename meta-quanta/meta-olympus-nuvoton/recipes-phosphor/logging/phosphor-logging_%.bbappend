FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/files:"

SRC_URI_append_olympus-nuvoton = " file://0001-build-meson-fix-python-command-parameter.patch"

OBMC_YAML_PROVIDER_RECIPES_append_olympus-nuvoton = " \
    olympus-nuvoton-debug-collector-yaml-provider.bb \
    "
