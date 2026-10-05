# TIP_FW 0.8.9 L0 0.7.8 L1
#
# Deploy the prebuilt TIP FW binaries shipped in this layer instead of
# building them from the npcm8xx-tip-fw git repository. The base recipe
# (npcm8xx-tip-fw.inc) already provides the deploy class, the deploy task and
# the TIP_FW/SA_TIP_FW file names; only where the files come from changes here.

FILESEXTRAPATHS:prepend := "${THISDIR}/npcm8xx-tip-fw:"

# The base recipe's PV comes from its file name (0.8.2.0.7.1), which does not
# describe these binaries.
PV = "0.8.9.0.7.8"

# Local files replace the git source. They are unpacked straight into
# UNPACKDIR, so point S there instead of the (never fetched) ${WORKDIR}/git.
SRC_URI = "file://${TIP_FW} file://${SA_TIP_FW}"
S = "${UNPACKDIR}"

# The license file lived in the git repository, which is no longer fetched.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

# Nothing to build, the binaries are already prebuilt.
do_compile[noexec] = "1"

# Replaces the base do_deploy, which copies from the git checkout.
do_deploy () {
    for f in ${TIP_FW} ${SA_TIP_FW}; do
        install -D -m 644 ${UNPACKDIR}/$f ${DEPLOYDIR}/$f
    done
}
