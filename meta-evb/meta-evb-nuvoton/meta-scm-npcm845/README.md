# Dependencies
This layer depends on:

```
  URI: github.com/Nuvoton-Israel/openbmc.git
  branch: npcm-v2.11
```

# [v2.08](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-core/os-release/os-release.bbappend) release note
* [701734] [701415] [BMC hang up issue](https://github.com/Nuvoton-Israel/linux/commit/e70594746e6f1048537f4188a23c05aa9b0c3685)
* [708682] [Sensor reading P3V BAT](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/configuration/entity-manager/aurea-hpm.json#L1063)
* [707675] [707675] [Temp_DIMM Sensor](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/sensors/dbus-sensors/0006-add-dimm-sensor.patch)
* [701248] [Self Test](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0012-Force-self-test-OK.patch)
* [701345] [Support LAN Interface](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-net/0001-Revert-Remove-HMAC-SHA1-from-Authentication-Integrit.patch)
* [701898] [Cold Reset SEL](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0016-Add-reset-SEL.patch)
* [701693] [CPLD version format](https://github.com/Nuvoton-Israel/nuvoton-ipmi-oem)
* [701495] [positive value in each sensor](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/sensors/dbus-sensors/0006-add-dimm-sensor.patch)
* [701944] [I3C timeout message](https://github.com/Nuvoton-Israel/linux/tree/NPCM-5.10-OpenBMC)
* [706887] [FRU Device Description](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/configuration/entity-manager/aurea-hpm.json#L1704)
* [706242] [Get DHCP IP after BMC FW update]()https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-bsp/u-boot/u-boot-nuvoton/0001-enable-mode-2.patch
* [706565] [BIOS POST code 240 bytes](https://github.com/Nuvoton-Israel/nuvoton-ipmi-oem)
* [706133] [BIOS POST code no respond](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/state/phosphor-post-code-manager/0001-delay-serialize.patch)
* [706554] [MAC address missing after BMC FW update](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/network/phosphor-network/0001-suuport-sync-mac-from-eeprom.patch)
* [707368] [SEL should not be cleared after BMC reboot](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/conf/machine/scm-npcm845.conf#L56)
* [707379] [IPMI Warm Reset support](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0009-implement-warm-reset-command.patch)
* [707328] [IPMI Get System GUID support](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0010-get-system-guid-command.patch)
* [708348] [708713] [711961] [711077] [711605] [Sensor name not correct](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/configuration/entity-manager/aurea-hpm.json#L1619)
* [708593] [session info should have the console mac address](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0018-Add-session-RemoteMACAddress-support.patch)
* [708012] [708786] [Session handle ID should be unique](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0015-Fix-seesion-handle-duplicated.patch)
* [708356] [SEL should log Clear SEL](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0014-Add-SEL-event-after-SEL-clear.patch)
* [708116] [IPMI add SEL command](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0004-Add-SEL-add-command.patch)
* [711506] [Uboot can't get DHCP IP](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-bsp/u-boot/u-boot-nuvoton/0005-net-phy-realtek-rtl8211f-introduce-phy_reset.patch)
* [711488] [sensor reading of CP](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/sensors/dbus-sensors/0010-add-sesnor-max16550.patch)
* [711263] [sensor reading of "Temp_OCP_NIC"](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/sensors/dbus-sensors/0007-add-nic-temp-sensor.patch)
* [711301] [BMC utilization sensors nameing](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/health/files/0001-change-the-cpu-sensor-name-from-CPU-to-CPU_Utilizati.patch)
* [712909] [BMC cannot recognize OEM SEL](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0023-add-oem-sel-support.patch)
* [712103] [IPMI Get Sensor Type incorrect](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0008-Add-sensor-type-command.patch)
* [713710] [IPMI Get Channel Authentication Capabilities](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0019-add-server-type-and-oem-id-to-meet-MS-spec.patch)
* [713949] [BMC Console print error message in idle](https://github.com/Nuvoton-Israel/linux/tree/NPCM-5.10-OpenBMC)
* [713972] [IPMI command- Master Muxed-Write-Read](https://github.com/Nuvoton-Israel/nuvoton-ipmi-oem)
* [713830] [IPMI command- Master Phase Write Read](https://github.com/Nuvoton-Israel/nuvoton-ipmi-oem)
* [713720] [IPMI command- Set Channel Security Keys](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0026-set-channel-security-keys.patch)
* [713984] [IPMI command- Set SEL Time](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0011-Add-SEL-time-set-command.patch)
* [713048] [IPMI command- Get Sensor Reading Factors](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0022-add-sensor-reading-factory-support.patch)
* [714971] [Get Chassis Status IPMI command is incorrect](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0027-implement-chassis-acfail-status.patch)
* [714509] [Unable to set the real time clock](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/settings/phosphor-settings-manager/time-sync.override.yml)
* [715605] [715800] [IPMI command-Set System Boot Options](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-v2.11/meta-evb/meta-evb-nuvoton/meta-scm-npcm845/recipes-phosphor/ipmi/phosphor-ipmi-host/0025-save-no-supported-boot-options.patch)
