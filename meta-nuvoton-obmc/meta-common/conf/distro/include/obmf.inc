# OBMF (Open Boot and Management Framework) over USB.
#
# Require from a distro .conf (or include from local.conf) to opt in:
#   require conf/distro/include/obmf.inc
#
# Recipes and bbappends gate their OBMF changes on the df-obmf override
# (or bb.utils.contains on DISTRO_FEATURES):
#   - linux-nuvoton: NPCM-6.1-OBMF-dev or NPCM-6.12-OBMF-dev kernel branch
#     (the board picks one with PREFERRED_VERSION_linux-nuvoton), USB OBMF class
#     drivers, eSPI flash, NCT7363 hwmon and the board OBMF DT overlay

DISTRO_FEATURES += "obmf"
DISTROOVERRIDES .= ":df-obmf"
