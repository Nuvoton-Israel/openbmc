#!/bin/sh

i=0
POWERDOWN_STATE="i 0"


findmtd() {
	m=$(grep -xl "$1" /sys/class/mtd/*/name)
	m=${m%/name}
	m=${m##*/}
	echo $m
}

r=$(busctl get-property org.openbmc.control.Power /org/openbmc/control/power0 org.openbmc.control.Power state)

until [ "$i" == "100" -o "$r" == "$POWERDOWN_STATE" ]
do
	i=$(($i+1))
	echo "Shut down"
	busctl set-property xyz.openbmc_project.State.Chassis \
						/xyz/openbmc_project/state/chassis0 \
						xyz.openbmc_project.State.Chassis \
						RequestedPowerTransition s xyz.openbmc_project.State.Chassis.Transition.Off
	sleep 3
	r=$(busctl get-property org.openbmc.control.Power /org/openbmc/control/power0 org.openbmc.control.Power state)
	echo "PowerState:"$r" Times:"$i
done

if [ "$r" == "$POWERDOWN_STATE" ]; then
	cho "HOST is shut down!"
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
	busctl set-property xyz.openbmc_project.State.Host \
			/xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host \
			RequestedHostTransition s xyz.openbmc_project.State.Host.Transition.On
	sleep 5
	r=$(busctl get-property org.openbmc.control.Power /org/openbmc/control/power0 org.openbmc.control.Power state)
	echo "PowerState:"$r
else
	echo "We could NOT power down HOST, so skip updating BIOS!!"
fi
