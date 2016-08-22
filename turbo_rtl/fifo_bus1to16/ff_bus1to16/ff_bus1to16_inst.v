	ff_bus1to16 u0 (
		.data    (<connected-to-data>),    //  fifo_input.datain
		.wrreq   (<connected-to-wrreq>),   //            .wrreq
		.rdreq   (<connected-to-rdreq>),   //            .rdreq
		.wrclk   (<connected-to-wrclk>),   //            .wrclk
		.rdclk   (<connected-to-rdclk>),   //            .rdclk
		.aclr    (<connected-to-aclr>),    //            .aclr
		.q       (<connected-to-q>),       // fifo_output.dataout
		.wrusedw (<connected-to-wrusedw>), //            .wrusedw
		.rdempty (<connected-to-rdempty>), //            .rdempty
		.wrfull  (<connected-to-wrfull>)   //            .wrfull
	);

