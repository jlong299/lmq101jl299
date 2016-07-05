
module bus2st_1TrbPkt_ram (
	data,
	wraddress,
	rdaddress,
	wren,
	wrclock,
	rdclock,
	rden,
	q);	

	input	[511:0]	data;
	input	[6:0]	wraddress;
	input	[6:0]	rdaddress;
	input		wren;
	input		wrclock;
	input		rdclock;
	input		rden;
	output	[511:0]	q;
endmodule
