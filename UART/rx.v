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