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
//  !  This is a temporary simple version. No ram.  Only for 1024 turbo len case
//
//  set_false_path   between two clks

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
	output 	reg			st_ready,

	input 					clk_bus,   // 400MHz clk
	input 					bus_ready,
	output 	reg [ST_PER_BUS-1:0] 	bus_data,
	output	reg				bus_en

	// output 					data2FlowCtrl   // to Flow Ctrl FIFO  (FROM_BUS2ST_NUM_BUS '1')
	);

// localparam RAM_DIN 		= 256;
// localparam RAM_DOUT 	= 256;

//start-----------   clk_bus --> clk_st  ----------------
logic bus_out_finish_clk_st, bus_out_finish_r1, bus_out_finish_r0,bus_out_finish;
always@(posedge clk_st)
begin
	bus_out_finish_clk_st <= bus_out_finish_r1;
	bus_out_finish_r1 <= bus_out_finish_r0;
	bus_out_finish_r0 <= bus_out_finish;
end

logic rst_n_st_r0, rst_n_st_r1, rst_n_st;
always@(posedge clk_st)
begin
	rst_n_st <= rst_n_st_r1;
	rst_n_st_r1 <= rst_n_st_r0;
	rst_n_st_r0 <= rst_n;
end
//end-----------   clk_bus --> clk_st  ----------------


//start---------   st in    ( Only for 1024 turbo len case ) ----------------
reg  [1:0]		st_fsm;
reg  [7:0]			cnt_st_valid;
reg  [ST_PER_BUS-1 : 0] 	bus_reg0, bus_reg1;
reg 			st_in_finish;
always@(posedge clk_st)
begin
	if (!rst_n_st)
	begin
		st_fsm <= 0;
		cnt_st_valid <= 0;
		st_ready <= 0;
		bus_reg0 <= 0;
		bus_reg1 <= 0;
		st_in_finish <= 0;
	end
	else
	begin
		//start------------- FSM   st------------
		case(st_fsm)  //signaltap
		2'h0:  // write st to bus_reg0
		begin 
			if (st_valid)
			begin
				cnt_st_valid <= (cnt_st_valid == NUM_ST_PER_BUS-1) ? 0 : (cnt_st_valid + 8'd1);
				
				bus_reg0[ST_PER_BUS-1 : ST_PER_BUS-ST] <= st_data;
				bus_reg0[ST_PER_BUS-ST-1 : 0] <= bus_reg0[ST_PER_BUS-1 : ST];

				if (cnt_st_valid == NUM_ST_PER_BUS-1)
					st_fsm <= 2'h1;
			end
			st_ready <= 1'b1;
			st_in_finish <= 0;
		end
		2'h1:  // write st to bus_reg1
		begin 
			if (st_valid)
			begin
				cnt_st_valid <= (cnt_st_valid == NUM_ST_PER_BUS-1) ? 0 : (cnt_st_valid + 8'd1);
				
				bus_reg1[ST_PER_BUS-1 : ST_PER_BUS-ST] <= st_data;
				bus_reg1[ST_PER_BUS-ST-1 : 0] <= bus_reg1[ST_PER_BUS-1 : ST];

				if (cnt_st_valid == NUM_ST_PER_BUS-1)
				begin
					st_fsm <= 2'h2;
					st_in_finish <= 1'b1;
				end
			end
			st_ready <= 1'b1;
		end
		2'h2:
		begin
			st_ready <= 0;

			if (bus_out_finish_clk_st)
				st_fsm <= 2'h0;
			st_in_finish <= 0;
		end
		default:
		begin
			st_fsm <= st_fsm;
			cnt_st_valid <= 0;
			st_ready <= 0;
			bus_reg0 <= 0;
			bus_reg1 <= 0;
			st_in_finish <= 0;
		end
		endcase
		//end------------- FSM   st------------
	end
end
//end ---------   st in    ( Only for 1024 turbo len case ) ----------------


//start-----------   clk_st --> clk_bus  ----------------
logic st_in_finish_clk_bus, st_in_finish_r1, st_in_finish_r0, st_in_finish_clk_st;
always@(posedge clk_bus)
begin
	st_in_finish_clk_bus <= st_in_finish_r1;
	st_in_finish_r1 <= st_in_finish_r0;
	st_in_finish_r0 <= st_in_finish;
end
//end-----------   clk_st --> clk_bus  ----------------


//start---------   bus out  ( Only for 1024 turbo len case ) ----------------
reg [1:0] 		bus_fsm;
reg [7:0]	cnt_bus_fsm_2;
reg [1:0]	cnt_bus_fsm;
always@(posedge clk_bus)
begin
	if (!rst_n)
	begin
		bus_fsm <= 0;
		bus_en <= 0;
		bus_out_finish <= 0;
		cnt_bus_fsm_2 <= 0;
		cnt_bus_fsm <= 0;
		// data2FlowCtrl <= 0;
	end
	else
	begin
		//start ----------- FSM     bus -----------------
		case(bus_fsm)  //signaltap
		2'h0:
		begin
			if (st_in_finish_clk_bus)
				bus_fsm <= 2'h1;
			bus_en <= 0;
			bus_out_finish <= 0;
			cnt_bus_fsm <= 0;
			cnt_bus_fsm_2 <= 0;
			// data2FlowCtrl <= 0;
		end
		2'h1:
		begin
			if (bus_ready)
			begin
				cnt_bus_fsm <= (cnt_bus_fsm == 2'h2) ? 0 : (cnt_bus_fsm + 2'h1);
				if (cnt_bus_fsm == 2'h2)
				begin
					bus_fsm <= 2'h2;
				end
				if (cnt_bus_fsm == 2'h1)
				begin
					bus_data <= bus_reg0;
					bus_en <= 1'b1;
				end
				if (cnt_bus_fsm == 2'h2)
				begin
					bus_data <= bus_reg1;
					bus_en <= 1'b1;
				end
			end
			bus_out_finish <= 0;
			// data2FlowCtrl <= 0;
		end
		2'h2:
		begin
			bus_en <= 0;
			if (cnt_bus_fsm_2 == 8'd25)
			begin
				cnt_bus_fsm_2 <= 0;
				bus_fsm <= 2'd0;
				// data2FlowCtrl <= 0;
			end
			else
			begin
				cnt_bus_fsm_2 <= cnt_bus_fsm_2 + 8'd1;
				// data2FlowCtrl <= 1'b1;  // signaltap
			end
			bus_out_finish <= 1'b1;
		end
		default:
		begin
			bus_fsm <= bus_fsm;
			bus_en <= 0;
			bus_out_finish <= 0;
			cnt_bus_fsm_2 <= 0;
			cnt_bus_fsm <= 0;
			// data2FlowCtrl <= 0;
		end 
		endcase
		//end----------- FSM     bus -----------------
	end
end
//end---------   bus out  ( Only for 1024 turbo len case ) ----------------



endmodule