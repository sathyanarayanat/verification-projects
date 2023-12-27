interface dff_if;
  logic clk;
  logic rst;
  logic din;
  logic dout;
  
endinterface

module dff(dff_if v_if);
 
  always@(posedge v_if.clk) begin
  
    if(v_if.rst)
      v_if.dout<=1'b0;
    else
      v_if.dout <= v_if.din;
end
endmodule