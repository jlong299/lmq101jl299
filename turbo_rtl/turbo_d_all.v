//-----------------------------------------------------------------
// Module Name:        	turbo_d_all.v
// Project:             NLB AFU turbo decoder
// Description:         Packed NUM_TURBO turbo decoders into one module
// Author:				Long Jiang
//
//---------------------------------------------------------------------------------------
//  bus in --> arbiter demux ----> bus2st --> turbo ----> trb_out_mux --> st out
//                            |                        |
//                            ---> bus2st --> turbo -->
//                                    ...
//                            |                        |
//                            ---> bus2st --> turbo -->
//
//----------------------------------------------------------------------------------------
// !!!
// Only work when fix turbo length = 1024

module turbo_d_all #(parameter 
	BUS=534,
	ST=8 
	)
(
	input 					rst_n,  // clk_bus Asynchronous reset active low
	
	input 					clk_bus,    // Clock 400MHz
	input [BUS-1:0]			bus_data,
	input					bus_en,
	output	reg				bus_ready,

	input 					clk_st,
	input			 		st_ready,
	output [ST-1:0] 		st_data,
	output					st_valid,
	output					st_sop,
	output					st_eop
	//output					st_error, 

);

localparam NUM_TURBO = 16;
localparam NUM_BUS_PER_TURBO_PKT=25;

reg [3:0] 		bus2st_rdy_fsm;
reg [NUM_TURBO-1 : 0] 	bus_ready_r;			
reg [8:0]  		cnt_bus_en;

reg [BUS-1:0] 	bus_data_r [3:0];

//reg [NUM_TURBO-1 : 0] 	bus_en_r;

//start-------- only for NUM_TURBO = 16 -----------
reg [3 : 0] 	bus_en_r;			
reg [15 : 0] 	bus_en_rr;	
//end  -------- only for NUM_TURBO = 16 -----------		
reg [3:0] 		bus2st_rdy_fsm_r;
 
