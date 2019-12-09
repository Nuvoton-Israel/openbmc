SUMMARY = "Copy error yaml files to known path for elog parsing"
PR = "r1"
PV = "1.0"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit native
inherit phosphor-dbus-yaml

S = "${WORKDIR}"
CONFIG_YAML_PATH="xyz/openbmc_project/Control"
SRC_URI = "file://Boot.errors.yaml"

do_install_append() {
    DEST=${D}${yaml_dir}/${CONFIG_YAML_PATH}
    install -d ${DEST}
    install Boot.errors.yaml ${DEST}
}
