#!/bin/sh

i=0
r=1

findmtd() {
	m=$(grep -xl "$1" /sys/class/mtd/*/name)
	m=${m%/name}
	m=${m##*/}
	echo $m
}

until [ "$i" == "100" -o "$r" == "0" ]
do
	i=$(($i+1))
	r=$(cat /sys/class/gpio/gpio506/value)
	echo "506valure:"$r "Times:"$i
	echo "Shut down"
	echo 0 > /sys/class/gpio/gpio505/value
	sleep 3
done
if [ "$r" == "0" ]; then
	echo "HOST is shut down!"
	echo "Mount BIOS flash"
	echo 227 > /sys/class/gpio/export
	echo 1 > /sys/class/gpio/gpio227/value
	cd /sys/bus/platform/devices/c0000000.fiu/driver
	echo -n "c0000000.fiu" > unbind
	echo -n "c0000000.fiu" > bind
	
	echo "Starting programing bios flash"
	m=$(findmtd bios)
	if test -z "$m"
	then
		echoerr "Unable to find mtd partition for bios."
		exit 1
	fi
	
	flashcp -v /tmp/bios-image /dev/$m && rm /tmp/bios-image
	
	echo "Unmount BISO flash"
	echo 0 > /sys/class/gpio/gpio227/value
	cd /sys/bus/platform/devices/c0000000.fiu/driver
	echo -n "c0000000.fiu" > unbind
	echo -n "c0000000.fiu" > bind
	
	echo "Power on"
	echo 0 > /sys/class/gpio/gpio505/value
	sleep 1
	echo 1 > /sys/class/gpio/gpio505/value
	sleep 1
	echo 0 > /sys/class/gpio/gpio505/value
	sleep 1
	echo 1 > /sys/class/gpio/gpio505/value
	sleep 5
	echo "Value of 506:"
	cat /sys/class/gpio/gpio506/value
else
	echo "HOST is still running!!"
fi
