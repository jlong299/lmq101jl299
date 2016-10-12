//-----------------------------------------------------------------
// Module Name:        	st2CL_afterAFU.v
// Project:             data flow framework of AFU on Xeon+FPGA platform
// Description:         ST to CL conversion
// Author:				Long Jiang
//------------------------------------------------------------------
//  Version 1.2
//  Description : ST to CL conversion after AFU
//  2016-10-12
//
//  ff is abbreviation of fifo
//  ---------------------------------------------------------------------------
//     sink_ready   <-- |     st2CL_afterAFU    | <-- source_ready
//     sink_ST      --> |                       | --> ff_data
//                      |                       | --> ff_wrreq,
//                      |                       | --> ff_wr_finish
//  ---------------------------------------------------------------------------
//
//  You can substitute this ST interface file with your customized interface file
//  like whatever2CL_afterAFU.v
//
//  Limitations:
//  1)  Currently only support continuous sink_valid
//  ---------------------------------------------------------------------------- 


module st2CL_afterAFU #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		ST2 =8, // st data width at output of AFU
		MaxNumOfST_inCL = 10'd41,   // the maximum allowed amount of STs in one CL
		w_len_CLHead =10 // width of 'length' part in CL head
	)
	(
	// left side
	input 					rst_n_sync,  // clk Synchronous reset active low
	input 					clk,    

	output reg				sink_ready,
	input [ST2-1 : 0]		sink_data,
	input 	 				sink_valid,
	input 	 				sink_sop,
	input 	 				sink_eop,

	//right side
	input					source_ready, 	
	output reg				ff_wrreq, 		
	output wire [CL-1:0] 	ff_data,  		
	output reg				ff_wr_finish   

	);

reg [1:0] 	fsm ;
reg [9:0] 	NumOfST_inCL;
reg 		sink_sop_delay;
reg [9:0] 	NumOfST_eop;
reg [CL-1+ST2:0] 			ff_data_PDOFI; //POF : Prevent Downwards Over Flow of Index.

assign 	ff_data = ff_data_PDOFI[CL-1+ST2:ST2];

always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		fsm <= 0;
		sink_ready <= 0;
	end
	else
	begin
		case (fsm)
		2'd0:
		begin
			fsm <= (source_ready) ? 2'd1 : 2'd0;
			sink_ready <= (source_ready) ? 1'b1 : 1'b0;
		end
		2'd1:
		begin
			fsm <= (sink_eop) ? 2'd2 : 2'd1;
			sink_ready <= (sink_eop) ? 1'b0 : 1'b1;
		end
		2'd2:
		begin
			fsm <= (ff_wr_finish) ? 2'd0 : 2'd2;
			sink_ready <= 1'b0;
		end
		default:
		begin
			fsm <= 0;
			sink_ready <= 1'b0;
		end
		endcase
	end
end

always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		NumOfST_inCL <= 10'd0;
		ff_wr_finish <= 0;
		ff_data_PDOFI <= 0;
		ff_wrreq <= 0;
		sink_sop_delay <= 0;
		NumOfST_eop <= 0;
	end
	else
	begin
		if (fsm==2'd1 && sink_valid==1'b1)
			NumOfST_inCL <= (NumOfST_inCL== MaxNumOfST_inCL-1) ? 10'd0 : NumOfST_inCL+10'd1;
		else if (fsm==2'd2 && NumOfST_inCL !=10'd0)
			NumOfST_inCL <= (NumOfST_inCL== MaxNumOfST_inCL-1) ? 10'd0 : NumOfST_inCL+10'd1;
		else
			NumOfST_inCL <= 10'd0;

		ff_wr_finish <= (fsm==2'd2 && NumOfST_inCL==10'd0) ? 1'b1 : 1'b0;

		if (fsm==2'd1 && sink_valid==1'b1)
		begin
			ff_data_PDOFI[ST2*MaxNumOfST_inCL-1+ST2 : ST2*MaxNumOfST_inCL-ST2+ST2] <= sink_data;
			ff_data_PDOFI[ST2*MaxNumOfST_inCL-ST2-1+ST2 : 0] <= ff_data_PDOFI[ST2*MaxNumOfST_inCL-1+ST2 : ST2];
			ff_data_PDOFI[CL_PAYLOAD-1+ST2 : ST2*MaxNumOfST_inCL+ST2] <= 0;
		end
		else if (fsm==2'd2 && NumOfST_inCL !=10'd0)
		begin
			ff_data_PDOFI[ST2*MaxNumOfST_inCL-1+ST2 : ST2*MaxNumOfST_inCL-ST2+ST2] <= 0;
			ff_data_PDOFI[ST2*MaxNumOfST_inCL-ST2-1+ST2 : 0] <= ff_data_PDOFI[ST2*MaxNumOfST_inCL-1+ST2 : ST2];
			ff_data_PDOFI[CL_PAYLOAD-1+ST2 : ST2*MaxNumOfST_inCL+ST2] <= 0;
		end
		else
			ff_data_PDOFI[CL_PAYLOAD-1+ST2:0] <= 0;

		if (MaxNumOfST_inCL==10'd1)
			ff_wrreq <= sink_valid;
		else
			ff_wrreq <= (NumOfST_inCL== MaxNumOfST_inCL-1) ? 1'b1 : 1'b0;

		if (MaxNumOfST_inCL==10'd1)
			ff_data_PDOFI[CL-5+ST2] <= sink_sop;
		else if (sink_sop_delay==1'b1 && NumOfST_inCL== MaxNumOfST_inCL-1)
			ff_data_PDOFI[CL-5+ST2] <= 1'b1;
		else
			ff_data_PDOFI[CL-5+ST2] <= 1'b0;

		if (sink_sop)			
			sink_sop_delay <= 1'b1;
		else if (NumOfST_inCL== MaxNumOfST_inCL-1)
			sink_sop_delay <= 1'b0;
		else
			sink_sop_delay <= sink_sop_delay;

		if (MaxNumOfST_inCL==10'd1)
			ff_data_PDOFI[CL-6+ST2] <= sink_eop;
		else if ( (sink_eop==1'b1 || fsm==2'd2) && NumOfST_inCL== MaxNumOfST_inCL-1)
			ff_data_PDOFI[CL-6+ST2] <= 1'b1;
		else 
			ff_data_PDOFI[CL-6+ST2] <= 1'b0;

		if (MaxNumOfST_inCL==10'd1)
			ff_data_PDOFI[CL-1-CL_HEAD+w_len_CLHead+ST2 : CL-CL_HEAD+ST2] <= 10'd1;
		else if (NumOfST_inCL== MaxNumOfST_inCL-1)
			ff_data_PDOFI[CL-1-CL_HEAD+w_len_CLHead+ST2 : CL-CL_HEAD+ST2] <= (fsm==2'd1)? MaxNumOfST_inCL : NumOfST_eop;
		else
			ff_data_PDOFI[CL-1-CL_HEAD+w_len_CLHead+ST2 : CL-CL_HEAD+ST2] <= 0;

		NumOfST_eop <= (sink_eop) ? NumOfST_inCL+10'd1 : NumOfST_eop; 
	end
end


endmodule