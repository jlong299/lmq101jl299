
module CL2st_preAFU #(parameter  // CL : cache line
		CL =512,  // 512 bits
		CL_HEAD =16,  // 16 bits
		CL_PAYLOAD =496, // 496 bits
		ST =12, // st data width
		w_len_CLHead =10 // width of 'length' part in CL head
	)
	(
	// left side
	input 					rst_n,  // clk Asynchronous reset active low
	input 					clk,    

	input					ff_rd_ready, 	// fifo has got one AFU frame, ready to source
	output 					ff_rdreq, 		// fifo rdreq
	input	 [CL-1:0] 		ff_q,  			// fifo out 
	output reg				ff_rd_finish,   // fifo rd finished (fifo_empty == 1)

	//right side
	input 					source_ready,
	output reg [ST-1 : 0]	source_data,
	output reg 				source_valid,
	output reg 				source_sop,
	output reg 				source_eop
	);

reg 