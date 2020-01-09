#!/bin/sh

i=0
findmtd() {
	m=$(grep -xl "$1" /sys/class/mtd/*/name)
	m=${m%/name}
	m=${m##*/}
	echo $m
}

r=$(cat /sys/class/gpio/gpio506/value)

until [ "$i" == "10" -o "$r" == "0" ]
do
	i=$(($i+1))
	echo "Shut down:" $i
	busctl set-property xyz.openbmc_project.State.Chassis \
						/xyz/openbmc_project/state/chassis0 \
						xyz.openbmc_project.State.Chassis \
						RequestedPowerTransition s xyz.openbmc_project.State.Chassis.Transition.Off
	j=0
	r=$(cat /sys/class/gpio/gpio506/value)
	until [ "$r" == "0" -o "$j" == "60" ]
	do
		j=$(($j+1))
		sleep 1
		r=$(cat /sys/class/gpio/gpio506/value)
		echo $j"s" " 506:" $r
	done
done

if [ "$r" == "0" ]; then
	echo "HOST is shut down!"
	sleep 10
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
	sleep 10

	echo "Unmount BISO flash"
	echo 0 > /sys/class/gpio/gpio227/value
	cd /sys/bus/platform/devices/c0000000.fiu/driver
	echo -n "c0000000.fiu" > unbind
	echo -n "c0000000.fiu" > bind

	sleep 10

	echo  0 > /sys/class/gpio/gpio451/value
	sleep 10
	echo  1 > /sys/class/gpio/gpio451/value
	sleep 1

	echo "Power on"
	busctl set-property xyz.openbmc_project.State.Host \
		/xyz/openbmc_project/state/host0 \
		xyz.openbmc_project.State.Host \
		RequestedHostTransition s xyz.openbmc_project.State.Host.Transition.On

	i=0
	r=$(cat /sys/class/gpio/gpio506/value)
	until [ "$r" == "1" -o "$i" == "60" ]
	do
		i=$(($i+1))
		sleep 1
		r=$(cat /sys/class/gpio/gpio506/value)
		echo $i"s" " 506:" $r
	done

else
	echo "We could NOT power down HOST, so skip updating BIOS!!"
fi
