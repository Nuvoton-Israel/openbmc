#!/bin/bash

espiflashdev="/dev/mtd/by-name/npcm-espi-flash"

dd if=/dev/random of=/tmp/test.bin bs=1M count=32
if ! flashcp -v /tmp/test.bin ${espiflashdev} > /dev/null ; then
  echo "flash bios image unsuccessfully"
else
  echo "flash bios image successfully"
fi
rm -rf /tmp/test.bin

