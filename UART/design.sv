// Code your design here
///UART TRANSMITTER//
module uarttx #(parameter clk_freq = 1000000 , parameter baud_rate = 9600)

(
input clk , rst, 
input newd,
input [7:0] datatx,
output  reg donetx,
output reg tx,
output reg par_bit,
output reg st_bit
);

localparam clkcount = clk_freq/baud_rate ;

parameter idle = 2'b00;
parameter transfer = 2'b01;

reg [9:0] din; // 8 bit data with parity bit and stop bit

reg uclk; // Slower clk
reg [1:0] state = idle;
 

integer count = 0;
integer bit_count = 0;

/////// slower clk ///////

always@(posedge clk) begin
if(count<clkcount/2)
		count <= count +1;
	else begin
		count <= 0;
		uclk = ~ uclk;
	end
end

/// uart logic/////

always@(posedge uclk)begin
	if(rst)
		state <=  idle;
	else begin
	
		case(state)
		idle : begin
			tx<=1'b1;
			donetx<=1'b0;
			bit_count <= 0;
			
			if(newd) begin
			state <= transfer;
			par_bit <= ~(^datatx); //parity bit
			st_bit <= 1;
			din<= {datatx,par_bit,st_bit}; //tansmitiing data with parity ans top bit
			tx<= 1'b0;
			 end
			else 
			state <= idle;
			end
		transfer : begin
			if(bit_count <= 10) begin
			tx <= din [bit_count] ;
			bit_count <= bit_count + 1;
			state <= transfer;
			 end
			else begin
			bit_count <= 0;
			tx <= 1'b1;
			donetx <= 1'b1;
			state<= idle;
			 end
			end
		default : state <= idle;
		endcase
	end
end
	
endmodule

///UART RECEIVER///

module uartrx #(parameter clk_freq = 1000000 , parameter baud_rate = 9600)

(
input clk , rst, 
input rx,
output reg [7:0] datarx,
output reg donerx,
output reg par_bit ,
output reg st_bit
);

parameter idle = 2'b00;
parameter receive = 2'b01;

localparam clkcount = clk_freq/baud_rate;
reg uclk; // Slower clk
reg [1:0] state = idle;


integer count = 0;
integer bit_count = 0;

/////// slower clk ///////

always@(posedge clk) begin
if(count<clkcount/2)
		count <= count +1;
	else begin
		count <= 0;
		uclk = ~ uclk;
	end
end

always@(posedge uclk)begin
	if(rst) 
		state <= idle;
	else begin
		case(state)
		idle : begin
			datarx <= 8'h00;
			bit_count <=0;
			donerx <=0;
			
			if(!rx)
			state <= receive ;
			else 
			state <= idle;
		end
		receive : begin
			  if(bit_count < 8)begin
				datarx <= rx;
				bit_count <= bit_count +1;
				state <= receive;
				end
			else if (bit_count == 8)
				par_bit <= rx;
			else if (bit_count == 9)
				st_bit <= rx;
			else begin
				bit_count <= 0;
				donerx <= 1'b0;
				state <= idle;
			end
		end
		default : state <= idle;
		endcase
	end


end
endmodule

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
output st_bit_tx,
output st_bit_rx,
);

uarttx #(clk_freq,baud_rate) 
utx
  (clk,rst,donetx,datatx,donetx,tx,par_bit_tx,st_bit_tx);

uartrx #(clk_freq,baud_rate) 
rtx
  (clk,rst,rx,datarx,donerx,par_bit_rx,st_bit_rx);
endmodule


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
  logic par_bit_tx;
  logic par_bit_rx;
  logic st_bit_tx;
  logic st_bit_rx;
  
endinterface
