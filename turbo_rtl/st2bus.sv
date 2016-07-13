//-----------------------------------------------------------------
// Module Name:        	st2bus.v
// Project:             NLB AFU turbo decoder
// Description:         to Avalon-ST to parallel data bus 
// Author:				Long Jiang
//
//  ---------------------------------------------------------------------------------------------------------------------------------------------------
//           memory  -->  bus2st.v  -->  TurboDecoder -->  st2bus.v  --> output
//  ------------------------------------------------------------------------------------------------------------------------------------------------
//  We need NUM_BUS_PER_TURBO_PKT buses to form one turbo packet.
//
//  !  This is a temporary simple version. No ram.

module st2bus #(parameter
		BUS=534,
		ST_PER_BUS=512,
		NUM_ST_PER_BUS=64, //  (ST_PER_BUS / ST)
		ST_PER_TURBO_PKT=128,   // 1024/ST
		NUM_BUS_PER_TURBO_PKT=2, // ( ST_PER_TURBO_PKT / NUM_ST_PER_BUS )
		ST=8, 
		FROM_BUS2ST_NUM_BUS=25   // !! NUM_BUS_PER_TURBO_PKT of bus2st.sv

	)
	(
	input rst_n, // clk_bus Asynchronous reset active low

	input clk_st,  // clk turbo decoder
	input [ST-1:0] 			st_data,
	input					st_valid,
	input					st_sop,
	input					st_eop,
	//input					st_error, 
	output 					st_ready,

	input 					clk_bus,   // 400MHz clk
	input 					bus_ready,
	output 	reg [BUS-1:0] 	bus_data,
	output					bus_en,

	output 					data2FlowCtrl   // to Flow Ctrl FIFO  (FROM_BUS2ST_NUM_BUS '1')
	);

// localparam RAM_DIN 		= 256;
// localparam RAM_DOUT 	= 256;

//start-----------   clk_bus --> clk_st  ----------------
logic mem_full_trig_clk_st, mem_full_trig_r1, mem_full_trig_r0;
always@(posedge clk_st)
begin
	mem_full_trig_clk_st <= mem_full_trig_r1;
	mem_full_trig_r1 <= mem_full_trig_r0;
	mem_full_trig_r0 <= mem_full_trigger;
end

logic rst_n_st_r0, rst_n_st_r1, rst_n_st;
always@(posedge clk_st)
begin
	rst_n_st <= rst_n_st_r1;
	rst_n_st_r1 <= rst_n_st_r0;
	rst_n_st_r0 <= rst_n;
end
//end-----------   clk_bus --> clk_st  ----------------


always@(posedge clk-st)
begin
	if (!)

end


endmodule