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
//
//  ---------------------------------------------------------------------------
//  Version 1.1
//  Description : begin to support variable length of AFU frame.  (AFU:Accelerator Func Unit)
//  Main change : clk_bus = clk_st 
//  2016-09-12
//  ---------------------------------------------------------------------------
//           bus  -->  FIFO  -->  st(stream)
//  ---------------------------------------------------------------------------


//  --------------------------- REFERENCE -------------------------------------------
//                  extracts from     (md format)
//                            2016.9.
//  -----------------------------------------------------------------------------





module bus2st #(parameter
		BUS =512,  // 512 bits
		BUS_HEAD =16,  // 16 bits
		BUS_PAYLOAD =496, // 496 bits
		ST =24, // 24 bits  // There must be at least 2 ST in one bus except the last one. 
		w_NumofST_in_Bus = 9,	// width of maximum Number of STs in one bus
		w_NumOfBUS_in_AFUFrm =11,  // width of maximum Number of buses in one AFU frame
		w_NumOfST_in_AFUFrm =16  // width of maximum Number of STs in one AFU frame
	)
	(
	input 					rst_n,  // clk Asynchronous reset active low
	
	input 					clk,    
	input [BUS-1:0]			bus_data,
	input					bus_en,  // pls make sure bus_en= 0 when bus_ready == 0
	output	reg				bus_ready,

	input					st_ready,
	output	reg [ST-1:0] 	st_data,
	output	reg				st_valid,
	output	reg				st_sop,
	output	reg				st_eop,
	output  reg [w_NumOfST_in_AFUFrm -1 : 0]	st_len
	
);

reg 	rst_r, rst_sync;
reg 	rdreq;
wire [BUS-1 : 0] 	q;

reg [1:0]	fsm;

wire 		end_AFU_frm;
reg [w_NumOfBUS_in_AFUFrm -1 : 0] 	NumOfBUS_in_AFUFrm;

reg 		st_out_finish;
reg [BUS_PAYLOAD-1 : 0] 	q_r;
reg 		rdreq_r, rdreq_rr;
reg [1:0] 	fsm_r, fsm_rr;
reg [w_NumOfBUS_in_AFUFrm -1 : 0] 	NumOfBUS_remain_FIFO;
//reg [9:0]		NumOfBits_remain_bus;

//---------  reset sync ------------
always@(posedge clk)
begin
	rst_sync <= rst_r;
	rst_r <= rst_n;
end


//start---------- PART1 :  fifo  &  FSM ------------
ff_bus2st
ff_bus2st_inst(
		.data   (bus_data),
		.wrreq  (bus_en),
		.rdreq  (rdreq),
		.clock  (clk),
		.sclr   (!rst_sync | st_out_finish ),
		.q      (q    ),
		.full   ( ),
		.empty  ( )
	);


//-------  FSM  ---------
always@(posedge clk)
begin
if (!rst_sync)
begin
	fsm <= 0;
	bus_ready <= 0;
end
else
begin
	case (fsm)
	2'd0: // s_wait
	begin
		if (bus_en)
			fsm <= 2'd1;
		else
			fsm <= 2'd0;
		bus_ready <= 1'b1;
	end
	2'd1: // s_bus_in
	begin
		if (end_AFU_frm)
		begin
			fsm <= 2'd2;
			bus_ready <= 1'b0;
		end
		else
		begin
			fsm <= 2'd1;
			bus_ready <= 1'b1;
		end
	end
	2'd2: // s_bus_end
	begin
		if (st_rdy)
			fsm <= 2'd3;
		else
			fsm <= 2'd2;
		bus_ready <= 1'b0;
	end
	2'd3: // s_st_out
	begin
		if (st_out_finish)
			fsm <= 2'd0;
		else
			fsm <= 2'd3;
		bus_ready <= 1'b0;
	end
	default: 
	begin
		fsm <= 2'd0;
		bus_ready <= 1'b0;
	end
	endcase
end
end
//end  ---------- PART1 :  fifo  &  FSM ------------



