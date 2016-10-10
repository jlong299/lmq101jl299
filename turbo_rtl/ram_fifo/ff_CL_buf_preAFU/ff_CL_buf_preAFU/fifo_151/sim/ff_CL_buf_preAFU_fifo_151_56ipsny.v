// (C) 2001-2015 Altera Corporation. All rights reserved.
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
module  ff_CL_buf_preAFU_fifo_151_56ipsny  (
    clock,
    data,
    rdreq,
    sclr,
    wrreq,
    empty,
    full,
    q);

    input    clock;
    input  [511:0]  data;
    input    rdreq;
    input    sclr;
    input    wrreq;
    output   empty;
    output   full;
    output [511:0]  q;

    wire  sub_wire0;
    wire  sub_wire1;
    wire [511:0] sub_wire2;
    wire  empty = sub_wire0;
    wire  full = sub_wire1;
    wire [511:0] q = sub_wire2[511:0];

    scfifo  scfifo_component (
                .clock (clock),
                .data (data),
                .rdreq (rdreq),
                .sclr (sclr),
                .wrreq (wrreq),
                .empty (sub_wire0),
                .full (sub_wire1),
                .q (sub_wire2),
                .aclr (),
                .almost_empty (),
                .almost_full (),
                .eccstatus (),
                .usedw ());
    defparam
        scfifo_component.add_ram_output_register  = "OFF",
        scfifo_component.enable_ecc  = "FALSE",
        scfifo_component.intended_device_family  = "Arria 10",
        scfifo_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
        scfifo_component.lpm_numwords  = 256,
        scfifo_component.lpm_showahead  = "OFF",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = 512,
        scfifo_component.lpm_widthu  = 8,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


endmodule


