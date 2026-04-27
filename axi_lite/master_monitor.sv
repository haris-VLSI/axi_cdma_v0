class master_monitor extends uvm_monitor;

   `uvm_component_utils (master_monitor)
   uvm_analysis_port #(master_seq_item)   mon_ap;
   virtual master_intf.MON_MOD_master     master_mon_intf;
   mailbox #(master_seq_item)  write_address_mbx ,write_data_mbx;      //to capture transactions on write address channel // Preserve ordering
   mailbox #(master_seq_item) wresp_array [id_t];    //associative array of mailboxes. Will hold packets waiting for write response.Mailboxes will preserve ordering based on ID.
   mailbox #(master_seq_item) read_address_array [id_t];
   mailbox #(master_seq_item) read_data_array[id_t];
   function new (string name = "master_monitor" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern task main_phase (uvm_phase phase);
   extern function void build_phase (uvm_phase phase);
   extern task  merge_write_info();
   extern task  capture_reset();
   extern task  capture_write_address();
   extern task  capture_write_data();
   extern task  capture_write_response();
   extern task  capture_read_address();
   extern task  capture_read_data();

endclass :master_monitor

   function void master_monitor :: build_phase (uvm_phase phase);
     super.build_phase (phase);
     mon_ap = new ("mon_ap",this);
     write_address_mbx = new();
     write_data_mbx    = new();
     `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
   endfunction : build_phase

