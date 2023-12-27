
/////////////////// DUT /////////////
interface fifo_if;
  
  logic  clk, rst;
  logic  wr,rd ;
  logic   [7:0] data_in;
  logic  [7:0] data_out;
  logic  full,empty;
  
  
endinterface

module fifo (fifo_if fif);
  
  reg [3:0] wptr,rptr;
  reg [15:0] mem [16];
  reg [4:0] cnt;
 
  always@(posedge fif.clk) begin
    if(fif.rst == 1'b1)begin
      wptr <= 0;
      rptr <= 0;
      cnt <= 0;
    end
    
    else if (fif.wr && !fif.full)begin
      mem[wptr] <= fif.data_in;
      wptr = wptr+1;
      cnt = cnt+1;
    end
    
    else if(fif.rd && !fif.empty)begin
      fif.data_out <= mem[rptr];
      rptr = rptr+1;
      cnt = cnt-1;
    end
    
  end
  
  assign fif.full = (cnt==16)? 1'b1:1'b0;
  assign fif.empty = (cnt==0)? 1'b1:1'b0;
  
endmodule

