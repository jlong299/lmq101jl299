






module turbo_d_all
	(
		blablabla...
		);



case (bus2st_rdy_fsm)
4'd0:
begin
	bus_ready_mux <= bus_ready_r[0];



 
bus_en_r[0] <= (bus2st_rdy_fsm == 4'd0) ? bus_en : 1'b0;


reg [8:0]  		cnt_bus_en;

if (cnt_bus_en == NUM_BUS_PER_TURBO_PKT)
begin
	bus2st_rdy_fsm <= ( bus2st_rdy_fsm == NUM_TURBO-1) ? 0 : bus2st_rdy_fsm + 4'd1;
end
else
begin
	









genvar i;
generate 
for (i=0; i<NUM_TURBO; i=i+1)
begin: test

	bus2st_turbo bus2st_turbo_inst (
	  // .clk             (clk),             //    clk.clk
	  // .reset_n         (test_Resetb        ),   //    rst.reset_n
	  // .sink_valid      (st_valid[i]     ),   //   sink.sink_valid
	  // .sink_ready      (trb_sink_ready[i]     ),   //       .sink_ready
	  // .sink_error      (trb_sink_error     ),   //       .sink_error
	  // .sink_sop        (st_sop[i]       ),   //       .sink_sop
	  // .sink_eop        (st_eop[i]       ),   //       .sink_eop
	  // .sel_crc24a      (trb_sel_crc24a     ),   //       .sel_crc24a
	  // .sink_max_iter   (trb_sink_max_iter  ),   //       .sink_max_iter
	  // .sink_blk_size   (trb_sink_blk_size  ),   //       .sink_blk_size
	  // .sink_data       (st_data      ),   //       .sink_data
	  .source_valid    (trb_source_valid   ),   // source.source_valid
	  .source_ready    (trb_source_ready   ),   //       .source_ready
	  .source_error    (trb_source_error   ),   //       .source_error
	  .source_sop      (trb_source_sop     ),   //       .source_sop
	  .source_eop      (trb_source_eop     ),   //       .source_eop
	  .crc_pass        (trb_crc_pass       ),   //       .crc_pass
	  .crc_type        (trb_crc_type       ),   //       .crc_type
	  .source_iter     (    ),   //       .source_iter
	  .source_blk_size (	),   //       .source_blk_size
	  .source_data_s   (trb_source_data_s  )    //       .source_data_s
	);
end
endgenerate

always@(posedge clk)
begin
  trb_sink_blk_size <= 13'd1024;
  //trb_source_ready <= 1'b1;
  trb_sink_error <= 2'b00;
  trb_sink_max_iter <= 5'd8;
  trb_sel_crc24a <= 1'b0;
end
