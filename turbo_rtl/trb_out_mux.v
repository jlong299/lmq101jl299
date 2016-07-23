//-----------------------------------------------------------------
// Module Name:        	trb_out_mux.v
// Project:             NLB AFU turbo decoder
// Description:         Mux arbiter consist of  NUM_TURBO FIFOs
// Author:				Long Jiang
//
//---------------------------------------------------------------------------------------
//  st in ---> FIFO ------> Arbiter/Mux --> st out
//                     |
//  st in ---> FIFO -->
//                 ...
//                     |
//  st in ---> FIFO -->
//
//----------------------------------------------------------------------------------------
// !!!
// Only work when fix turbo length = 1024

module trb_out_mux #(parameter
	NUM_TURBO = 2
	)
(
	input 			rst_n, 	 // sync to clk !		
	input 			clk,	

	input [7:0]						st_data_in [NUM_TURBO-1 :0] ,
	input [NUM_TURBO-1 :0]			st_valid_in,
	input [NUM_TURBO-1 :0]			st_sop_in,
	input [NUM_TURBO-1 :0]			st_eop_in,
	output reg	[NUM_TURBO-1 :0]	st_ready_out,

	input 				st_ready_in,
	output reg	[7:0]	st_data_out,
	output reg			st_valid_out,
	output reg			st_sop_out,
	output reg			st_eop_out,

	output reg	[NUM_TURBO-1 : 0] 	err_fifo_state,  //if (fifo empty) && (rden == 1) 
	output reg	[NUM_TURBO-1 : 0] 	err_fifo_full   
	);


localparam ST_LEN = 128; // turbo_length/8
reg 		read_one_frame_done;
reg [5 : 0]  		num_frame_in_fifo [NUM_TURBO-1 : 0] ;
reg [10 : 0] 		cnt_rden [NUM_TURBO-1 : 0] ;
reg [NUM_TURBO-1 : 0]				rden;

reg	[7:0]					st_data_q [NUM_TURBO-1 : 0] ;
reg	[NUM_TURBO-1 : 0] 		st_valid_q;
reg	[NUM_TURBO-1 : 0] 		st_sop_q;
reg	[NUM_TURBO-1 : 0] 		st_eop_q;

reg	[NUM_TURBO-1 : 0] 		empty;

reg 	[3:0] 	st_out_fsm;


