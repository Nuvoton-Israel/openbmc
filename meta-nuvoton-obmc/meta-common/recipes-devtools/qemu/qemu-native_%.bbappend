FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Override source URI to Nuvoton's fork
QBRANCH = "npcm-v10.2.0"
SRC_URI = "gitsm://github.com/Nuvoton-Israel/qemu.git;protocol=https;branch=${QBRANCH}"
SRCREV = "48e6aea0574f1dcca3c7bc8fb5ea68a92728144a"

S = "${WORKDIR}/git"
PV = "10.2.0+git${SRCPV}"

# Since qemu-native runs on the build host and doesn't see machine overrides like npcm7xx/npcm8xx,
# we must enable both ARM (for NPCM7xx) and AArch64 (for NPCM8xx) targets unconditionally.
EXTRA_OECONF:append = " --target-list=aarch64-softmmu,aarch64-linux-user,arm-softmmu,arm-linux-user"

# PACKAGECONFIG modification
PACKAGECONFIG:append = " nettle fdt libusb"
PACKAGECONFIG:remove = " gnutls"

# Remove options that cause issues with this specific QEMU version
EXTRA_OECONF:remove = "--disable-static --disable-download"

# Force use of host python to avoid shebang length limit issues with sysroot python
EXTRA_OECONF:append = " --python=${HOSTTOOLS_DIR}/python3"

# Allow fetching subprojects during configure
do_configure[network] = "1"

# License Checksum Override (since we are fetching a different codebase)
# Note: Since this is a .bbappend, we need to be careful.
# Ideally, we should check if these files exist in the new source.
# Based on previous interactions, we know the checksums.

LIC_FILES_CHKSUM = "file://COPYING;md5=a3b50d8b88dcc0eb3d7d39b760b9e821 \
                    file://COPYING.LIB;endline=24;md5=8a8178c06478747a771588adec965232"
