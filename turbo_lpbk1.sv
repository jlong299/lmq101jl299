// ***************************************************************************
// Copyright (c) 2013-2016, Intel Corporation
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// * Neither the name of Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Module Name:         test_lpbk1.v
// Project:             NLB AFU
// Description:         memory copy test
//
// ***************************************************************************
// ---------------------------------------------------------------------------------------------------------------------------------------------------
//                                         Loopback 1- memory copy test
//  ------------------------------------------------------------------------------------------------------------------------------------------------
//
// This is a memory copy test. It copies cache lines from source to destination buffer.
//

module turbo_lpbk1 #(parameter PEND_THRESH=1, ADDR_LMT=20, MDATA=14)
(

//      ---------------------------global signals-------------------------------------------------
       Clk_400               ,        // in    std_logic;  -- Core clock
       uClk_usrDiv2,      // User clock domain. Half the programmed frequency  ** Currently provides fixed 150MHz clock **

       l12ab_WrAddr,                   // [ADDR_LMT-1:0]        arb:               write address
       l12ab_WrTID,                    // [ADDR_LMT-1:0]        arb:               meta data
       l12ab_WrDin,                    // [511:0]               arb:               Cache line data
       l12ab_WrEn,                     //                       arb:               write enable
       ab2l1_WrSent,                   //                       arb:               write issued
       ab2l1_WrAlmFull,                //                       arb:               write fifo almost full

       l12ab_RdAddr,                   // [ADDR_LMT-1:0]        arb:               Reads may yield to writes
       l12ab_RdTID,                    // [15:0]                arb:               meta data
       l12ab_RdEn,                     //                       arb:               read enable
       ab2l1_RdSent,                   //                       arb:               read issued

       ab2l1_RdRspValid_T0,            //                       arb:               read response valid
       ab2l1_RdRsp_T0,                 // [15:0]                arb:               read response header
       ab2l1_RdRspAddr_T0,             // [ADDR_LMT-1:0]        arb:               read response address
       ab2l1_RdData_T0,                // [511:0]               arb:               read data
       ab2l1_stallRd,                  //                       arb:               stall read requests FOR LPBK1

       ab2l1_WrRspValid_T0,            //                       arb:               write response valid
       ab2l1_WrRsp_T0,                 // [15:0]                arb:               write response header
       ab2l1_WrRspAddr_T0,             // [ADDR_LMT-1:0]        arb:               write response address
       re2xy_go,                       //                       requestor:         start the test
       re2xy_NumLines,                 // [31:0]                requestor:         number of cache lines
       re2xy_Cont,                     //                       requestor:         continuous mode

       l12ab_TestCmp,                  //                       arb:               Test completion flag
       l12ab_ErrorInfo,                // [255:0]               arb:               error information
       l12ab_ErrorValid,               //                       arb:               test has detected an error
       test_Resetb,                    //                       requestor:         rest the app

       l12ab_RdLen,
       l12ab_RdSop,
       l12ab_WrLen,
       l12ab_WrSop,

       ab2l1_RdRspFormat,
       ab2l1_RdRspCLnum_T0,
       ab2l1_WrRspFormat_T0,
       ab2l1_WrRspCLnum_T0,
       re2xy_multiCL_len
);
    input                   Clk_400;               //                      csi_top:            Clk_400
    input 						 uClk_usrDiv2;

    output  [ADDR_LMT-1:0]  l12ab_WrAddr;           // [ADDR_LMT-1:0]        arb:               write address
    output  [15:0]          l12ab_WrTID;            // [15:0]                arb:               meta data
    output  [511:0]         l12ab_WrDin;            // [511:0]               arb:               Cache line data
    output                  l12ab_WrEn;             //                       arb:               write enable
    input                   ab2l1_WrSent;           //                       arb:               write issued
    input                   ab2l1_WrAlmFull;        //                       arb:               write fifo almost full

    output  [ADDR_LMT-1:0]  l12ab_RdAddr;           // [ADDR_LMT-1:0]        arb:               Reads may yield to writes
    output  [15:0]          l12ab_RdTID;            // [15:0]                arb:               meta data
    output                  l12ab_RdEn;             //                       arb:               read enable
    input                   ab2l1_RdSent;           //                       arb:               read issued

    input                   ab2l1_RdRspValid_T0;    //                       arb:               read response valid
    input  [15:0]           ab2l1_RdRsp_T0;         // [15:0]                arb:               read response header
    input  [ADDR_LMT-1:0]   ab2l1_RdRspAddr_T0;     // [ADDR_LMT-1:0]        arb:               read response address
    input  [511:0]          ab2l1_RdData_T0;        // [511:0]               arb:               read data
    input                   ab2l1_stallRd;          //                       arb:               stall read requests FOR LPBK1

    input                   ab2l1_WrRspValid_T0;    //                       arb:               write response valid
    input  [15:0]           ab2l1_WrRsp_T0;         // [15:0]                arb:               write response header
    input  [ADDR_LMT-1:0]   ab2l1_WrRspAddr_T0;     // [Addr_LMT-1:0]        arb:               write response address

    input                   re2xy_go;               //                       requestor:         start of frame recvd
    input  [31:0]           re2xy_NumLines;         // [31:0]                requestor:         number of cache lines
    input                   re2xy_Cont;             //                       requestor:         continuous mode

    output                  l12ab_TestCmp;          //                       arb:               Test completion flag
    output [255:0]          l12ab_ErrorInfo;        // [255:0]               arb:               error information
    output                  l12ab_ErrorValid;       //                       arb:               test has detected an error
    input                   test_Resetb;

    output [1:0]            l12ab_RdLen;
    output                  l12ab_RdSop;
    output [1:0]            l12ab_WrLen;
    output                  l12ab_WrSop;

    input                   ab2l1_RdRspFormat;
    input  [1:0]            ab2l1_RdRspCLnum_T0;
    input                   ab2l1_WrRspFormat_T0;
    input  [1:0]            ab2l1_WrRspCLnum_T0;

    input  [1:0]            re2xy_multiCL_len;

    //------------------------------------------------------------------------------------------------------------------------

    reg     [ADDR_LMT-1:0]  l12ab_WrAddr;           // [ADDR_LMT-1:0]        arb:               Writes are guaranteed to be accepted
    reg     [15:0]          l12ab_WrTID;            // [15:0]                arb:               meta data
    reg     [511:0]         l12ab_WrDin;            // [511:0]               arb:               Cache line data
    reg                     l12ab_WrEn;             //                       arb:               write enable
    reg     [ADDR_LMT-1:0]  l12ab_RdAddr;           // [ADDR_LMT-1:0]        arb:               Reads may yield to writes
    reg     [15:0]          l12ab_RdTID;            // [15:0]                arb:               meta data
    reg                     l12ab_RdEn;             //                       arb:               read enable
    reg                     l12ab_TestCmp;          //                       arb:               Test completion flag
    reg    [255:0]          l12ab_ErrorInfo;        // [255:0]               arb:               error information
    reg                     l12ab_ErrorValid;       //                       arb:               test has detected an error

    reg     [MDATA-1:0]     wr_mdata;
    reg     [1:0]           read_fsm;
    reg                     write_fsm, write_fsm_q;
    reg     [19:0]          Num_Read_req;
    reg     [19:0]          Num_Write_req;
    reg     [19:0]          Num_Write_rsp;
    reg     [1:0]           l12ab_RdLen;
    reg                     l12ab_RdSop;
    reg     [1:0]           l12ab_WrLen;
    reg                     l12ab_WrSop;

    // ----------------------------------------------------------------------------
    // Duplicate registers with high routing congestion to relax timing
    // -----------------------------------------------------------------------------
    // (* maxfan=2   *) reg   [6:0]       rd_mdata, rd_mdata_next; // limit max mdata to 8 bits or 256 requests
    // (* maxfan=1   *) reg   [2**7-1:0]  rd_mdata_pend;           // bitvector to track used mdata values
    // (* maxfan=1   *) reg               rd_mdata_avail;          // is the next rd madata free and available
    // (* maxfan=32  *) logic [8:0]       memwr_addr;
    // (* maxfan=1   *) logic [3:0]       RdRsp_vector_bank[0:15][0:7];
    // (* maxfan=1   *) logic [15:0]      ab2l1_RdRsp;
    // (* maxfan=1   *) logic [6:0]       ab2l1_RdRsp_q;
    reg   [6:0]       rd_mdata, rd_mdata_next; // limit max mdata to 8 bits or 256 requests
    reg   [2**7-1:0]  rd_mdata_pend;           // bitvector to track used mdata values
    reg               rd_mdata_avail;          // is the next rd madata free and available
    logic [8:0]       memwr_addr;
    logic [3:0]       RdRsp_vector_bank[0:15][0:7];
    logic [15:0]      ab2l1_RdRsp;
    logic [6:0]       ab2l1_RdRsp_q;

    // ------------------------------------------------------
    // RAM to store RdRsp Data and Address
    // ------------------------------------------------------
    logic [533:0] rdrsp_mem_in;
    logic [533:0] wrreq_mem_out;
    logic [533:0] wrreq_mem_out_q;
    logic [8:0]   memrd_addr;
    logic         memwr_en;

    // 2 cycle Read latency
    // 2 cycle Rd2Wr latency
    // Unknown data returned if same address is read, written
    lpbk1_RdRspRAM2PORT rdrsp_mem (
      .data      (rdrsp_mem_in),    //[533:0]  ram_input.datain
      .wraddress (memwr_addr),      //[8:0]             .wraddress
      .rdaddress (memrd_addr),      //[8:0]             .rdaddress
      .wren      (memwr_en),        //                  .wren
      .clock     (Clk_400),         //                  .clock
      .q         (wrreq_mem_out)    //[533:0] ram_output.dataout
    );
    // ------------------------------------------------------
    logic                Wr_go, Wr_go_q;
    logic                ram_rdValid;
    logic                ram_rdValid_q;
    logic                ram_rdValid_qq;
    logic                ram_rdValid_qqq;
    logic                wrsop;
    logic                wrsop_q;
    logic                wrsop_qq;
    logic                wrsop_qqq;
    logic [7:0]          i;
    logic [6:0]          WrReq_tid, WrReq_tid_q;
    logic [6:0]          WrReq_tid_mCL;
    logic [1:0]          CL_ID;
    logic [1:0]          wrCLnum;
    logic [1:0]          wrCLnum_q;
    logic [1:0]          wrCLnum_qq;
    logic [1:0]          wrCLnum_qqq;
    logic [2:0]          multiCL_num;
    logic                ab2l1_RdRspValid_q;
    logic                RdRsp_vector_bank_Ready[0:15] [0:7];
    logic [1:0]          ab2l1_RdRspCLnum;
    logic [ADDR_LMT-1:0] ab2l1_RdRspAddr;
    logic [511:0]        ab2l1_RdData;
    logic                ab2l1_RdRspValid;

    logic [3:0]          RdRsp_is_Ready;
    logic [3:0]          new_RdRsp_tracker;
    logic [3:0]          new_RdRsp_tracker_q;
    logic [3:0]          old_RdRsp_tracker;
    logic                b2b_RdRsp;

    logic [15:0]         ab2l1_WrRsp;
    logic [1:0]          ab2l1_WrRspCLnum;
    logic [ADDR_LMT-1:0] ab2l1_WrRspAddr;
    logic                ab2l1_WrRspFormat;
    logic                ab2l1_WrRspValid;

    logic [4:0]       cnt_gap_turbo_go;
    logic             gap_turbo_go;
    logic             bus2st_ready;
    reg               bus2st_mem_rd_finish;
    reg               bus2st_mem_rd_finish_q;
    reg [7:0]         cnt_mdata_pend;
    reg [1:0]         mode_mdata_pend;

    // Timing fix: Registering WrRsp inputs - Adds 1 additional cycle bw last WrRsp to completion
    always@(posedge Clk_400)
    begin
      ab2l1_WrRsp        <= ab2l1_WrRsp_T0;
      ab2l1_WrRspCLnum   <= ab2l1_WrRspCLnum_T0;
      ab2l1_WrRspAddr    <= ab2l1_WrRspAddr_T0;
      ab2l1_WrRspFormat  <= ab2l1_WrRspFormat_T0;
      ab2l1_WrRspValid   <= ab2l1_WrRspValid_T0;
    end

    // Timing fix: Registering RdRsp inputs - Adds 1 additional cycle bw RdRsp to WrReq
    always@(posedge Clk_400)
    begin
      ab2l1_RdRsp        <= ab2l1_RdRsp_T0;
      ab2l1_RdRspCLnum   <= ab2l1_RdRspCLnum_T0;
      ab2l1_RdRspAddr    <= ab2l1_RdRspAddr_T0;
      ab2l1_RdData       <= ab2l1_RdData_T0;
      ab2l1_RdRspValid   <= ab2l1_RdRspValid_T0;

      if (ab2l1_RdRspValid_T0 && ab2l1_RdRspValid && ab2l1_RdRsp_T0[6:0] == ab2l1_RdRsp[6:0])
      begin
        b2b_RdRsp        <= 1;
      end

      else
      begin
        b2b_RdRsp        <= 0;
      end
    end

    always @(posedge Clk_400)
    begin
      memwr_en                          <= 0;
      memwr_addr                        <= {ab2l1_RdRsp[6:0],ab2l1_RdRspCLnum[1:0]};
      rdrsp_mem_in                      <= {ab2l1_RdData[511:0],ab2l1_RdRspAddr[19:0],ab2l1_RdRspCLnum[1:0]};

      // Store RdResponses in RAM
      if(ab2l1_RdRspValid)
      begin
        memwr_en                        <= 1;
      end

      // One-hot RdRsp-Tracker
      begin
        if (!test_Resetb)
        begin
          RdRsp_is_Ready                <= 4'b0000;
          new_RdRsp_tracker             <= 4'b0000;
          new_RdRsp_tracker_q           <= 4'b0000;
          old_RdRsp_tracker             <= 4'b0000;
        end

        else
        begin
          // Static Update based on multi CL length
          case (re2xy_multiCL_len)
            2'b00  :  RdRsp_is_Ready    <= 4'b0001;
            2'b01  :  RdRsp_is_Ready    <= 4'b0011;
            2'b11  :  RdRsp_is_Ready    <= 4'b1111;
            default:  RdRsp_is_Ready    <= 4'b0001;
          endcase

          // Update vector based on current CL RdRsp
          case (ab2l1_RdRspCLnum_T0)
            2'b00  :  new_RdRsp_tracker <= 4'b0001;
            2'b01  :  new_RdRsp_tracker <= 4'b0010;
            2'b10  :  new_RdRsp_tracker <= 4'b0100;
            2'b11  :  new_RdRsp_tracker <= 4'b1000;
          endcase

          new_RdRsp_tracker_q           <= new_RdRsp_tracker;
        end
      end

      // 2 cycles to update numRdRsp vector
      begin
        // Register Read Responses
        ab2l1_RdRspValid_q                       <= ab2l1_RdRspValid;
        ab2l1_RdRsp_q                            <= ab2l1_RdRsp;

        // It takes 2 cycles to update RdRsp vector RF
        // If there are 2 successive RspValids to the same entry in RdRsp vector,
        // Forwarding current cycle response while updating RdRsp vector for prev response
        // 1st cycle - READ from RF
        // 2nd cycle - MODIFY + WRITE to RF
        // If there is rsp valid to same entry in 2nd cycle --> MODIFY includes forwarded value.
        // If all RdRsp required for initiating a write is received, Updating Ready vector is overlapped with MODIFY + WRITE

        // if (ab2l1_RdRspValid)
        // begin
        //   if (b2b_RdRsp)
        //   begin
        //     old_RdRsp_tracker                    <= (RdRsp_vector_bank[ab2l1_RdRsp_q[6:3]][ab2l1_RdRsp_q[2:0]][3:0]) | new_RdRsp_tracker_q;
        //   end

        //   // Response Received, Read current count from RdRsp vector
        //   else
        //   begin
        //     old_RdRsp_tracker                    <= RdRsp_vector_bank[ab2l1_RdRsp[6:3]][ab2l1_RdRsp[2:0]][3:0];
        //   end
        // end

        // Update RdRsp vector
        if (ab2l1_RdRspValid_q)
        begin
          //RdRsp_vector_bank[ab2l1_RdRsp_q[6:3]][ab2l1_RdRsp_q[2:0]][3:0] <= new_RdRsp_tracker_q | old_RdRsp_tracker;
          RdRsp_vector_bank[ab2l1_RdRsp_q[6:3]][ab2l1_RdRsp_q[2:0]][3:0] <= 4'b0001;
          //if ((new_RdRsp_tracker_q | old_RdRsp_tracker) == RdRsp_is_Ready)
          //begin
            RdRsp_vector_bank_Ready[ab2l1_RdRsp_q[6:3]][ab2l1_RdRsp_q[2:0]]    <= 1;
          //end
        end
      end

      // Insert gap to wr_go, in order to prevent bus2st ram full
      begin
        if (!test_Resetb)
        begin
          cnt_gap_turbo_go <= 0;
          gap_turbo_go <= 0;
        end
        else
        begin
          if (cnt_gap_turbo_go==5'h10)
          begin
            cnt_gap_turbo_go <= 0;
            gap_turbo_go <= 1'b1;
          end
          else
          begin
            cnt_gap_turbo_go <= cnt_gap_turbo_go + 5'h1;
            gap_turbo_go <= 0;
          end
        end
      end

      // Compute next Write Request number and update Write go
      begin
        Wr_go                  <= (RdRsp_vector_bank_Ready[WrReq_tid[6:3]][WrReq_tid[2:0]]) & gap_turbo_go & bus2st_ready;
        if (Wr_go && !write_fsm)
        begin
          // Store TID for mCL requests and update TID
          WrReq_tid_mCL                                          <= WrReq_tid[6:0];
          WrReq_tid[6:0]                                         <= WrReq_tid[6:0] + 1'h1;

          // Clear RdRsp vectors
          RdRsp_vector_bank[WrReq_tid[6:3]][WrReq_tid[2:0]][3:0] <= 4'h0;
          RdRsp_vector_bank_Ready[WrReq_tid[6:3]][WrReq_tid[2:0]]<= 1'h0;
        end

        // Make corresponding Rd mdata available in next clk
        Wr_go_q                                                  <= Wr_go;
        write_fsm_q                                              <= write_fsm;
        WrReq_tid_q                                              <= WrReq_tid;
        // if (Wr_go_q & !write_fsm_q)
        // begin
        //   rd_mdata_pend[{WrReq_tid_q[6:3],WrReq_tid_q[2:0]}]     <= 1'b0;
        // end

      end

      // FSM to send mem write requests
      // Requestor Stores Tx Writes in a FIFO
      // TxFIFO is sized in such a way that writes are guaranteed to be accepted
      // So, ab2l1_WrSent = 0 when WrEn=1 is an error condition
      case (write_fsm)   /* synthesis parallel_case */
      1'h0:
        begin
        if (Wr_go)
        begin
          // Read first CL of 'num_multi_CL' memWrite requests from RAM
          write_fsm                        <= 1'h1;
          CL_ID                            <= CL_ID + 1'b1;
          memrd_addr                       <= {WrReq_tid[6:0], CL_ID};
          ram_rdValid                      <= 1;
          wrsop                            <= 1;
          wrCLnum                          <= re2xy_multiCL_len[1:0];
        end
        end

      1'h1:
        begin
          // if (|wrCLnum[1:0])
          // begin
          // // Read remaining CLs of 're2xy_multiCL_len' memWrite requests from RAM
          // write_fsm                        <= 1'h1;
          // CL_ID                            <= CL_ID + 1'b1;
          // memrd_addr                       <= {WrReq_tid_mCL[6:0], CL_ID};
          // ram_rdValid                      <= 1;
          // wrsop                            <= 0;
          // wrCLnum                          <= wrCLnum - 1'b1;
          // end

          // else
          begin
          // Goto next set of multiCL requests
          // One cycle bubble between each set of multi CL writes.
          // TODO: optimize
          write_fsm                        <= 1'h0;
          CL_ID                            <= 0;
          ram_rdValid                      <= 0;
          wrsop                            <= 1;
          wrCLnum                          <= re2xy_multiCL_len[1:0];
          end
        end

      default:
      begin
        write_fsm                            <= write_fsm;
      end
      endcase

      // Pipeline WrReq parameters till RAM output is valid
      ram_rdValid_q                            <= ram_rdValid;
      ram_rdValid_qq                           <= ram_rdValid_q;
      ram_rdValid_qqq                          <= ram_rdValid_qq;

      wrsop_q                                  <= wrsop;
      wrsop_qq                                 <= wrsop_q;
      wrsop_qqq                                <= wrsop_qq;

      wrCLnum_q                                <= wrCLnum;
      wrCLnum_qq                               <= wrCLnum_q;
      wrCLnum_qqq                              <= wrCLnum_qq;

      wrreq_mem_out_q                          <= wrreq_mem_out;

      // // send Multi CL Write Requests
      // l12ab_WrEn                               <= (ram_rdValid_qqq == 1'b1);
      // l12ab_WrAddr                             <= wrreq_mem_out_q[21:2] + wrreq_mem_out_q[1:0] ;
      // l12ab_WrDin                              <= wrreq_mem_out_q[533:22];
      // l12ab_WrTID[15:0]                        <= wrreq_mem_out_q[17:2];
      // l12ab_WrSop                              <= wrsop_qqq;
      // l12ab_WrLen                              <= wrCLnum_qqq;


      // Track Num Write requests
      if (l12ab_WrEn)
      begin
        Num_Write_req                          <= Num_Write_req   + 1'b1;
      end

      // Track Num Write responses
      if(ab2l1_WrRspValid && ab2l1_WrRspFormat)   // Packed write response
      begin
        Num_Write_rsp                          <= Num_Write_rsp + 1'b1 + ab2l1_WrRspCLnum;
      end

      else if (ab2l1_WrRspValid)                  // unpacked write response
      begin
        Num_Write_rsp                          <= Num_Write_rsp + 1'b1;
      end

      // // Meta data locked when RdSent
      // if(l12ab_RdEn && ab2l1_RdSent)
      // begin
      //   rd_mdata_pend[rd_mdata]                <= 1'b1;
      // end

      if (!test_Resetb)
      begin
        Wr_go                                  <= 0;
        memwr_en                               <= 0;

        for (i=0; i[7]!=1; i=i+1'b1)
        begin
        RdRsp_vector_bank[i[6:3]][i[2:0]]      <= 0;
        RdRsp_vector_bank_Ready[i[6:3]][i[2:0]]<= 0;
        end

        multiCL_num                            <= 1;
        rd_mdata_pend                          <= 0;
        write_fsm                              <= 1'h0;
        WrReq_tid                              <= 0;
        WrReq_tid_mCL                          <= 0;
        CL_ID                                  <= 0;
        ram_rdValid                            <= 0;
        wrsop                                  <= 1;
        wrCLnum                                <= 0;
        //l12ab_WrEn                             <= 0;
        //l12ab_WrSop                            <= 1;
        //l12ab_WrLen                            <= 0;
        Num_Write_req                          <= 20'h1;
        Num_Write_rsp                          <= 0;
      end
    end

    always @(posedge Clk_400)
    begin
            //Read FSM
            case(read_fsm)  /* synthesis parallel_case */
            2'h0:
            begin  // Wait for re2xy_go
              l12ab_RdAddr                       <= 0;
              l12ab_RdLen                        <= re2xy_multiCL_len;
              l12ab_RdSop                        <= 1'b1;
              Num_Read_req                       <= 20'h0 + re2xy_multiCL_len + 1'b1;       // Default is 1 req; implies single CL

              if(re2xy_go)
                if(re2xy_NumLines!=0)
                  read_fsm                       <= 2'h1;
                else
                  read_fsm                       <= 2'h2;
            end

            2'h1:
            begin  // Send read requests
              if(ab2l1_RdSent)
              begin
                l12ab_RdAddr                     <= l12ab_RdAddr + re2xy_multiCL_len + 1'b1; // multiCL_len = {0/1/2/3}
                l12ab_RdLen                      <= l12ab_RdLen;                             // All reqs are uniform. Based on test cfg
                l12ab_RdSop                      <= 1'b1;                                    // All reqs are uniform. Based on test cfg
                Num_Read_req                     <= Num_Read_req + re2xy_multiCL_len + 1'b1; // final count will be same as re2xy_NumLines

                if(Num_Read_req == re2xy_NumLines)
                if(re2xy_Cont)    read_fsm       <= 2'h0;
                else              read_fsm       <= 2'h2;
              end // ab2l1_RdSent
            end

            default:              read_fsm       <= read_fsm;
            endcase

            if(l12ab_RdEn && ab2l1_RdSent)
            begin
              rd_mdata_next                      <= rd_mdata + 2'h2;
              rd_mdata                           <= rd_mdata_next;
              //rd_mdata_avail                     <= !rd_mdata_pend[rd_mdata_next];
            end
            else
            begin
              //rd_mdata_avail                     <= !rd_mdata_pend[rd_mdata];
              rd_mdata_next                      <= rd_mdata + 1'h1;
            end


            //start -------- cnt_mdata_pend   substitute  rd_mdata_pend[] -----
            bus2st_mem_rd_finish_q <= bus2st_mem_rd_finish;

            if(l12ab_RdEn && ab2l1_RdSent)
            begin
              if (bus2st_mem_rd_finish & (!bus2st_mem_rd_finish_q))
              begin
                mode_mdata_pend <= 2'h3;
              end
              else
                mode_mdata_pend <= 2'h1;
            end
            else if (bus2st_mem_rd_finish & (!bus2st_mem_rd_finish_q))
              mode_mdata_pend <= 2'h2;
            else
              mode_mdata_pend <= 2'h0;


            case(mode_mdata_pend)
            2'h0:
            begin
              cnt_mdata_pend <= cnt_mdata_pend;
            end
            2'h1:
            begin
              cnt_mdata_pend <= cnt_mdata_pend + 8'd1;
            end
            2'h2:
            begin
              if (cnt_mdata_pend >= 8'd25)
                  cnt_mdata_pend <= cnt_mdata_pend - 8'd25;
              else
                  cnt_mdata_pend <= 8'd0;
            end
            2'h3:
            begin
              if (cnt_mdata_pend >= 8'd24)
                cnt_mdata_pend <= cnt_mdata_pend - 8'd24;
              else
                cnt_mdata_pend <= 8'd0;
            end
            default:
            begin
              cnt_mdata_pend <= cnt_mdata_pend;
            end
            endcase

            if (cnt_mdata_pend[6:5] == 2'b11)
              rd_mdata_avail <= 1'b0;
            else
              rd_mdata_avail <= 1'b1;
            //end -------- cnt_mdata_pend   substitute  rd_mdata_pend[] -----


            // TODO:
            if(read_fsm==2'h2 && Num_Write_rsp==re2xy_NumLines)
            begin
              l12ab_TestCmp                      <= 1'b1;
            end

            // Error logic
            if(l12ab_WrEn && ab2l1_WrSent==0)
            begin
              // WrFSM assumption is broken
              $display ("%m LPBK1 test WrEn asserted, but request Not accepted by requestor");
              l12ab_ErrorValid                   <= 1'b1;
              l12ab_ErrorInfo                    <= 1'b1;
            end

            if(!test_Resetb)
            begin
//            l12ab_WrAddr                       <= 0;
//            l12ab_RdAddr                       <= 0;
              l12ab_TestCmp                      <= 0;
              l12ab_ErrorInfo                    <= 0;
              l12ab_ErrorValid                   <= 0;
              read_fsm                           <= 0;
              rd_mdata                           <= 0;
              rd_mdata_avail                     <= 1'b1;
              Num_Read_req                       <= 20'h1;
              l12ab_RdLen                        <= 0;
              l12ab_RdSop                        <= 1;
              bus2st_mem_rd_finish_q             <= 0;
              cnt_mdata_pend                     <= 0;
              mode_mdata_pend                     <= 2'h0;
            end
    end

    always @(*)
    begin
      l12ab_RdTID = 0;
      l12ab_RdTID[MDATA-1:0] = rd_mdata;
      l12ab_RdEn = (read_fsm  ==2'h1) & !ab2l1_stallRd & rd_mdata_avail;
    end



  reg [12-1:0]  st_data  ;
  reg       st_valid  ;
  reg       st_sop  ;
  reg       st_eop  ;
  reg       st_error  ;

  logic     trb_sink_error;
  logic     trb_sink_ready;
  logic [0:0] trb_sel_crc24a;
  logic [4:0] trb_sink_max_iter;
  logic [12:0]  trb_sink_blk_size;
  logic     trb_source_valid /* synthesis keep */ ;
  logic   trb_source_ready;
  logic   [1:0] trb_source_error;
  logic     trb_source_sop /* synthesis keep */ ;
  logic     trb_source_eop /* synthesis keep */ ;
  logic   [0:0] trb_crc_pass;
  logic   [0:0] trb_crc_type;
  logic   [4:0] trb_source_iter;
  logic   [12:0]  trb_source_blk_size;
  logic   [7:0] trb_source_data_s /* synthesis keep */ ;
  
  reg     st_out_ready;

  bus2st #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (42), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (1028),   // 1024+4
    .NUM_BUS_PER_TURBO_PKT (25),
    .ST (12)
  )
  inst_bus2st
  (
   .rst_n       (test_Resetb),
   .clk_bus     (Clk_400),
   .bus_data    (wrreq_mem_out_q),
   .bus_en      (ram_rdValid_qqq),
   .bus_ready   (bus2st_ready),

   .clk_st      (uClk_usrDiv2),
   .st_ready    (st_out_ready),
   .st_data     (st_data),
   .st_valid    (st_valid),
   .st_sop      (st_sop),
   .st_eop      (st_eop),
   .st_error    (st_error),

   .mem_rd_complt_clk_bus  (bus2st_mem_rd_finish)

  );

  ready_adjust inst_ready_adjust
  (
    .rst_n      (test_Resetb),
    .clk        (uClk_usrDiv2),

    .ready_in   (trb_sink_ready),
    .sink_eop   (st_eop),
    .source_eop (trb_source_eop),

    .ready_out  (st_out_ready)
    );

always@(posedge uClk_usrDiv2)
begin
  trb_sink_blk_size <= 13'd1024;
  //trb_source_ready <= 1'b1;
  trb_sink_error <= 2'b00;
  trb_sink_max_iter <= 5'd8;
  trb_sel_crc24a <= 1'b0;
end

  turbo_d0 turbo_d0_inst (
  .clk             (uClk_usrDiv2),             //    clk.clk
  .reset_n         (test_Resetb        ),   //    rst.reset_n
  .sink_valid      (st_valid     ),   //   sink.sink_valid
  .sink_ready      (trb_sink_ready     ),   //       .sink_ready
  .sink_error      (trb_sink_error     ),   //       .sink_error
  .sink_sop        (st_sop       ),   //       .sink_sop
  .sink_eop        (st_eop       ),   //       .sink_eop
  .sel_crc24a      (trb_sel_crc24a     ),   //       .sel_crc24a
  .sink_max_iter   (trb_sink_max_iter  ),   //       .sink_max_iter
  .sink_blk_size   (trb_sink_blk_size  ),   //       .sink_blk_size
  .sink_data       (st_data      ),   //       .sink_data
  .source_valid    (trb_source_valid   ),   // source.source_valid
  .source_ready    (trb_source_ready   ),   //       .source_ready
  .source_error    (trb_source_error   ),   //       .source_error
  .source_sop      (trb_source_sop     ),   //       .source_sop
  .source_eop      (trb_source_eop     ),   //       .source_eop
  .crc_pass        (trb_crc_pass       ),   //       .crc_pass
  .crc_type        (trb_crc_type       ),   //       .crc_type
  .source_iter     (trb_source_iter    ),   //       .source_iter
  .source_blk_size (trb_source_blk_size),   //       .source_blk_size
  .source_data_s   (trb_source_data_s  )    //       .source_data_s
);

reg [15:0]      cnt_trb_dly_L /* synthesis keep */;
reg [15:0]      cnt_trb_dly_H /* synthesis keep */;
reg [15:0]      cnt_trb_src_eop /* synthesis keep */;
reg start_cnt;

always@(posedge uClk_usrDiv2)
begin
  if (!test_Resetb)
  begin
    cnt_trb_dly_L <= 0;
    cnt_trb_dly_H <= 0;
    cnt_trb_src_eop <= 0;
    start_cnt <= 0;
  end
  else
  begin
    if (st_sop)
      start_cnt <= 1'b1;
    else
      start_cnt <= start_cnt;

    if (start_cnt)
    begin
      cnt_trb_dly_L <= cnt_trb_dly_L + 16'd1;
      if (cnt_trb_dly_L == 16'hffff)
      begin
        cnt_trb_dly_H <= cnt_trb_dly_H + 16'd1;
      end
    end

    if (trb_source_eop)
      cnt_trb_src_eop <= cnt_trb_src_eop + 16'd1;
  end
end


reg [511:0] st2bus_out_data;
reg         st2bus_out_valid;
reg         st2bus_out_data2FlowCtrl;
reg         ready_out_st2bus;

st2bus #(
    .BUS (534),
    .ST_PER_BUS (512),
    .NUM_ST_PER_BUS (64), //  (ST_PER_BUS / ST)
    .ST_PER_TURBO_PKT (128),   // 1024/ST
    .NUM_BUS_PER_TURBO_PKT (2), // ( ST_PER_TURBO_PKT / NUM_ST_PER_BUS )
    .ST (8),
    .FROM_BUS2ST_NUM_BUS (25)   // !! NUM_BUS_PER_TURBO_PKT of bus2st.sv
  )
  st2bus_inst
  (
  .rst_n       (test_Resetb),    //input    // clk_bus Asynchronous reset active low

  .clk_st      (uClk_usrDiv2),   // input               // clk turbo decoder
  .st_data     (trb_source_data_s),       // input [ST-1:0]      
  .st_valid    (trb_source_valid),        // input               
  .st_sop      (trb_source_sop),          // input               
  .st_eop      (trb_source_eop),          // input               
  //st_error    ,            // //input              
  .st_ready    (trb_source_ready),        // output              

  .clk_bus     (Clk_400),         // input                    // 400MHz clk
  .bus_ready   (1'b1),            // input                   
  .bus_data    (l12ab_WrDin), // output  reg [ST_PER_BUS-1:0]   
  .bus_en      (l12ab_WrEn) // output  reg             

  //data2FlowCtrl   (st2bus_out_data2FlowCtrl)  // output            // to Flow Ctrl FIFO  (FROM_BUS2ST_NUM_BUS '1')

  );

  
  always@(posedge Clk_400)
  begin
    if (!test_Resetb)
    begin
      l12ab_WrAddr <= 0;
      l12ab_WrTID <= 0;
      l12ab_WrSop <= 0;
      l12ab_WrLen <= 0;
    end
    else
    begin
      l12ab_WrSop <= 1'b1;
      l12ab_WrLen <= 2'b00;
      if (l12ab_WrEn)
      begin
        l12ab_WrAddr <= l12ab_WrAddr + 20'h1;
        l12ab_WrTID  <= l12ab_WrTID + 16'h1;
      end
    end
  end


   // synthesis translate_off
   logic numCL_error = 0;
   always @(posedge Clk_400)
   begin
     if( re2xy_go && ((re2xy_NumLines)%(re2xy_multiCL_len + 1) != 0)  )
     begin
       $display("%m \m ERROR: Total Num Lines should be exactly divisible by multiCL length");
       $display("\m re2xy_NumLines = %d and re2xy_multiCL_len = %d",re2xy_NumLines,re2xy_multiCL_len);
       numCL_error <= 1'b1;
     end

     if(numCL_error)
     $finish();
   end
   // synthesis translate_on

endmodule
