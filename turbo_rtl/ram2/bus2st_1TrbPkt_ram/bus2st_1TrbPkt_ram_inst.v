	bus2st_1TrbPkt_ram u0 (
		.data      (<connected-to-data>),      //  ram_input.datain
		.wraddress (<connected-to-wraddress>), //           .wraddress
		.rdaddress (<connected-to-rdaddress>), //           .rdaddress
		.wren      (<connected-to-wren>),      //           .wren
		.wrclock   (<connected-to-wrclock>),   //           .wrclock
		.rdclock   (<connected-to-rdclock>),   //           .rdclock
		.rden      (<connected-to-rden>),      //           .rden
		.q         (<connected-to-q>)          // ram_output.dataout
	);

