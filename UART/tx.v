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