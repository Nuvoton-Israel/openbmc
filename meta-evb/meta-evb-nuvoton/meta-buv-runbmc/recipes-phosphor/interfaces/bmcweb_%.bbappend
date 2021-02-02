FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"


# Enable CPU Log and Raw PECI support
#EXTRA_OEMESON_append = " -Dredfish-cpu-log=enabled"
#EXTRA_OEMESON_append = " -Dredfish-raw-peci=enabled"

# Enable Redfish BMC Journal support
# EXTRA_OEMESON_append = " -Dredfish-bmc-journal=enabled"

# Enable DBUS log service
EXTRA_OEMESON_append = " -Dredfish-dbus-log=enabled"

# Enable TFTP
EXTRA_OEMESON_append = " -Dinsecure-tftp-update=enabled"

# Increase body limit for BIOS FW
EXTRA_OEMESON_append = " -Dhttp-body-limit=35"

# enable debug
# EXTRA_OEMESON_append = " -Dbmcweb-logging=enabled"
