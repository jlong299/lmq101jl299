`timescale  	1 ns / 1 ns

module CL_buf_preAFU_tb #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		//w_NumOfCL_in_AFUFrm =11,  // width of maximum Number of CLs in one AFU frame
		w_NumOfST_in_AFUFrm =16  // width of maximum Number of STs in one AFU frame
	)
	(
		);
	// left side
	reg 					rst_n;  // clk Asynchronous reset active low
	reg 					clk;    

	wire					sink_ready;
	reg [CL-1:0]			sink_data;
	reg					sink_valid;  

	// right side
	wire					ff_rd_ready; 	// fifo has got one AFU frame, ready to source
	wire 					ff_rdreq; 		// fifo rdreq
	wire	 [CL-1:0] 		ff_q;  			// fifo out 
	wire 					ff_rd_finish;   // fifo rd finished (fifo_empty == 1)

	// sideband signals, optional
	reg [w_NumOfST_in_AFUFrm-1 : 0]   	sb_len;	// length of AFU frame by ST

	localparam 	ST =12;
	reg 					source_ready;
	wire [ST-1 : 0]		source_data;
	wire 				source_valid;
	wire 				source_sop;
	wire 				source_eop;

	reg [15:0] 		cnt_valid;
	reg [2:0] 		cnt_gap;

	reg [CL_PAYLOAD-1 : 0] 	sink_data_intl;
	reg [11:0] 		cnt_data_intl;

	initial	begin
		rst_n = 0;
		clk = 0;
		source_ready = 0;

		# 300 rst_n = 1'b1;
		source_ready = 1'b1;
	end

	integer i;
	initial begin
		sink_data_intl = 0;
		cnt_data_intl = 0;
		for (i=0; i<40; i=i+1)
		begin
		# 5 cnt_data_intl = cnt_data_intl + 12'd1;
		    sink_data_intl = {sink_data_intl[CL_PAYLOAD-13:12],cnt_data_intl,12'd0};
		end
    end

	always # 5 clk = ~clk; //100M

	always@(posedge clk)
	begin
		if (!rst_n)
		begin
			sink_data <= sink_data_intl;
			sink_valid <= 0;
			cnt_valid <= 0;
			cnt_gap <= 0;
		end
		else
		begin
			cnt_gap <= (cnt_gap==2'd2) ? 2'd0 : cnt_gap + 2'd1;
			if ((sink_ready) & (cnt_gap==2'd2))
			begin
				sink_valid <= 1'b1;
				sink_data[CL_PAYLOAD-1:0] <= sink_data[CL_PAYLOAD-1:0] + 1'd1;
				cnt_valid <= cnt_valid + 16'd1;
				if (cnt_valid[3:0]==4'h0)
					sink_data[CL-5:CL-6] <= 2'b10;
				else if (cnt_valid[3:0]==4'hf)
					sink_data[CL-5:CL-6] <= 2'b01;
				else
					sink_data[CL-5:CL-6] <= 2'b00;

				sink_data[CL-7:CL-16] <= 10'd1;
			end
			else
			begin
				sink_valid <= 0;
			end
		end
	end


	CL_buf_preAFU #(  // CL : cache line
		.CL (512),  // 512 bits
		.CL_HEAD (16),  // 16 bits
		.CL_PAYLOAD (496), // 496 bits
		.w_NumOfST_in_AFUFrm (16)  // width of maximum Number of STs in one AFU frame
	)
	CL_buf_preAFU_inst
	(
	// left side
	.rst_n (rst_n), // clk Asynchronous reset active low
	.clk (clk),    

	.sink_ready (sink_ready),
	.sink_data (sink_data),
	.sink_valid (sink_valid),  

	// right side
	.ff_rd_ready (ff_rd_ready), 	// fifo has got one AFU frame, ready to source
	.ff_rdreq (ff_rdreq), 		// fifo rdreq
	.ff_q (ff_q),  			// fifo out 
	.ff_rd_finish (ff_rd_finish),   // fifo rd finished (fifo_empty == 1)

	// sideband signals, optional
	.sb_len ()	// length of AFU frame by ST

	);

	CL2st_preAFU #(  // CL : cache line
		.CL (512),  // 512 bits
		.CL_HEAD (16),  // 16 bits
		.CL_PAYLOAD (496), // 496 bits
		.ST (12), // st data width
		.w_len_CLHead (10) // width of 'length' part in CL head
	)
	CL2st_preAFU_inst
	(
	// left side
	.rst_n_sync (rst_n),  // clk Asynchronous reset active low
	.clk (clk),    

	.ff_rd_ready (ff_rd_ready), 	// fifo has got one AFU frame , ready to source
	.ff_rdreq (ff_rdreq), 		// fifo rdreq
	.ff_q (ff_q),  			// fifo out 
	.ff_rd_finish (ff_rd_finish),   // fifo rd finished (fifo_empty == 1)

	//right side
	.source_ready (source_ready),
	.source_data (source_data),
	.source_valid (source_valid),
	.source_sop (source_sop),
	.source_eop (source_eop)
	);

endmodule