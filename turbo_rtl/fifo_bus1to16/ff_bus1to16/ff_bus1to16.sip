set_global_assignment -entity "ff_bus1to16" -library "lib_ff_bus1to16" -name IP_TOOL_NAME "QsysPrimePro"
set_global_assignment -entity "ff_bus1to16" -library "lib_ff_bus1to16" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "ff_bus1to16" -library "lib_ff_bus1to16" -name IP_TOOL_ENV "QsysPrimePro"
set_global_assignment -library "lib_ff_bus1to16" -name SPD_FILE [file join $::quartus(sip_path) "ff_bus1to16.spd"]
set_global_assignment -library "lib_ff_bus1to16" -name MISC_FILE [file join $::quartus(sip_path) "../ff_bus1to16.qsys"]

set_global_assignment -library "lib_ff_bus1to16" -name MISC_FILE [file join $::quartus(sip_path) "sim/ff_bus1to16.v"]
set_global_assignment -library "lib_ff_bus1to16" -name MISC_FILE [file join $::quartus(sip_path) "fifo_151/sim/ff_bus1to16_fifo_151_4q2xupy.v"]
set_global_assignment -library "lib_ff_bus1to16" -name MISC_FILE [file join $::quartus(sip_path) "fifo_151/sim/ff_bus1to16_fifo_151_4q2xupy.sdc"]
