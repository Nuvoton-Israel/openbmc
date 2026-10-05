# BMC-mediated Composite EAT: swap in NVIDIA's SPDM stack with the composite
# producer. Enabled by conf/distro/include/composite-eat.inc.
require ${@bb.utils.contains('DISTRO_FEATURES', 'composite-eat', 'spdm-composite-eat.inc', '', d)}
