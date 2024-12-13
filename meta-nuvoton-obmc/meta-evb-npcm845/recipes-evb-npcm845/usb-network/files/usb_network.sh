#!/bin/bash

cd /sys/kernel/config/usb_gadget || exit 1

version_above_5(){
  MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
  if [ "$MAJOR_VERSION" -ge 6 ]  ; then
    return 0
  else
    return 1
  fi
}

dev_name="f0832000.udc"
if version_above_5
then
  dev_name="ci_hdrc.2"
fi

if [ ! -f "g1" ]; then
    mkdir g1
    cd g1 || exit 1

    echo 0x1d6b > idVendor  # Linux foundation
    echo 0x0104 > idProduct # Multifunction composite gadget
    mkdir -p strings/0x409
    echo "Linux" > strings/0x409/manufacturer
    echo "Ethernet/RNDIS gadget" > strings/0x409/product
    
    mkdir -p configs/c.1
    echo 100 > configs/c.1/MaxPower
    mkdir -p configs/c.1/strings/0x409
    echo "RNDIS" > configs/c.1/strings/0x409/configuration

    mkdir -p functions/rndis.usb0
    # In order to be compatible with Windows
    echo ef > functions/rndis.usb0/class
    echo 04 > functions/rndis.usb0/subclass
    echo 01 > functions/rndis.usb0/protocol
    
    ln -s functions/rndis.usb0 configs/c.1
    
    echo "${dev_name}" > UDC

fi
exit 0
