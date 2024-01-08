module spi_master(
	input clk,newd,rst,
  	input [11:0] din,
  	output reg sclk,cs,mosi
);
  
////////Creating sclk = clk/20////////////
  int count_sclk = 0;
  int count = 0;
  
  always@(posedge clk) begin
    if(rst)begin
      count_sclk <=0;
      sclk <= 1'b0;
    end
    else begin
      if(count_sclk<10) begin
        count_sclk = count_sclk +1;
      end
      else begin
        count_sclk <= 0;
        sclk <= ~sclk;
      end
    end
  end
//////////// State Machine /////////
    
    typedef enum {idle,send} state_variable; //  creating enum datatype for different states of the FSM
    state_variable state ;
    
    reg [11:0] temp;
    
    always@(posedge sclk) begin
      if(rst) begin
        cs <= 1'b1;
        mosi <= 1'b0;
      end
      
      else begin
        case(state)
          
          idle : begin
            if(newd)begin 
              state <= send;
              temp <= din;
              cs<=1'b0; //Enabling Control slave (active low)
            end
            else begin 
              state <= idle;
              
              temp <= 8'd0;
            end
          end
          
          send : begin 
            if(count<=11) begin
              mosi = temp[count]; //Trasmitting each bit every clk cycle usinf Maaster out Slave in (mosi)
              count = count +1;
            end
            else begin
              count<=0;
              cs = 1'b1;
              state<= idle;
              mosi <= 1'b0;
            end
          
          end
          default : state <= idle;
        endcase
      end
      
      end
  
  
endmodule
    
////////////////// INTERFACE //////////////
    
interface spi_if;
	logic clk;
 	logic rst;
	logic newd;
  	logic [11:0] din;
  	logic sclk;
  	logic cs;
  	logic mosi;
endinterface