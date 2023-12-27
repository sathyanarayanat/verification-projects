//`include "transaction.sv"


////////// SCOREBOARD CLASS //////////
class scoreboard;

transaction tr; //creating handle for transaction
mailbox #(transaction) mbx; //mailbox to recieve data from monitor class

event nxt;
bit [7:0] din[$]; //queue to store the incoming data
bit [7:0] temp; //temp variable 
int err=0; //variable to count the number of errors

function new(mailbox #(transaction) mbx);
this.mbx=mbx;
endfunction

task run();
forever begin
mbx.get(tr);
$display("[MON] : wr = %0d , rd = %0d , data in =%0d ,data out = %0d , full = %0d,empty = %0d",tr.wr,tr.rd,tr.data_in,tr.data_out,tr.full,tr.empty);

if(tr.wr==1)begin
if(!tr.full)begin
din.push_front(tr.data_in);
$display("[SCO] : DATA STORED IN QUEUE :%0d", tr.data_in);
end
else
$display("[SCO] : FIFO IS FULL ");
$display("----------------------");
end

if(tr.rd == 1'b1)begin
if(!tr.empty)begin
temp = din.pop_back();

if(tr.data_out == temp)
$display("[SCO] : DATA MATCHING");
else begin
$display("[SCO] : DATA NOT MATCHING");
err++;
end
end
else $display("[SCO] : FIFO IS EMPTY");
$display("--------------------------------------"); 
end
->nxt;
end
endtask

endclass

