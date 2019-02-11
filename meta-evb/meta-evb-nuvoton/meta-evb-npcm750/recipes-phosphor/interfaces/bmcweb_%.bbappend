FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-bmcweb-support-obmc-ikvm.patch"

EXTRA_OECMAKE += "-DBMCWEB_ENABLE_KVM=OFF -DBMCWEB_ENABLE_OBMC_IKVM=ON"
