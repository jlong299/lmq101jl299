//-----------------------------------------------------------------
// Module Name:        	CL_buf_preAFU.v
// Project:             data flow framework of AFU on Xeon+FPGA platform
// Description:         parallel data bus buffer ( bus = CL  512 bits)
// Author:				Long Jiang
//------------------------------------------------------------------
//  Version 1.2
//  Description : CL(cache line) buffer pre AFU
//  2016-10-05
//
//  ff is abbreviation of fifo
//  ---------------------------------------------------------------------------
//        CL in --> | CL_head_analysis  -->  FIFO | -->  ff_rd_ready
//   sink_ready <-- |                             | <--  ff_rdreq 
//                  |                             | -->  CL out
//                  |                             | <--  ff_rd_finish
//  ---------------------------------------------------------------------------


module CL_buf_preAFU #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		//w_NumOfCL_in_AFUFrm =11,  // width of maximum Number of CLs in one AFU frame
		w_NumOfST_in_AFUFrm =16  // width of maximum Number of STs in one AFU frame
	)
	(
	// left side   
	input 					rst_n,  // clk Asynchronous reset active low
	input 					clk,    

	output					sink_ready,
	input [CL-1:0]			sink_data,
	input					sink_valid,  

	// right side
	output					ff_rd_ready, 	// fifo has got one AFU frame, ready to source
	input 					ff_rdreq, 		// fifo rdreq
	output	 [CL-1:0] 		ff_q,  			// fifo out 
	input 					ff_rd_finish,   // fifo rd finished (fifo_empty == 1)

	// sideband signals, optional
	output [w_NumOfST_in_AFUFrm-1 : 0]   	sb_len	// length of AFU frame by ST
	
);

reg 	rst_n_r, rst_n_sync;
wire 	ff_wrreq;
wire [CL-1:0] 	ff_data;
//---------  reset sync ------------
always@(posedge clk)
begin
	rst_n_sync <= rst_n_r;
	rst_n_r <= rst_n;
end

//start---------- PART1 :  CL_head_analysis ------------
CL_head_analysis #(
	.CL (512),  // 512 bits
	.CL_HEAD (16),  // 16 bits
	.CL_PAYLOAD (496), // 496 bits
	.w_NumOfST_in_AFUFrm (16)  // width of maximum Number of STs in one AFU frame
	)
inst_CL_head_analysis (
	.rst_n_sync		(rst_n_sync),
	.clk 			(clk),
	.sink_ready 	(sink_ready),
	.sink_data 		(sink_data),
	.sink_valid 	(sink_valid),
	.ff_rd_ready 	(ff_rd_ready),
	.source_data 	(ff_data),
	.source_valid 	(ff_wrreq),
	.ff_rd_finish 	(ff_rd_finish),
	.sb_len 		(sb_len)
	);

//start---------- PART2 :  CL buffer instantiated as fifo ------------
// Depth : 256
ff_CL_buf_preAFU
inst_ff_CL_buf_preAFU(
		.data   (ff_data),
		.wrreq  (ff_wrreq),
		.rdreq  (ff_rdreq),
		.clock  (clk),
		.sclr   (!rst_n_sync),
		.q      (ff_q    ),
		.full   ( ),
		.empty  ( )
	);



endmodule