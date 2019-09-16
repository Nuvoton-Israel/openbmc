#!/bin/sh

sigfile=/tmp/bmc.sig
bmcimage=/run/initramfs/image-bmc
publickey=/etc/activationdata/OpenBMC/publickey

if [ -f $sigfile ];then
	r=$(openssl dgst -verify $publickey  -sha256 -signature $sigfile   $bmcimage)
	echo $r
	if [ "Verified OK" == "$r" ]; then
		echo "success" > /tmp/bmc.verify
	else
		echo "failed" > /tmp/bmc.verify
	fi
else
	echo "No $sigfile file"
fi
