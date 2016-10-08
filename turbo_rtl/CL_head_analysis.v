//-----------------------------------------------------------------
// Module Name:        	
// Project:             
// Description:         
// Author:				Long Jiang
//------------------------------------------------------------------
//  Version 1.2
//------------------------------------------------------------------


module CL_head_analysis #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		//w_NumOfCL_in_AFUFrm =11,  // width of maximum Number of CLs in one AFU frame
		w_NumOfST_in_AFUFrm =16  // width of maximum Number of STs in one AFU frame
	)
	(
	input 					rst_n_sync,  // clk Asynchronous reset active low
	input 					clk,    

	output	reg				sink_ready,
	input [CL-1:0]			sink_data,
	input					sink_valid, 

	output	reg				ff_rd_ready, 	// fifo has got one AFU frame, ready to source

	output [CL-1:0] 		source_data,
	output 					source_valid,

	input 					ff_rd_finish,

	// sideband signals, optional
	output reg [w_NumOfST_in_AFUFrm-1 : 0]   	sb_len	// length of AFU frame by ST
	
);

assign source_data = sink_data;
assign source_valid = sink_valid & sink_ready;

reg [1:0] 	fsm;
reg 		end_of_AFUfrm;
reg [w_NumOfST_in_AFUFrm-1 : 0]   	sb_len_t;	// length of AFU frame by ST


//start-------  FSM  ---------
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
	case (fsm)
	2'd0: // s_wait
	begin
		if (source_valid)
			fsm <= 2'd1;
		else
			fsm <= 2'd0;
		sink_ready <= 1'b1;
		ff_rd_ready <= 1'b0;
	end
	2'd1: // s_data_in
	begin
		if (end_of_AFUfrm)
		begin
			fsm <= 2'd2;
			sink_ready <= 1'b0;
			ff_rd_ready <= 1'b1;
		end
		else
		begin
			fsm <= 2'd1;
			sink_ready <= 1'b1;
			ff_rd_ready <= 1'b0;
		end
	end
	2'd2: // s_data_end
	begin
		if (ff_rd_finish)
		begin
			fsm <= 2'd0;
			ff_rd_ready <= 1'b0;
		end
		else
		begin
			fsm <= 2'd2;
			ff_rd_ready <= 1'b1;
		end
		sink_ready <= 1'b0;
	end
	default: 
	begin
		fsm <= 2'd0;
		sink_ready <= 1'b0;
		ff_rd_ready <= 1'b0;
	end
	endcase
end
end
//end------- FSM ------------


always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		end_of_AFUfrm <= 0;
	end
	else
	begin
		end_of_AFUfrm <= (fsm==2'd1) & (source_valid) & (source_data[CL-4]==1'b1);
	end
end

always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		sb_len_t <= 0;
		sb_len <= 0;
	end
	else
	begin
		if (fsm==2'd2)	
			sb_len_t <= 0;
		else
			sb_len_t <= (source_valid) ? (sb_len_t + source_data[CL-5 : CL-16]) : sb_len_t ;

		sb_len <= (end_of_AFUfrm) ? sb_len_t : sb_len ;
	end
end


endmodule