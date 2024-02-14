///UART TOP////

module uart_top #(parameter clk_freq = 1000000 , parameter baud_rate = 9600)

(
input clk , rst, 
input newd,
input rx,
input [7:0] datatx,
output  donetx,
output  tx,
output [7:0] datarx,
output  donerx,
output  par_bit_tx,
output  par_bit_rx,
output st_bit
);

uarttx #(clk_freq,baud_rate) 
utx
(clk,rst,donetx,datatx,donetx,tx,par_bit_tx,st_bit);

uartrx #(clk_freq,baud_rate) 
rtx
(clk,rst,rx,datarx,donerx,par_bit_rx,st_bit);
endmodule

/* 
interface uart_if;
  logic clk;
  logic uclktx;
  logic uclkrx;
  logic rst;
  logic rx;
  logic [7:0] datatx;
  logic newd;
  logic tx;
  logic [7:0] datarx;
  logic donetx;
  logic donerx;
  logic par_bit;
  
endinterface
*/