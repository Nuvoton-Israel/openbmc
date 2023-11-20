ALT_RMCPP_IFACE:evb-npcm845 = "eth1"
SYSTEMD_SERVICE:${PN}:append:evb-npcm845 := " \
        ${PN}@${ALT_RMCPP_IFACE}.service \
        ${PN}@${ALT_RMCPP_IFACE}.socket \
        "