//start---------- PART2 :  Bus In  ------------------ 
always@(*)
begin
	end_AFU_frm = bus_en & (bus_data[BUS_HEAD-2]==1'b1)
end

always@(posedge clk)
begin
	if (!rst_sync)
	begin
		NumOfBUS_in_AFUFrm <= 0;
	end

	else
	begin
		if (st_out_finish)
			NumOfBUS_in_AFUFrm <= 0;
		else if (bus_en)
			NumOfBUS_in_AFUFrm <= NumOfBUS_in_AFUFrm + w_NumOfBUS_in_AFUFrm'd1;
		else
			NumOfBUS_in_AFUFrm <= NumOfBUS_in_AFUFrm;
	end
end
//end  ---------- PART2 :  Bus In  ------------------ 


//start---------- PART3.1 :  st out  ------------------
always@(posedge clk)
begin
	if (!rst_sync)
	begin
		rdreq_r <= 0;
		rdreq_rr <= 0;
		q_r <= 0;
		fsm_r <= 0;
		fsm_rr <= 0;
		NumOfBUS_remain_FIFO <= 0;
		NumOfBits_remain_bus <= 0;
		st_out_finish <= 0;
	end

	else
	begin
		rdreq_r  <= rdreq;
		rdreq_rr <= rdreq_r;
		fsm_r   <= fsm;
		fsm_rr 	<= fsm_r;

		if (rdreq_r)
			q_r <= { q[ST-1 : 0] , q[BUS_PAYLOAD-1 : ST] };
		else
			q_r <= { q_r[ST-1 : 0] , q_r[BUS_PAYLOAD-1 : ST] };

		if (fsm == 2'd2)
			NumOfBUS_remain_FIFO <= NumOfBUS_in_AFUFrm;
		else if(rdreq)
			NumOfBUS_remain_FIFO <= NumOfBUS_remain_FIFO - w_NumOfBUS_in_AFUFrm'd1;
		else
			NumOfBUS_remain_FIFO <= NumOfBUS_remain_FIFO;

		if (fsm_rr != 2'd3 )
			NumOfBits_remain_bus <= 0;
		else if (rdreq_r)
			NumOfBits_remain_bus <= NumOfBits_remain_bus + BUS_PAYLOAD[9:0] - ST[9:0];
		else
			NumOfBits_remain_bus <= NumOfBits_remain_bus - ST[9:0];

		if (fsm != 2'd3  || NumOfBUS_remain_FIFO == 0 ) 
			rdreq <= 0;
		else if ( fsm == 2'd3 &&  NumOfBits_remain_bus < 3*(ST[9:0]) )
			rdreq <= 1'b1 & (!rdreq_r) & (!rdreq_rr)
		else
			rdreq <= 0;

		//!!! Wrong!  if (fsm == 2'd3 && NumOfBUS_remain_FIFO == 0 && NumOfBits_remain_bus < 2*(ST[9:0]) )
			st_out_finish <= 1'b1 & (!rdreq_r);
		else
			st_out_finish <= 1'b0;
	end
end
//end  ---------- PART3.1 :  st out  ------------------


//start---------- PART3.2 :  st out  --  st_data description ------------------
//!!!!!!  This is a universal version which accommodates all ST values, 
//!!!!!!  but may cause worse timing result.
always@(posedge clk)
begin
	if (!rst_sync)
	begin
		st_data <= 0;
	end
	else















assign st_eop = st_out_finish;


//start---------- PART3.3 :  st out  --  st_len description ------------------
//!!!!!!  This part only supports certain ST values. 
//!!!!!!  If you need new ST value support, modify the "case" part.
always@(posedge clk)
begin
	if (!rst_sync)
	begin
		st_len <= 0;
	end
	else
	begin
		if (fsm == 2'd2)
			case (ST)
			24 : 	st_len <= NumOfByte_in_AFUFrm/3;
			12 : 	st_len <= (2*NumOfByte_in_AFUFrm)/3;
			default :  blabla
		else
			st_len <= st_len;
	end
end

endmodule