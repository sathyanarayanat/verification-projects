`include "DUT.sv"
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"


///////////// ENVIRONMENT ////////////
class environment;

virtual fifo_if fif;

generator gen;
driver drv;
monitor mon;
scoreboard sco;

mailbox #(transaction) mbx_g2d;
mailbox #(transaction) mbx_m2s;

event nxt;

function new(virtual fifo_if fif);
mbx_g2d = new();
gen = new(mbx_g2d);
drv = new(mbx_g2d);

mbx_m2s = new();
mon = new(mbx_m2s);
sco = new(mbx_m2s);

this.fif = fif;
drv.fif = this.fif;
mon.fif = this.fif;

gen.nxt = nxt;
sco.nxt = nxt;

endfunction

task pre_test();
drv.reset();
endtask

task test();
fork
gen.run();
drv.main();
mon.run();
sco.run();
join_any
endtask

task post_test();
wait(gen.done.triggered);
 $display("---------------------------------------------");
  $display("Error Count :%0d", sco.err);
    $display("---------------------------------------------");
    $finish();
endtask

task run();
pre_test();
test();
post_test();
endtask


endclass

module tb;

environment env;
fifo_if fif;
fifo DUT(fif);

initial begin 
fif.clk = 1'b0;
end

always #10 fif.clk = ~fif.clk;

initial begin
env = new(fif); // Initialize the environment with the DUT interface
env.gen.count = 10; // Set the generator's stimulus count
env.run(); // Run the environment
end

initial begin
    $dumpfile("dump.vcd"); // Specify the VCD dump file
    $dumpvars; // Dump all variables
  end

endmodule

