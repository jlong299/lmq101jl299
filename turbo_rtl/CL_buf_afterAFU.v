//-----------------------------------------------------------------
// Module Name:        	CL_buf_afterAFU.v
// Project:             data flow framework of AFU on Xeon+FPGA platform
// Description:         CL buffer after AFU
// Author:				Long Jiang
//------------------------------------------------------------------
//  Version 1.2
//  2016-10-12
//
//  ff is abbreviation of fifo
//  ---------------------------------------------------------------------------
//     source_ready   <-- |     CL_buf_afterAFU   | -->  ff_rd_ready
//     ff_data        --> |                       | <--  ff_rdreq 
//     ff_wrreq       --> |                       | -->  CL out
//     ff_wr_finish   --> |                       | <--  ff_rd_finish
//  ---------------------------------------------------------------------------


module CL_buf_afterAFU #(parameter  // CL : cache line
		CL =512,  // 512 bits
		w_NumOfCL_inBuf = 10  // width of max number of CLs in fifo
	)
	(
	// left side
	input 					rst_n_sync,  // clk Synchronous reset active low
	input 					clk,   

	output reg				sink_ready, 	
	input	 				ff_wrreq, 		
	input  [CL-1:0] 		ff_data,  		
	input 					ff_wr_finish,  

	// right side
	output	reg				ff_rd_ready, 	// fifo has got one AFU frame, ready to source
	input 					ff_rdreq, 		// fifo rdreq
	output	 [CL-1:0] 		ff_q,  			// fifo out 
	input 					ff_rd_finish,   // fifo rd finished (fifo_empty == 1)

	// sideband signals
	output reg [w_NumOfCL_inBuf-1 : 0]   sb_len	// amount of CLs in fifo(one AFU frame)
	);


reg [1:0]   	fsm;
reg [w_NumOfCL_inBuf-1 : 0] 	NumOfCL_inBuf;
 
always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		fsm <= 0;
		sink_ready <= 0;
		ff_rd_ready <= 0;
	end
	else
	begin
		case(fsm)
		2'd0:
		begin
			fsm <= (ff_wrreq) ? 2'd1 : 2'd0;
			sink_ready <= 1'b1;
			ff_rd_ready <= 0;
		end
		2'd1:
		begin
			fsm <= (ff_wr_finish) ? 2'd2 : 2'd1;
			sink_ready <= 1'b1;
			ff_rd_ready <= 0;
		end
		2'd2:
		begin
			fsm <= (ff_rd_finish) ? 2'd0 : 2'd2;
			sink_ready <= 1'b0;
			ff_rd_ready <= 1'b1;
		end
		default:
		begin
			fsm <= 0;
			sink_ready <= 0;
			ff_rd_ready <= 0;
		end
		endcase
	end
end

// Depth : 64
ff_CL_buf_afterAFU
inst_ff_CL_buf_afterAFU(
		.data   (ff_data),
		.wrreq  (ff_wrreq),
		.rdreq  (ff_rdreq),
		.clock  (clk),
		.sclr   (!rst_n_sync),
		.q      (ff_q    ),
		.full   ( ),
		.empty  ( )
	);

always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		NumOfCL_inBuf <= 0;
		sb_len <= 0;
	end
	else
	begin
		if (fsm==2'd2)
			NumOfCL_inBuf <= 0;
		else
			NumOfCL_inBuf <= (ff_wrreq) ? NumOfCL_inBuf+1'd1 : NumOfCL_inBuf;

		sb_len <= (ff_wr_finish==1'b1 && fsm==2'd1) ? NumOfCL_inBuf : sb_len;
	end
end




endmodule