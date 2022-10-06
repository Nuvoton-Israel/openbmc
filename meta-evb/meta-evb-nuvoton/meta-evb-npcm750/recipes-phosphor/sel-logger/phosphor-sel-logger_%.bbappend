inherit entity-utils

PACKAGECONFIG:append:evb-npcm750 = " log-watchdog clears-sel"
PACKAGECONFIG:append:evb-npcm750 = " ${@entity_enabled(d, 'log-threshold', 'send-to-logger log-alarm')}"
