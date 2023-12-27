//`include "DUT.sv"
//`include "transaction.sv"

////////// MONITOR ///////////
class monitor;

transaction tr; //transaction handle
mailbox #(transaction) mbx; //mailbox to send data to scoreboard

virtual fifo_if fif; //virtual interface to get dtaa from DUT

function new(mailbox #(transaction) mbx);
this.mbx=mbx;
endfunction

task run();
tr = new();
forever begin
repeat(2)@(posedge fif.clk);
tr.wr = fif.wr;
tr.rd = fif.rd;
tr.full = fif.full;
tr.empty = fif.empty;
tr.data_in = fif.data_in;
@(posedge fif.clk);
tr.data_out = fif.data_out;
mbx.put(tr);
$display("[MON] : wr = %0d , rd = %0d , data in =%0d ,data out = %0d , full = %0d,empty = %0d",tr.wr,tr.rd,tr.data_in,tr.data_out,tr.full,tr.empty);
end
endtask
endclass
