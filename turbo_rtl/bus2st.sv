//-----------------------------------------------------------------
// Module Name:        	bus2st.v
// Project:             NLB AFU turbo decoder
// Description:         parallel data bus to Avalon-ST
// Author:				Long Jiang
//
//  ---------------------------------------------------------------------------------------------------------------------------------------------------
//           memory  -->  bus2st.v  -->  TurboDecoder
//  ------------------------------------------------------------------------------------------------------------------------------------------------
//  When one turbo packet operation finishes,  set bus_ready=1  which indicates
//  the next several (NUM_BUS_PER_TURBO_PKT) bus data can come in.  
//
//  We need NUM_BUS_PER_TURBO_PKT buses to form one turbo packet.
//
//  When st_ready from TurboDecoder ==1,  st_data can go out.

module bus2st #(parameter
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
	output	reg				bus_ready,
	//output					bus_almost_ready,

	input					clk_st,  // clk turbo decoder
	input					st_ready,
	output	reg [ST-1:0] 	st_data,
	output	reg				st_valid,
	output	reg				st_sop,
	output	reg				st_eop,
	output	reg				st_error,

	output	reg				mem_rd_complt_clk_bus
	
);


localparam RAM_DIN 		= 256;
localparam RAM_DOUT 	= 256;

logic [2*RAM_DOUT-1 : 0] 	bus_mem_out;
logic [6:0] 		bus_mem_wraddr;
logic 				bus_mem_rden;
logic [6:0] 		bus_mem_rdaddr;

////start------------  1 turbo packet RAM -------------------------
//// half 0
//// ram for one Turbo Packet   (due to InputWidth = 256, so need 2 rams)
//bus2st_1TrbPkt_ram TrbPkt_ram_half0 (
//	.data 			(bus_data[BUS-1 : BUS-RAM_DIN]),	//input	[255:0]  	data;
//	.rdaddress		(bus_mem_rdaddr),	//input	[6:0]  		rdaddress;
//	.rdclock		(clk_st),	//input	  			rdclock;
//	.rden 			(bus_mem_rden),
//	.wraddress		(bus_mem_wraddr),	//input	[6:0]  		wraddress;
//	.wrclock		(clk_bus),	//input	  			wrclock;
//	.wren			(bus_en),	//input	  			wren;
//	.q				(bus_mem_out[2*RAM_DOUT-1 : RAM_DOUT]) 	//output [255:0]  	q;
//	);
//// half 1
//// ram for one Turbo Packet   (due to InputWidth = 256, so need 2 rams)
//bus2st_1TrbPkt_ram TrbPkt_ram_half1 (
//	.data 			(bus_data[BUS-RAM_DIN-1 : BUS-2*RAM_DIN]),	//input	[255:0]  	data;
//	.rdaddress		(bus_mem_rdaddr),	//input	[6:0]  		rdaddress;
//	.rdclock		(clk_st),	//input	  			rdclock;
//	.rden 			(bus_mem_rden),
//	.wraddress		(bus_mem_wraddr),	//input	[6:0]  		wraddress;
//	.wrclock		(clk_bus),	//input	  			wrclock;
//	.wren			(bus_en),	//input	  			wren;
//	.q				(bus_mem_out[RAM_DOUT-1 : 0]) 	//output [255:0]  	q;
//	);
	
	bus2st_1TrbPkt_ram TrbPkt_ram_half1 (
	.data 			(bus_data[BUS-1 : BUS-2*RAM_DIN]),	//input	[255:0]  	data;
	.rdaddress		(bus_mem_rdaddr),	//input	[6:0]  		rdaddress;
	.rdclock		(clk_st),	//input	  			rdclock;
	.rden 			(bus_mem_rden),
	.wraddress		(bus_mem_wraddr),	//input	[6:0]  		wraddress;
	.wrclock		(clk_bus),	//input	  			wrclock;
	.wren			(bus_en),	//input	  			wren;
	.q				(bus_mem_out[2*RAM_DOUT-1 : 0]) 	//output [255:0]  	q;
	);
		//------------------------
		// (output reg mode)
		// rden 	0  1  0  0
		// q    	x  x  x  d1
		//------------------------
