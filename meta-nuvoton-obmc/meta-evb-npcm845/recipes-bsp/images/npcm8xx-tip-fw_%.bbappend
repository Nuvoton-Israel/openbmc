# BMC-mediated Composite EAT: deploy the prebuilt TIP FW that provides the
# Composite EAT service. Enabled by conf/distro/include/composite-eat.inc.
require ${@bb.utils.contains('DISTRO_FEATURES', 'composite-eat', 'npcm8xx-tip-fw-composite-eat.inc', '', d)}
