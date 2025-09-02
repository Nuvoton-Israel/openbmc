# use TEST key only on special device
EXTRA_OEMAKE:append = " CFG_RPMB_TESTKEY=n CFG_RPMB_WRITE_KEY=y CFG_RPMB_RESET_FAT=n "