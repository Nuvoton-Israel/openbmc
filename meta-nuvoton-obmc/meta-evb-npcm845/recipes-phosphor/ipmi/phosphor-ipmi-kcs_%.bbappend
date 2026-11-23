KCS_DEVICE = "ipmi-kcs1"

# OBMF IPMI channel (/dev/ipmi-obmfN-C) exists only while SMC1 is
# enumerated: start kcsbridged from udev and stop it with the device.
OBMF_KCS_DEVICES = "ipmi-obmf0-3"
FILESEXTRAPATHS:prepend:df-obmf := "${THISDIR}/${PN}:"
SRC_URI:append:df-obmf = " file://81-obmf-ipmi.rules"
FILES:${PN}:append:df-obmf = " ${systemd_unitdir}/system/${BPN}@*.service.d"
do_install:append:df-obmf() {
    install -D -m 0644 ${UNPACKDIR}/81-obmf-ipmi.rules \
        ${D}${nonarch_base_libdir}/udev/rules.d/81-obmf-ipmi.rules
    for i in ${OBMF_KCS_DEVICES}
    do
        u=dev-$(echo $i | sed "s/-/\\\\x2d/g").device
        d=${D}${systemd_unitdir}/system/${BPN}@${i}.service.d
        install -d $d
        printf "[Unit]\nBindsTo=%s\nAfter=%s\n" "$u" "$u" > $d/obmf-dev.conf
    done
}
