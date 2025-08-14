inherit entity-utils

PACKAGECONFIG:append  = " log-watchdog"
PACKAGECONFIG:append  = " ${@entity_enabled(d, 'log-threshold', 'send-to-logger log-alarm')}"
