////////////////// TRANSACTION CLASS ////////////////////
class transaction;
rand bit din;
bit dout;

  function transaction copy();
    copy = new();
    copy.din = this.din;
    copy.dout = this.dout;
  endfunction

  function void display(string msg);
    $display("[%0s] : din = %0d , dout = %0d",msg,din,dout);
  endfunction

endclass

////////////////// GENERATOR CLASS ////////////////////

class generator;

transaction tr;
  mailbox #(transaction) mbx_g2d; //gen to drv mail box
  mailbox #(transaction) mbx_ref;//gen to scr mail box
  
 int rn_num;
 event done;
 event sconxt;

  function new(mailbox #(transaction) mbx_g2d ,mailbox #(transaction) mbx_ref );
    this.mbx_g2d = mbx_g2d ;
    this.mbx_ref = mbx_ref ;
    tr = new();
  endfunction
  
  task run();
    repeat(rn_num) begin
       assert(tr.randomize) else $error("[GEN] : RANDOMIZATION FAILED");
      mbx_g2d.put(tr.copy); // Initialize the mailbox for sending data to the driver
      mbx_ref.put(tr.copy); //// Initialize the mailbox for sending data to the scoreboard
      tr.display("GEN");
      @(sconxt);
      end
    ->done;
  endtask
endclass

////////////////// DRIVER CLASS ////////////////////

class driver;
  
  transaction tr;
  mailbox #(transaction) mbx_g2d; // get data from generator
  
 virtual dff_if v_if; // virtual interface declaration
  
  function new(mailbox #(transaction) mbx_g2d);
  this.mbx_g2d = mbx_g2d;
  endfunction
  
  task reset();
    v_if.rst <= 1'b1; //assert reset
    repeat(5)@(posedge v_if.clk); //wait for 5 clock cycles
    v_if.rst <= 1'b0; //deasset reset
    @(posedge v_if.clk)
    $display("[DRV] : RESET DONE"); ;
  endtask
  
  task run();
    forever begin
      mbx_g2d.get(tr);
      v_if.din = tr.din;
      @(posedge v_if.clk); // Wait for the rising edge of the clock
      tr.display("DRV"); // Display transaction information
      v_if.din <= 1'b0; // Set DUT input to 0
      @(posedge v_if.clk); // Wait for the rising edge of the clock
    end
  endtask
  
endclass


////////////////// MONITER CLASS ////////////////////

class moniter;
transaction tr; // handler for transaction class
  mailbox #(transaction) mbx_m2s;
  virtual dff_if v_if;//// Creating a mailbox to send data to the scoreboard
  
  function new(mailbox #(transaction) mbx_m2s);
   this.mbx_m2s = mbx_m2s; // Initialize the mailbox for sending data to the scoreboard
    
  endfunction
  
  task run();
    tr = new();
    
    forever begin
      repeat(2) @(posedge v_if.clk)
       tr.dout = v_if.dout; //capture DUT output
      mbx_m2s.put(tr);
      tr.display("MON");
     end
    
  endtask
  
endclass


////////////////// SCOREBOARD CLASS ////////////////////

class scoreboard;
 transaction tr;    // Define a transaction object
 transaction tref;  // Define a reference transaction object for comparison
 mailbox #(transaction) mbx_m2s;
 mailbox #(transaction) mbx_ref;
  
  event sconxt;
  
  function new( mailbox #(transaction) mbx_m2s, mailbox #(transaction) mbx_ref);
   this.mbx_m2s = mbx_m2s;
   this.mbx_ref = mbx_ref;
  endfunction
  
  task run();
    forever begin
      mbx_m2s.get(tr);
      mbx_ref.get(tref);
      tr.display("SCO");
      tref.display("REF");
      
      if (tr.dout == tref.din)
        $display("[SCO] : DATA MATCHED"); // Compare data 
      else
        $display("[SCO] : DATA MISMATCHED");
      $display("-------------------------------------------------");
      ->sconxt; // Signal completion of scoreboard work
    end
  endtask
endclass

////////////////// ENVIRONMENT CLASS ////////////////////
    
class environment;
  
  generator gen;
  driver drv;
  moniter mon;
  scoreboard sco;
  event next; // Event to signal communication between gen and sco
  
  mailbox #(transaction) mbx_g2d;//mailbox to communicate btw gen and drv
  mailbox #(transaction) mbx_ref;//mailbox to communicate btw gen and sro
  mailbox #(transaction) mbx_m2s;//mailbox to communicate btw mon and sro
  
   virtual dff_if v_if; // Virtual interface for DUT
  
  function new(virtual dff_if v_if);
    
    //creating and initialising the mailboxes
    mbx_g2d = new();
    mbx_ref = new();        
    mbx_m2s = new();
    gen = new (mbx_g2d, mbx_ref);
    drv = new (mbx_g2d);
    mon = new(mbx_m2s);
    sco = new (mbx_m2s,mbx_ref);
    
    //connecting the interfaces and events
    this.v_if = v_if;
    drv.v_if = this.v_if;
    mon.v_if = this.v_if;
    gen.sconxt = next;
    sco.sconxt = next;
    
   endfunction
  
  task pre_test();
    drv.reset(); // Perform the driver reset
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
    endtask
  
  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask
 
task run();
    pre_test(); // Run pre-test setup
    test(); // Run the test
    post_test(); // Run post-test cleanup
  endtask
endclass
  
  
module tb;
  environment env; //creating environment handler
  
  dff_if v_if(); //create virtual interface
  
  dff dut(v_if); // Instantiate DUT
  
  initial begin
    v_if.clk <= 0; // Initialize clock signal
  end
  always #10 v_if.clk = ~v_if.clk; //time period is 20ns
  

  
  initial begin
    env = new(v_if);
    env.gen.rn_num = 20; // Set the generator's stimulus count
    env.run();
  end
  
   initial begin
    $dumpfile("dump.vcd"); // Specify the VCD dump file
    $dumpvars; // Dump all variables
  end
  
endmodule
    
    