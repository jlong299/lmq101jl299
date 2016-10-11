// ff_CL_buf_preAFU.v

// Generated using ACDS version 15.1 185

`timescale 1 ps / 1 ps
module ff_CL_buf_preAFU (
		input  wire [511:0] data,  //  fifo_input.datain
		input  wire         wrreq, //            .wrreq
		input  wire         rdreq, //            .rdreq
		input  wire         clock, //            .clk
		input  wire         sclr,  //            .sclr
		output wire [511:0] q,     // fifo_output.dataout
		output wire         full,  //            .full
		output wire         empty  //            .empty
	);

	ff_CL_buf_preAFU_fifo_151_56ipsny fifo_0 (
		.data  (data),  //  fifo_input.datain
		.wrreq (wrreq), //            .wrreq
		.rdreq (rdreq), //            .rdreq
		.clock (clock), //            .clk
		.sclr  (sclr),  //            .sclr
		.q     (q),     // fifo_output.dataout
		.full  (full),  //            .full
		.empty (empty)  //            .empty
	);

endmodule