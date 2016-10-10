//-----------------------------------------------------------------
// Module Name:        	CL2st_preAFU.v
// Project:             data flow framework of AFU on Xeon+FPGA platform
// Description:         CL to ST conversion
// Author:				Long Jiang
//------------------------------------------------------------------
//  Version 1.2
//  Description : CL to ST conversion pre AFU
//  2016-10-08
//
//  ff is abbreviation of fifo
//  ---------------------------------------------------------------------------
//     ff_rd_ready  --> |     CL2st_preAFU      | <-- source_ready
//     ff_rdreq     <-- |                       | --> source_ST signals
//     CL out       --> |                       |
//     ff_rd_finish <-- |                       |
//  ---------------------------------------------------------------------------
//
//  You can substitute this ST interface file with your customized interface file
//  like CL2whatever_preAFU.v
//
//  ---------------------------------------------------------------------------- 


module CL2st_preAFU #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		ST =12, // st data width
		w_len_CLHead =10 // width of 'length' part in CL head
	)
	(
	// left side
	input 					rst_n_sync,  // clk Asynchronous reset active low
	input 					clk,    

	input					ff_rd_ready, 	// fifo has got one AFU frame, ready to source
	output reg				ff_rdreq, 		// fifo rdreq
	input	 [CL-1:0] 		ff_q,  			// fifo out 
	output reg				ff_rd_finish,   // fifo rd finished (fifo_empty == 1)

	//right side
	input 					source_ready,
	output [ST-1 : 0]		source_data,
	output reg 				source_valid,
	output reg 				source_sop,
	output reg 				source_eop
	);

reg [1:0] 	fsm, fsm_r, fsm_rr;
reg [CL-1:0] 	ff_q_r;
reg [3:0] 	cnt_fsm_s3;
reg 		ff_rdreq_r;


reg [w_len_CLHead-1 : 0] 	NumOfST_remain;


//start-------  FSM  ---------
always@(posedge clk)
begin
if (!rst_n_sync)
begin
	fsm <= 0;
end
else
begin
	case (fsm)
	2'd0: // s0, s_wait
	begin
		if (ff_rd_ready)
			fsm <= 2'd1;
		else
			fsm <= 2'd0;
	end
	2'd1: //s1
	begin
		if (source_ready)
			fsm <= 2'd2;
		else
			fsm <= 2'd1;
	end
	2'd2: //s2, s_source_data
	begin
		if (source_eop)
			fsm <= 2'd3;
		else
			fsm <= 2'd2;
	end
	2'd3: //s3
	begin
		if (cnt_fsm_s3 == 4'd15)
			fsm <= 2'd0;
		else
			fsm <= 2'd3;
	end
	default: 
	begin
		fsm <= 2'd0;
	end
	endcase
end
end

always@(posedge clk)
begin
	if (!rst_n_sync)
		cnt_fsm_s3 <= 0;
	else
		if (fsm == 2'd3)
			cnt_fsm_s3 <= (cnt_fsm_s3==4'd15) ? 4'd0 : cnt_fsm_s3 + 4'd1;
		else
			cnt_fsm_s3 <= 0;
end
//end------- FSM ------------

always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		fsm_r <= 0;
		fsm_rr <= 0;
		ff_rdreq_r <= 0;
	end
	else
	begin
		fsm_r <= fsm;
		fsm_rr <= fsm_r;
		ff_rdreq_r <= ff_rdreq;
	end
end

always@(*)
begin
	if (fsm != 2'd2)
		ff_rdreq = 1'b0;
	else if (fsm_r==2'd1)  // fsm=2 beginning
		ff_rdreq = 1'b1;
	else if (ff_q[CL-1-5]==1'b1) // end CL of one AFU frame
		ff_rdreq = 1'b0;
	else if (ff_q[CL-CL_HEAD+w_len_CLHead-1 : CL-CL_HEAD] == 1'd1 || NumOfST_remain == 1'd1) // trigger next rdreq
		ff_rdreq = 1'b1;
	else
		ff_rdreq = 1'b0;
end

assign source_data = ff_q_r[ST-1 : 0];

always@(posedge clk)
begin
	if (!rst_n_sync)
	begin
		NumOfST_remain <= 0;
		ff_q_r <= 0;
		source_sop <= 0;
		source_eop <= 0;
		source_valid <= 0;
		ff_rd_finish <= 0;
	end
	else
	begin
		if (ff_rdreq_r)
			NumOfST_remain <= ff_q[CL-CL_HEAD+w_len_CLHead-1 : CL-CL_HEAD] - 1'd1;
		else
			NumOfST_remain <= NumOfST_remain - 1'd1;

		if (ff_rdreq_r)
			ff_q_r <= ff_q;
		else
			ff_q_r <= {{ST{1'b0}}, ff_q_r[CL_PAYLOAD-1 : ST]};

		source_sop <= (fsm_r==2'd2 && fsm_rr==2'd1) ? 1'b1 : 1'b0;

		if (fsm==2'd2 && ff_q[CL-1-5]==1'b1 && fsm_r==2'd2)
			if ((ff_q[CL-CL_HEAD+w_len_CLHead-1 : CL-CL_HEAD] == 1'd1 || NumOfST_remain == 1'd1) & (!source_eop))
				source_eop <= 1'b1;
			else
				source_eop <= 1'b0;
		else
			source_eop <= 1'b0;

		if (fsm_r==2'd2 && fsm_rr==2'd1)
			source_valid <= 1'b1;
		else if (source_eop)
			source_valid <= 1'b0;
		else
			source_valid <= source_valid;

		ff_rd_finish <= source_eop;

	end
end

endmodule