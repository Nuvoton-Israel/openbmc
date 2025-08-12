# This file is a bbappend for the obmc-ikvm recipe, which is used to
# customize the build for the Nuvoton NPCM845 EVB platform.

# Legacy kvm driver version
#LIC_FILES_CHKSUM = "file://LICENSE;md5=d32239bcb673463ab874e80d47fae504"
#SRC_URI:nuvoton := "git://github.com/Nuvoton-Israel/obmc-ikvm.git;branch=master;protocol=https"
#SRCREV:nuvoton := "9ac93031be05d807a4a24c722f560ac6172c431a"

# V4L2 kvm driver version
LIC_FILES_CHKSUM = "file://LICENSE;md5=75859989545e37968a99b631ef42722e"
SRC_URI:nuvoton := "git://github.com/Nuvoton-Israel/obmc-ikvm.git;branch=upstream-v4l2;protocol=https"
SRCREV:nuvoton := "b4ae317e8b441354c6c4dbe61e359b2ce56326bf"

# USB capture device version
#LIC_FILES_CHKSUM = "file://LICENSE;md5=75859989545e37968a99b631ef42722e"
#SRC_URI:nuvoton := "git://github.com/Nuvoton-Israel/obmc-ikvm.git;branch=upstream-usb-video;protocol=https"
#SRCREV:nuvoton := "847f81259485964618650ba539399c1e6bc21028"
