# [Setup Guide] Using Poleg Buv-Runbmc Board with phosphor-power to Monitor Power Supply Unit (PSU)

#### Version 1.0 | 25 April 2023

# Table of Contents
- [Introduction](#introduction)
  * [BUV and RunBMC card](#buv-and-runbmc-card)
  * [phosphor-power](#phosphor-power)
- [Setup](#setup)
  * [Get Source Code and Build Image](#get-source-code-and-build-image)
  * [Kernel](#kernel)
    + [Driver](#driver)
    + [DTS](#dts)
  * [Modify phosphor-power Related Setting](#modify-phosphor-power-related-setting)
  * [Add Debug Log](#add-debug-log)
  * [Add dummy Fan Fault](#add-dummy-fan-fault)
- [Inventory-Manager - Monitor & Test PSU](#inventory-manager-monitor-&-test-PSU)
  * [Start phosphor-power daemon](#start-phosphor-power-daemon)
  * [Check PSU DBus Object](#check-psu-dbus-object)
  * [Check Basic PSU Status via WebUI and Redfish](#check-basic-psu-status-via-webui-and-redfish)
  * [Check Dummy Fan Fault Status](#check-dummy-fan-fault-status)
- [Entity-Manager - Monitor & Test PSU](#entity-manager-monitor-&-test-psu)
  * [Different files used in Entity-Manager](#different-files-used-in-entity-manager)
  * [Status of phosphor-power daemon](#status-of-phosphor-power-daemon)
  * [Check PSU DBus Object](#check-psu-dbus-object)
  * [Check PSU Information](#check-psu-information)
- [Add Two PSUs](#add-two-psus)
- [PSU Hot Plug](#psu-hot-plug)
  * [PSU Hot Plug Related Setting](#psu-hot-plug-related-setting)
  * [PSU Hot Plug Call flow](#psu-hot-plug-call-flow)
  * [PSU Hot Plug Test](#psu-hot-plug-test)
- [PowerShelves Related Redfish Schema Implementation](#powershelves-related-redfish-schema-implementation)
  * [Use chassis String as PowerDistributionId](#use-chassis-string-as-powerdistributionId)
  * [Use a number String as PowerDistributionId](#use-a-number-string-as-[owerdistributionId)
- [Reference](#reference)

## Implementation List of Redfish API


### Use chassis String as PowerDistributionId

### /redfish/v1/Chassis/{ChassisId}/PowerSubsystem/PowerSupplies/{PowerSupplyId}

### /redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies/{PowerSupplyId}

### Use number String as PowerDistributionId

# Introduction

This document guides how to connect BUV-Runbmc module to one PSU or more PSUs and using phosphor-power daemon monitor these PSU. Including add dummy PSU fault to observe the error log via WebUI and Redfish.

## BUV and RunBMC card

Here is a quick setup guide which descripts more about BUV-Runbmc module hardware, usage, emergency BMC FW update, …, etc.

* [HSBUV_Nuvoton_NPCM7XX_RunBMC_Setup_Guide.pdf](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-master/meta-evb/meta-evb-nuvoton/meta-buv-runbmc/HSBUV_Nuvoton_NPCM7XX_RunBMC_Setup_Guide.pdf)

If there are further questions about BUV-Runbmc or Poleg BMC, please consult your Nuvoton contact window.

Before you starting test the following step, we recommend you follow this quick setup guide to get one build pass result. The source code on Nuvoton Github is under build testing every day. If you get build fail result, it might be your build machine is not powerful enough or due to another reasons. You should solve it at the beginning.

## phosphor-power

The Nuvoton phosphor-power daemon is implemented base on IBM phosphor-power daemon.

Nuvoton divides this daemon to inventory-manager and entity-manager which means when you build inventory-manager image or entity-manager image, this phosphor-power daemon both works fine. In this setup guide, we will describe how to set phosphor-power related files, psu.json, service configuration,…,etc.

The features of phosphor-power daemon:

- Monitor more than one PSU.
- Read string from sysfs files and pass these string to specific DBus interface.
- Polling PSU status\_word per second(default).
- If fault occurs (status\_word != 0), do further check to analyze which PSU faults occur, then log these PSU faults to journal and Redfish.

# Setup
Here are some steps that you need to check based on the real situation of the PSU you are using.

## Get Source Code and Build Image

Refer:
* [HSBUV_Nuvoton_NPCM7XX_RunBMC_Setup_Guide.pdf](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-master/meta-evb/meta-evb-nuvoton/meta-buv-runbmc/HSBUV_Nuvoton_NPCM7XX_RunBMC_Setup_Guide.pdf)

## Kernel
### Driver
You should enable your PSU driver, here we take inspur-ipsp.c as an example. You are able to refer it to enable your own PSU driver.

Enable this driver in buv-runbmc.cfg
    
     CONFIG_SENSORS_INSPUR_IPSPS=y

### DTS
Here is an example that PSU connected to i2c bus 2, address 0x58.

You have to put you kernel patch under this folder:
    
     ../meta-evb/meta-evb-nuvoton/meta-buv-runbmc/recipes-kernel/linux/linux-nuvoton/0009-Add-buv-runbmc-PSU-driver-inspur-ipsps.c.patch

And modify the bbappend file:
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_1_kernel_bbappend.png">
* [0009-Add-buv-runbmc-PSU-driver-inspur-ipsps.c.patch](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-master/meta-evb/meta-evb-nuvoton/meta-buv-runbmc/recipes-kernel/linux/linux-nuvoton/0009-Add-buv-runbmc-PSU-driver-inspur-ipsps.c.patch)

After building image successfully, you are able to see your dts setting in:
    
     ../build/buv-runbmc/tmp/work-shared/buv-runbmc/kernel-source/arch/arm/boot/dts/nuvoton-npcm750-buv-runbmc.dts

    &i2c2 {
	status = "okay";
	power-supply@58 {
		compatible = "inspur,ipsps1";
		reg = <0x58>;
	};
};

## Modify phosphor-power Related Setting
Refer:
* [phosphor-power](https://github.com/openbmc/phosphor-power)

The phosphor-power daemon need the setting in psu.json to run. The JSON configuration file provide information for:
- Where to access the pmbus attributes
- Which attribute file in pmbus maps to which property and interface in D-Bus
- Which kernel device directory is used on which PSU

For example, we connect a PSU(powersupply0) to I2C bus 2 and address is 0x58, the sysfs type is hwmon, you could check the kernel device dir as following:

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_2_PSU_hwmon.png">
    
Move to "/sys/bus/i2c/devices" path and use "ls -al" command to check yor device is linked to correct path.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_3_PSU_dev_path.png">

And the psu.json should be set as:
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_4_psu_json.png">

## Add Debug Log
If you need to add debug log in phosphor-power source code, e.g. power\_supply.cpp, you could use the "log\<level::ERR\>" function then using "journalctl" to print these debug log.

Print string:
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_5_add_log1.png">

Print string and variable(inventoryPath):
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_6_add_log2.png">

Command:

     $ journalctl | grep power_supply
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_6_add_log3.png">

## Add dummy Fan Fault
You could follow this patch to force set the status\_word as "FAN\_FAULT" and observe the phosphor-power actions when fan fault occurs.

[0004-Fan-fault-test.patch](https://github.com/Nuvoton-Israel/openbmc/blob/npcm-master/meta-evb/meta-evb-nuvoton/meta-buv-runbmc/recipes-buv-runbmc/power/phosphor-power/0004-Fan-fault-test.patch)

# Inventory-Manager - Monitor & Test PSU
## Start phosphor-power daemon

The power-supply-monitor\@#.service is the service which starts phosphor-power daemon. The instance is the PSU number you are using.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_7_power_supply_service.png">

For example, you are using PSU0, then you could use this command to start monitoring:

     $ systemctl start power-supply-monitor\@0.service

Then, you are able to check if the status is active or not:

     $ systemctl status power-supply-monitor\@0.service

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_8_power_supply_service_status.png">

## Check PSU DBus Object
After starting phosphor-power daemon, it will create a PSU DBus object, if everything works fine (driver, daemon…etc.) you are able to see your PSU information in this DBus object:

E.g. you are using a PSU (powersupply0)

     $ busctl introspect xyz.openbmc\_project.Inventory.Manager /xyz/openbmc\_project/inventory/system/chassis/motherboard/powersupply0

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_9_powersupply0_DBus_obj.png">

## Check Journal Log

     $ journalctl | grep psu-monitor

In default, the polling time is one second:

     ../openbmc/build/olympus-nuvoton/tmp/work/armv7a-openbmc-linux-gnueabi/phosphor-power/1.0+gitAUTOINC+bb54ba3a74-r1/git/power-supply/main.cpp

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_10_polling_time.png">

You could modify this setting according to your requirement. E.g. 500 ms

## Check Basic PSU Status via WebUI and Redfish
You are able to see the PSU information on WebUI page and Redfish url.

WebUI:

     https://\<BMC IP\>/#/hardware-status/inventory

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_11_webui_psu.png">

Redfish:

     https://\<BMC IP\>/redfish/v1/Chassis/motherboard/Power

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_12_redfish_psu.png">

## Check Dummy Fan Fault Status
If you enable **[2.5 Add dummy Fan Fault]**, you are able to check these log as following:

In inventory-manager image with phosphor-power, we use DBus event log creation, which will create a log entry, so that you could see this log via this entry.

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_13_add_dbus_log.png">

### Log File
     $ cat /var/lib/phosphor-logging/errors/1

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_14_add_dbus_log_result_file.png">

### Redfish
     https://\<BMC IP\>/redfish/v1/Systems/system/LogServices/EventLog/Entries

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_15_add_dbus_log_result_redfish.png">

### WebUI
     https://\<BMC IP\>/#/logs/event-logs

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_16_add_dbus_log_result_webui.png">

# Entity-Manager - Monitor & Test PSU
Using different launch build option to trigger monitor-em in phosphor-power and redfish-bmc-journal in bmcweb:

     $ DISTRO=buv-entity bitbake obmc-phosphor-image

Below sections show only the results of PSU0, including different files between inventory-manager and entity-manager, the status of service, DBus object information, PSU information, and dummy fan fault log.

## Different files used in Entity-Manager

| **Inventory-Manager** | **Entity-Manager** |
| --- | --- |
| psu.json | psu\_em.json |
| power-supply-monitor@.service | power-supply-monitor-em@.service |
| power-supply-monitor-%i.conf | power-supply-monitor-em-%i.conf |

## Status of phosphor-power daemon

     $ systemctl status power-supply-monitor-em@0.service

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_17_power-supply-monitor-em_service_status.png">

## Check PSU DBus Object

     $ busctl introspect xyz.openbmc\_project.EntityManager /xyz/openbmc\_project/inventory/system/powersupply/powersupply0

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_18_EM_powersupply0_DBus_obj.png">

## Check PSU Information
### WebUI
     
     https://\<BMC IP\>/#/hardware-status/inventory

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_19_EM_PSU_webui.png">

### Redfish
     
     https://\<BMC IP\>/ redfish/v1/Chassis/\<BoardName\>/Power

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_20_EM_PSU_redfish.png">

## Check Dummy Fan Fault Journal Log
     
In entity-manager with phosphor-power, we use journal based event log. Which means this log will be sent to journal first, then rsyslog daemon collect redfish related logs and stores to /var/log/redfish file.

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_21_EM_add_journal_log.png">

### Log File Location
    $ cat /var/log/redfish

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_22_EM_add_journal_log_result_file.png">

### WebUI
    https://\<BMC IP\>/#/logs/event-logs

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_24_EM_add_journal_log_result_webui.png">

### Redfish
    https://\<BMC IP\>/redfish/v1/Systems/system/LogServices/EventLog/Entries

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_25_EM_add_journal_log_result_redfish.png">

# Add Two PSUs

If you want to add more PSUs, you need to add some settings for these PSUs.  
For example:  
PSU0, connect to i2c bus 1, address is 0x5a  
PSU1, connect to i2c bus 1, address is 0x5b  
  
First, you need to modify the DTS to set PSU driver and PSU address on i2c bus 1 node.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_52_two_psu_dts.png">
  
Second, modify buv-runbmc.conf, the OBMC_POWER_SUPPLY_INSTANCES should be "0 1", means PSU0 and PSU1.  
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_51_two_psu_instance.png">
  
Third, set sysfs path in psu.json for PSU0(powersupply0) and PSU1(powersupply1) in psu.json.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_48_two_psu_json.png">
  
Forth, set PSU address in power-supply-monitor-*.conf.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_49_psu0_conf.png">
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_50_psu1_conf.png">
  
Then, the PSU0 and PSU1 should work fine, you are able to see these two PSUs on WebUI/Redfish/DBus.
## Two PSUs info
|  | **Inventory-Manager** | **Entity-Manager** |
| --- | --- | --- |
| **Dbus** | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_IM_psu_dbus.png"> | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_EM_psu_dbus.png">  |
| **ipmitool sdr** | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_IM_ipmitool_sdr.png"> | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_EM_ipmitool_sdr.png"> |
| **WebUi sensors** | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_IM_webui_sensors.png"> | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_EM_webui_sensors.png"> |
| **Redfish** | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_IM_redfish.png"> | <img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/buv_two_psu_EM_redfish.png"> |
  
# PSU Hot Plug
This feature is based on phosphor-gpio-monitor. When the PSU is removed/inserted, the PSU present pin state is low-to-high/hight-to-low. We monitor the PSU present pin state to implement PSU hot plug actions, including WebUI/Redfish logs, unbind/bind PSU driver, switch Present/Functional property of PSU DBus interface. The flow of inventory-manager/entity-manager PSU hot plug is the same basically, only need to notice the senor relatedd part and DBus interface, we will descript it in the following.

## PSU Hot Plug Related Setting

### BUV-GpioMonitorConfig.json
Refer:
* [phosphor-gpio-monitor](https://github.com/openbmc/phosphor-gpio-monitor)  
     **Name:** Name of gpio for reference.  
     **LineName:** this is the line name defined in device tree for specific gpio  
     **GpioNum:** GPIO offset, this field is optional if LineName is defined.  
     **ChipId:** This is device name either offset ("0") or complete gpio device ("gpiochip0"). This field is not required if LineName is defined.  
     **EventMon:** Event of gpio to be monitored. This can be "FALLING", "RISING" OR "BOTH". Default value for this is "BOTH".  
     **Target:** This is an optional systemd service which will get started after triggering event. A journal entry will be added for every event occurs irrespective of this definition.  
     **Targets:** This is an optional systemd service which will get started after triggering corresponding event(RASING or FALLING). A journal entry will be added for every event occurs irrespective of this definition.  
     **Continue:** This is a optional flag and if it is defined as true then this gpio will be monitored continously. If not defined then monitoring of this gpio will stop after first event.  

In BUV-GpioMonitorConfig.json, we use GPIO pin 4 as dummy PSU0 present pin.   
BUV-GpioMonitorConfig.json for entity-manager:  
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_33_BUV-GpioMonitorConfig.-EM_json.png">  
BUV-GpioMonitorConfig.json for inventory-manager:  
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_34_BUV-GpioMonitorConfig.-IM_json.png">

Basically, these two json files are the same, the difference is because of:
1. The sensor services are different, so the "FALLING" and "RISING" call different services.
2. DBus interface is different, so the setting of "Inventory" is case by case.

### psu_hotplug_action.sh
When the "Targets" service is called, the script will execute corresponding  command to reload/start/stop sensor service.

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_46_psu_hotplug_action.sh.png">
  
This is psusensor_reload.service, it will call psu_hotplug_action.sh with a parameter.   
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_32_psusensor_reload.service.png">

## PSU Hot Plug Call flow
As following flow chart, the PSU hot plug flow are:  
1. phosphor-gpio-monitor monitor the gpio siginal and trigger the PSU hot plug process.
2. phosphor-gpio-monitor will set the "Present" property of PSU DBus interface and start pre-define service according to the rising/falling..
3. phosphor-power detects the "Present" property is changed, bind/unbind PSU driver, record log
4. If you are using entity-manager image, reload psusensor service.

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_31_EM_call_flow.png">

# PSU Hot Plug Test
Here we insert two PSUs and use PSU0 as PSU hot plug example.   
For test, we use "MB P12V INA219*" as PSU0 sensors, "MB P3V3 INA219*" as PSU1 sensors.  
If PSU is removed, the related sensor will disapear.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_27_IM_webui_hot_plug_sensor_init.png">


## Initial state
 
If you add two PSUs as example [Add two PSUs](#add-two-psus), you will see these two PSU on WebUI as following.  
ID 0 is PSU0, ID 1 is PSU1.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_26_IM_webui_psu_hot_plug_init.png">
  
You are able to see the powersupply0 and powersupply1 on Redfish.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_28_IM_redfish_hot_plug_psu_init.png">
  
Use Dbus command and you will see the "Present", "Functional" property is true.  

    busctl introspect xyz.openbmc_project.Inventory.Manager /xyz/openbmc_project/inventory/system/chassis/motherboard/powersupply0
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_29_IM_dbus_hot_plug_psu_init.png">  
  
Move to "/sys/bus/i2c/driver/<your PSu driver>", you are able to see PSU0 (1-005a) and PSU1 (1-005b)  
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_30_IM_driver_hot_plug_psu_init.png">

## GPIO Setting For Dummy PSU Present Pin
1. Set gpio 5 as output pin.  
    ```echo 5 > /sys/class/gpio/export```  
    ```echo out > /sys/class/gpio/gpio5/direction``` 

2. Connect BUV J712 pin4(GPIO5) and pin8(GPIO4), so that we cann use command to simulate GPIO4(PSU0 present pin) rising/falling.  
```echo 0 > /sys/class/gpio/gpio5/value```  
```echo 1 > /sys/class/gpio/gpio5/value```

## PSU Remove test - Inventory-Manager
Use command "echo 1" to "/sys/class/gpio/gpio5/value", to simulate PSU0 present pin rising, means PSU0 removed.  
```echo 1 > /sys/class/gpio/gpio5/value```

The PSU0 driver unbind (1-005a).  
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_38_IM_PSU0_driver_unbind.png">  

The "Present" and "Functional" property is set false.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_39_IM_dbus_hot_plug_psu_removed.png">

You are able to see the PSU removed log in log file.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_40_IM_psu_removed_log_file.png">

On WebUI, PSU 0 is disappear.
<img align="top" width="%" src=https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_43_IM_psu_removed_webui_inventory.png">

On WebUI, you are able to see the PSU removed log.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_42_IM_psu_removed_webui_log.png">

On WebUI, PSU0 related sensors (MB P12V INA219*) are disappear.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_41_IM_psu_removed_webui_sensor.png">

On Redfish,  powersupply0 is disappear.  

     https://<BMC IP>/redfish/v1/Managers/bmc/LogServices/Journal/Entries
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_47_psu_removed_redfish.png">

Also, you are able to see the PSU removed log on Redfish.  
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_44_IM_psu_removed_redfish_log.png">

## PSU Insert test - Inventory-Manager
Use command "echo 0" to "/sys/class/gpio/gpio5/value", to simulate PSU0 present pin falling, means PSU0 insert.  
```echo 0 > /sys/class/gpio/gpio5/value```

You will see the "Present" and "Functionl" is set to true in PSU0 DBus interface.  
PSU0 driver bind and there is a PowerSupplyInsert log in log file.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_45_IM_psu_installed.png">

On the WebUI, the PSU0 appear again, and also there is a PowerSupplyInserted log.  
And same as Redfish.
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_45_IM_psu_installed_webui_redfish.png">

## PSU Initial - Entity-Manager
The PSU hot plug test steps/result of entity-manager is the same as inventory-manager.  
Using commands to echo 0/1 to gpio5 value to simulate gpio5 falling/rising.  
```echo 0 > /sys/class/gpio/gpio5/value```  
```echo 1 > /sys/class/gpio/gpio5/value```  

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_35_EM_initial_state.png">

## PSU Remove test - Entity-Manager
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_37_EM_PSU0_removed.png">

## PSU Insert test - Entity-Manager
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/BUV_phosphor-power_36_EM_PSU0_installed.png">


# PowerShelves Related Redfish Schema Implementation
For powershelf products, we refer latest(DSP2046_2023.1) Redfish schema to implement some Redfish API for powershelf. In these API, we are able to see the data/information of each PSUs which are installed in a powershelf.

Please refer following commit of our implementations:

https://github.com/Nuvoton-Israel/openbmc/commit/d13699f523596cb2d9ee028a134dbbd6f81da1a2  
https://github.com/Nuvoton-Israel/openbmc/commit/76e8aabbe28e19830266fd0e6aa64126f92b485e  
https://github.com/Nuvoton-Israel/openbmc/commit/a5aeabe697c1a9986a07744ccee4dbc0b890fa45  
https://github.com/Nuvoton-Israel/openbmc/commit/4f5a4f49e3af5330c0e9a40f4ed0554f36a64cc0  
https://github.com/Nuvoton-Israel/openbmc/commit/307512dd664353b21e4343fa22ca4c40c9fa7e69  


## Implementation List of Redfish API
The power supply is a major component of a powershelf.
In DSP2046_2023.1, power supply data are collected and be linked to properties of PowerSubsystem and PowerEquipment.

6.97 PowerSupply 1.5.1, descript PowerSupply schema:

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_1.PNG">

The URLs and examples as following:
### Use chassis String as PowerDistributionId

### /redfish/v1/Chassis/{ChassisId}/PowerSubsystem/PowerSupplies/{PowerSupplyId}
/redfish/v1/Chassis/{ChassisId}/PowerSubsystem

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_3.PNG">

/redfish/v1/Chassis/{ChassisId}/PowerSubsystem/PowerSupplies
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_4.PNG">

/redfish/v1/Chassis/{ChassisId}/PowerSubsystem/PowerSupplies/{PowerSupplyId}
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_5.PNG">

### /redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies/{PowerSupplyId}
/redfish/v1/PowerEquipment

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_6.PNG">

/redfish/v1/PowerEquipment/PowerShelves

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_7.PNG">

/redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_8.PNG">

/redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/Metrics

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_9.PNG">

/redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_10.PNG">

/redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies/{PowerSupplyId}

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_11.PNG">

/redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies/{PowerSupplyId}/Metrics

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_16.PNG">

### Use a number String as PowerDistributionId
On DMTF official web page, there is an example that uses a number string as PowerDistributionId. We also refer it to implement the following URLs:
<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_2.PNG">

redfish/v1/PowerEquipment/PowerShelves

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_12.PNG">

redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_13.PNG">

redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/Metrics

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_13.PNG">

redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies/{PowerSupplyId}

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_14.PNG">

redfish/v1/PowerEquipment/PowerShelves/{PowerDistributionId}/PowerSupplies/{PowerSupplyId}/Metrics

<img align="top" width="%" src="https://raw.githubusercontent.com/NTC-CCBG/snapshots/master/openbmc/PSU_redfish_17.PNG">

# Reference
### [phosphor-power](https://github.com/openbmc/phosphor-power)
### [phosphor-logging](https://github.com/openbmc/phosphor-logging)
### [phosphor-gpio-monitor](https://github.com/openbmc/phosphor-gpio-monitor)
### [phosphor-bmc-code-mgmt](https://github.com/openbmc/phosphor-bmc-code-mgmt)
### Redfish Resource and Schema Guide - DSP2046_2023_1
### [openbmc-bmcweb GitHub](https://github.com/openbmc/bmcweb/tree/master)
