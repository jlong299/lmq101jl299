
module ff_bus1to16 (
	data,
	wrreq,
	rdreq,
	wrclk,
	rdclk,
	aclr,
	q,
	wrusedw,
	rdempty,
	wrfull);	

	input	[533:0]	data;
	input		wrreq;
	input		rdreq;
	input		wrclk;
	input		rdclk;
	input		aclr;
	output	[533:0]	q;
	output	[4:0]	wrusedw;
	output		rdempty;
	output		wrfull;
endmodule
