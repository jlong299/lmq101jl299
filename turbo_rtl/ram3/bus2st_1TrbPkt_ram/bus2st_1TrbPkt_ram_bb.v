
module bus2st_1TrbPkt_ram (
	data,
	wraddress,
	rdaddress,
	wren,
	clock,
	rden,
	q);	

	input	[255:0]	data;
	input	[6:0]	wraddress;
	input	[6:0]	rdaddress;
	input		wren;
	input		clock;
	input		rden;
	output	[255:0]	q;
endmodule
