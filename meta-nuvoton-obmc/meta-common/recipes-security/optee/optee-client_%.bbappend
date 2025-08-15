FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

EXTRA_OECMAKE = " \
    -DBUILD_SHARED_LIBS=ON \
    -DCFG_TEE_FS_PARENT_PATH='/var/tee' \
"

EXTRA_OECMAKE:append:toolchain-clang = " -DCFG_WERROR=0"

SRC_URI:remove = " file://0001-tee-supplicant-add-udev-rule-and-systemd-service-fil.patch"
SRC_URI:remove = " file://0001-tee-supplicant-update-udev-systemd-install-code.patch"

SRC_URI:append = " file://tee-supplicant@.service"
SRC_URI:append = " file://optee-udev.rules"
SRC_URI:append = " file://tee-supplicant.sh"

do_install:append() {
    install -D -p -m0644 ${UNPACKDIR}/tee-supplicant@.service ${D}${systemd_system_unitdir}/tee-supplicant@.service
    install -D -p -m0755 ${UNPACKDIR}/tee-supplicant.sh ${D}${sysconfdir}/init.d/tee-supplicant
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${UNPACKDIR}/optee-udev.rules ${D}${sysconfdir}/udev/rules.d/optee.rules

    sed -i -e s:@sysconfdir@:${sysconfdir}:g \
           -e s:@sbindir@:${sbindir}:g \
              ${D}${systemd_system_unitdir}/tee-supplicant@.service \
              ${D}${sysconfdir}/init.d/tee-supplicant
}

#FILES:${PN}:remove = " ${nonarch_base_libdir}/udev/rules.d/"

#USERADD_PACKAGES = "${PN}"

#GROUPADD_PARAM:${PN}:remove = "--system ${TEE_GROUP_NAME}; --system teepriv; --system teesuppl"
#USERADD_PARAM:${PN}:remove = "--system -g teesuppl --groups teepriv --home-dir ${localstatedir}/lib/tee -M --shell /sbin/nologin teesuppl;"


#GROUPADD_PARAM:${PN}:append = "--system teeclnt;"