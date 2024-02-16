class transaction;
  typedef enum bit {write = 1'b0 , read = 1'b1} op_type;
  randc  op_type op;
  rand bit [7:0] datatx;
  
  bit rx;
  bit tx;
  bit newd;
  bit donetx;
  bit  par_bit_tx;
  bit st_bit_tx;
  bit [7:0] datarx;
  bit donerx;
  bit par_bit_rx;
  bit st_bit_rx;
  
  function transaction copy();
    copy = new();
    copy.rx = this.rx;
    copy.datatx = this.datatx;
    copy.newd = this.newd;
    copy.tx = this.tx;
    copy.datarx = this.datarx;
    copy.donetx = this.donetx;
    copy.donerx = this.donerx;
    copy.op = this.op;
    copy.par_bit_tx = this.par_bit_tx;
    copy.st_bit_tx = this.st_bit_tx;
    copy.par_bit_rx = this.par_bit_rx;
    copy.st_bit_rx = this.st_bit_rx;
  endfunction
  
endclass

//////GENRATOR CLASS/////////
class generator;

  transaction tr ;
  
  mailbox #(transaction) mbx;
  
  event done;
  event sconext;
  event drvnext;
  
  int count = 0;
  
  function new (mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
    endfunction
  
  task run();
    repeat(count) begin
      assert(tr.randomize) else $error("[GEN] : RANDOMIZATION FAILED");
      mbx.put(tr.copy);
      $display("oper_type: %s , data in : %0d ",tr.op.name(),tr.datatx);
      @(drvnext);
      @(sconext);
    end
    -> done;
  endtask
  
endclass

/////// DRIVER CLASS ///////

class driver;
  
  virtual uart_if vif;
  
  transaction tr;
  
  mailbox #(transaction) mbx;
  mailbox  mbxds;
  
  event drvnext;
  
   bit [7:0] din;
  
  
  bit wr = 0;  ///random operation read / write
  bit [9:0] data_rx;  ///data rcvd during read
  
  
  
  
  
  function new( mailbox #(transaction) mbx,mailbox mbxds);
    this.mbx = mbx;
    this.mbxds = mbxds;
   endfunction
  
  task reset();
   vif.rst <= 1'b1;
   vif.datatx <= 0;
   vif.rx <= 0;
   vif.rx = 1;
  
    repeat(5) @(posedge vif.uclktx);
    vif.rst <= 1'b0;
    @(posedge vif.uclktx);
    $display("[DRV] : RESET DONE");
    $display("----------------------------------------");
  endtask
 
  task run();
    forever begin
      mbx.get(tr);
      
      if(tr.op == 1'b0 ) begin
        @(posedge vif.uclktx);
        vif.rst <= 0;
        vif.newd <= 1;
        vif.rx <= 0;
        vif.datatx <= tr.datatx;
        tr.par_bit_tx <= ~(^tr.datarx); // generation of parity bit
        tr.st_bit_tx <= 1'b1;
        @(posedge vif.uclktx);
        vif.newd <= 0;
        mbxds.put({tr.datatx,tr.par_bit_tx,tr.st_bit_tx}); //sending data to scoreboard
        $display("[DRV]: Data Sent : %0d , parity bit : %0d", tr.datatx,tr.par_bit_tx);
             wait(vif.donetx == 1'b1);  
             ->drvnext;
      end
      
      else if((tr.op == 1'b1))begin
        @(posedge vif.uclkrx);
        vif.rst <=0;
        vif.rx <= 0;
        vif.newd <=0;
        @(posedge vif.uclkrx );
        for(int i=0; i<=7; i++) begin  
                      @(posedge vif.uclkrx);                
                      vif.rx <= $urandom;
                      data_rx[i] = vif.rx;
        end
        data_rx[8] <= ~(^data_rx[7:0]); //calculating parity bit
        data_rx[9]<= 1'b1;
        mbxds.put(data_rx);
        $display("[DRV]: Data RCVD : %0d", data_rx); 
                wait(vif.donerx == 1'b1);
                 vif.rx <= 1'b1;
				->drvnext;
      end
      
    end
  endtask

   
endclass

/////MONITOR VLASS////////////

class monitor;
 
  transaction tr;
  
  mailbox mbx;
  
  bit [9:0] srx; //////send
  bit [9:0] rrx; ///// recv
  
 
  
  virtual uart_if vif;
  
  
  function new(mailbox mbx);
    this.mbx = mbx;
    endfunction
  
  task run();
    
    forever begin
     
       @(posedge vif.uclktx);
      if ( (vif.newd== 1'b1) && (vif.rx == 1'b1) ) 
                begin
                  
                  @(posedge vif.uclktx); ////start collecting tx data from next clock tick
                  
                  for(int i = 0; i<= 9; i++) 
              begin 
                    @(posedge vif.uclktx);
                    srx[i] = vif.tx;
                    
              end
 
                  
                  $display("[MON] : DATA SEND on UART TX %0d", srx);
                  
                  //////////wait for done tx before proceeding next transaction                
                @(posedge vif.uclktx); //
                mbx.put(srx);
                 
               end
      
      else if ((vif.rx == 1'b0) && (vif.newd == 1'b0) ) 
        begin
          wait(vif.donerx == 1);
          rrx = {vif.datarx,vif.par_bit_rx,vif.st_bit_rx};     
           $display("[MON] : DATA RCVD RX %0d", rrx);
           @(posedge vif.uclktx); 
           mbx.put(rrx);
      end
  end  
endtask
  
 
endclass

/////SCORE BOARD ///////

class scoreboard;
  mailbox mbxds, mbxms;
  
  bit [9:0] ds;
  bit [9:0] ms;
  
   event sconext;
  
  function new( mailbox  mbxms,mailbox  mbxds);
    this.mbxds = mbxds;
    this.mbxms = mbxms;
  endfunction
  
  task run();
    forever begin
      
      mbxds.get(ds);
      mbxms.get(ms);
      
      $display("[SCO] : DRV : %0d MON : %0d", ds, ms);
      if(ds == ms)
        $display("DATA MATCHED");
      else
        $display("DATA MISMATCHED");
      
      $display("----------------------------------------");
      
     ->sconext; 
    end
  endtask
  
  
endclass

///////ENVIRONMENT CLASS ////////

class environment;
 
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco; 
  
    
  
    event nextgd; ///gen -> drv
  
    event nextgs;  /// gen -> sco
  
  mailbox #(transaction) mbxgd; ///gen - drv
  
  mailbox  mbxds; /// drv - sco
    
     
  mailbox  mbxms;  /// mon - sco
  
    virtual uart_if vif;
 
  
  function new(virtual uart_if vif);
       
    mbxgd = new();
    mbxms = new();
    mbxds = new();
    
    gen = new(mbxgd);
    drv = new(mbxgd,mbxds);
    
    
 
    mon = new(mbxms);
    sco = new( mbxms,mbxds);
    
    this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
    
    gen.sconext = nextgs;
    sco.sconext = nextgs;
    
    gen.drvnext = nextgd;
    drv.drvnext = nextgd;
 
  endfunction
  
  task pre_test();
    drv.reset();
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
    pre_test();
    test();
    post_test();
  endtask
  
  
  
endclass

//////TEST BENCH //////

 
module tb;
    
  uart_if vif();
  
  uart_top #(1000000, 9600) dut (vif.clk,vif.rst,vif.newd,vif.rx,vif.datatx,vif.donetx,vif.tx,vif.datarx, vif.donerx,vif.par_bit_tx,vif.par_bit_rx,vif.st_bit_tx,vif.st_bit_rx);
  
  
  
    initial begin
      vif.clk <= 0;
    end
    
    always #10 vif.clk <= ~vif.clk;
    
    environment env;
    
    
    
    initial begin
      env = new(vif);
      env.gen.count = 2;
      env.run();
    end
      
    
    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
   
  assign vif.uclktx = dut.utx.uclk;
  assign vif.uclkrx = dut.rtx.uclk;
    
  endmodule