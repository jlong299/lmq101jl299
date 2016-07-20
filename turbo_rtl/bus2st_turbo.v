//-----------------------------------------------------------------
// Module Name:        	bus2st_turbo.v
// Project:             NLB AFU turbo decoder
// Description:         bus2st + turbo 
// Author:				Long Jiang
//
//  ---------------------------------------------------------------------------------------------------------------------------------------------------
//           memory  -->  bus2st.v  -->  TurboDecoder --> output
//  ------------------------------------------------------------------------------------------------------------------------------------------------
//  When one turbo packet operation finishes,  set bus_ready=1  which indicates
//  the next several (NUM_BUS_PER_TURBO_PKT) bus data can come in.  
//
//  We need NUM_BUS_PER_TURBO_PKT buses to form one turbo packet.
//
//  When st_ready from TurboDecoder ==1,  st_data can go out.

module bus2st_turbo #(parameter
		BUS=534,
		ST_PER_BUS=512,
		NUM_ST_PER_BUS=42, //  (ST_PER_BUS / ST)
		ST_PER_TURBO_PKT=1028,   // 1024+4
		NUM_BUS_PER_TURBO_PKT=25,
		ST=12
	)
	(
	input 					rst_n,  // clk_bus Asynchronous reset active low
	
	input 					clk_bus,    // Clock 400MHz
	input [BUS-1:0]			bus_data,
	input					bus_en,
	output					bus_ready,

	output  reg 			rst_n_out, 	// output , rst of clk_st domain		

	input					clk_st,  // clk turbo decoder

	output         			source_valid,    // source.source_valid
	input          			source_ready,    //       .source_ready
	//output  [1:0]  			source_error,    //       .source_error
	output         			source_sop,      //       .source_sop
	output         			source_eop,      //       .source_eop
	//output  [0:0]  			crc_pass,        //       .crc_pass
	//output  [0:0]  			crc_type,        //       .crc_type
	//output  [4:0]  			source_iter,     //       .source_iter
	//output  [12:0] 			source_blk_size, //       .source_blk_size
	output  [7:0]  			source_data_s,    //       .source_data_s

	output reg 				bus2st_mem_rd_finish;;;;//!!!!!!!!
	
);


reg  rst_n_q, rst_n_qq;
always@(posedge clk_st)
begin
	rst_n_out <= rst_n_qq;
	rst_n_qq <= rst_n_q;
	rst_n_q <= rst_n;
end


reg [12-1:0]  st_data  ;
reg       st_valid  ;
reg       st_sop  ;
reg       st_eop  ;
reg    	  st_out_ready;

wire [1:0]    trb_sink_error;
wire     trb_sink_ready;
wire [0:0] trb_sel_crc24a;
wire [4:0] trb_sink_max_iter;
wire [12:0]  trb_sink_blk_size;




wire   [7:0] trb_source_data_s /* synthesis keep */ ;


  bus2st #(
    .BUS (BUS),
    .ST_PER_BUS (ST_PER_BUS),
    .NUM_ST_PER_BUS (NUM_ST_PER_BUS), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (ST_PER_TURBO_PKT),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (NUM_BUS_PER_TURBO_PKT),
    .ST (ST)
  )
  inst_bus2st
  (
   .rst_n       (rst_n),
   .clk_bus     (clk_bus),
   .bus_data    (bus_data),
   .bus_en      (bus_en),
   .bus_ready   (bus_ready),

   .clk_st      (clk_st),
   .st_ready    (st_out_ready),
   .st_data     (st_data),
   .st_valid    (st_valid),
   .st_sop      (st_sop),
   .st_eop      (st_eop),
   .st_error    (),

   .mem_rd_complt_clk_bus  (bus2st_mem_rd_finish)

  );


//start------------ Turbo Decoder ------------------

ready_adjust inst_ready_adjust
(
  .rst_n      (rst_n),
  .clk        (clk_st),

  .ready_in   (trb_sink_ready),
  .sink_eop   (st_eop),
  .source_eop (trb_source_eop),

  .ready_out  (st_out_ready)
  );


  assign trb_sink_blk_size = 13'd1024;
  //trb_source_ready = 1'b1;
  assign trb_sink_error = 2'b00;
  assign trb_sink_max_iter = 5'd8;
  assign trb_sel_crc24a = 1'b0;


turbo_d0 turbo_d0_inst (
  .clk             (clk_st),             //    clk.clk
  .reset_n         (rst_n        ),   //    rst.reset_n
  .sink_valid      (st_valid     ),   //   sink.sink_valid
  .sink_ready      (trb_sink_ready     ),   //       .sink_ready
  .sink_error      (trb_sink_error     ),   //       .sink_error
  .sink_sop        (st_sop       ),   //       .sink_sop
  .sink_eop        (st_eop       ),   //       .sink_eop
  .sel_crc24a      (trb_sel_crc24a     ),   //       .sel_crc24a
  .sink_max_iter   (trb_sink_max_iter  ),   //       .sink_max_iter
  .sink_blk_size   (trb_sink_blk_size  ),   //       .sink_blk_size
  .sink_data       (st_data      ),   //       .sink_data
  .source_valid    (source_valid   ),   // source.source_valid
  .source_ready    (source_ready   ),   //       .source_ready
  .source_error    (   ),   //       .source_error
  .source_sop      (source_sop     ),   //       .source_sop
  .source_eop      (source_eop     ),   //       .source_eop
  .crc_pass        (       ),   //       .crc_pass
  .crc_type        (       ),   //       .crc_type
  .source_iter     (    ),   //       .source_iter
  .source_blk_size (),   //       .source_blk_size
  .source_data_s   (source_data_s  )    //       .source_data_s
);
//end------------ Turbo Decoder ------------------