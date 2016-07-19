// Author : JL
// Date   : 19 Jul 2016
// Descriptin: counters of turbo dec for SignalTap  

module counter_trb_sigtap  
(
  input     rst_n,
  input     clk,

  input     sop,  // counter start

  output reg [WIDTH-1 : 0]     cnt_L,
  output reg [WIDTH-1 : 0]     cnt_M,
  output reg [WIDTH-1 : 0]     cnt_H
  );

always@(posedge clk)
begin
  if (!rst_n)
  begin
    start_cnt <= 0;
  end
  else
  begin
    if (sop)
      start_cnt <= 1'b1;
    else
      start_cnt <= start_cnt;
  end
end

always@(posedge clk)
begin
  if (!rst_n)
  begin
    cnt_trb_dly_L <= 0;
  end
  else
  begin
    if (start_cnt)
    begin
      cnt_trb_dly_L <= cnt_trb_dly_L + 16'd1;
    end
  end
end

always@(posedge clk)
begin
  if (!rst_n)
  begin
    cnt_trb_dly_M <= 0;
  end
  else
  begin
    if (start_cnt)
    begin
      if (cnt_trb_dly_L == 16'hffff)
      begin
        cnt_trb_dly_M <= cnt_trb_dly_M + 16'd1;
      end
    end
  end
end

always@(posedge clk)
begin
  if (!rst_n)
  begin
    cnt_trb_dly_H <= 0;
  end
  else
  begin
    if (start_cnt)
    begin
      if (cnt_trb_dly_M == 16'hffff)
      begin
        cnt_trb_dly_H <= cnt_trb_dly_H + 16'd1;
      end
    end
  end
end

endmodule