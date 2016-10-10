set_global_assignment -entity "ff_CL_buf_preAFU" -library "lib_ff_CL_buf_preAFU" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "ff_CL_buf_preAFU" -library "lib_ff_CL_buf_preAFU" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "ff_CL_buf_preAFU" -library "lib_ff_CL_buf_preAFU" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_ff_CL_buf_preAFU" -name SPD_FILE [file join $::quartus(sip_path) "ff_CL_buf_preAFU.spd"]
set_global_assignment -library "lib_ff_CL_buf_preAFU" -name MISC_FILE [file join $::quartus(sip_path) "../ff_CL_buf_preAFU.qsys"]

set_global_assignment -library "lib_ff_CL_buf_preAFU" -name MISC_FILE [file join $::quartus(sip_path) "sim/ff_CL_buf_preAFU.v"]
set_global_assignment -library "lib_ff_CL_buf_preAFU" -name MISC_FILE [file join $::quartus(sip_path) "fifo_151/sim/ff_CL_buf_preAFU_fifo_151_56ipsny.v"]
