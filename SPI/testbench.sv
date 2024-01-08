class transaction;
	rand bit newd;
    rand bit [11:0] din;
	bit cs;
  	bit mosi;
  
///////////display function////////
  
  function void display(string tag);
    $display("[%0s] : NEW_DATA = %0d , DATA_IN = %0d , CS = %0d , MOSI = %0d",tag,newd,din,cs,mosi);
  endfunction

  
///////// Creating a Deep copy /////
  function transaction copy();
    copy = new();
    copy.newd = this.newd;
    copy.din = this.din;
    copy.cs = this.cs;
    copy.mosi = this.mosi;
    endfunction
    

endclass


///////GENERATOR CLASS//////
class generator;
  
 transaction tr;
 mailbox #(transaction) mbx;
 
 event done; ////Event to terminate the testbench
 event sconxt;
 event drvnxt;
 int num = 0;
 
  // Custom Constructor 
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction

  // Generating Transaction
  task run();
    repeat(num) begin
      assert(tr.randomize) else $error("RANDOMIZATION FAILED");
      tr.display("GEN");
      mbx.put(tr.copy);
      @(drvnxt); //waiting for event trigger from driver
      @(sconxt); // waiting for event trigger from scoreboard
    end
    -> done;
  endtask
endclass

///////DRIVER CLASS//////

class driver;
  
  virtual spi_if vif; // Virtual interface
  transaction tr;
  mailbox #(transaction) mbx;
  mailbox #(bit[11:0] ) mbxds;
  
  event drvnxt;
  bit [11:0] din;
  
  function new(mailbox #(transaction) mbx ,mailbox #(bit[11:0] ) mbxds);
    this.mbx = mbx;
    this.mbxds = mbxds;
  endfunction
  
  //////Reset Task/////
  task reset();
    
     vif.rst <= 1'b1;
     vif.cs <= 1'b1;
     vif.newd <= 1'b0;
     vif.din <= 1'b0;
     vif.mosi <= 1'b0;
    repeat(5) @(posedge vif.clk);
    vif.rst <= 1'b0;
    repeat(5) @(posedge vif.clk);
    
     $display("[DRV] : RESET DONE");
    $display("-----------------------------------------");
    endtask
  
  task run();
    
    forever begin
      mbx.get(tr);
    @(posedge vif.sclk);
    vif.newd <= 1'b1;
    vif.din <= tr.din;
      mbxds.put(tr.din);
    @(posedge vif.sclk);
    vif.newd <= 1'b0;
    wait(vif.cs);
    $display("[DRV] : DATA SENT TO DAC : %0d",tr.din);
    ->drvnxt;
    end
  endtask
endclass

//////MONITOR CLASS//////

class monitor;
  
  virtual spi_if vif;
  transaction tr;
  
  mailbox #(bit [11:0]) mbx;
  
  function new(mailbox #(bit [11:0]) mbx);
    this.mbx = mbx;
  endfunction
  bit [11:0] mnrx; //To hold data from DUT
  
  task run();
    forever begin
      @(posedge vif.sclk);
      wait (vif.cs==0);
      @(posedge vif.sclk);
      for(int i = 0 ; i<12 ; i= i+1) begin
        @(posedge vif.sclk);
        mnrx[i] = vif.mosi;
      end
      wait(vif.cs);
      $display("[MON] : DATA SENT : %0d", mnrx);
      mbx.put(mnrx);
    end
  endtask
endclass
  
//////SCOREBOARD CLASS///////
  
  
class scoreboard;
  //transaction tr, tref;
  event sconxt;
  
  mailbox #(bit [11:0]) mbxm; //Mailbox to recieve data from monitor
  mailbox #(bit [11:0]) mbxd; //Mailbox to recieve golden data from driver
  reg [11:0] md ; //Data from monitor 
  reg [11:0] dd ; // data from driver
 
  //custom constructor
  function new(mailbox #(bit [11:0]) mbxm,mailbox #(bit [11:0])mbxd);
  this.mbxd = mbxd;
  this.mbxm = mbxm;
  endfunction

// Task to compare data from driver and monitor
  task run();
    forever begin
      mbxd.get(dd);
      mbxm.get(md);
      $display("[SCO] : DRV : %0d MON : %0d", dd, md);
 
      if (dd == md)
        $display("[SCO] : DATA MATCHED");
      else
        $display("[SCO] : DATA MISMATCHED");
 
      $display("-----------------------------------------");
      ->sconxt;
    end
  endtask
endclass

////////////////Environment Class//////////////
 
class environment;
 
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;
 
    event nextgd; // gen -> drv
    event nextgs; // gen -> sco
 
    mailbox #(transaction) mbxgd; // gen - drv
    mailbox #(bit [11:0]) mbxds; // drv - mon
    mailbox #(bit [11:0]) mbxms; // mon - sco
 
    virtual spi_if vif;
 
  // Constructor
  function new(virtual spi_if vif);
    mbxgd = new();
    mbxms = new();
    mbxds = new();
    gen = new(mbxgd);
    drv = new(mbxgd, mbxds);
 
    mon = new(mbxms);
    sco = new(mbxms, mbxds);
 
    this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
 
    gen.sconxt = nextgs;
    sco.sconxt = nextgs;
 
    gen.drvnxt = nextgd;
    drv.drvnxt = nextgd;
  endfunction
 
  // Task to perform pre-test actions
  task pre_test();
    drv.reset();
  endtask
 
  // Task to run the test
  task test();
  fork
    gen.run();
    drv.run();
    mon.run();
    sco.run();
  join_any
  endtask
 
  // Task to perform post-test actions
  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask
 
  // Task to start the test environment
  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass
 
////////////////Testbench Top
module tb;
 
  spi_if vif();
  spi_master dut(vif.clk, vif.newd, vif.rst, vif.din, vif.sclk, vif.cs, vif.mosi);
 
  initial begin
    vif.clk <= 0;
  end
 
  always #10 vif.clk <= ~vif.clk;
 
  environment env;
 
  initial begin
    env = new(vif);
    env.gen.num = 20;
    env.run();
  end
 
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule