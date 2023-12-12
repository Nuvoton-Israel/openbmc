inherit entity-utils

PACKAGECONFIG:append:evb-npcm845 = " log-watchdog"
PACKAGECONFIG:append:evb-npcm845 = " ${@entity_enabled(d, 'log-threshold', 'send-to-logger log-alarm')}"
