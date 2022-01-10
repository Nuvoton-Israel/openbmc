FILESEXTRAPATHS:append:olympus-nuvoton := "${THISDIR}/${PN}:"

PACKAGECONFIG:append:olympus-nuvoton= " log-threshold log-alarm log-pulse log-watchdog"
