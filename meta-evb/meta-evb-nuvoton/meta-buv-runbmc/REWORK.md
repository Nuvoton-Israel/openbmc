# NPCM750 RunBMC BUV hardware rework
This is the Nuvoton RunBMC BUV hardware layer.

BUV board can plug the RunBMC card.

# Contacts for Patches

Please submit any patches against the meta-runbmc-nuvoton layer to the maintainer of nuvoton:

* Joseph Liu, <KWLIU@nuvoton.com>
* Medad CChien, <CTCCHIEN@nuvoton.com>
* Tyrone Ting, <KFTING@nuvoton.com>
* Stanley Chu, <YSCHU@nuvoton.com>
* Tim Lee, <CHLI30@nuvoton.com>
* Brian Ma, <CHMA0@nuvoton.com>
* Jim Liu, <JJLIU0@nuvoton.com>

# Table of Contents

- [Contacts for Patches](#contacts-for-patches)
- [Rework for RunBMC BUV](#Rework-for-RunBMC-BUV)
  * [Runbmc card](#Runbmc-card)
  * [Secure boot](#Secure-boot)
  * [Nist](#Nist)
  * [LED](#LED)

# Rework for RunBMC BUV

## Runbmc card
Runbmc card work on buv board.
1. remove R206 0k ohm
2. short R422 for control GPIO09 to set 7 segment display and avoid reset U23
<img align="left" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_p1.png">
<img align="center" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_p1.png">
<img align="center" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_p3.png">
 


## Secure boot
The NPCM7xx is a BMC that authenticates it's code before it runs and so can become the Root of Trust for th BMC subsystem.
NPCM750 RunBMC can support normal mode and secure mode
1. Make a jumper to Connect 2.2k ohm on R108 when enable secure boot

<img align="left" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_secure1.png">
<img align="center" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_secure2.png">
<img align="center" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_secure3.png">

## Nist
RunBMC can support Nist feature
1. remove runbmc R175
2. mount 0k ohm on R186
3. make a jumper wire to connect R186(runbmc) and BUV J705 pin 7
  
<img align="left" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_nist.png">
<img align="center" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_nist2.png"> 
  
## LED
Add R722 66ohm for led E2

<img align="center" width="30%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/runbmc_buv_led.png">
