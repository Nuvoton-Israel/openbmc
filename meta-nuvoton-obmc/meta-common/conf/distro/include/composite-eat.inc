# BMC-mediated Composite EAT (Entity Attestation Token) attestation.
#
# Require from a distro .conf (or include from local.conf) to opt in:
#   require conf/distro/include/composite-eat.inc
#
# Recipes and bbappends gate their Composite EAT changes on the
# df-composite-eat override (or bb.utils.contains on DISTRO_FEATURES):
#   - spdm: NVIDIA SPDM stack + composite/ core and Lead Attester backend
#   - bmcweb: ComponentIntegrity and OpenBMCCompositeEATBundle OEM API
#   - phosphor-dbus-interfaces: SPDM.Responder / Item.SPDMResponder
#   - mctp: publish Common.UUID learned after the endpoint is published
#   - linux-nuvoton: Composite EAT mailbox client, UAPI and DT bindings
#   - npcm8xx-tip-fw: TIP firmware with the Composite EAT service
#
# Composite EAT evidence is collected over SPDM, which runs over MCTP, so
# the machine must also include conf/distro/include/mctp.inc.

require conf/distro/include/spdm.inc

DISTRO_FEATURES += "composite-eat"
DISTROOVERRIDES .= ":df-composite-eat"

# Move the NPCM8xx kernel load/entry address up from the default 0x6200000.
UBOOT_ENTRYPOINT:npcm8xx = "0x6300000"
UBOOT_LOADADDRESS:npcm8xx = "0x6300000"
