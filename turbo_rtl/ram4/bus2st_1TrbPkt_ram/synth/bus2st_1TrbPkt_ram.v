// bus2st_1TrbPkt_ram.v

// Generated using ACDS version 15.1 193

`timescale 1 ps / 1 ps
module bus2st_1TrbPkt_ram (
		input  wire [511:0] data,      //  ram_input.datain
		input  wire [6:0]   wraddress, //           .wraddress
		input  wire [6:0]   rdaddress, //           .rdaddress
		input  wire         wren,      //           .wren
		input  wire         wrclock,   //           .wrclock
		input  wire         rdclock,   //           .rdclock
		input  wire         rden,      //           .rden
		output wire [511:0] q          // ram_output.dataout
	);

	bus2st_1TrbPkt_ram_ram_2port_151_a364sna ram_2port_0 (
		.data      (data),      //  ram_input.datain
		.wraddress (wraddress), //           .wraddress
		.rdaddress (rdaddress), //           .rdaddress
		.wren      (wren),      //           .wren
		.wrclock   (wrclock),   //           .wrclock
		.rdclock   (rdclock),   //           .rdclock
		.rden      (rden),      //           .rden
		.q         (q)          // ram_output.dataout
	);

endmodule
