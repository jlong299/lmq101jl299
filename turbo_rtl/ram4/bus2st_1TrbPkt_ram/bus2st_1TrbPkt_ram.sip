set_global_assignment -entity "bus2st_1TrbPkt_ram" -library "lib_bus2st_1TrbPkt_ram" -name IP_TOOL_NAME "QsysPrimePro"
set_global_assignment -entity "bus2st_1TrbPkt_ram" -library "lib_bus2st_1TrbPkt_ram" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "bus2st_1TrbPkt_ram" -library "lib_bus2st_1TrbPkt_ram" -name IP_TOOL_ENV "QsysPrimePro"
set_global_assignment -library "lib_bus2st_1TrbPkt_ram" -name SPD_FILE [file join $::quartus(sip_path) "bus2st_1TrbPkt_ram.spd"]
set_global_assignment -library "lib_bus2st_1TrbPkt_ram" -name MISC_FILE [file join $::quartus(sip_path) "../bus2st_1TrbPkt_ram.qsys"]

set_global_assignment -library "lib_bus2st_1TrbPkt_ram" -name MISC_FILE [file join $::quartus(sip_path) "sim/bus2st_1TrbPkt_ram.v"]
set_global_assignment -library "lib_bus2st_1TrbPkt_ram" -name MISC_FILE [file join $::quartus(sip_path) "ram_2port_151/sim/bus2st_1TrbPkt_ram_ram_2port_151_a364sna.v"]
