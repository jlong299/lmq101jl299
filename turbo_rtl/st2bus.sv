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

module st2bus #(parameter
		BUS=534,
		ST_PER_BUS=512,
		NUM_ST_PER_BUS=64, //  (ST_PER_BUS / ST)
		ST_PER_TURBO_PKT=128,   // 1024/ST
		//NUM_BUS_PER_TURBO_PKT=25,
		ST=8

	)
// 	(
// 	input 					rst_n,  // clk_400 Asynchronous reset active low
	
// 	input 					clk_400,    // Clock 400MHz
// 	input [BUS-1:0]			bus_data,
// 	input					bus_en,
// 	output	reg				bus_ready,
// 	//output					bus_almost_ready,

// 	input					clk_st,  // clk turbo decoder
// 	input					st_ready,
// 	output	reg [ST-1:0] 	st_data,
// 	output	reg				st_valid,
// 	output	reg				st_sop,
// 	output	reg				st_eop,
// 	output	reg				st_error
	
// );


localparam RAM_DIN 		= 256;
localparam RAM_DOUT 	= 256;


endmodule