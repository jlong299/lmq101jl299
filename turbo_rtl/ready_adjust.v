//-----------------------------------------------------------------
// Module Name:        	ready_adjust.v
// Project:             NLB AFU turbo decoder
// Description:         Adjust "ready" signal which from turbo dec to bus2st 
// Author:				Long Jiang
//
//  ---------------------------------------------------------------------------------------------------------------------------------------------------
//  ------------------------------------------------------------------------------------------------------------------------------------------------

module ready_adjust (
	input 	rst_n,  // Asynchronous reset active low
	input 	clk,    // Clock

	input 	ready_in,
	input	sink_eop,
	input 	source_eop,

	output reg	ready_out	
);

reg rst_n_clk, rst_n_q, rst_n_qq;
always@(posedge clk)
begin
	rst_n_clk <= rst_n_qq;
	rst_n_qq <= rst_n_q;
	rst_n_q <= rst_n;
end

reg		fsm;
always@(posedge clk)
begin
	if (!rst_n_clk)
	begin
		ready_out <= 0;
		fsm <= 0;
	end
	else
	begin
		case (fsm)
		1'b0:
		begin
			if (sink_eop)
				fsm <= 1'b1;
		end
		1'b1:
		begin
			if (source_eop)
				fsm <= 1'b0;
		end
		default:
		begin
			fsm <= fsm;
		end
		endcase

		if (fsm)
			ready_out <= 1'b0;
		else
			ready_out <= ready_in;
	end
end

endmodule