# NPCM500 A2 JTAG slave control output check
# Run after the JEN cfg (the cfg already does init):
#   openocd -f <JEN>_jtag1_*.cfg -c "set JEN 0111" -f ctrl_out_check.tcl
# Steps:
#   1. MCU TAP: if HW_FLOW_STATUS[3:0] = 4 (MCI BP), write MCI_BOOTFSM_GO = 1
#   2. CLP TAP: if CPTRA_BOOTFSM_GO = 0 (CLP BP), write 1
#   3. MCU SBA: read STRPST1 / CPTRA_LC_STS / CPTRA_WRAP_IN_STS, compare [3:0]

# JEN -> expected CPTRA_WRAP_IN_STS[3:0] (bit0 CLP BP, bit1 MCI BP, bit2 DI, bit3 PPD)
array set EXP {
	0000 0x4 0001 0x5 0010 0x4 0011 0x0 0100 0x1 0101 0x0 0110 0xD 0111 0x2
	1000 0x1 1001 0x0 1010 0x6 1011 0x0 1100 0x0 1101 0x0 1110 0x0 1111 0x0
}

if {![info exists JEN] || ![info exists EXP($JEN)]} {
	echo "ERROR: give the strap, e.g. -c \"set JEN 0111\""
	shutdown error
}

proc has_target {t} { expr {[lsearch -exact [target names] $t] >= 0} }

proc dmi_rd {addr} {
	if {[catch {riscv dmi_read $addr} v]} { return -1 }
	return $v
}

echo "==== JEN $JEN, expected CPTRA_WRAP_IN_STS\[3:0\] = $EXP($JEN) ===="

# 1. MCI BP release (MCU TAP uncore DMI)
if {[has_target mcu]} {
	targets mcu
	set hw [dmi_rd 0x5F]
	echo [format "MCU HW_FLOW_STATUS (DMI 0x5F) = 0x%08x" $hw]
	if {$hw >= 0 && ($hw & 0xF) == 4} {
		echo "Stopped at MCI BP -> write MCI_BOOTFSM_GO (DMI 0x74) = 1"
		riscv dmi_write 0x74 0x1
		sleep 500
		set hw [dmi_rd 0x5F]
		echo [format "MCU HW_FLOW_STATUS after = 0x%08x" $hw]
		if {($hw & 0xF) == 4} {
			echo "MCI BP NOT released (0111 needs LC = TEST_UNLOCKED/MANUF/RMA)"
		}
	} elseif {($EXP($JEN) & 0x2) && ($hw & 0xF) != 4} {
		echo "MCI BP expected but 0x5F != 4: MCU uncore closed (no DI, LC RAW/TL/PROD), cannot release"
	}
}

# 2. CLP BP release (CLP TAP uncore DMI), only for straps with CLP BP
#    (CPTRA_BOOTFSM_GO also reads 0 when there is no CLP BP)
if {[has_target clp] && ($EXP($JEN) & 0x1)} {
	targets clp
	set go [dmi_rd 0x61]
	echo [format "CLP CPTRA_BOOTFSM_GO (DMI 0x61) = 0x%08x" $go]
	if {$go == 0} {
		echo "Stopped at CLP BP -> write CPTRA_BOOTFSM_GO = 1"
		riscv dmi_write 0x61 0x1
		sleep 500
		echo [format "CLP CPTRA_BOOTFSM_GO after = 0x%08x" [dmi_rd 0x61]]
	}
}

# 3. Read EXT_REG via MCU SBA (needs MCU out of reset and MCU debug open)
if {![has_target mcu]} {
	echo "No MCU TAP in this cfg: read CPTRA_WRAP_IN_STS with the other JTAG cfg or FW"
	shutdown
}
sleep 2000
targets mcu
catch {mcu arp_examine}
riscv set_mem_access sysbus
if {[catch {read_memory 0x70030008 32 1 phys} in]} {
	echo "SBA read failed: $in"
	echo "RESULT JEN $JEN: INCONCLUSIVE (read 0x70030008 from FW instead)"
	shutdown
	return
}
set strap_ok 1
if {![catch {read_memory 0x400C3001 8 1 phys} sp]} {
	set sj [format %04b [expr {($sp >> 4) & 0xF}]]
	echo [format "STRPST1      (0x400C3001) = 0x%02x, JEN1..4 = %s" $sp $sj]
	if {$sj ne $JEN} {
		echo "STRPST1 JEN $sj != $JEN: strap pin problem, not control output"
		set strap_ok 0
	}
}
catch {echo [format "CPTRA_LC_STS (0x70030000) = 0x%08x" [read_memory 0x70030000 32 1 phys]]}
set got [expr {$in & 0xF}]
echo [format "CPTRA_WRAP_IN_STS (0x70030008) = 0x%08x, \[3:0\] = 0x%x" $in $got]
if {!$strap_ok} {
	echo "RESULT JEN $JEN: STRAP MISMATCH"
} elseif {$got == $EXP($JEN)} {
	echo "RESULT JEN $JEN: PASS"
} else {
	echo [format "RESULT JEN %s: FAIL (expected 0x%x)" $JEN $EXP($JEN)]
}
shutdown
