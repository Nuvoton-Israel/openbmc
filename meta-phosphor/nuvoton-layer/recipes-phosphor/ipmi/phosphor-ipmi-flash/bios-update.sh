#!/bin/sh

i=0
findmtd() {
	m=$(grep -xl "$1" /sys/class/mtd/*/name)
	m=${m%/name}
	m=${m##*/}
	echo $m
}
IPMB_LOG=/tmp/bios_flash.log

getDbusReturn(){
    dbus_res=$(echo $1 | tr -d "\" si")
    echo $dbus_res
}

isMERecovery(){
    res=`busctl call xyz.openbmc_project.NodeManagerProxy \
        /xyz/openbmc_project/status/me xyz.openbmc_project.SetHealth \
        GetSelfTestResults`
    res=`getDbusReturn "$res"`
    echo "ME self test result: ${res}" | tee -a ${IPMB_LOG}
    me_res=${res:0:6}
    if [ "$me_res" == "000081" ];then
        return 81
    elif [ "$me_res" == "000055" ];then
        return 55
    else
        return 0
    fi
}

sendEnableMEcmd(){
    res=`busctl call xyz.openbmc_project.NodeManagerProxy \
        /xyz/openbmc_project/status/me \
        xyz.openbmc_project.SetHealth EnableForceRecovery b ${1}`
    cmd_res=`getDbusReturn "$res"`
    echo $cmd_res
}

setEnableME() {
    echo "==== $(date) ==== $1" |tee -a ${IPMB_LOG}
    res=`sendEnableMEcmd "${1}"`
    retry=3
    sleep 5
    if [ "$1" == "true" ];then
        TEST_RESULT="81"
    else
        TEST_RESULT="55"
    fi
    isMERecovery
    until [ "$?" == "$TEST_RESULT" -o "$retry" == "0" ]
    do
        sleep 2
        res=`sendEnableMEcmd "${1}"`
        # if is I2C error (res==1), just keep try again
        # or there is not I2C error, sleep while for ME ready
        if [ "$res" == "0" ];then
            sleep 5
        fi
        retry=$(($retry-1))
        isMERecovery
    done
    if [ "${retry}" == "0" ];then
        res="1"
    else
        res="0"
    fi
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
        echo "${i}s  506: ${r}"
    done
}

r=$(cat /sys/class/gpio/gpio506/value)
echo -e "\n $(date) starting bios update..." | tee -a ${IPMB_LOG}
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
	echo "HOST is shut down!" | tee -a ${IPMB_LOG}
    # disable ME
    setEnableME true
    if [ "$res" != "0" ];then
        echo "disable ME fail!! skip update BIOS" | tee -a ${IPMB_LOG}
        exit 1
    fi
    sleep 1
	echo "Mount BIOS flash" | tee -a ${IPMB_LOG}
    if [ ! -d "/sys/class/gpio/gpio227" ];then
	    echo 227 > /sys/class/gpio/export
    fi
	echo 1 > /sys/class/gpio/gpio227/value
	cd /sys/bus/platform/devices/c0000000.fiu/driver
	echo -n "c0000000.fiu" > unbind
	echo -n "c0000000.fiu" > bind

	echo "Starting programing bios flash" | tee -a ${IPMB_LOG}
	m=$(findmtd bios)
	if test -z "$m"
	then
		echoerr "Unable to find mtd partition for bios."
		exit 1
	fi

	flashcp -v /tmp/bios-image /dev/$m && rm /tmp/bios-image
	sleep 10

	echo "Unmount BISO flash"  tee -a ${IPMB_LOG}
	echo 0 > /sys/class/gpio/gpio227/value
	cd /sys/bus/platform/devices/c0000000.fiu/driver
	echo -n "c0000000.fiu" > unbind
	echo -n "c0000000.fiu" > bind

	sleep 1

    # Enable ME
    echo "Enable ME" | tee -a ${IPMB_LOG}
    setEnableME false
    sleep 9

    echo "Power on" | tee -a ${IPMB_LOG}
    PowerOn
    if [ "$r" == "1" ];then
        echo "Power on success" | tee -a ${IPMB_LOG}
    else
        echo "Power on failed..." | tee -a ${IPMB_LOG}
    fi

else
	echo "We could NOT power down HOST, so skip updating BIOS!!" | tee -a ${IPMB_LOG}
    exit 1
fi
