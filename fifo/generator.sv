//`include "DUT.sv"
//`include "transaction.sv"

/////////////GENERATOR CLASS//////////
class generator;

transaction tr; // Transaction object to generate and send
mailbox #(transaction) mbx; //maiulbox to send data to driver class
int i = 0; //variable to count iteration
int count = 0; // Number of transactions to generate

event done;
event nxt;

function new(mailbox #(transaction) mbx);
this.mbx = mbx;
tr = new();
endfunction

task run();
repeat(count) begin
assert(tr.randomize) else $error("RANDOMIZATION FAILED");
i++;
mbx.put(tr);
$display("[GEN] : Oper : %0d iteration : %0d", tr.op, i);
@(nxt);
end
-> done ;//triggering event done
endtask
endclass
