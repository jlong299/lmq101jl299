set_global_assignment -entity "cnst_rom" -library "lib_cnst_rom" -name IP_TOOL_NAME "QsysPrimePro"
set_global_assignment -entity "cnst_rom" -library "lib_cnst_rom" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "cnst_rom" -library "lib_cnst_rom" -name IP_TOOL_ENV "QsysPrimePro"
set_global_assignment -library "lib_cnst_rom" -name SPD_FILE [file join $::quartus(sip_path) "cnst_rom.spd"]
set_global_assignment -library "lib_cnst_rom" -name MISC_FILE [file join $::quartus(sip_path) "../cnst_rom.qsys"]

set_global_assignment -library "lib_cnst_rom" -name MISC_FILE [file join $::quartus(sip_path) "sim/cnst_rom.v"]
set_global_assignment -library "lib_cnst_rom" -name MISC_FILE [file join $::quartus(sip_path) "rom_1port_151/sim/cnst_rom_rom_1port_151_5e6juei.v"]
