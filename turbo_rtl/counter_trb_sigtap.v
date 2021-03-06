// Author : JL
// Date   : 19 Jul 2016
// Descriptin: counters of turbo dec for SignalTap  

module counter_trb_sigtap  #(parameter WIDTH=16)
(
  input     rst_n,
  input     clk,

  input     sop,  // counter start

  output reg [WIDTH-1 : 0]     cnt_L,
  output reg [WIDTH-1 : 0]     cnt_M,
  output reg [WIDTH-1 : 0]     cnt_H
  );
 
reg start_cnt; 

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
    cnt_L <= 0;
  end
  else
  begin
    if (start_cnt)
    begin
      cnt_L <= cnt_L + 16'd1;
    end
  end
end

always@(posedge clk)
begin
  if (!rst_n)
  begin
    cnt_M <= 0;
  end
  else
  begin
    if (start_cnt)
    begin
      if (cnt_L == 16'hffff)
      begin
        cnt_M <= cnt_M + 16'd1;
      end
    end
  end
end

always@(posedge clk)
begin
  if (!rst_n)
  begin
    cnt_H <= 0;
  end
  else
  begin
    if (start_cnt)
    begin
      if (cnt_M == 16'hffff)
      begin
        cnt_H <= cnt_H + 16'd1;
      end
    end
  end
end

endmodule