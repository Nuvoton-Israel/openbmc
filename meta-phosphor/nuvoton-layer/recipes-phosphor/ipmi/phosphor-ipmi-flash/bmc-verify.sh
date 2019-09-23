#!/bin/sh

sigfile=/tmp/bmc.sig
imagebmc=/run/initramfs/image-bmc
bmcimage=/run/initramfs/bmc-image
publickey=/etc/activationdata/OpenBMC/publickey

if [ -f $publickey ];then
	r=$(openssl dgst -verify $publickey  -sha256 -signature $sigfile   $bmcimage)
	echo "$r" > /tmp/update-bmc.log
	if [ "Verified OK" == "$r" ]; then
		mv $bmcimage $imagebmc
		echo "success" > /tmp/bmc.verify
	else
		echo "failed" > /tmp/bmc.verify
	fi
else
	echo "No $publickey file" > /tmp/update-bmc.log
fi
