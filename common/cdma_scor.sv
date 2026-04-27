class cdma_sbd extends uvm_scoreboard;
  `uvm_component_utils(cdma_sbd)

  // Analysis FIFOs
  uvm_tlm_analysis_fifo #(master_seq_item) mas_af;
  uvm_tlm_analysis_fifo #(slave_seq_item)  slv_af;

  logic [31:0] sa;    
  logic [31:0] da;     
  logic [31:0] btt;   
  byte mem_sa[$];
  byte mem_da[$];   
  byte expected;
  byte actual;
  logic [127:0] temp;
    int pushed_bytes;

  function new(string name = "cdma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mas_af  = new("mas_af", this);
    slv_af  = new("slv_af", this);
  endfunction

  // Run Phase
  virtual task run_phase(uvm_phase phase);
    master_seq_item mas_pkt;
    slave_seq_item  slv_pkt;

    fork
      forever begin
        mas_af.get(mas_pkt);
        `uvm_info("SCB:: Received master pkt", mas_pkt.sprint(), UVM_MEDIUM)          
        master_write(mas_pkt);
      end

      forever begin
        slv_af.get(slv_pkt);
        `uvm_info("SCB:: Received slave pkt", slv_pkt.sprint(), UVM_MEDIUM)                    
        slave_write(slv_pkt);
      end
    join
  endtask : run_phase

  extern function void master_write(master_seq_item pkt);
  extern function void slave_write(slave_seq_item pkt);
  extern function void compare_data();

endclass : cdma_scoreboard


// ====================== Master Side ======================
  function void cdma_scoreboard::master_write(master_seq_item pkt);
    if (pkt == null) return;

    if (pkt.operation == WRITE) begin
      if (pkt.awaddr == 32'h0000_0018) sa  = pkt.wdata[0];  
      `uvm_info("CDMA_SB", $sformatf("SA captured = 0x%0h", sa), UVM_MEDIUM);
      if (pkt.awaddr == 32'h0000_0020) da  = pkt.wdata[0];
      `uvm_info("CDMA_SB", $sformatf("DA captured = 0x%0h", da), UVM_MEDIUM);
      if (pkt.awaddr == 32'h0000_0028) btt = pkt.wdata[0];
      `uvm_info("CDMA_SB", $sformatf("BTT captured = 0x%0h", btt), UVM_MEDIUM);
      end
  endfunction : master_write

// ====================== Slave Side ======================
function void cdma_scoreboard::slave_write(slave_seq_item pkt);
  if (pkt == null) return;
  
  if (pkt.operation == READ) begin
    if (pkt.araddr != sa) begin
      `uvm_error("CDMA_SB", 
        $sformatf("READ ADDRESS MISMATCH! Expected SA=0x%0h, Got=0x%0h", sa, pkt.araddr));
    end
pushed_bytes = 0;

foreach (pkt.rdata[i]) begin
  temp = pkt.rdata[i];
  for (int j = 0; j < 16; j++) begin
    if (pushed_bytes < btt) begin
      mem_sa.push_back(temp[7:0]);
      pushed_bytes++;
    end
    temp = temp >> 8;
  end
end

    //foreach (pkt.rdata[i]) begin
    //  temp = pkt.rdata[i];
    //  repeat (16) begin
    //    mem_sa.push_back(temp[7:0]);
    //    temp = temp >> 8;
    //  end
    //end
    `uvm_info("CDMA_SB_RDATA", $sformatf("Slave READ beats=%0d, mem_sa_size=%0d", pkt.rdata.size(), mem_sa.size()), UVM_MEDIUM);
  end 

  else if (pkt.operation == WRITE) begin
    if (pkt.awaddr != da) begin
      `uvm_error("CDMA_SB", 
        $sformatf("WRITE ADDRESS MISMATCH! Expected DA=0x%0h, Got=0x%0h", da, pkt.awaddr));
    end
pushed_bytes = 0;

foreach (pkt.wdata[i]) begin
  temp = pkt.wdata[i];
  for (int j = 0; j < 16; j++) begin
    if (pushed_bytes < btt) begin
      mem_da.push_back(temp[7:0]);
      pushed_bytes++;
    end
    temp = temp >> 8;
  end
end

    //foreach (pkt.wdata[i]) begin
    //  temp = pkt.wdata[i];
    //  repeat (16) begin
    //    mem_da.push_back(temp[7:0]);
    //    temp = temp >> 8;
    //  end
    //end
    `uvm_info("CDMA_SB_WDATA", $sformatf("Slave WRITE beats=%0d, mem_da_size=%0d", pkt.wdata.size(), mem_da.size()), UVM_MEDIUM);
  end

  compare_data();

endfunction : slave_write

// ======== Comparison using BTT ========
function void cdma_scoreboard::compare_data();
  if (btt == 0) begin
    `uvm_fatal("CDMA_SB", "BTT is 0, nothing to compare")
    return;
  end

  `uvm_info("CDMA_SB", $sformatf("Starting comparison: BTT=%0d bytes", btt), UVM_LOW);

//  for (int i = 0; i < btt; i++) begin
 while (mem_sa.size() > 0 && mem_da.size() > 0) begin
///    `uvm_warning("CDMA_SB", $sformatf("Queue empty at byte %0d", i));
//    break; // stop comparison
//  end
    expected = mem_sa.pop_front();
    actual   = mem_da.pop_front();

    if (expected === actual)begin
     `uvm_info("CDMA_SB", $sformatf("MATCH  Exp=0x%0h | Act=0x%0h",  expected, actual), UVM_MEDIUM);
    end else 
      `uvm_error("CDMA_SB", $sformatf("MISMATCH  Exp=0x%0h | Act=0x%0h",  expected, actual));
  end

  `uvm_info("CDMA_SB", "=== DATA COMPARISON COMPLETED ===", UVM_LOW);
endfunction : compare_data



/*class cdma_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cdma_scoreboard)

  // Analysis FIFOs
  uvm_tlm_analysis_fifo #(master_seq_item) mas_af;
  uvm_tlm_analysis_fifo #(slave_seq_item)  slv_af;

  logic [31:0] sa;    // Source Address
  logic [31:0] da;    // Destination Address  
  logic [31:0] btt;   // Bytes To Transfer
  logic [127:0] mem_sa[$];
  logic [127:0] mem_da[$];   
  logic [127:0] expected;
  logic [127:0] actual;

  function new(string name = "cdma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mas_af  = new("mas_af", this);
    slv_af  = new("slv_af", this);
  endfunction

    // Run Phase
  virtual task run_phase(uvm_phase phase);
    master_seq_item mas_pkt;
    slave_seq_item  slv_pkt;

      fork
        forever begin
          mas_af.get(mas_pkt);
          `uvm_info("SCB:: Received master pkt",mas_pkt.sprint(),UVM_MEDIUM)          
          master_write(mas_pkt);
        end
        forever begin
          slv_af.get(slv_pkt);
          `uvm_info("SCB:: Received slave pkt",slv_pkt.sprint(),UVM_MEDIUM)                    
          slave_write(slv_pkt);
        end
        join
       endtask : run_phase

  extern function void master_write(master_seq_item pkt);
  extern function void slave_write(slave_seq_item pkt);
  extern function void compare_data();

endclass : cdma_scoreboard

  // ====================== Master Side ======================
  function void cdma_scoreboard::master_write(master_seq_item pkt);
    if (pkt == null) return;

    if (pkt.operation == WRITE) begin
      if (pkt.awaddr == 32'h0000_0018) sa  = pkt.wdata[0];  
      `uvm_info("CDMA_SB", $sformatf("SA captured = 0x%0h", sa), UVM_MEDIUM);
      if (pkt.awaddr == 32'h0000_0020) da  = pkt.wdata[0];
      `uvm_info("CDMA_SB", $sformatf("DA captured = 0x%0h", da), UVM_MEDIUM);
      if (pkt.awaddr == 32'h0000_0028) btt = pkt.wdata[0];
      `uvm_info("CDMA_SB", $sformatf("BTT captured = 0x%0h", btt), UVM_MEDIUM);
      end
  endfunction : master_write

  // ====================== Slave Side ======================
  function void cdma_scoreboard::slave_write(slave_seq_item pkt);
    if (pkt == null) return;

    if (pkt.operation == READ) begin
    if (pkt.araddr != sa) begin
      `uvm_error("CDMA_SB", 
        $sformatf("ADDRESS MISMATCH on READ! Expected SA=0x%0h, Received araddr=0x%0h",sa, pkt.araddr));
    end
    else begin
      `uvm_info("CDMA_SB",$sformatf("READ Address MATCHED: araddr = 0x%0h ", pkt.araddr), UVM_MEDIUM);
    end
    foreach (pkt.rdata[i]) begin
        mem_sa.push_back(pkt.rdata[i]);
      `uvm_info("CDMA_SB_RDATA", $sformatf("Slave READ: beats = %0d ,rdata=%0h,mem_sa_size =%0d ", pkt.rdata.size(),pkt.rdata[i],mem_sa.size()), UVM_MEDIUM)
      end
    end 
    else if (pkt.operation == WRITE) begin
    if (pkt.awaddr != da) begin
      `uvm_error("CDMA_SB",$sformatf("ADDRESS MISMATCH on WRITE! Expected DA=0x%0h, Received awaddr=0x%0h",da, pkt.awaddr));
    end
    else begin
      `uvm_info("CDMA_SB",$sformatf("WRITE Address MATCHED: awaddr = 0x%0h", pkt.awaddr), UVM_MEDIUM);
    end
      for (pkt.wdata[i]) begin
        mem_da.push_back(pkt.wdata[i]);
        `uvm_info("CDMA_SB_WDATA",$sformatf("Slave WRITE ,beats = %0d ,wdata=%0h,mem_da_size =%0d ", pkt.wdata.size(),pkt.wdata[i],mem_da.size()), UVM_MEDIUM)
        end
      end
    compare_data();
  endfunction : slave_write

  // ======== Comparison using BTT ========
  function void cdma_scoreboard::compare_data();
    if (btt == 0) begin
      `uvm_fatal("CDMA_SB", "BTT is 0, nothing to compare")
      return;
    end

    `uvm_info("CDMA_SB", $sformatf("Starting comparison: BTT=%0d bytes", btt), UVM_LOW)
    
    while (mem_sa.size() > 0 && mem_da.size() > 0) begin
    expected = mem_sa.pop_front();
    actual   = mem_da.pop_front();

    if (expected === actual) begin
`uvm_info("CDMA_SB", 
        $sformatf("DATA MATCH at  Exp=0x%0h | Act=0x%0h", expected, actual), 
        UVM_MEDIUM);
    end else begin
      `uvm_error("CDMA_SB", $sformatf("DATA MISMATCH Exp=0x%0h | Act=0x%0h",  expected, actual));
    end
  end
  
    `uvm_info("CDMA_SB", "=== DATA COMPARISON COMPLETED ===", UVM_LOW);
    
  endfunction :compare_data*/

/*if (mem_sa.size() != mem_da.size()) begin
      `uvm_error("CDMA_SB", $sformatf("Size mismatch, Source=%0d, Destination=%0d", mem_sa.size(), mem_da.size()))
      return;
    end

    if (mem_sa.size() < btt) begin
      `uvm_warning("CDMA_SB", $sformatf("Not enough data captured, Exp=%0d,Act=%0d",btt, mem_sa.size()))
    end

    for (int i = 0; i < btt; i++) begin
      if (mem_sa[i] == mem_da[i]) begin
      `uvm_info("CDMA_SB",$sformatf("DATA MATCH  at byte %0d | Exp=0x%0h | Act=0x%0h", i, mem_sa[i], mem_da[i]), 
        UVM_MEDIUM);
    end
    else begin
      `uvm_error("CDMA_SB",$sformatf("DATA MISMATCH ,byte = %0d | Exp=0x%0h , Act=0x%0h",i, mem_sa[i], mem_da[i]))
      end
    end*/
