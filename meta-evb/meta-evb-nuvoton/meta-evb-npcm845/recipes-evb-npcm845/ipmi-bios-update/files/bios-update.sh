#!/bin/sh

IMAGE_FILE="/tmp/image-bios"

FLASH_LOG="/tmp/bios_flash.log"

findmtd() {
    m=$(grep -xl "$1" /sys/class/mtd/*/name)
    m=${m%/name}
    m=${m##*/}
    echo $m
}

main() {
    if [ ! -f ${IMAGE_FILE} ]; then
        echo "Invalid bios image file!" | tee -a ${FLASH_LOG}
        exit 1
    fi

    echo "Find mtd partition for bios" | tee -a ${FLASH_LOG}
    m=$(findmtd bios)
    if test -z "$m"
    then
        echo "Unable to find mtd partition for bios." | tee -a ${FLASH_LOG}
        exit 1
    fi

    echo "Starting programing BIOS flash" | tee -a ${FLASH_LOG}
    flashcp -v ${IMAGE_FILE} /dev/$m | tee -a ${FLASH_LOG}
    if [ $? -eq 0 ]; then
        echo "bios update successfully..." | tee -a ${FLASH_LOG}
    else
        echo "bios update failed..." | tee -a ${FLASH_LOG}
        exit 1
    fi
}

main "$@"
