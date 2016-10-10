
module ff_CL_buf_preAFU (
	data,
	wrreq,
	rdreq,
	clock,
	sclr,
	q,
	full,
	empty);	

	input	[511:0]	data;
	input		wrreq;
	input		rdreq;
	input		clock;
	input		sclr;
	output	[511:0]	q;
	output		full;
	output		empty;
endmodule
