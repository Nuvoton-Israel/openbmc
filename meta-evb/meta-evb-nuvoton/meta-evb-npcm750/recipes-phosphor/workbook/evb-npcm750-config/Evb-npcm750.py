## System states
##   state can change to next state in 2 ways:
##   - a process emits a GotoSystemState signal with state name to goto
##   - objects specified in EXIT_STATE_DEPEND have started
SYSTEM_STATES = [
]

FRU_INSTANCES = {
'<inventory_root>/system/chassis/motherboard/bmc' : { 'fru_type' : 'BMC','is_fru' : False, 'manufacturer' : 'NUVOTON' },
}

# I believe these numbers need to match the yaml file used to create the c++ ipmi map.
# the devices have types, but I don't believe that factors in here, I think these are
# just unique IDs.
ID_LOOKUP = {
    'FRU' : {},
    # The number at the end needs to match the FRU ID.
    # https://github.com/openbmc/skeleton/blob/master/pysystemmgr/system_manager.py#L143
    # The paramter for it is of type 'y' (unsigned 8-bit integer) presumably decimal?
    'FRU_STR' : {},
    'SENSOR' : {},
    'GPIO_PRESENT' : {}
}

GPIO_CONFIG = {}
GPIO_CONFIG['POWER_UP_PIN'] = { 'gpio_pin': '219', 'direction': 'out' }
GPIO_CONFIG['RESET_UP_PIN'] = { 'gpio_pin': '218', 'direction': 'out' }


# Miscellaneous non-poll sensor with system specific properties.
# The sensor id is the same as those defined in ID_LOOKUP['SENSOR'].

MISC_SENSORS = {

}