genvar i;
generate 
for (i=0; i<NUM_TURBO; i=i+1)
begin: gen_test

	// FIFOs inst
	fifo_st_data fifo_st_data_inst (
	  .data  (st_data_in[i]), 
	  .wrreq (st_valid_in[i]),
	  .rdreq (rden[i]),
	  .clock (clk),
	  .sclr  (!rst_n), 
	  .q     (st_data_q[i]),    
	  .usedw (),
	  .full  (err_fifo_full[i]), 
	  .empty (empty[i]) 
	);

	
	always@(posedge clk)
	begin
		if (!rst_n)
		begin
			num_frame_in_fifo[i] <= 0;
			cnt_rden[i] <= 0;
			rden[i] <= 0;
		end
		else
		begin
			// If number of frames in fifo less then 4, st_ready_out=1'b1
			if (num_frame_in_fifo[i] <= 6'd4)
				st_ready_out[i] <= 1'b1;
			else 
				st_ready_out[i] <= 1'b0;

			// Number of turbo frames in fifo. Every clk +1, -1, or maintain
			if ( cnt_rden[i] == ST_LEN )
				if (st_eop_in[i])
					num_frame_in_fifo[i] <= num_frame_in_fifo[i];
				else
					num_frame_in_fifo[i] <= num_frame_in_fifo[i] - 6'd1;
			else if (st_eop_in[i])
				num_frame_in_fifo[i] <= num_frame_in_fifo[i] + 6'd1;
			else
				num_frame_in_fifo[i] <= num_frame_in_fifo[i];

			// Set rden length = ST_lEN
			if ( (st_out_fsm == i) && (num_frame_in_fifo[i] != 0) && st_ready_in )
			begin
				cnt_rden[i] <= ( cnt_rden[i] == ST_LEN ) ? 11'd0 : cnt_rden[i] + 11'd1;
				rden[i] <= ( cnt_rden[i] != 11'd0 );
			end
			else
			begin
				cnt_rden[i] <= 0;
				rden[i] <= 0;
			end
		end
	end

	// Generate sop,eop,valid  according to rden
	always@(posedge clk)
	begin
		if (!rst_n)
		begin
			st_valid_q[i] <= 0;
			st_sop_q[i] <= 0;
			st_eop_q[i] <= 0;
			err_fifo_state[i] <= 0;
		end
		else
		begin
			st_valid_q[i] <= rden[i];
			st_sop_q[i] <= rden[i] & (!st_valid_q[i]) ;
			st_eop_q[i] <= (cnt_rden[i] == 11'd0) && (rden[i] == 1'b1) ;
			err_fifo_state[i] <= empty[i] & rden[i];
		end
	end

end
endgenerate


//-------- FSM : represent one mux branch ----------
always@(posedge clk)
begin
	if (!rst_n)
	begin
		st_out_fsm <= 0;
	end
	else
	begin
		if ( read_one_frame_done )
			st_out_fsm <= (st_out_fsm == NUM_TURBO-1) ? 4'd0 : st_out_fsm + 4'd1;
		else
			st_out_fsm <= st_out_fsm;
	end
end


//-----------------------------------------------
//start----- Rewrite if NUM_TURBO change --------
//-----------------------------------------------
always@(posedge clk)
begin
	if (!rst_n)
	begin
		read_one_frame_done <= 0;
	end
	else
	begin
		read_one_frame_done <= 	( cnt_rden[0] == ST_LEN ) |
								( cnt_rden[1] == ST_LEN ) |
								( cnt_rden[2] == ST_LEN ) |
								( cnt_rden[3] == ST_LEN ) |
								( cnt_rden[4] == ST_LEN ) |
								( cnt_rden[5] == ST_LEN ) |
								( cnt_rden[6] == ST_LEN ) |
								( cnt_rden[7] == ST_LEN ) 
								;
	end
end

reg [3:0] st_out_fsm_q;
always@(posedge clk)		
begin
	st_out_fsm_q <= st_out_fsm;
end

always@(*)
begin
	case (st_out_fsm_q)
	4'd0:
	begin
		st_data_out <= st_data_q[0];
		st_valid_out <= st_valid_q[0];
		st_sop_out <= st_sop_q[0];
		st_eop_out <= st_eop_q[0];
	end
	4'd1:
	begin
		st_data_out <= st_data_q[1];
		st_valid_out <= st_valid_q[1];
		st_sop_out <= st_sop_q[1];
		st_eop_out <= st_eop_q[1];
	end
	4'd2:
	begin
		st_data_out <= st_data_q[2];
		st_valid_out <= st_valid_q[2];
		st_sop_out <= st_sop_q[2];
		st_eop_out <= st_eop_q[2];
	end
	4'd3:
	begin
		st_data_out <= st_data_q[3];
		st_valid_out <= st_valid_q[3];
		st_sop_out <= st_sop_q[3];
		st_eop_out <= st_eop_q[3];
	end
	4'd4:
	begin
		st_data_out <= st_data_q[4];
		st_valid_out <= st_valid_q[4];
		st_sop_out <= st_sop_q[4];
		st_eop_out <= st_eop_q[4];
	end
	4'd5:
	begin
		st_data_out <= st_data_q[5];
		st_valid_out <= st_valid_q[5];
		st_sop_out <= st_sop_q[5];
		st_eop_out <= st_eop_q[5];
	end
	4'd6:
	begin
		st_data_out <= st_data_q[6];
		st_valid_out <= st_valid_q[6];
		st_sop_out <= st_sop_q[6];
		st_eop_out <= st_eop_q[6];
	end
	4'd7:
	begin
		st_data_out <= st_data_q[7];
		st_valid_out <= st_valid_q[7];
		st_sop_out <= st_sop_q[7];
		st_eop_out <= st_eop_q[7];
	end
	default:
	begin
		st_data_out <= 0;
		st_valid_out <= 0;
		st_sop_out <= 0;
		st_eop_out <= 0;
	end
	endcase
end
//---------------------------------------------
//end----- Rewrite if NUM_TURBO change --------
//---------------------------------------------

endmodule
