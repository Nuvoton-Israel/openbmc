KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-6.1-OpenBMC"
LINUX_VERSION = "6.1.51"
SRCREV = "f22a260fff1e2f959fd1bbc50fd0abfecb996676"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://0017-drivers-i2c-workaround-for-i2c-slave-behavior.patch"
SRC_URI:append:nuvoton = " file://enable-emc.cfg"
SRC_URI:append:nuvoton:df-obmc-static-norootfs = " file://enable-spinor-ubifs.cfg"

# New Arch VDMX/VDMA driver
# SRC_URI:append:nuvoton = " file://2222-driver-misc-add-nuvoton-vdmx-vdma-driver.patch"
# SRC_URI:append:nuvoton = " file://2223-net-mctp-Support-mctp-over-pcie-vdm.patch"

# SRC_URI:append:nuvoton = " file://0015-driver-misc-nuvoton-vdm-support-openbmc-libmctp.patch"

SRC_URI:append:nuvoton = " file://0001-mctp-avoid-confusion-over-local-peer-dest-source-add.patch"
SRC_URI:append:nuvoton = " file://0002-mctp-make-key-lookups-match-the-ANY-address-on-eithe.patch"
SRC_URI:append:nuvoton = " file://0003-mctp-serial-use-netif_receive_skb-instead-of-netif_r.patch"

# Let sign-file/extract-cert build against OpenSSL without the ENGINE API,
# and stop "make modules_sign" from running depmod on the host
SRC_URI:append:nuvoton = " file://0101-sign-file-Fix-incorrect-return-values-check.patch"
SRC_URI:append:nuvoton = " file://0102-sign-file-extract-cert-move-common-SSL-helper-functi.patch"
SRC_URI:append:nuvoton = " file://0103-sign-file-extract-cert-avoid-using-deprecated-ERR_ge.patch"
SRC_URI:append:nuvoton = " file://0104-sign-file-extract-cert-use-pkcs11-provider-for-OPENS.patch"
SRC_URI:append:nuvoton = " file://0105-kbuild-do-not-run-depmod-for-make-modules_sign.patch"
