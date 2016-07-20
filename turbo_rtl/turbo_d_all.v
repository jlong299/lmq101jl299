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


localparam NUM_TURBO = 2;
localparam NUM_BUS_PER_TURBO_PKT=25;

reg [3:0] 		bus2st_rdy_fsm;
reg [NUM_TURBO-1 : 0] 	bus_en_r, bus_ready_r;			
reg [8:0]  		cnt_bus_en;

 
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
		bus_en_r <= 0;
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
		default:
			bus_ready <= 0;
		endcase
		 
		bus_en_r[0] <= (bus2st_rdy_fsm == 4'd0) ? bus_en : 1'b0;
		bus_en_r[1] <= (bus2st_rdy_fsm == 4'd1) ? bus_en : 1'b0;
		//---------------------------------------------
		//end----- Rewrite if NUM_TURBO change --------
		//---------------------------------------------

		if (  cnt_bus_en == NUM_BUS_PER_TURBO_PKT-1  && bus_en == 1'b1 )
			bus2st_rdy_fsm <= ( bus2st_rdy_fsm == NUM_TURBO-1) ? 0 : bus2st_rdy_fsm + 4'd1;
		else
			bus2st_rdy_fsm <= bus2st_rdy_fsm;

		if (bus_en)
			cnt_bus_en <= (cnt_bus_en == NUM_BUS_PER_TURBO_PKT-1) ? 0 : cnt_bus_en + 9'd1;
		else
			cnt_bus_en <= cnt_bus_en;
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

genvar i;
generate 
for (i=0; i<NUM_TURBO; i=i+1)
begin: test

	bus2st_turbo bus2st_turbo_inst #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (1028),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (25),
    .ST (12)
  	)
	(
	  .rst_n            (rst_n),             
	  .clk_bus         	(clk_bus),
	  .bus_data			(bus_data),
	  .bus_en 			(bus_en_r[i]),
	  .bus_ready 		(bus_ready_r[i]),

	  .rst_n_out 		(rst_n_clk_st), // output , rst of clk_st domain

	  .clk_st 			(clk_st),
	  
	  .source_valid    (trb_source_valid[i]   ),   // source.source_valid
	  .source_ready    (trb_source_ready[i]   ),   //       .source_ready
	  .source_error    (   ),   //       .source_error
	  .source_sop      (trb_source_sop[i]     ),   //       .source_sop
	  .source_eop      (trb_source_eop[i]     ),   //       .source_eop
	  .crc_pass        (    ),   //       .crc_pass
	  .crc_type        (    ),   //       .crc_type
	  .source_iter     (    ),   //       .source_iter
	  .source_blk_size (	),   //       .source_blk_size
	  .source_data_s   (trb_source_data_s[i]  )    //       .source_data_s
	);
end
endgenerate
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