task master_monitor :: main_phase (uvm_phase phase);
 `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
 fork
  capture_reset();
  capture_write_address();
  capture_write_data();
  capture_write_response();
  capture_read_address();
  capture_read_data();
 join
endtask

task  master_monitor :: capture_write_address();
 master_seq_item     pkt;
 //write_address_mbx = new ();
 forever begin
    `uvm_info("master_monitor :: capture_write_address","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    wait( master_mon_intf.mas_mon_cb.awready && master_mon_intf.mas_mon_cb.awvalid && master_mon_intf.areset_n==1);
    pkt.wadd_hndshk = $realtime();  //capturing timestamp for handshake.
    pkt.awaddr   = master_mon_intf.mas_mon_cb.awaddr;
    pkt.awburst  = burst_type_t'(master_mon_intf.mas_mon_cb.awburst);
    pkt.awcache  = master_mon_intf.mas_mon_cb.awcache;
    pkt.awid     = master_mon_intf.mas_mon_cb.awid;
    pkt.awlen    = master_mon_intf.mas_mon_cb.awlen;
    pkt.awlock   = master_mon_intf.mas_mon_cb.awlock;
    pkt.awprot   = master_mon_intf.mas_mon_cb.awprot;
    pkt.awqos    = master_mon_intf.mas_mon_cb.awqos;
    pkt.awregion = master_mon_intf.mas_mon_cb.awregion;
    pkt.awsize   = master_mon_intf.mas_mon_cb.awsize;
    pkt.operation = WRITE;
    write_address_mbx.put(pkt);
    $display("write_address_mbx_length=%0h",write_address_mbx.num());
    `uvm_info("capture_write_address::task",pkt.sprint(),UVM_LOW)
    @(master_mon_intf.mas_mon_cb); //wait for a clk
  end
endtask

task  master_monitor ::  capture_write_data();
 master_seq_item     pkt;
 int i;
 bit last;
 //write_data_mbx =    new ();
 forever begin
    `uvm_info("master_monitor :: capture_write_data","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    pkt.wdata_hndshk =new[0];
    pkt.wdata =new[0];
    pkt.wstrobe= new[0];
    i = 0;
    do begin
      wait( master_mon_intf.mas_mon_cb.wready==1 && master_mon_intf.mas_mon_cb.wvalid==1 && master_mon_intf.areset_n==1);
      pkt.wdata_hndshk =new[pkt.wdata_hndshk.size() +1](pkt.wdata_hndshk);
      pkt.wdata =new[pkt.wdata.size() +1](pkt.wdata);
      pkt.wstrobe =new[pkt.wstrobe.size() +1](pkt.wstrobe);
      pkt.wdata_hndshk[i] = $realtime();  //capturing timestamp for handshake.
      pkt.wdata[i]    = master_mon_intf.mas_mon_cb.wdata;
      pkt.wstrobe[i]  = master_mon_intf.mas_mon_cb.wstrobe;
      last = master_mon_intf.mas_mon_cb.wlast;
      i=i+1;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
      end while(last==0);           //keeps sampling till last indicates end of data phase.
      write_data_mbx.put(pkt);
      $display("write_data_mbx_length=%0h",write_data_mbx.num());

      `uvm_info("master_monitor::capture_write_data_task",pkt.sprint(),UVM_LOW)
 end
endtask

task  master_monitor ::  capture_write_response();
 master_seq_item     pkt;
 forever begin
    `uvm_info("master_monitor :: capture_write_response","Triggred",UVM_LOW);
    wait( master_mon_intf.mas_mon_cb.bready==1 && master_mon_intf.mas_mon_cb.bvalid==1 && master_mon_intf.areset_n==1);
    merge_write_info(); //merges addr+data info waiting for response
    if(wresp_array.exists(master_mon_intf.mas_mon_cb.bid)) begin    //to check if captured bid matches with any transaction waiting for response.
       pkt = master_seq_item :: type_id :: create("pkt");
       wresp_array[master_mon_intf.mas_mon_cb.bid].get(pkt);           //this pkt already has add + data info
       pkt.wresp_hndshk = $realtime();  //capturing timestamp for handshake.
       pkt.bid    = master_mon_intf.mas_mon_cb.bid;
       pkt.bresp  =response_t'( master_mon_intf.mas_mon_cb.bresp);
       //`uvm_info("master_monitor :: capture_write_response","Sending pkt to SB",UVM_LOW);
       pkt.print_write_txn(pkt);
      // `uvm_info("write_response_phase",$sformatf("Printing pkt handshake Timestamps - add= %t data =%p wresp =%t",pkt.wadd_hndshk,pkt.wdata_hndshk, pkt.wresp_hndshk),UVM_LOW);
       `uvm_info("write_reponse_phase_pkt",pkt.sprint(),UVM_LOW)
       mon_ap.write(pkt);//write pkt to sb
    end
    //else `uvm_error("Master_monitor :: capture_write_response",$sformatf("unexpected write response, BID not found bid= %b",master_mon_intf.mas_mon_cb.bid))
    @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
 end
endtask

task  master_monitor :: capture_read_address();
 master_seq_item     pkt;
 forever begin
    `uvm_info("master_monitor :: capture_read_address","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    wait( master_mon_intf.mas_mon_cb.arready==1 && master_mon_intf.mas_mon_cb.arvalid==1 && master_mon_intf.areset_n==1);
    pkt.radd_hndshk = $realtime();  //capturing timestamp for handshake.
    pkt.araddr   = master_mon_intf.mas_mon_cb.araddr;
    pkt.arburst  = burst_type_t'(master_mon_intf.mas_mon_cb.arburst);
    pkt.arcache  = master_mon_intf.mas_mon_cb.arcache;
    pkt.arid     = master_mon_intf.mas_mon_cb.arid;  
    pkt.arlen    = master_mon_intf.mas_mon_cb.arlen;
    pkt.arlock   = master_mon_intf.mas_mon_cb.arlock;
    pkt.arprot   = master_mon_intf.mas_mon_cb.arprot;
    pkt.arqos    = master_mon_intf.mas_mon_cb.arqos;
    pkt.arregion = master_mon_intf.mas_mon_cb.arregion;
    pkt.arsize   = master_mon_intf.mas_mon_cb.arsize;
    pkt.operation = READ;
    //`uvm_info("master_monitor :: capture_read_address","captured address pkt put to read_address_array",UVM_LOW);
    if(!read_address_array.exists(pkt.arid)) 
    read_address_array[pkt.arid]=new(); 
    read_address_array[pkt.arid].put(pkt);
    @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
  end
endtask

task  master_monitor ::  capture_read_data();
 master_seq_item     pkt, pkt2sb;
 int i,no_of_beats;
 bit last;
 forever begin
    `uvm_info("master_monitor :: capture_read_data","Triggred",UVM_LOW);
    i = 0;
    do begin
      pkt = master_seq_item :: type_id :: create("pkt");
      pkt.rdata_hndshk = new[1];
      pkt.rdata =new [1];
      pkt.rresp =new [1];
      wait( master_mon_intf.mas_mon_cb.rready==1 && master_mon_intf.mas_mon_cb.rvalid==1 && master_mon_intf.areset_n==1);
      pkt.rdata_hndshk[0] = $realtime();  //capturing timestamp for handshake.
      pkt.rid       = master_mon_intf.mas_mon_cb.rid;
      pkt.rdata[0]  = master_mon_intf.mas_mon_cb.rdata;
      pkt.rresp[0]  = response_t'(master_mon_intf.mas_mon_cb.rresp);
      if(!read_data_array.exists(pkt.rid)) read_data_array[pkt.rid] = new();
      read_data_array[pkt.rid].put(pkt);
      i=i+1;
      last = master_mon_intf.mas_mon_cb.rlast;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
    end while( last ==0); //keeps sampling till last indicates end of data phase.
      pkt2sb = master_seq_item :: type_id :: create("pkt2sb");
      //get  pkt with address info and add data info.//
      read_address_array[pkt.rid].get(pkt2sb);  // this has address info for required rid pkt.
      no_of_beats = read_data_array[pkt.rid].num();
      pkt2sb.rid = pkt.rid;
      pkt2sb.rdata = new[no_of_beats];
      pkt2sb.rresp = new[no_of_beats];
      pkt2sb.rdata_hndshk = new[no_of_beats];
   for(i=0 ; i<no_of_beats; i++)begin         //merges all beats with same rid to pkt having address info
      read_data_array[pkt2sb.rid].get(pkt);
      pkt2sb.rdata[i] = pkt.rdata[0];
      pkt2sb.rresp[i] = pkt.rresp[0];
      pkt2sb.rdata_hndshk[i] = pkt.rdata_hndshk[0];
   end
    `uvm_info("master_monitor :: capture_read_data","Sending pkt to SB",UVM_LOW);
    //pkt2sb.print_read_txn(pkt2sb);
    //`uvm_info("read_data_phase",$sformatf("Printing handshake Timestamps - add= %t data =,%p",pkt2sb.radd_hndshk,pkt2sb.rdata_hndshk),UVM_LOW);

    //`uvm_info("read_data_after_writing to ap port",pkt.sprint(),UVM_MEDIUM)
    mon_ap.write(pkt2sb); //write pkt to sb
    //`uvm_info("read_data_after_writing to ap port",pkt.sprint(),UVM_MEDIUM)
 end
endtask

task master_monitor :: merge_write_info();
master_seq_item addr_pkt,data_pkt,merged_pkt;
int x ,no_addr, no_data; //indicates number of completed write transactions waiting for response.
  `uvm_info("master_monitor :: merge_write_info","Triggred",UVM_LOW);
  no_addr = write_address_mbx.num();
  no_data = write_data_mbx.num();
  x = (no_addr<no_data)? no_addr :no_data;
  //`uvm_info("master_monitor :: merge_write_info",$sformatf("before get pkt comparing no_of_elements  addr= %d, data=%d ,x=%d",no_addr,no_data,x),UVM_LOW);
  //repeat(x)begin
  merged_pkt = master_seq_item :: type_id :: create("merged_pkt");
  write_address_mbx.get(addr_pkt);
  `uvm_info("merge_pkt::write_addr",addr_pkt.sprint(),UVM_LOW)
  write_data_mbx.get(data_pkt);
  `uvm_info("merge_pkt::write_data",data_pkt.sprint(),UVM_LOW)
  //Merging address and data phases
   //write address_phase
   merged_pkt.operation = WRITE;
   merged_pkt.wadd_hndshk = addr_pkt.wadd_hndshk;
   merged_pkt.awburst     = addr_pkt.awburst;
   merged_pkt.awaddr      = addr_pkt.awaddr;
   merged_pkt.awsize      = addr_pkt.awsize;
   merged_pkt.awid        = addr_pkt.awid;
   merged_pkt.awlen       = addr_pkt.awlen;
   merged_pkt.awlock      = addr_pkt.awlock;
   merged_pkt.awprot      = addr_pkt.awprot;
   merged_pkt.awqos       = addr_pkt.awqos;
   merged_pkt.awcache     = addr_pkt.awcache;
   merged_pkt.awregion    = addr_pkt.awregion;
   //write data phase
   merged_pkt.wdata_hndshk =data_pkt.wdata_hndshk;
   merged_pkt.wdata    = data_pkt.wdata;
   merged_pkt.wstrobe  = data_pkt.wstrobe;
  //adding packets to array waiting for response
  // `uvm_info("master_monitor :: merge_write_info",$sformatf("putting merged pkt to wresp_array awaddr = %b",merged_pkt.awaddr),UVM_LOW);
    `uvm_info("master_monitor::merge_write_info_",merged_pkt.sprint(),UVM_LOW)
    if(!wresp_array.exists(merged_pkt.awid)) wresp_array[merged_pkt.awid] = new();
    wresp_array[merged_pkt.awid].put(merged_pkt);

  //end
endtask


task master_monitor :: capture_reset();
 master_seq_item     rst_pkt;
 `uvm_info("master_monitor :: capture_reset","Triggred",UVM_LOW);
 fork
  forever begin //reset deasserted
    @(posedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_DEASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_deasserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
  forever begin //reset asserted
    @(negedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_ASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_asserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
join
endtask

/*
class master_monitor extends uvm_monitor;

   `uvm_component_utils (master_monitor)
   uvm_analysis_port #(master_seq_item)   mon_ap;
   virtual master_intf.MON_MOD_master     master_mon_intf;
   mailbox #(master_seq_item)  write_address_mbx ,write_data_mbx;      //to capture transactions on write address channel // Preserve ordering
   mailbox #(master_seq_item) wresp_array [id_t];    //associative array of mailboxes. Will hold packets waiting for write response.Mailboxes will preserve ordering based on ID.
   mailbox #(master_seq_item) read_address_array [id_t];
   mailbox #(master_seq_item) read_data_array[id_t];
   function new (string name = "master_monitor" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern task main_phase (uvm_phase phase);
   extern function void build_phase (uvm_phase phase);
   extern task  merge_write_info();
   extern task  capture_reset();
   extern task  capture_write_address();
   extern task  capture_write_data();
   extern task  capture_write_response();
   extern task  capture_read_address();
   extern task  capture_read_data();

endclass :master_monitor

   function void master_monitor :: build_phase (uvm_phase phase);
     super.build_phase (phase);
     mon_ap = new ("mon_ap",this);
     write_address_mbx = new();
     write_data_mbx    = new();
     `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
   endfunction : build_phase

task master_monitor :: main_phase (uvm_phase phase);
 `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
 fork
  capture_reset();
  capture_write_address();
  capture_write_data();
  capture_write_response();
  capture_read_address();
  capture_read_data();
 join
endtask

task  master_monitor :: capture_write_address();
 master_seq_item     pkt;
 //write_address_mbx = new ();
 forever begin
    `uvm_info("master_monitor :: capture_write_address","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    wait( master_mon_intf.mas_mon_cb.awready && master_mon_intf.mas_mon_cb.awvalid && master_mon_intf.areset_n==1);
    pkt.wadd_hndshk = $realtime();  //capturing timestamp for handshake.
    pkt.awaddr   = master_mon_intf.mas_mon_cb.awaddr;
    pkt.awburst  = burst_type_t'(master_mon_intf.mas_mon_cb.awburst);
    pkt.awcache  = master_mon_intf.mas_mon_cb.awcache;
    pkt.awid     = master_mon_intf.mas_mon_cb.awid;
    pkt.awlen    = master_mon_intf.mas_mon_cb.awlen;
    pkt.awlock   = master_mon_intf.mas_mon_cb.awlock;
    pkt.awprot   = master_mon_intf.mas_mon_cb.awprot;
    pkt.awqos    = master_mon_intf.mas_mon_cb.awqos;
    pkt.awregion = master_mon_intf.mas_mon_cb.awregion;
    pkt.awsize   = master_mon_intf.mas_mon_cb.awsize;
    pkt.operation = WRITE;
    write_address_mbx.put(pkt);
    $display("write_address_mbx_length=%0h",write_address_mbx.num());
    `uvm_info("capture_write_address::task",pkt.sprint(),UVM_LOW)
    @(master_mon_intf.mas_mon_cb); //wait for a clk
  end
endtask

task  master_monitor ::  capture_write_data();
 master_seq_item     pkt;
 int i;
 bit last;
 //write_data_mbx =    new ();
 forever begin
    `uvm_info("master_monitor :: capture_write_data","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    pkt.wdata_hndshk =new[0];
    pkt.wdata =new[0];
    pkt.wstrobe= new[0];
    i = 0;
    do begin
      wait( master_mon_intf.mas_mon_cb.wready==1 && master_mon_intf.mas_mon_cb.wvalid==1 && master_mon_intf.areset_n==1);
      pkt.wdata_hndshk =new[pkt.wdata_hndshk.size() +1](pkt.wdata_hndshk);
      pkt.wdata =new[pkt.wdata.size() +1](pkt.wdata);
      pkt.wstrobe =new[pkt.wstrobe.size() +1](pkt.wstrobe);
      pkt.wdata_hndshk[i] = $realtime();  //capturing timestamp for handshake.
      pkt.wdata[i]    = master_mon_intf.mas_mon_cb.wdata;
      pkt.wstrobe[i]  = master_mon_intf.mas_mon_cb.wstrobe;
      last = master_mon_intf.mas_mon_cb.wlast;
      i=i+1;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
      end while(last==0);           //keeps sampling till last indicates end of data phase.
      write_data_mbx.put(pkt);
      $display("write_data_mbx_length=%0h",write_data_mbx.num());

      `uvm_info("master_monitor::capture_write_data_task",pkt.sprint(),UVM_LOW)
 end
endtask

task  master_monitor ::  capture_write_response();
 master_seq_item     pkt;
 forever begin
    `uvm_info("master_monitor :: capture_write_response","Triggred",UVM_LOW);
    wait( master_mon_intf.mas_mon_cb.bready==1 && master_mon_intf.mas_mon_cb.bvalid==1 && master_mon_intf.areset_n==1);
    merge_write_info(); //merges addr+data info waiting for response
    if(wresp_array.exists(master_mon_intf.mas_mon_cb.bid)) begin    //to check if captured bid matches with any transaction waiting for response.
       pkt = master_seq_item :: type_id :: create("pkt");
       wresp_array[master_mon_intf.mas_mon_cb.bid].get(pkt);           //this pkt already has add + data info
       pkt.wresp_hndshk = $realtime();  //capturing timestamp for handshake.
       pkt.bid    = master_mon_intf.mas_mon_cb.bid;
       pkt.bresp  =response_t'( master_mon_intf.mas_mon_cb.bresp);
       //`uvm_info("master_monitor :: capture_write_response","Sending pkt to SB",UVM_LOW);
       pkt.print_write_txn(pkt);
      // `uvm_info("write_response_phase",$sformatf("Printing pkt handshake Timestamps - add= %t data =%p wresp =%t",pkt.wadd_hndshk,pkt.wdata_hndshk, pkt.wresp_hndshk),UVM_LOW);
       `uvm_info("write_reponse_phase_pkt",pkt.sprint(),UVM_LOW)
       mon_ap.write(pkt);//write pkt to sb
    end
    //else `uvm_error("Master_monitor :: capture_write_response",$sformatf("unexpected write response, BID not found bid= %b",master_mon_intf.mas_mon_cb.bid))
    @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
 end
endtask

task  master_monitor :: capture_read_address();
 master_seq_item     pkt;
 forever begin
    `uvm_info("master_monitor :: capture_read_address","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    wait( master_mon_intf.mas_mon_cb.arready==1 && master_mon_intf.mas_mon_cb.arvalid==1 && master_mon_intf.areset_n==1);
    pkt.radd_hndshk = $realtime();  //capturing timestamp for handshake.
    pkt.araddr   = master_mon_intf.mas_mon_cb.araddr;
    pkt.arburst  = burst_type_t'(master_mon_intf.mas_mon_cb.arburst);
    pkt.arcache  = master_mon_intf.mas_mon_cb.arcache;
    pkt.arid     = master_mon_intf.mas_mon_cb.arid;  
    pkt.arlen    = master_mon_intf.mas_mon_cb.arlen;
    pkt.arlock   = master_mon_intf.mas_mon_cb.arlock;
    pkt.arprot   = master_mon_intf.mas_mon_cb.arprot;
    pkt.arqos    = master_mon_intf.mas_mon_cb.arqos;
    pkt.arregion = master_mon_intf.mas_mon_cb.arregion;
    pkt.arsize   = master_mon_intf.mas_mon_cb.arsize;
    pkt.operation = READ;
    //`uvm_info("master_monitor :: capture_read_address","captured address pkt put to read_address_array",UVM_LOW);
    if(!read_address_array.exists(pkt.arid)) 
    read_address_array[pkt.arid]=new(); 
    read_address_array[pkt.arid].put(pkt);
    @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
  end
endtask

task  master_monitor ::  capture_read_data();
 master_seq_item     pkt, pkt2sb;
 int i,no_of_beats;
 bit last;
 forever begin
    `uvm_info("master_monitor :: capture_read_data","Triggred",UVM_LOW);
    i = 0;
    do begin
      pkt = master_seq_item :: type_id :: create("pkt");
      pkt.rdata_hndshk = new[1];
      pkt.rdata =new [1];
      pkt.rresp =new [1];
      wait( master_mon_intf.mas_mon_cb.rready==1 && master_mon_intf.mas_mon_cb.rvalid==1 && master_mon_intf.areset_n==1);
      pkt.rdata_hndshk[0] = $realtime();  //capturing timestamp for handshake.
      pkt.rid       = master_mon_intf.mas_mon_cb.rid;
      pkt.rdata[0]  = master_mon_intf.mas_mon_cb.rdata;
      pkt.rresp[0]  = response_t'(master_mon_intf.mas_mon_cb.rresp);
      if(!read_data_array.exists(pkt.rid)) read_data_array[pkt.rid] = new();
      read_data_array[pkt.rid].put(pkt);
      i=i+1;
      last = master_mon_intf.mas_mon_cb.rlast;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
    end while( last ==0); //keeps sampling till last indicates end of data phase.
      pkt2sb = master_seq_item :: type_id :: create("pkt2sb");
      //get  pkt with address info and add data info.//
      read_address_array[pkt.rid].get(pkt2sb);  // this has address info for required rid pkt.
      no_of_beats = read_data_array[pkt.rid].num();
      pkt2sb.rid = pkt.rid;
      pkt2sb.rdata = new[no_of_beats];
      pkt2sb.rresp = new[no_of_beats];
      pkt2sb.rdata_hndshk = new[no_of_beats];
   for(i=0 ; i<no_of_beats; i++)begin         //merges all beats with same rid to pkt having address info
      read_data_array[pkt2sb.rid].get(pkt);
      pkt2sb.rdata[i] = pkt.rdata[0];
      pkt2sb.rresp[i] = pkt.rresp[0];
      pkt2sb.rdata_hndshk[i] = pkt.rdata_hndshk[0];
   end
    `uvm_info("master_monitor :: capture_read_data","Sending pkt to SB",UVM_LOW);
    //pkt2sb.print_read_txn(pkt2sb);
    //`uvm_info("read_data_phase",$sformatf("Printing handshake Timestamps - add= %t data =,%p",pkt2sb.radd_hndshk,pkt2sb.rdata_hndshk),UVM_LOW);

    //`uvm_info("read_data_after_writing to ap port",pkt.sprint(),UVM_MEDIUM)
    mon_ap.write(pkt2sb); //write pkt to sb
    //`uvm_info("read_data_after_writing to ap port",pkt.sprint(),UVM_MEDIUM)
 end
endtask

task master_monitor :: merge_write_info();
master_seq_item addr_pkt,data_pkt,merged_pkt;
int x ,no_addr, no_data; //indicates number of completed write transactions waiting for response.
  `uvm_info("master_monitor :: merge_write_info","Triggred",UVM_LOW);
  no_addr = write_address_mbx.num();
  no_data = write_data_mbx.num();
  x = (no_addr<no_data)? no_addr :no_data;
  //`uvm_info("master_monitor :: merge_write_info",$sformatf("before get pkt comparing no_of_elements  addr= %d, data=%d ,x=%d",no_addr,no_data,x),UVM_LOW);
  //repeat(x)begin
  merged_pkt = master_seq_item :: type_id :: create("merged_pkt");
  write_address_mbx.get(addr_pkt);
  `uvm_info("merge_pkt::write_addr",addr_pkt.sprint(),UVM_LOW)
  write_data_mbx.get(data_pkt);
  `uvm_info("merge_pkt::write_data",data_pkt.sprint(),UVM_LOW)
  //Merging address and data phases
   //write address_phase
   merged_pkt.operation = WRITE;
   merged_pkt.wadd_hndshk = addr_pkt.wadd_hndshk;
   merged_pkt.awburst     = addr_pkt.awburst;
   merged_pkt.awaddr      = addr_pkt.awaddr;
   merged_pkt.awsize      = addr_pkt.awsize;
   merged_pkt.awid        = addr_pkt.awid;
   merged_pkt.awlen       = addr_pkt.awlen;
   merged_pkt.awlock      = addr_pkt.awlock;
   merged_pkt.awprot      = addr_pkt.awprot;
   merged_pkt.awqos       = addr_pkt.awqos;
   merged_pkt.awcache     = addr_pkt.awcache;
   merged_pkt.awregion    = addr_pkt.awregion;
   //write data phase
   merged_pkt.wdata_hndshk =data_pkt.wdata_hndshk;
   merged_pkt.wdata    = data_pkt.wdata;
   merged_pkt.wstrobe  = data_pkt.wstrobe;
  //adding packets to array waiting for response
  // `uvm_info("master_monitor :: merge_write_info",$sformatf("putting merged pkt to wresp_array awaddr = %b",merged_pkt.awaddr),UVM_LOW);
   //mon_ap.write(merged_pkt);
    `uvm_info("master_monitor::merge_write_info_",merged_pkt.sprint(),UVM_LOW)
    if(!wresp_array.exists(merged_pkt.awid)) wresp_array[merged_pkt.awid] = new();
    wresp_array[merged_pkt.awid].put(merged_pkt);
  //end
endtask


task master_monitor :: capture_reset();
 master_seq_item     rst_pkt;
 `uvm_info("master_monitor :: capture_reset","Triggred",UVM_LOW);
 fork
  forever begin //reset deasserted
    @(posedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_DEASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_deasserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
  forever begin //reset asserted
    @(negedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_ASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_asserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
join
endtask

/*
 * class master_monitor extends uvm_monitor;

   `uvm_component_utils (master_monitor)
   uvm_analysis_port #(master_seq_item)   mon_ap;
   virtual master_intf.MON_MOD_master     master_mon_intf;
   mailbox #(master_seq_item)  write_address_mbx ,write_data_mbx;      //to capture transactions on write address channel // Preserve ordering
   mailbox #(master_seq_item) wresp_array [id_t];    //associative array of mailboxes. Will hold packets waiting for write response.Mailboxes will preserve ordering based on ID.
   mailbox #(master_seq_item) read_address_array [id_t];
   mailbox #(master_seq_item) read_data_array[id_t];

   function new (string name = "master_monitor" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern task main_phase (uvm_phase phase);
   extern function void build_phase (uvm_phase phase);
   extern task  merge_write_info();
   extern task  capture_reset();
   extern task  capture_write_address();
   extern task  capture_write_data();
   extern task  capture_write_response();
   extern task  capture_read_address();
   extern task  capture_read_data();

endclass :master_monitor

   function void master_monitor :: build_phase (uvm_phase phase);
     super.build_phase (phase);
     mon_ap = new ("mon_ap",this);
     `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
   endfunction : build_phase

task master_monitor :: main_phase (uvm_phase phase);
 `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
 fork
  capture_reset();
  capture_write_address();
  capture_write_data();
  capture_write_response();
  capture_read_address();
  capture_read_data();
 join
endtask

task  master_monitor :: capture_write_address();
 master_seq_item     pkt;
 write_address_mbx = new ();
 forever begin
    `uvm_info("master_monitor :: capture_write_address","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    wait( master_mon_intf.mas_mon_cb.awready && master_mon_intf.mas_mon_cb.awvalid && master_mon_intf.areset_n==1);
    pkt.wadd_hndshk = $realtime();  //capturing timestamp for handshake.
    pkt.awaddr   = master_mon_intf.mas_mon_cb.awaddr;
    pkt.awburst  = burst_type_t'(master_mon_intf.mas_mon_cb.awburst);
    pkt.awcache  = master_mon_intf.mas_mon_cb.awcache;
    pkt.awid     = master_mon_intf.mas_mon_cb.awid;
    pkt.awlen    = master_mon_intf.mas_mon_cb.awlen;
    pkt.awlock   = master_mon_intf.mas_mon_cb.awlock;
    pkt.awprot   = master_mon_intf.mas_mon_cb.awprot;
    pkt.awqos    = master_mon_intf.mas_mon_cb.awqos;
    pkt.awregion = master_mon_intf.mas_mon_cb.awregion;
    pkt.awsize   = master_mon_intf.mas_mon_cb.awsize;
    pkt.operation = WRITE;
    `uvm_info("master_monitor :: capture_write_address","captured address pkt put to write_address_mbx",UVM_LOW);
    //`uvm_info("MASTER_MONITOR:: capture_write_address",pkt.sprint(),UVM_MEDIUM)
    write_address_mbx.put(pkt);
    @(master_mon_intf.mas_mon_cb); //wait for a clk
  end
endtask

task  master_monitor ::  capture_write_data();
 master_seq_item     pkt;
 int i;
 bit last;
 write_data_mbx =    new ();
 forever begin
    `uvm_info("master_monitor :: capture_write_data","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    pkt.wdata_hndshk =new[0];
    pkt.wdata =new[0];
    pkt.wstrobe= new[0];
    i = 0;
    do begin
      wait( master_mon_intf.mas_mon_cb.wready==1 && master_mon_intf.mas_mon_cb.wvalid==1 && master_mon_intf.areset_n==1); 
      `uvm_info("master_monitor :: capture_write_data","Inside dowhile loop",UVM_LOW);
      pkt.wdata_hndshk =new[pkt.wdata_hndshk.size() +1](pkt.wdata_hndshk);
      pkt.wdata =new[pkt.wdata.size() +1](pkt.wdata);
      pkt.wstrobe =new[pkt.wstrobe.size() +1](pkt.wstrobe);
      pkt.wdata_hndshk[i] = $realtime();  //capturing timestamp for handshake.
      pkt.wdata[i]    = master_mon_intf.mas_mon_cb.wdata;
      pkt.wstrobe[i]  = master_mon_intf.mas_mon_cb.wstrobe;
      last = master_mon_intf.mas_mon_cb.wlast;
      i=i+1;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
      end while(last==0);           //keeps sampling till last indicates end of data phase.
      `uvm_info("master_monitor :: capture_write_data","captured data pkt put to write_data_mbx",UVM_LOW);
      `uvm_info("MASTER_MONITOR:: capture_write_data",pkt.sprint(),UVM_MEDIUM)
      write_data_mbx.put(pkt);
 end
endtask

task  master_monitor ::  capture_write_response();
 master_seq_item     pkt;
 master_seq_item wresp_q[$];  // queue of master_seq_item
 
 forever begin
    `uvm_info("master_monitor :: capture_write_response","Triggred",UVM_LOW);
    wait(master_mon_intf.mas_mon_cb.bready==1 && master_mon_intf.mas_mon_cb.bvalid==1 && master_mon_intf.areset_n==1);
    merge_write_info(); //merges addr+data info waiting for response
    //if(wresp_array.exists(master_mon_intf.mas_mon_cb.bid)) begin    //to check if captured bid matches with any transaction waiting for response.
       pkt = master_seq_item :: type_id :: create("pkt");
       //wresp_array[master_mon_intf.mas_mon_cb.bid].get(pkt);           //this pkt already has add + data info

        wresp_q.push_back(pkt);  // add pkt to the end of the queue   
        if (wresp_q.size() > 0) begin
        pkt = wresp_q.pop_front();

       pkt.wresp_hndshk = $realtime();  //capturing timestamp for handshake.
       pkt.bid    = master_mon_intf.mas_mon_cb.bid;
       pkt.bresp  = response_t'(master_mon_intf.mas_mon_cb.bresp);
    //`uvm_info("master_monitor :: capture_write_response","Sending pkt to SB",UVM_LOW);
       //pkt.print_write_txn(pkt);
       //`uvm_info("write_response_phase",$sformatf("Printing pkt handshake Timestamps - add= %t data =%p wresp =%t",pkt.wadd_hndshk,pkt.wdata_hndshk, pkt.wresp_hndshk),UVM_LOW);
    `uvm_info("MASTER_MONITOR:: capture_write_responce",pkt.sprint(),UVM_MEDIUM)
       mon_ap.write(pkt); //write pkt to sb
    end else `uvm_error("Master_monitor :: capture_write_response",$sformatf("unexpected write response, BID not found bid= %b",master_mon_intf.mas_mon_cb.bid))
    @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
 end
endtask

task  master_monitor :: capture_read_address();
 master_seq_item     pkt;
 forever begin
    `uvm_info("master_monitor :: capture_read_address","Triggred",UVM_LOW);
    pkt = master_seq_item :: type_id :: create("pkt");
    wait( master_mon_intf.mas_mon_cb.arready==1 && master_mon_intf.mas_mon_cb.arvalid==1 && master_mon_intf.areset_n==1);
    pkt.radd_hndshk = $realtime();  //capturing timestamp for handshake.
    pkt.araddr   = master_mon_intf.mas_mon_cb.araddr;
    pkt.arburst  = burst_type_t'(master_mon_intf.mas_mon_cb.arburst);
    pkt.arcache  = master_mon_intf.mas_mon_cb.arcache;
    pkt.arid     = master_mon_intf.mas_mon_cb.arid;
    pkt.arlen    = master_mon_intf.mas_mon_cb.arlen;
    pkt.arlock   = master_mon_intf.mas_mon_cb.arlock;
    pkt.arprot   = master_mon_intf.mas_mon_cb.arprot;
    pkt.arqos    = master_mon_intf.mas_mon_cb.arqos;
    pkt.arregion = master_mon_intf.mas_mon_cb.arregion;
    //pkt.arsize   = master_mon_intf.mas_mon_cb.arsize;
    pkt.operation = READ;
    //`uvm_info("master_monitor :: capture_read_address","captured address pkt put to read_address_array",UVM_LOW);
    if(!read_address_array.exists(pkt.arid)) read_address_array[pkt.arid]=new();
    //`uvm_info("MASTER_MONITOR:: capture_read_address",pkt.sprint(),UVM_MEDIUM)
    read_address_array[pkt.arid].put(pkt);
    @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
  end
endtask

task  master_monitor ::  capture_read_data();
 master_seq_item     pkt, pkt2sb;
 int i,no_of_beats;
 bit last;
 forever begin
    `uvm_info("master_monitor :: capture_read_data","Triggred",UVM_LOW);
    i = 0;
    do begin
      pkt = master_seq_item :: type_id :: create("pkt");
      pkt.rdata_hndshk = new[1];
      pkt.rdata =new [1];
      pkt.rresp =new [1];
      wait( master_mon_intf.mas_mon_cb.rready==1 && master_mon_intf.mas_mon_cb.rvalid==1 && master_mon_intf.areset_n==1);
      pkt.rdata_hndshk[0] = $realtime();  //capturing timestamp for handshake.
      pkt.rid       = master_mon_intf.mas_mon_cb.rid;
      pkt.rdata[0]  = master_mon_intf.mas_mon_cb.rdata;
      pkt.rresp[0]  = response_t'(master_mon_intf.mas_mon_cb.rresp);
      if(!read_data_array.exists(pkt.rid)) read_data_array[pkt.rid] = new();
      read_data_array[pkt.rid].put(pkt);
      i=i+1;
      last = master_mon_intf.mas_mon_cb.rlast;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
    end while( last ==0); //keeps sampling till last indicates end of data phase.
      pkt2sb = master_seq_item :: type_id :: create("pkt2sb");
      //get  pkt with address info and add data info.//
      read_address_array[pkt.rid].get(pkt2sb);  // this has address info for required rid pkt.
      no_of_beats = read_data_array[pkt.rid].num();
      pkt2sb.rid = pkt.rid;
      pkt2sb.rdata = new[no_of_beats];
      pkt2sb.rresp = new[no_of_beats];
      pkt2sb.rdata_hndshk = new[no_of_beats];
   for(i=0 ; i<no_of_beats; i++)begin         //merges all beats with same rid to pkt having address info
      read_data_array[pkt2sb.rid].get(pkt);
      pkt2sb.rdata[i] = pkt.rdata[0];
      pkt2sb.rresp[i] = pkt.rresp[0];
      pkt2sb.rdata_hndshk[i] = pkt.rdata_hndshk[0];
   end
    `uvm_info("master_monitor :: capture_read_data","Sending pkt to SB",UVM_LOW);
    //`uvm_info("MASTER_MONITOR:: capture_read_address: pkt",pkt.sprint(),UVM_MEDIUM)
    //`uvm_info("MASTER_MONITOR:: capture_read_address",pkt2sb.sprint(),UVM_MEDIUM)
    //pkt2sb.print_read_txn(pkt2sb);
  //  `uvm_info("read_data_phase",$sformatf("Printing handshake Timestamps - add= %t data =,%p",pkt2sb.radd_hndshk,pkt2sb.rdata_hndshk),UVM_LOW);
    mon_ap.write(pkt2sb); //write pkt to sb
    //`uvm_info("MASTER_MONITOR:: capture_read_data",pkt2sb.sprint(),UVM_MEDIUM)
 end
endtask

task master_monitor :: merge_write_info();
master_seq_item addr_pkt,data_pkt,merged_pkt;
int x ,no_addr, no_data; //indicates number of completed write transactions waiting for response.
  `uvm_info("master_monitor :: merge_write_info","Triggred",UVM_LOW);
  no_addr = write_address_mbx.num();
  no_data = write_data_mbx.num();
  x = (no_addr<no_data)? no_addr :no_data;
  //`uvm_info("master_monitor :: merge_write_info",$sformatf("before get pkt comparing no_of_elements  addr= %d, data=%d ,x=%d",no_addr,no_data,x),UVM_LOW);
  //repeat(x)begin
  merged_pkt = master_seq_item :: type_id :: create("merged_pkt");
  write_address_mbx.get(addr_pkt);
  write_data_mbx.get(data_pkt);
  //Merging address and data phases
   //write address_phase
   merged_pkt.operation = WRITE;
   merged_pkt.wadd_hndshk = addr_pkt.wadd_hndshk;
   merged_pkt.awburst     = addr_pkt.awburst;
   merged_pkt.awaddr      = addr_pkt.awaddr;
   merged_pkt.awsize      = addr_pkt.awsize;
   merged_pkt.awid        = addr_pkt.awid;
   merged_pkt.awlen       = addr_pkt.awlen;
   merged_pkt.awlock      = addr_pkt.awlock;
   merged_pkt.awprot      = addr_pkt.awprot;
   merged_pkt.awqos       = addr_pkt.awqos;
   merged_pkt.awcache     = addr_pkt.awcache;
   merged_pkt.awregion    = addr_pkt.awregion;
   //write data phase
   merged_pkt.wdata_hndshk =data_pkt.wdata_hndshk;
   merged_pkt.wdata    = data_pkt.wdata;
   merged_pkt.wstrobe  = data_pkt.wstrobe;
  //adding packets to array waiting for response
   //`uvm_info("master_monitor :: merge_write_info",$sformatf("putting merged pkt to wresp_array awid = %b",merged_pkt.awid),UVM_LOW);
    if(!wresp_array.exists(merged_pkt.awid)) wresp_array[merged_pkt.awid] = new();
    wresp_array[merged_pkt.awid].put(merged_pkt);
  //end
endtask


task master_monitor :: capture_reset();
 master_seq_item     rst_pkt;
 `uvm_info("master_monitor :: capture_reset","Triggred",UVM_LOW);
 fork
  forever begin //reset deasserted
    @(posedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_DEASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_deasserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
  forever begin //reset asserted
    @(negedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_ASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_asserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
join
endtask

