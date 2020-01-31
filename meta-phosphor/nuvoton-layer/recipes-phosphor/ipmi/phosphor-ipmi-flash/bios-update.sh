#!/bin/sh

i=0
findmtd() {
	m=$(grep -xl "$1" /sys/class/mtd/*/name)
	m=${m%/name}
	m=${m##*/}
	echo $m
}
IPMB_LOG=/tmp/bios_flash.log
setEnableME() {
    echo "==== $(date) ==== $1" >> $IPMB_LOG
    journalctl --no-p -u ipmb | tail -n 2 >> $IPMB_LOG
    res=`busctl call xyz.openbmc_project.NodeManagerProxy \
        /xyz/openbmc_project/status/me \
        xyz.openbmc_project.SetHealth EnableForceRecovery b ${1}`
    echo "==== $(date) ====" >> $IPMB_LOG
    journalctl --no-p -u ipmb |tail -n 2 >> $IPMB_LOG
}
PowerOn() {
    i=0
    busctl set-property xyz.openbmc_project.State.Host \
        /xyz/openbmc_project/state/host0 \
        xyz.openbmc_project.State.Host \
        RequestedHostTransition s \
        xyz.openbmc_project.State.Host.Transition.On
    r=$(cat /sys/class/gpio/gpio506/value)
    until [ "$r" == "1" -o "$i" == "30" ]
    do
        i=$(($i+1))
        sleep 1
        r=$(cat /sys/class/gpio/gpio506/value)
        echo "${i}s  506: ${r}, retry:${retry}"
    done
}

r=$(cat /sys/class/gpio/gpio506/value)

hostState=${r}
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
    # disable ME
    setEnableME true
    if [ "$res" != "i 0" ];then
        echo "disable ME fail!!"
        # retry
        echo "start retry..."
        setEnableME true
        sleep 5
        setEnableME false
        if [ "$res" != "i 0" ];then
            echo "disable ME failed."
            exit 1
        fi
    fi
    sleep 1
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

	sleep 1

    # Enable ME
    setEnableME false
    sleep 12

	#echo  0 > /sys/class/gpio/gpio451/value
	#sleep 10
	#echo  1 > /sys/class/gpio/gpio451/value
	#sleep 1

    #if [ "$hostState" == "1" ];then
    retry=0
    echo "Power on"
    PowerOn
    if [ "$r" == "1" ];then
        echo "Power on success"
    else
        echo "Power on failed..."
        # i2c may fail, retry boot
        setEnableME false
        sleep 12
        retry=1
        PowerOn
    fi
    #fi

else
	echo "We could NOT power down HOST, so skip updating BIOS!!"
fi
