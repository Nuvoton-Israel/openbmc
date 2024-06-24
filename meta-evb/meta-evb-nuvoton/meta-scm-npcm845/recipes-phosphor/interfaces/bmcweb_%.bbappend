# Enable Redfish Journal support
EXTRA_OEMESON:append = " -Dredfish-bmc-journal=enabled"

# Enable TFTP
EXTRA_OEMESON:append  = " -Dinsecure-tftp-update=enabled"

# Increase body limit for FW size
EXTRA_OEMESON:append  = " -Dhttp-body-limit=65"

# Enable dbus rest API /xyz/
EXTRA_OEMESON:append = " -Drest=enabled"

# Enable http support for Event Service
EXTRA_OEMESON:append = " -Dinsecure-push-style-notification=enabled"
