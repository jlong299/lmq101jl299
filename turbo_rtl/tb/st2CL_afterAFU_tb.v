`timescale  	1 ns / 1 ns

module st2CL_afterAFU_tb #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		ST2 =8, // st data width at output of AFU
		MaxNumOfST_inCL = 10'd41,   // the maximum allowed amount of STs in one CL
		w_len_CLHead =10 // width of 'length' part in CL head
	)
	(
		);

	// left side
	reg 					rst_n;  // clk Synchronous reset active low
	reg 					clk;    

	wire					sink_ready;
	reg [ST2-1 : 0]			sink_data;
	reg 	 				sink_valid;
	reg 	 				sink_sop;
	reg 	 				sink_eop;

	//right side
	reg					source_ready; 	
	wire				ff_wrreq; 		
	wire [CL-1:0] 		ff_data;  		
	wire				ff_wr_finish;  

	initial	begin
		rst_n = 0;
		clk = 0;
		source_ready = 0;

		# 100 rst_n = 1'b1;
		source_ready = 1'b1;
	end

	always # 5 clk = ~clk; //100M

	localparam len_st_AFUfrm = 16'd2;

	reg [15:0]  NumOfST_gen;
	reg [3:0] 	cnt_fsm_2;
	reg [1:0] 	fsm, fsm_r;

	always@(posedge clk)
	begin
		if (!rst_n)
		begin
			fsm <= 0;
			cnt_fsm_2 <= 0;
		end
		else
		begin
			case(fsm)
				2'd0:
					fsm <= (sink_ready) ? 2'd1 : 2'd0;
				2'd1:
					fsm <= (sink_eop) ? 2'd2 : 2'd1;
				2'd2:
					fsm <= (cnt_fsm_2==4'd15) ? 2'd0 : 2'd2;
				default:
					fsm <= 0;
			endcase
			cnt_fsm_2 <= (fsm==2'd2) ? cnt_fsm_2+4'd1 : 4'd0;
		end
	end

	
	
	always@(posedge clk)
	begin
		if (!rst_n)
		begin
			sink_data <= 1'd1;
			sink_valid <= 0;
			sink_sop <= 0;
			sink_eop <= 0;
			NumOfST_gen <= 0;
			fsm_r <= 0;
		end
		else
		begin
			fsm_r <= fsm;
			sink_sop <= (fsm==2'd1 && fsm_r==2'd0) ? 1'b1 : 1'b0;
			if (fsm==2'd1 && fsm_r==2'd0)
				sink_valid <= 1'b1;
			else if (sink_eop)
				sink_valid <= 1'b0;
			else
				sink_valid <= sink_valid;

			NumOfST_gen <= (sink_valid==1'b1 || (fsm==2'd1 && fsm_r==2'd0)) ? NumOfST_gen + 16'd1 : 16'd0;

			if (len_st_AFUfrm==16'd1)
				sink_eop <= (fsm==2'd1 && fsm_r==2'd0) ? 1'b1 : 1'b0;
			else 
				sink_eop <= (NumOfST_gen == len_st_AFUfrm-16'd1) ? 1'b1 : 1'b0;

			sink_data <= (sink_valid) ? sink_data+1'd1 : 1;
		end
	end

	st2CL_afterAFU #(  // CL : cache line
			.CL (512),  // 512 bits
			.CL_HEAD (16),  // 16 bits
			.CL_PAYLOAD (496), // 496 bits
			.ST2 (8), // st data width at output of AFU
			.MaxNumOfST_inCL ( 10'd1),   // the maximum allowed amount of STs in one CL
			.w_len_CLHead (10) // width of 'length' part in CL head
		)
	st2CL_afterAFU_inst
		(
		// left side
		.rst_n_sync (rst_n),  // clk Synchronous reset active low
		.clk (clk),    

		.sink_ready (sink_ready),
		.sink_data (sink_data),
		.sink_valid (sink_valid),
		.sink_sop (sink_sop),
		.sink_eop (sink_eop),

		.source_ready (source_ready), 	
		.ff_wrreq (ff_wrreq), 		
		.ff_data (ff_data),  		
		.ff_wr_finish (ff_wr_finish)   

		);


endmodule