//---------------------------------------
//start--------- Arbiter ----------------
//-- Description: mux/demux of "ready" and "en" signal
//--              one root  <---> NUM_TURBO branches     
//----------------------------------------
always@(posedge clk_bus)
begin
	if (!rst_n)
	begin
		bus2st_rdy_fsm <= 0;
		bus2st_rdy_fsm_r <= 0;
		bus_en_r <= 0;
		bus_en_rr <= 0;
		cnt_bus_en <= 0;
		bus_ready <= 0;
	end
	else
	begin
		//-----------------------------------------------
		//start----- Rewrite if NUM_TURBO change --------
		//-----------------------------------------------
		case (bus2st_rdy_fsm)
		4'd0:
			bus_ready <= bus_ready_r[0];
		4'd1:
			bus_ready <= bus_ready_r[1];
		4'd2:
			bus_ready <= bus_ready_r[2];
		4'd3:
			bus_ready <= bus_ready_r[3];
		4'd4:
			bus_ready <= bus_ready_r[4];
		4'd5:
			bus_ready <= bus_ready_r[5];
		4'd6:
			bus_ready <= bus_ready_r[6];
		4'd7:
			bus_ready <= bus_ready_r[7];
		4'd8:
			bus_ready <= bus_ready_r[8];
		4'd9:
			bus_ready <= bus_ready_r[9];
		4'd10:
			bus_ready <= bus_ready_r[10];
		4'd11:
			bus_ready <= bus_ready_r[11];
		4'd12:
			bus_ready <= bus_ready_r[12];
		4'd13:
			bus_ready <= bus_ready_r[13];
		4'd14:
			bus_ready <= bus_ready_r[14];
		4'd15:
			bus_ready <= bus_ready_r[15];
		default:
			bus_ready <= 0;
		endcase
		 
		// bus_en_r[0] <= (bus2st_rdy_fsm == 4'd0) ? bus_en : 1'b0;
		// bus_en_r[1] <= (bus2st_rdy_fsm == 4'd1) ? bus_en : 1'b0;
		// bus_en_r[2] <= (bus2st_rdy_fsm == 4'd2) ? bus_en : 1'b0;
		// bus_en_r[3] <= (bus2st_rdy_fsm == 4'd3) ? bus_en : 1'b0;
		// bus_en_r[4] <= (bus2st_rdy_fsm == 4'd4) ? bus_en : 1'b0;
		// bus_en_r[5] <= (bus2st_rdy_fsm == 4'd5) ? bus_en : 1'b0;
		// bus_en_r[6] <= (bus2st_rdy_fsm == 4'd6) ? bus_en : 1'b0;
		// bus_en_r[7] <= (bus2st_rdy_fsm == 4'd7) ? bus_en : 1'b0;
		// bus_en_r[8] <= (bus2st_rdy_fsm == 4'd8) ? bus_en : 1'b0;
		// bus_en_r[9] <= (bus2st_rdy_fsm == 4'd9) ? bus_en : 1'b0;
		// bus_en_r[10] <= (bus2st_rdy_fsm == 4'd10) ? bus_en : 1'b0;
		// bus_en_r[11] <= (bus2st_rdy_fsm == 4'd11) ? bus_en : 1'b0;
		// bus_en_r[12] <= (bus2st_rdy_fsm == 4'd12) ? bus_en : 1'b0;
		// bus_en_r[13] <= (bus2st_rdy_fsm == 4'd13) ? bus_en : 1'b0;
		// bus_en_r[14] <= (bus2st_rdy_fsm == 4'd14) ? bus_en : 1'b0;
		// bus_en_r[15] <= (bus2st_rdy_fsm == 4'd15) ? bus_en : 1'b0;

		//start-------- only for NUM_TURBO = 16 -----------
		bus_en_r[0] <= (bus2st_rdy_fsm[3:2] == 2'd0) ? bus_en : 1'b0;
		bus_en_r[1] <= (bus2st_rdy_fsm[3:2] == 2'd1) ? bus_en : 1'b0;
		bus_en_r[2] <= (bus2st_rdy_fsm[3:2] == 2'd2) ? bus_en : 1'b0;
		bus_en_r[3] <= (bus2st_rdy_fsm[3:2] == 2'd3) ? bus_en : 1'b0;

		bus_en_rr[0] <= (bus2st_rdy_fsm_r[1:0] == 2'd0) ? bus_en_r[0] : 1'b0;
		bus_en_rr[1] <= (bus2st_rdy_fsm_r[1:0] == 2'd1) ? bus_en_r[0] : 1'b0;
		bus_en_rr[2] <= (bus2st_rdy_fsm_r[1:0] == 2'd2) ? bus_en_r[0] : 1'b0;
		bus_en_rr[3] <= (bus2st_rdy_fsm_r[1:0] == 2'd3) ? bus_en_r[0] : 1'b0;
		bus_en_rr[4] <= (bus2st_rdy_fsm_r[1:0] == 2'd0) ? bus_en_r[1] : 1'b0;
		bus_en_rr[5] <= (bus2st_rdy_fsm_r[1:0] == 2'd1) ? bus_en_r[1] : 1'b0;
		bus_en_rr[6] <= (bus2st_rdy_fsm_r[1:0] == 2'd2) ? bus_en_r[1] : 1'b0;
		bus_en_rr[7] <= (bus2st_rdy_fsm_r[1:0] == 2'd3) ? bus_en_r[1] : 1'b0;
		bus_en_rr[8] <= (bus2st_rdy_fsm_r[1:0] == 2'd0) ? bus_en_r[2] : 1'b0;
		bus_en_rr[9] <= (bus2st_rdy_fsm_r[1:0] == 2'd1) ? bus_en_r[2] : 1'b0;
		bus_en_rr[10] <= (bus2st_rdy_fsm_r[1:0] == 2'd2) ? bus_en_r[2] : 1'b0;
		bus_en_rr[11] <= (bus2st_rdy_fsm_r[1:0] == 2'd3) ? bus_en_r[2] : 1'b0;
		bus_en_rr[12] <= (bus2st_rdy_fsm_r[1:0] == 2'd0) ? bus_en_r[3] : 1'b0;
		bus_en_rr[13] <= (bus2st_rdy_fsm_r[1:0] == 2'd1) ? bus_en_r[3] : 1'b0;
		bus_en_rr[14] <= (bus2st_rdy_fsm_r[1:0] == 2'd2) ? bus_en_r[3] : 1'b0;
		bus_en_rr[15] <= (bus2st_rdy_fsm_r[1:0] == 2'd3) ? bus_en_r[3] : 1'b0;
		//end  -------- only for NUM_TURBO = 16 -----------

		//---------------------------------------------
		//end----- Rewrite if NUM_TURBO change --------
		//---------------------------------------------

		if (  cnt_bus_en == NUM_BUS_PER_TURBO_PKT-1  && bus_en == 1'b1 )
			bus2st_rdy_fsm <= ( bus2st_rdy_fsm == NUM_TURBO-1) ? 4'd0 : bus2st_rdy_fsm + 4'd1;
		else
			bus2st_rdy_fsm <= bus2st_rdy_fsm;

		if (bus_en)
			cnt_bus_en <= (cnt_bus_en == NUM_BUS_PER_TURBO_PKT-1) ? 9'd0 : cnt_bus_en + 9'd1;
		else
			cnt_bus_en <= cnt_bus_en;

		bus2st_rdy_fsm_r <= bus2st_rdy_fsm;
	end
end
//end--------- Arbiter ---------------------
//------------------------------------------


//start-------- bus2st & turbo ----------------
reg [NUM_TURBO-1 : 0]		trb_source_valid;
reg [NUM_TURBO-1 : 0]		trb_source_ready;
reg [NUM_TURBO-1 : 0]		trb_source_sop;
reg [NUM_TURBO-1 : 0]		trb_source_eop;
reg [7:0] 		trb_source_data_s [NUM_TURBO-1 :0] ;
reg  		rst_n_clk_st;


reg  rst_n_q, rst_n_qq;
always@(posedge clk_st)
begin
	rst_n_clk_st <= rst_n_qq;
	rst_n_qq <= rst_n_q;
	rst_n_q <= rst_n;
end

// genvar i;
// generate 
// for (i=0; i<NUM_TURBO; i=i+1)
// begin: test

// 	bus2st_turbo  #(
//     .BUS (534),
//     .ST_PER_BUS (512),
//     .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
//     .ST_PER_TURBO_PKT (1028),   // 1024+4
//     .NUM_BUS_PER_TURBO_PKT (25),
//     .ST (12)
//   	)
// 	bus2st_turbo_inst(
// 	  .rst_n            (rst_n),             
// 	  .clk_bus         	(clk_bus),
// 	  .bus_data			(bus_data),
// 	  .bus_en 			(bus_en_r[i]),
// 	  .bus_ready 		(bus_ready_r[i]),

// 	  //.rst_n_out 		(rst_n_clk_st), // output , rst of clk_st domain

// 	  .clk_st 			(clk_st),
	  
// 	  .source_valid    (trb_source_valid[i]   ),   // source.source_valid
// 	  .source_ready    (trb_source_ready[i]   ),   //       .source_ready
// 	  //.source_error    (   ),   //       .source_error
// 	  .source_sop      (trb_source_sop[i]     ),   //       .source_sop
// 	  .source_eop      (trb_source_eop[i]     ),   //       .source_eop
// 	  //.crc_pass        (    ),   //       .crc_pass
// 	  //.crc_type        (    ),   //       .crc_type
// 	  //.source_iter     (    ),   //       .source_iter
// 	  //.source_blk_size (	),   //       .source_blk_size
// 	  .source_data_s   (trb_source_data_s[i]  )    //       .source_data_s
// 	);
// end
// endgenerate


//start--------- only for NUM_TURBO = 16 ---------------
always@(posedge clk_bus)
begin
	bus_data_r[0] <= bus_data;
	bus_data_r[1] <= bus_data;
	bus_data_r[2] <= bus_data;
	bus_data_r[3] <= bus_data;
end


genvar i;
generate 
for (i=0; i<4; i=i+1)
begin: test0

	bus2st_turbo  #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (1028),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (25),
    .ST (12)
  	)
	bus2st_turbo_inst(
	  .rst_n            (rst_n),             
	  .clk_bus         	(clk_bus),
	  .bus_data			(bus_data_r[0]),
	  .bus_en 			(bus_en_rr[i]),
	  .bus_ready 		(bus_ready_r[i]),

	  //.rst_n_out 		(rst_n_clk_st), // output , rst of clk_st domain

	  .clk_st 			(clk_st),
	  
	  .source_valid    (trb_source_valid[i]   ),   // source.source_valid
	  .source_ready    (trb_source_ready[i]   ),   //       .source_ready
	  //.source_error    (   ),   //       .source_error
	  .source_sop      (trb_source_sop[i]     ),   //       .source_sop
	  .source_eop      (trb_source_eop[i]     ),   //       .source_eop
	  //.crc_pass        (    ),   //       .crc_pass
	  //.crc_type        (    ),   //       .crc_type
	  //.source_iter     (    ),   //       .source_iter
	  //.source_blk_size (	),   //       .source_blk_size
	  .source_data_s   (trb_source_data_s[i]  )    //       .source_data_s
	);
end
endgenerate

generate 
for (i=4; i<8; i=i+1)
begin: test1

	bus2st_turbo  #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (1028),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (25),
    .ST (12)
  	)
	bus2st_turbo_inst(
	  .rst_n            (rst_n),             
	  .clk_bus         	(clk_bus),
	  .bus_data			(bus_data_r[1]),
	  .bus_en 			(bus_en_rr[i]),
	  .bus_ready 		(bus_ready_r[i]),

	  //.rst_n_out 		(rst_n_clk_st), // output , rst of clk_st domain

	  .clk_st 			(clk_st),
	  
	  .source_valid    (trb_source_valid[i]   ),   // source.source_valid
	  .source_ready    (trb_source_ready[i]   ),   //       .source_ready
	  //.source_error    (   ),   //       .source_error
	  .source_sop      (trb_source_sop[i]     ),   //       .source_sop
	  .source_eop      (trb_source_eop[i]     ),   //       .source_eop
	  //.crc_pass        (    ),   //       .crc_pass
	  //.crc_type        (    ),   //       .crc_type
	  //.source_iter     (    ),   //       .source_iter
	  //.source_blk_size (	),   //       .source_blk_size
	  .source_data_s   (trb_source_data_s[i]  )    //       .source_data_s
	);
end
endgenerate

generate 
for (i=8; i<12; i=i+1)
begin: test2

	bus2st_turbo  #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (1028),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (25),
    .ST (12)
  	)
	bus2st_turbo_inst(
	  .rst_n            (rst_n),             
	  .clk_bus         	(clk_bus),
	  .bus_data			(bus_data_r[2]),
	  .bus_en 			(bus_en_rr[i]),
	  .bus_ready 		(bus_ready_r[i]),

	  //.rst_n_out 		(rst_n_clk_st), // output , rst of clk_st domain

	  .clk_st 			(clk_st),
	  
	  .source_valid    (trb_source_valid[i]   ),   // source.source_valid
	  .source_ready    (trb_source_ready[i]   ),   //       .source_ready
	  //.source_error    (   ),   //       .source_error
	  .source_sop      (trb_source_sop[i]     ),   //       .source_sop
	  .source_eop      (trb_source_eop[i]     ),   //       .source_eop
	  //.crc_pass        (    ),   //       .crc_pass
	  //.crc_type        (    ),   //       .crc_type
	  //.source_iter     (    ),   //       .source_iter
	  //.source_blk_size (	),   //       .source_blk_size
	  .source_data_s   (trb_source_data_s[i]  )    //       .source_data_s
	);
end
endgenerate

generate 
for (i=12; i<16; i=i+1)
begin: test3

	bus2st_turbo  #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (1028),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (25),
    .ST (12)
  	)
	bus2st_turbo_inst(
	  .rst_n            (rst_n),             
	  .clk_bus         	(clk_bus),
	  .bus_data			(bus_data_r[3]),
	  .bus_en 			(bus_en_rr[i]),
	  .bus_ready 		(bus_ready_r[i]),

	  //.rst_n_out 		(rst_n_clk_st), // output , rst of clk_st domain

	  .clk_st 			(clk_st),
	  
	  .source_valid    (trb_source_valid[i]   ),   // source.source_valid
	  .source_ready    (trb_source_ready[i]   ),   //       .source_ready
	  //.source_error    (   ),   //       .source_error
	  .source_sop      (trb_source_sop[i]     ),   //       .source_sop
	  .source_eop      (trb_source_eop[i]     ),   //       .source_eop
	  //.crc_pass        (    ),   //       .crc_pass
	  //.crc_type        (    ),   //       .crc_type
	  //.source_iter     (    ),   //       .source_iter
	  //.source_blk_size (	),   //       .source_blk_size
	  .source_data_s   (trb_source_data_s[i]  )    //       .source_data_s
	);
end
endgenerate
//end  --------- only for NUM_TURBO = 16 ---------------

//end-------- bus2st & turbo ----------------


//start--------- trb_out_mux ----------------
trb_out_mux #( .NUM_TURBO (NUM_TURBO) )
trb_out_mux_inst
(
	.rst_n 			(rst_n_clk_st), //!!! to be connected
	.clk 			(clk_st),

	.st_data_in 	(trb_source_data_s),
	.st_valid_in 	(trb_source_valid),
	.st_sop_in 		(trb_source_sop),
	.st_eop_in 		(trb_source_eop),
	.st_ready_out 	(trb_source_ready),

	.st_ready_in 	(st_ready),
	.st_data_out 	(st_data),
	.st_valid_out 	(st_valid),
	.st_sop_out 	(st_sop),
	.st_eop_out 	(st_eop)
	);
//end--------- trb_out_mux ----------------


endmodule