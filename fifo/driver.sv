//`include "DUT.sv"
//`include "transaction.sv"


///////////DRIVER CLASS ////////
class driver;

transaction datac;// Transaction object for communication
mailbox #(transaction) mbx; //mailbox to get data from generator class

virtual fifo_if fif; // Virtual interface to the FIFO

function new(mailbox #(transaction) mbx);
this.mbx = mbx;
endfunction

//reset the DUT
task reset();
@(posedge fif.clk);
fif.rst <= 1'b1;
fif.wr <= 1'b0;
fif.rd <= 1'b0;
fif.data_in <= 0;
repeat(5)@(posedge fif.clk);
fif.rst <= 1'b0;
$display("[DRV] : DUT Reset Done");
$display("------------------------------------------");
endtask

//write data to FIFO
task write();
@(posedge fif.clk);
fif.rst<=1'b0;
fif.rd<=1'b0;
fif.wr<=1'b1;
fif.data_in <= datac.dta_in;
@(posedge fif.clk);
fif.wr<=1'b0;
$display("[DRV] : DATA WRITE  data : %0d", fif.data_in); 
@(posedge fif.clk);
endtask

//write data to FIFO
task read();
@(posedge fif.clk);
fif.rst <= 1'b0;
fif.wr <= 1'b0;
fif.rd <= 1'b1;
@(posedge fif.clk);
fif.rd <= 1'b0;
$display("[MON] : DATA READ ");
@(posedge fif.clk);
endtask

// read and write
task main();
forever begin
mbx.get(datac);
if(datac.op==1'b1)
write();
else
read();
end
endtask

endclass
