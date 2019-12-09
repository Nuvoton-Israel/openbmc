RDEPENDS_${PN}-fan-control_remove = " \
                                     phosphor-fan-control \
                                     phosphor-fan-monitor \
                                    "
RDEPENDS_${PN}-inventory_remove = " \
                                   phosphor-fan-presence-tach \
                                  "
RDEPENDS_${PN}-host-state-mgmt_append_olympus-nuvoton = " olympus-nuvoton-debug-collector"
