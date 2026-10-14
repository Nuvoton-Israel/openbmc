# NPCM500: 32K clock domain (INT32K_OUT -> LFCLK) switched to the RTC 32.768 kHz crystal
#
# Sequence follows MCU firmware cs00-caliptra-mcu-sw platforms/npcm-common/src/rtc.rs
# switch_lfcg_to_rtc_clock(); works on both the M7 (cortex_m) and MCU (riscv) targets.
# Requires OpenOCD 0.12+ (read_memory / write_memory).
#
# Usage:
#   ~/.local/opt/openocd-nohalt/bin/openocd -f npcm500_mcu.cfg -f rtc_switch.tcl \
#       -c init -c "npcm500_switch_32k_to_rtc" -c shutdown
#
# Addresses: NPCM500M datasheet V0.1, C2H layout checked against Zephyr reg_def.h,
#       PWDWN_CTL0/5 and LFCGCTL2 (16-bit, bit8 RTC_SW) taken from the MCU firmware.

set PWDWN_CTL0   0x4000D007 ;# Byte, bit7 RTC_PD
set PWDWN_CTL5   0x4000D00C ;# Byte, bit3 C2HACC_PD
set C2H_IHIOA    0x4000E000 ;# Word
set C2H_IHD      0x4000E002 ;# Byte
set C2H_CRSMAE   0x4000E008 ;# Word
set C2H_SIBCTRL  0x4000E00A ;# Byte
set LFCGCTL      0x400B5100 ;# Word, bit5 LFLOC
set LFCGCTL2     0x400B5114 ;# Word, bit8 RTC_SW(RO), bit7 LFREF_STS(RO), reset 0x8080

set RTC_PD       0x80
set C2HACC_PD    0x08
set CRSMAE_RTC   0x07       ;# Core Access Select 00111b = RTC
set SIBCTRL_CSAE 0x01
set SIBCTRL_CSRD 0x02
set SIBCTRL_CSWR 0x04
set RTC_INDEX    0          ;# RTC host I/O +0 = index port
set RTC_DATA     1          ;# RTC host I/O +1 = data port
set RTC_CFG      0x0A
set RTC_CTS      0x0D
set RTC_CFG_ENRTCPAD 0x08
set RTCCTS_PAD       0x80   ;# RTCPAD_status
set RTCCTS_PAD_05S   0x40   ;# RTCPAD_0.5s_status
set LFCGCTL_LFLOC    0x0020
set LFCGCTL2_KEEP    0x000A ;# AUDP_EN | INTK_BYP, preserved, as in firmware encode_lfcgctl2
set LFCGCTL2_RTC_SEL 0x0040
set LFCGCTL2_STOPCAL 0x0010
set LFCGCTL2_RTC_SW  0x0100

proc rd8  {addr}     { return [lindex [[target current] read_memory $addr 8 1] 0] }
proc rd16 {addr}     { return [lindex [[target current] read_memory $addr 16 1] 0] }
proc wr8  {addr val} { [target current] write_memory $addr 8  [list $val] }
proc wr16 {addr val} { [target current] write_memory $addr 16 [list $val] }

proc clear_pd_bit {addr mask name} {
    set v [rd8 $addr]
    if {$v & $mask} {
        wr8 $addr [expr {$v & ~$mask & 0xFF}]
        if {[rd8 $addr] & $mask} { error "$name did not clear" }
    }
}

# Poll SIBCTRL until all bits in mask are 0
proc sib_wait_clear {mask timeout_ms} {
    for {set i 0} {$i < $timeout_ms} {incr i} {
        if {([rd8 $::C2H_SIBCTRL] & $mask) == 0} { return }
        sleep 1
    }
    error [format "SIBCTRL mask 0x%02x not cleared after %d ms" $mask $timeout_ms]
}

# datasheet 5.2 "Core Write Access"
proc sib_write {io_ofs val} {
    sib_wait_clear [expr {$::SIBCTRL_CSRD | $::SIBCTRL_CSWR}] 100
    wr16 $::C2H_IHIOA $io_ofs
    wr8  $::C2H_IHD   $val
    sib_wait_clear $::SIBCTRL_CSWR 100
}

# datasheet 5.2 "Core Read Access"
proc sib_read {io_ofs} {
    sib_wait_clear [expr {$::SIBCTRL_CSRD | $::SIBCTRL_CSWR}] 100
    wr16 $::C2H_IHIOA $io_ofs
    wr8  $::C2H_SIBCTRL [expr {$::SIBCTRL_CSAE | $::SIBCTRL_CSRD}]
    sib_wait_clear $::SIBCTRL_CSRD 100
    return [rd8 $::C2H_IHD]
}

proc rtc_write {index val} { sib_write $::RTC_INDEX $index; sib_write $::RTC_DATA $val }
proc rtc_read  {index}     { sib_write $::RTC_INDEX $index; return [sib_read $::RTC_DATA] }

proc npcm500_switch_32k_to_rtc {{osc_timeout_ms 2000}} {
    if {[rd16 $::LFCGCTL] & $::LFCGCTL_LFLOC} { error "LFLOC=1: LFCG registers are write-locked" }

    # 1. Power up the C2H (SIB) and RTC host modules
    clear_pd_bit $::PWDWN_CTL5 $::C2HACC_PD "C2HACC_PD"
    clear_pd_bit $::PWDWN_CTL0 $::RTC_PD    "RTC_PD"

    # 2. Enable core access to the RTC
    wr16 $::C2H_CRSMAE  $::CRSMAE_RTC
    wr8  $::C2H_SIBCTRL $::SIBCTRL_CSAE

    # 3. Paired action, no other access in between: write RTCCFG=08, read it back,
    #    then switch LFCGCTL2 immediately
    set c2 [rd16 $::LFCGCTL2]                       ;# read first to shorten the gap between the two writes
    set c2_new [expr {0x8080 | ($c2 & $::LFCGCTL2_KEEP) | $::LFCGCTL2_RTC_SEL | $::LFCGCTL2_STOPCAL}]
    rtc_write $::RTC_CFG $::RTC_CFG_ENRTCPAD
    set cfg_rb [sib_read $::RTC_DATA]               ;# IHIOA still points at the data port
    wr16 $::LFCGCTL2 $c2_new
    if {$cfg_rb != $::RTC_CFG_ENRTCPAD} { error [format "RTCCFG readback 0x%02x != 0x08" $cfg_rb] }

    # 4. Wait for RTCPAD_status and RTCPAD_0.5s_status (firmware limit 2000 ms,
    #    measured 965 ms on FPGA)
    set want [expr {$::RTCCTS_PAD | $::RTCCTS_PAD_05S}]
    set cts 0
    for {set t 0} {$t < $osc_timeout_ms} {incr t 10} {
        set cts [rtc_read $::RTC_CTS]
        if {($cts & $want) == $want} { break }
        sleep 10
    }
    if {($cts & $want) != $want} { error [format "RTC not stable after %d ms (RTCCTS=0x%02x)" $osc_timeout_ms $cts] }

    # 5. Confirm in hardware that the mux has switched
    set c2n [rd16 $::LFCGCTL2]
    echo [format "RTCCTS=0x%02x after ~%d ms, LFCGCTL2 0x%04x -> 0x%04x" $cts $t $c2 $c2n]
    if {!($c2n & $::LFCGCTL2_RTC_SW)} { error "LFCGCTL2.RTC_SW=0: switch not confirmed" }

    # 6. Disable core access to the host module
    wr16 $::C2H_CRSMAE 0
}
