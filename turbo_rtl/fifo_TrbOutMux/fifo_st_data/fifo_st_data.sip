set_global_assignment -entity "fifo_st_data" -library "lib_fifo_st_data" -name IP_TOOL_NAME "QsysPrimePro"
set_global_assignment -entity "fifo_st_data" -library "lib_fifo_st_data" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "fifo_st_data" -library "lib_fifo_st_data" -name IP_TOOL_ENV "QsysPrimePro"
set_global_assignment -library "lib_fifo_st_data" -name SPD_FILE [file join $::quartus(sip_path) "fifo_st_data.spd"]
set_global_assignment -library "lib_fifo_st_data" -name MISC_FILE [file join $::quartus(sip_path) "../fifo_st_data.qsys"]

set_global_assignment -library "lib_fifo_st_data" -name MISC_FILE [file join $::quartus(sip_path) "sim/fifo_st_data.v"]
set_global_assignment -library "lib_fifo_st_data" -name MISC_FILE [file join $::quartus(sip_path) "fifo_151/sim/fifo_st_data_fifo_151_xtsoi5y.v"]
