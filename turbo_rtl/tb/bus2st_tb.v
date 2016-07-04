// Author:				Long Jiang
// 20160629

`timescale  	1 ns / 1 ns

module bus2st_tb #(parameter
	BUS=534,
	ST=12
	)
	(
	);

	reg 					rst_n;  // clk_400 Asynchronous reset active low
	
	reg 					clk_400;    // Clock 400MHz
	reg [BUS-1:0]			bus_data;
	reg					bus_en;
	wire				bus_ready;
	//					bus_almost_ready;

	reg					clk_st;  // clk turbo decoder
	wire					st_ready;
	wire [ST-1:0] 	st_data;
	wire				st_valid;
	wire				st_sop;
	wire				st_eop;
	wire				st_error;

reg [7:0] cnt_perBus;
reg [11:0] cnt_inc;

initial begin
	rst_n = 0;
	clk_400 = 0;
	clk_st = 0;

	# 100 rst_n = 1;
end

always 
	#5 clk_400 = ~clk_400; //100M

always
	#15 clk_st = ~clk_st; //33.3M

localparam NUM_ST_PER_BUS = 42; // 512/12=42.x


always@(posedge clk_400)
begin
if (!rst_n)
begin
	cnt_perBus <= 0;
	cnt_inc <= 0;
	bus_data <= 0;
	//bus_en <= 0;
end
else
begin

	if (cnt_perBus == NUM_ST_PER_BUS-1)
	begin
		cnt_perBus <=0;
		bus_data <= 0;
	end
	else
	begin
		cnt_perBus <= cnt_perBus + 8'h1;
		bus_data[ 12*NUM_ST_PER_BUS-13+22 : 0+22] <= bus_data[ 12*NUM_ST_PER_BUS-1+22 : 12+22];
		bus_data[ 12*NUM_ST_PER_BUS-1+22 : 12*NUM_ST_PER_BUS-12+22 ] <= cnt_inc;
	end


	cnt_inc <= cnt_inc + 12'h1;
end
end

always@(*)
begin
	bus_en <= ((cnt_perBus== NUM_ST_PER_BUS-2) ? 1'b1 : 1'b0) & bus_ready;
end

assign st_ready = 1'b1;

bus2st  #(
		 .BUS (534),
		 .ST_PER_BUS (512),
		 .NUM_ST_PER_BUS (42),
		 .ST_PER_TURBO_PKT (1028),   //1024+4
		 .NUM_BUS_PER_TURBO_PKT (25),
		 .ST (12)
		 )
inst_bus2st
	(
	.rst_n  (rst_n),  	
	
	.clk_400 (clk_400),  	  
	.bus_data (bus_data),	
	.bus_en	(bus_en),		
	.bus_ready (bus_ready),	

	.clk_st (clk_st), 	 
	.st_ready (st_ready),	
	.st_data (st_data),	
	.st_valid (st_valid),	
	.st_sop	(st_sop),		
	.st_eop	(st_eop),		
	.st_error (st_error)	
	
);


// //20160427
// // for turbo IPcore simulation

// `timescale  	1 ns / 1 ns

// module ome_top_tb(
// 	);

// reg clk_base;
// reg rst_n;

// initial begin
// 	rst_n = 0;
// 	# 100 rst_n = 1;
// 	clk_base = 0;
// end

// always 
// 	#5 clk_base = ~clk_base;

// ome_top inst_ome_top(
//   // Reset and clocks
// .pin_cmos25_inp_vl_QPI_PWRGOOD  	(rst_n),
// .pin_cmos25_inp_vl_HSECLK_112       (clk_base)

// );		
// 	////////////////////
	



endmodule