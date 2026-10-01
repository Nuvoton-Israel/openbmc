SUMMARY = "Caliptra recovery images for NPCM500"
DESCRIPTION = "Caliptra FW bundle, SoC manifest and MCU runtime that \
nuv-ocp-recovery streams to the NPCM500 over I3C.  Built from the \
cs00-caliptra-sw npcm_rom_2.1.2 branch."

LICENSE = "CLOSED"

# The source branch is npcm_rom_2.1.2.  PV keeps only the numeric part: the
# ipk file name is <pkg>_<version>_<arch>.ipk, so an '_' inside the version
# would make the fields ambiguous.
PV = "2.1.2"

SRC_URI = "file://caliptra_fw.bin \
           file://soc_manifest.bin \
           file://runtime-npcm500.bin \
          "

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

# The images are installed as-is; there is nothing to configure or build.
do_configure[noexec] = "1"
do_compile[noexec] = "1"

images_dir = "${datadir}/nuv-ocp-recovery"

do_install() {
    # The installed names must match FwImage, SocManifest and McuRuntime in
    # nuv-ocp-recovery's recovery-config.json.
    install -Dm644 ${S}/caliptra_fw.bin ${D}${images_dir}/fw_image.bin
    install -Dm644 ${S}/soc_manifest.bin ${D}${images_dir}/soc_manifest.bin
    install -Dm644 ${S}/runtime-npcm500.bin ${D}${images_dir}/mcu_rt.bin
}

# The default FILES only covers ${datadir}/${BPN}; the images go into the
# directory nuv-ocp-recovery reads them from.
FILES:${PN} = " \
    ${images_dir}/fw_image.bin \
    ${images_dir}/soc_manifest.bin \
    ${images_dir}/mcu_rt.bin \
    "
