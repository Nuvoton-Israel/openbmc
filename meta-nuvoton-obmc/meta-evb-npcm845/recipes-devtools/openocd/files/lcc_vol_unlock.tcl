# NPCM500 LCC volatile RAW -> TEST_UNLOCKED0 over JTAG1 LCC TAP
# Based on RD jtag_lcc_volatile_unlock.tcl, uses RD lcc_common.tcl functions.
# Differences from RD script: no init/shutdown on success (so ctrl_out_check.tcl
# can run in the same session), token from ROM log, LCC target selected here.
#   openocd -f 0111_jtag1_clp_mcu_lcc.cfg -f lcc_vol_unlock.tcl \
#           -c "set JEN 0111" -f ctrl_out_check.tcl
# Override token: -c "set LCC_TOKEN {0xf0930a4d 0xde8a30e6 0xd1c8cbba 0x896e4a11}"
# Volatile: any reset (POR or warm) re-samples straps and drops LC back to OTP
# state, so re-run this after every reset before testing 0111.

source [find lcc_common.tcl]

set LC_RAW            0
set LC_TEST_UNLOCKED0 1
# Token per RD: 1117 bitfile uses 0xf0930a4d..; newer bitfiles use 0xf90fd5b2..
if {![info exists LCC_TOKEN]} {
	set LCC_TOKEN {0xf90fd5b2 0x49914e2d 0x89aa42e6 0x4423165e}
}

poll off
targets lcc
# lcc is -defer-examine; examine sets up the DTM/dmi_read (fails on DM, ignore)
catch {lcc arp_examine}

lcc_initialization
set st [read_lc_state]
set cnt [read_lc_counter]
if {$st != $LC_RAW} {
	echo "LCC: state $st is not RAW, skip volatile unlock"
	return
}
if {$cnt >= 24} {
	echo "LCC: counter max"
	shutdown error
}

Write_LC_VOLATILE_REG
set vol [Read_LC_VOLATILE_REG]
echo [format "LC_CTRL_TRANSITION_CTRL = 0x%08x" $vol]
if {($vol & 0x2) == 0} {
	echo "LCC VOLATILE UNLOCK RESULT: FAIL (VOLATILE_RAW_UNLOCK bit did not stick)"
	shutdown error
}

transition_state $LC_TEST_UNLOCKED0 {*}$LCC_TOKEN 1

set st [read_lc_state]
if {$st != $LC_TEST_UNLOCKED0} {
	echo "LCC VOLATILE UNLOCK RESULT: FAIL (state $st)"
	shutdown error
}
echo "LCC VOLATILE UNLOCK RESULT: PASS -> continue with MCI BP release"