//end------------  1 turbo packet RAM -------------------------


//start-----------   clk_st --> clk_bus  ----------------
logic  mem_rd_complt_r1, mem_rd_complt_r0, mem_rd_complt_clk_st;
always@(posedge clk_bus)
begin
	mem_rd_complt_clk_bus <= mem_rd_complt_r1;
	mem_rd_complt_r1 <= mem_rd_complt_r0;
	mem_rd_complt_r0 <= mem_rd_complt_clk_st;
end
//end-----------   clk_st --> clk_bus  ----------------


//start-------------  bus logic ( clk_bus domain)------------
logic bus_fsm;
logic [7:0] cnt_bus_fsm;
logic 	mem_full_trigger;

always@(*)
begin
	bus_ready <= (bus_fsm == 1'h0) && (cnt_bus_fsm != NUM_BUS_PER_TURBO_PKT);
end

always@(posedge clk_bus)
begin
//start--------------  FSM  --------------------
if (!rst_n)
begin
	bus_fsm <= 0;
	cnt_bus_fsm <= 0;
	bus_mem_wraddr <= 0;
	//bus_almost_ready <= 0;
	mem_full_trigger <= 0;
end
else
begin

	case (bus_fsm)
	1'h0:
	begin
		if (bus_en)
		begin
			cnt_bus_fsm <= cnt_bus_fsm + 8'h1;
			bus_mem_wraddr <= bus_mem_wraddr + 7'h1;
		end

		if ( cnt_bus_fsm == NUM_BUS_PER_TURBO_PKT)
			bus_fsm <= 1'h1;
		mem_full_trigger <= 0;

		//if ( cnt_bus_fsm >= NUM_BUS_PER_TURBO_PKT-1)
			//bus_almost_ready <= 1'b0;
		//else
			//bus_almost_ready <= 1'b1;
	end
	1'h1:
	begin
		if ( mem_rd_complt_clk_bus ) 
			bus_fsm <= 1'h0;
		bus_mem_wraddr <= 0;
		cnt_bus_fsm <= 0;
		//bus_almost_ready <= 0;
		mem_full_trigger <= 1'b1;
	end

	default: 
	begin
		bus_fsm <= bus_fsm;
		bus_mem_wraddr <= 0;
		cnt_bus_fsm <= 0;
		//bus_almost_ready <= 0;
	end
	endcase
end
//end--------------  FSM  --------------------
end

	//----------------------------------------
	//		in case NUM_BUS_PER_TURBO_PKT=25
	// en   		: 	1 	0 	0 	1
	// cnt_bus_fsm 	:	23 	24 	24 	24 	25
	// bus_almost_ready:  	1 	0 	0 	0
	// bus_ready    :  		1 	1 	1 	0
	//-----------------------------------

//end-------------  bus logic ( clk_bus domain)------------


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


//start---------  mem out logic (clk_st domain) ----------
logic [1:0] memout_fsm;
logic [10:0] 	cnt_memout_fsm;
logic [3:0] 	cnt_memout_fsm_3;

always@(posedge clk_st)
begin
if (!rst_n_st)
begin
	memout_fsm <= 0;
	bus_mem_rdaddr <= 0;
	bus_mem_rden <= 0;
	cnt_memout_fsm <= 0;
	cnt_memout_fsm_3 <= 0;
	mem_rd_complt_clk_st <= 0;
end
else
begin

	//start------------- FSM  ----------------
	case(memout_fsm)
	2'h0:
	begin
		if (mem_full_trig_clk_st) //trig : trigger
			memout_fsm <= 2'h1;

		bus_mem_rdaddr <= 0;
		bus_mem_rden <= 0;
		cnt_memout_fsm <= 0;
		cnt_memout_fsm_3 <= 0;
		mem_rd_complt_clk_st <= 1'b0;
	end
	2'h1:
	begin
		if (st_ready)
		begin
			memout_fsm <= 2'h2;
			bus_mem_rden <= 1'h1;
		end
		bus_mem_rdaddr <= 0;
		cnt_memout_fsm <= 0;
		cnt_memout_fsm_3 <= 0;
		mem_rd_complt_clk_st <= 1'b0;
	end
	2'h2:
	begin
		cnt_memout_fsm <= (cnt_memout_fsm==NUM_ST_PER_BUS-1) ? 0 : cnt_memout_fsm+11'h1;
		if ( cnt_memout_fsm == NUM_ST_PER_BUS-1)
		begin
			bus_mem_rdaddr <= bus_mem_rdaddr + 7'h1;
			bus_mem_rden <= 1'b1;
		end
		else
		begin
			bus_mem_rdaddr <= bus_mem_rdaddr;
			bus_mem_rden <= 1'b0;
		end 

		if (bus_mem_rdaddr == NUM_BUS_PER_TURBO_PKT-1) 
		begin
			memout_fsm <= 2'h3;
		end
		cnt_memout_fsm_3 <= 0;
		mem_rd_complt_clk_st <= 1'b0;
	end
	2'h3:
	begin
		mem_rd_complt_clk_st <= 1'b1;
		cnt_memout_fsm_3 <= (cnt_memout_fsm_3 == 4'h7) ?  0 : cnt_memout_fsm_3+4'h1;
		if ( cnt_memout_fsm_3 == 4'h7)
		begin
			memout_fsm <= 2'h0;
		end

		cnt_memout_fsm <= 0;
		bus_mem_rdaddr <= 0;
		bus_mem_rden <= 0;
	end
	default: 
	begin
		memout_fsm <= memout_fsm;
		cnt_memout_fsm <= 0;
		cnt_memout_fsm_3 <= 0;
		bus_mem_rdaddr <= 0;
		bus_mem_rden <= 0;
		mem_rd_complt_clk_st <= 1'b0;
	end 
	endcase
	//end-------------  FSM  ----------------
end
end
//end---------  mem out logic (clk_st domain) ----------


//start---------  st out logic ----------------------
logic [13:0] 	cnt_st_TrbPkt;
logic [ST_PER_BUS-1:0]  	bus_mem_out_cp;
logic [1:0]  memout_fsm_q;
logic 		 bus_mem_rden_q, bus_mem_rden_qq;

always@(posedge clk_st)
begin
if (!rst_n_st)
begin
	bus_mem_out_cp <= 0;
	cnt_st_TrbPkt <= 0;
	st_sop <= 0;
	st_eop <= 0;
	st_error <= 0;
	st_valid <= 0;
	st_data <= 0;
	memout_fsm_q <= 0;
	bus_mem_rden_q <= 0;
	bus_mem_rden_qq <= 0;

end
else
begin
	memout_fsm_q <= memout_fsm;
	bus_mem_rden_q <= bus_mem_rden;
	bus_mem_rden_qq <= bus_mem_rden_q;

	if ( bus_mem_rden_qq || (memout_fsm == 2'h1) )
		bus_mem_out_cp <= bus_mem_out;
	else
	begin
		bus_mem_out_cp[ST_PER_BUS-1-ST : 0] <= bus_mem_out_cp[ST_PER_BUS-1 : ST];
		bus_mem_out_cp[ST_PER_BUS-1 : ST_PER_BUS-ST] <= 0;
	end

	st_data <= bus_mem_out_cp[ST-1 : 0];

	if (memout_fsm == 2'h2 && memout_fsm_q == 2'h1)	
			cnt_st_TrbPkt <= 14'h1;
	else
		if ( cnt_st_TrbPkt==0 || cnt_st_TrbPkt==ST_PER_TURBO_PKT+8)
			cnt_st_TrbPkt <= 0;
		else
			cnt_st_TrbPkt <= cnt_st_TrbPkt + 14'h1;

	st_sop <= (cnt_st_TrbPkt==14'h3) ? 1'b1 : 0;
	st_eop <= (cnt_st_TrbPkt==ST_PER_TURBO_PKT+2) ? 1'b1 : 0;
	st_error <= 0;
	if ( cnt_st_TrbPkt==14'h3 )
		st_valid <= 1'b1;
	else if ( cnt_st_TrbPkt==ST_PER_TURBO_PKT+3 ) 
		st_valid <= 1'b0;
	else
		st_valid <= st_valid;
end
end



//end---------  st out logic ----------------------

endmodule