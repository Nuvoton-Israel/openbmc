#!/bin/sh
# Drive NPCM500 (FPGA A2) JTAG strap pins JEN1#..JEN4# from Arbel GPIOs.
#
#   JEN1# <- GPIO199 (J4.19)   -> FPGA GPIO75
#   JEN2# <- GPIO198 (J4.20)   -> FPGA GPIOB4
#   JEN3# <- GPIO123 (J4.21)   -> FPGA GPIOF1
#   JEN4# <- GPIO122 (J4.22)   -> FPGA GPIOB1
#   GND   <- J4.2 or J4.39
#
# Pins have 2K pull-ups to 3.3V on the EVB, so the default is 1111 (Normal Boot).
# Straps are sampled at NPCM500 reset: reset the FPGA after changing them.

# "chip line" for JEN1..JEN4 (Arbel GPIOn = gpiochip(n/32) line(n%32))
PINS="6 7
6 6
3 27
3 26"

usage() {
    echo "Usage: $0 <JEN1JEN2JEN3JEN4>   e.g. $0 0011"
    echo "       $0 get"
    exit 1
}

case "$1" in
get|"")
    # Do not use gpioget: it re-requests the line as input, which drops the
    # driven value (pins float back to the 1111 pull-up). Read GPIO bank
    # registers instead: base 0xF0010000 + bank*0x1000, DIN 0x04, DOUT 0x0C,
    # OE 0x10. DIN reads 0 for output pins, so use DOUT when OE is set.
    out=""
    echo "$PINS" | {
        while read -r chip line; do
            base=$((0xF0010000 + chip * 0x1000))
            oe=$(devmem $((base + 0x10)) 32)
            if [ $(( (oe >> line) & 1 )) -eq 1 ]; then
                val=$(devmem $((base + 0x0C)) 32)
            else
                val=$(devmem $((base + 0x04)) 32)
            fi
            out="$out$(( (val >> line) & 1 ))"
        done
        echo "JEN1#..JEN4# = $out"
    }
    ;;
[01][01][01][01])
    i=1
    echo "$PINS" | while read -r chip line; do
        gpioset "$chip" "$line=$(echo "$1" | cut -c$i)" || exit 1
        i=$((i + 1))
    done || exit 1
    # Enable the Arbel JTAG master buffer (GPIO70, active low)
    gpioset 2 6=0 || exit 1
    echo "JEN1#..JEN4# set to $1 (reset the FPGA to apply)"
    ;;
*)
    usage
    ;;
esac
