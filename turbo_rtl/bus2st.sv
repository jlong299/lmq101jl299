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
//  Version 1.0
//  Description : begin to support variable length of AFU frame.  (AFU:Accelerator Func Unit)
//  Main change : clk_bus = clk_st 
//  2016-09-08
//  ---------------------------------------------------------------------------
//           bus  -->  FIFO  -->  st(stream)
//  ---------------------------------------------------------------------------


//  --------------------------- REFERENCE -------------------------------------------
//                  extracts from  pj101 Turbo Dec Acc v1.0 (md format)
//                            2016.9.9

//    ## New version (v1.0) data structure
//    ### Composition of one CL v1.0.1
//    One CL consists of header part and payload part. Header occupies the highest 8 bits and payload occupies the lower 504 bits.
//    > Header  (8) +  Payload (504)
//
//    Header is composed by flag part and length part.
//    > Header = flag (2) + length (6)
//
//    Flag 
//    - 10 : start of one AFU frame
//    - 00 : body of one AFU frame
//    - 01 : end of one AFU frame
//    - 11 : start and end of one AFU frame 
//
//    Length
//    - Unsigned number indicates the valid bytes of payload (from the lowest).  
//
//    >  AFU means Accelerate Function Unit which is turbo decoder in our case 
//
//    For example, if one CL is CL[511:0]. Then the header part is CL[511:504], payload part is CL[503:0].  If CL[511:504] == 8'b01000011, that means this CL is the end of one AFU frame, and  the lowest 7 bytes of payload is valid. Which means CL[7:0], CL[15:8], CL[23:16]. (the lowest the first)
//
//    In order to achieve flexibility, the length of header and payload could be set by changing some parameters in source code. 
//    > Header (8k) + Payload (512-8k)
//
//    ### bus2st 
//    Module description :  Change bus (CL) to st (stream).
//    > In our case,  bus = CL
//    The main steps of bus2st are:
//    - 1) Set bus_ready=1, wait for the first bus of one AFU frame (flag==10). When it arrives, extract payload part and store it into FIFO, extract header part and start counter.
//    - 2) When the last bus of one AFU frame arrives(flag==01), store payload part into FIFO, and stop receiving.  Get the frame length from counter.
//    - 3) When st_ready==1,  output st format data from FIFO according to the frame length.
//    - 4) Go back to 1), flush the FIFO.
//
//    Step 3) of above is a little complicated, because the width of b us may not be an integer times of width of st.  An example of step 3) design can found in my evernote "pj101 v1.0 bus2st | st out stage"
//
//    FSM of bus2st code implementation is as follows.
//
//    ![Alt text](./1473321919098.png)
//
//    ## Further discussion
//    ### Side-band signal
//    For certain applications, side-band signal may be  present to store some information of AFU frame, like serial number. In these cases, side-band signal handling unit acts like a supplementary part of AFU. 
//    Currently we do not need side-band signal in turbo acc program.
//  -----------------------------------------------------------------------------




//-----------------------------------------------------


//              Abort  this version !!!!!
//              2016/09/12


//------------------------------------------------------




module bus2st #(parameter
		BUS =512,  // 512 bits
		BUS_HEAD =8,  // 8 bits
		BUS_PAYLOAD =504, // 504 bits
		ST =24, // 24 bits   // BUS_PAYLOAD must > ST*3 
		w_NumOfBUS_in_AFUFrm =11,  // width of maximum Number of buses in one AFU frame
		w_NumOfByte_in_AFUFrm =16,  // width of maximum Number of bytes in one AFU frame
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
wire [BUS_PAYLOAD-1 : 0] 	q;

reg [1:0]	fsm;

wire 		end_AFU_frm;
reg [w_NumOfBUS_in_AFUFrm -1 : 0] 	NumOfBUS_in_AFUFrm;
reg [w_NumOfByte_in_AFUFrm -1 : 0] 	NumOfByte_in_AFUFrm;

reg 		st_out_finish;
reg [BUS_PAYLOAD-1 : 0] 	q_r;
reg 		rdreq_r, rdreq_rr;
reg [1:0] 	fsm_r, fsm_rr;
reg [w_NumOfBUS_in_AFUFrm -1 : 0] 	NumOfBUS_remain_FIFO;
reg [9:0]		NumOfBits_remain_bus;

//---------  reset sync ------------
always@(posedge clk)
begin
	rst_sync <= rst_r;
	rst_r <= rst_n;
end


//start---------- PART1 :  fifo  &  FSM ------------
ff_bus2st
ff_bus2st_inst(
		.data   (bus_data[BUS_PAYLOAD-1 : 0] ),
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
	case (bus_fsm)
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
		NumOfByte_in_AFUFrm <= 0;
	end

	else
	begin
		if (st_out_finish)
			NumOfBUS_in_AFUFrm <= 0;
		else if (bus_en)
			NumOfBUS_in_AFUFrm <= NumOfBUS_in_AFUFrm + w_NumOfBUS_in_AFUFrm'd1;
		else
			NumOfBUS_in_AFUFrm <= NumOfBUS_in_AFUFrm;

		if (st_out_finish)
			NumOfByte_in_AFUFrm <= 0;
		else if (bus_en)
			NumOfByte_in_AFUFrm <= NumOfByte_in_AFUFrm + bus_data[BUS_HEAD-3 : BUS_HEAD-8];
		else
			NumOfByte_in_AFUFrm <= NumOfByte_in_AFUFrm;
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