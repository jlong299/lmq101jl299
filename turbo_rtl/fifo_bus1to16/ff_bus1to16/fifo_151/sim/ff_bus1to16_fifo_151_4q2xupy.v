// (C) 2001-2016 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  ff_bus1to16_fifo_151_4q2xupy  (
    aclr,
    data,
    rdclk,
    rdreq,
    wrclk,
    wrreq,
    q,
    rdempty,
    wrfull,
    wrusedw);

    input    aclr;
    input  [533:0]  data;
    input    rdclk;
    input    rdreq;
    input    wrclk;
    input    wrreq;
    output [533:0]  q;
    output   rdempty;
    output   wrfull;
    output [4:0]  wrusedw;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri0     aclr;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [533:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [4:0] sub_wire3;
    wire [533:0] q = sub_wire0[533:0];
    wire  rdempty = sub_wire1;
    wire  wrfull = sub_wire2;
    wire [4:0] wrusedw = sub_wire3[4:0];

    dcfifo  dcfifo_component (
                .aclr (aclr),
                .data (data),
                .rdclk (rdclk),
                .rdreq (rdreq),
                .wrclk (wrclk),
                .wrreq (wrreq),
                .q (sub_wire0),
                .rdempty (sub_wire1),
                .wrfull (sub_wire2),
                .wrusedw (sub_wire3),
                .eccstatus (),
                .rdfull (),
                .rdusedw (),
                .wrempty ());
    defparam
        dcfifo_component.enable_ecc  = "FALSE",
        dcfifo_component.intended_device_family  = "Arria 10",
        dcfifo_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
        dcfifo_component.lpm_numwords  = 32,
        dcfifo_component.lpm_showahead  = "OFF",
        dcfifo_component.lpm_type  = "dcfifo",
        dcfifo_component.lpm_width  = 534,
        dcfifo_component.lpm_widthu  = 5,
        dcfifo_component.overflow_checking  = "ON",
        dcfifo_component.rdsync_delaypipe  = 5,
        dcfifo_component.read_aclr_synch  = "OFF",
        dcfifo_component.underflow_checking  = "ON",
        dcfifo_component.use_eab  = "ON",
        dcfifo_component.write_aclr_synch  = "ON",
        dcfifo_component.wrsync_delaypipe  = 5;


endmodule


