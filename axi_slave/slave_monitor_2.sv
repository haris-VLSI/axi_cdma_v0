class slave_monitor extends uvm_monitor;

   `uvm_component_utils (slave_monitor)
   uvm_analysis_port #(slave_seq_item)   mon_ap;
   uvm_analysis_port #(slave_seq_item)   resp_ap;
   virtual slave_intf.MON_MOD_slave      slave_mon_intf;
   mailbox #(slave_seq_item)  write_address_mbx ,write_data_mbx;      //to capture transactions on write address channel // Preserve ordering
   mailbox #(slave_seq_item) wresp_array [id_t];    //associative array of mailboxes. Will hold packets waiting for write response.Mailboxes will preserve ordering based on ID.
   mailbox #(slave_seq_item) read_address_array [id_t];
   mailbox #(slave_seq_item) read_data_array[id_t];

   function new (string name = "slave_monitor" , uvm_component parent);
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
endclass :slave_monitor

function void slave_monitor :: build_phase (uvm_phase phase);
  super.build_phase (phase);
  mon_ap = new ("mon_ap",this);
  resp_ap = new("resp_ap",this);
  `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
endfunction : build_phase

task slave_monitor :: main_phase (uvm_phase phase);
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

task  slave_monitor :: capture_write_address();
 slave_seq_item     pkt;
 write_address_mbx = new ();
 forever begin
    `uvm_info("slave_monitor :: capture_write_address","Triggred",UVM_MEDIUM);
    pkt = slave_seq_item :: type_id :: create("pkt");
    wait( slave_mon_intf.slv_mon_cb.awvalid && slave_mon_intf.areset_n==1); //wait for valid
    pkt.awaddr   = slave_mon_intf.slv_mon_cb.awaddr;
    pkt.awburst  = burst_type_t'(slave_mon_intf.slv_mon_cb.awburst);
    pkt.awcache  = slave_mon_intf.slv_mon_cb.awcache;
    pkt.awid     = slave_mon_intf.slv_mon_cb.awid;
    pkt.awlen    = slave_mon_intf.slv_mon_cb.awlen;
    pkt.awlock   = slave_mon_intf.slv_mon_cb.awlock;
    pkt.awprot   = slave_mon_intf.slv_mon_cb.awprot;
    pkt.awqos    = slave_mon_intf.slv_mon_cb.awqos;
    pkt.awregion = slave_mon_intf.slv_mon_cb.awregion;
    pkt.awsize   = slave_mon_intf.slv_mon_cb.awsize;
    pkt.operation = WRITE;
    resp_ap.write(pkt); //write pkt to sequencer for response
    wait(slave_mon_intf.slv_mon_cb.awready && slave_mon_intf.slv_mon_cb.awvalid && slave_mon_intf.areset_n==1); //wait for handshake
    pkt.wadd_hndshk = $realtime();  //capturing timestamp for handshake.
    `uvm_info("slave_monitor :: capture_write_address",pkt.sprint(),UVM_MEDIUM);
    write_address_mbx.put(pkt);
    @(slave_mon_intf.slv_mon_cb); //wait till next clk posedge
  end
endtask

task  slave_monitor ::  capture_write_data();
 slave_seq_item     pkt;
 int i;
 bit last;
 write_data_mbx =    new ();
 forever begin
    `uvm_info("slave_monitor :: capture_write_data","Triggred",UVM_MEDIUM);
    pkt = slave_seq_item :: type_id :: create("pkt");
    pkt.wdata_hndshk =new[0];
    pkt.wdata =new[0];
    pkt.wstrobe= new[0];
    i = 0;
    do begin
      @(slave_mon_intf.slv_mon_cb); //wait till next clk posedge
      wait(slave_mon_intf.slv_mon_cb.wready==1 && slave_mon_intf.slv_mon_cb.wvalid==1 && slave_mon_intf.areset_n==1);
      pkt.wdata_hndshk =new[pkt.wdata_hndshk.size() +1](pkt.wdata_hndshk);
      pkt.wdata =new[pkt.wdata.size() +1](pkt.wdata);
      pkt.wstrobe =new[pkt.wstrobe.size() +1](pkt.wstrobe);
      pkt.wdata_hndshk[i] = $realtime();  //capturing timestamp for handshake.
      pkt.wdata[i]    = slave_mon_intf.slv_mon_cb.wdata;
      pkt.wstrobe[i]  = slave_mon_intf.slv_mon_cb.wstrobe;
      last = slave_mon_intf.slv_mon_cb.wlast;
      i=i+1;
      end while( last==0); //keeps sampling till last indicates end of data phase.
      //`uvm_info("slave_monitor :: capture_write_data","captured data pkt put to write_data_mbx",UVM_MEDIUM);
    `uvm_info("slave_monitor:: capture_write_data",pkt.sprint(),UVM_MEDIUM)
    write_data_mbx.put(pkt);
 end
endtask

task  slave_monitor ::  capture_write_response();
 slave_seq_item     pkt;
 forever begin
    `uvm_info("slave_monitor :: capture_write_response","Triggred",UVM_MEDIUM);
    wait( slave_mon_intf.slv_mon_cb.bready==1 && slave_mon_intf.slv_mon_cb.bvalid==1 && slave_mon_intf.areset_n==1);
    merge_write_info(); //merges addr+data info waiting for response
    `uvm_info("slave_monitor :: capture_write_response","IamInside",UVM_MEDIUM);
    
    if(wresp_array.exists(slave_mon_intf.slv_mon_cb.bid)) begin    //to check if captured bid matches with any transaction waiting for response.
       pkt = slave_seq_item :: type_id :: create("pkt");
       wresp_array[slave_mon_intf.slv_mon_cb.bid].get(pkt);           //this pkt already has add + data info
       //add response info to pkt
       pkt.wresp_hndshk = $realtime();  //capturing timestamp for handshake.
       pkt.bid    = slave_mon_intf.slv_mon_cb.bid;
       pkt.bresp  =response_t'( slave_mon_intf.slv_mon_cb.bresp);
       //`uvm_info("slave_monitor :: capture_write_response","Sending pkt to SB",UVM_MEDIUM);
       //pkt.print_write_txn(pkt);
       mon_ap.write(pkt); //write pkt to sb
       `uvm_info("slave_monitor:: capture_write_responce",pkt.sprint(),UVM_MEDIUM)
    end else `uvm_error("slave_monitor :: capture_write_response",$sformatf("unexpected write response, BID not found bid= %b",slave_mon_intf.slv_mon_cb.bid))
    @(slave_mon_intf.slv_mon_cb); //wait till next clk posedge
 end
endtask

task  slave_monitor :: capture_read_address();
 slave_seq_item     pkt;
 forever begin
    `uvm_info("slave_monitor :: capture_read_address","Triggred",UVM_MEDIUM);
    pkt = slave_seq_item :: type_id :: create("pkt");
    wait(slave_mon_intf.slv_mon_cb.arvalid==1 && slave_mon_intf.areset_n==1); //wait for valid
    pkt.araddr   = slave_mon_intf.slv_mon_cb.araddr;
    pkt.arburst  = burst_type_t'(slave_mon_intf.slv_mon_cb.arburst);
    pkt.arcache  = slave_mon_intf.slv_mon_cb.arcache;
    pkt.arid     = slave_mon_intf.slv_mon_cb.arid;
    pkt.arlen    = slave_mon_intf.slv_mon_cb.arlen;
    pkt.arlock   = slave_mon_intf.slv_mon_cb.arlock;
    pkt.arprot   = slave_mon_intf.slv_mon_cb.arprot;
    pkt.arqos    = slave_mon_intf.slv_mon_cb.arqos;
    pkt.arregion = slave_mon_intf.slv_mon_cb.arregion;
    pkt.arsize   = slave_mon_intf.slv_mon_cb.arsize;
    pkt.operation = READ;
    resp_ap.write(pkt); //write pkt to sequencer for response
    wait( slave_mon_intf.slv_mon_cb.arready==1 && slave_mon_intf.slv_mon_cb.arvalid==1 && slave_mon_intf.areset_n==1); //handshake
    pkt.radd_hndshk = $realtime();  //capturing timestamp for handshake.
    //`uvm_info("slave_monitor :: capture_read_address",$sformatf("captured address pkt put to read_address_array arid=%d",pkt.arid),UVM_MEDIUM);
    if(!read_address_array.exists(pkt.arid)) read_address_array[pkt.arid]=new();
    read_address_array[pkt.arid].put(pkt);
    @(slave_mon_intf.slv_mon_cb); //wait till next clk posedge
  end
endtask

task  slave_monitor ::  capture_read_data();
 slave_seq_item     pkt, pkt2sb;
 int i,no_of_beats;
 bit last;
 forever begin
    `uvm_info("slave_monitor :: capture_read_data","Triggred",UVM_MEDIUM);
    i = 0;
    do begin
      pkt = slave_seq_item :: type_id :: create("pkt");
      pkt.rdata_hndshk = new[1];
      pkt.rdata =new [1];
      pkt.rresp =new [1];
      wait(slave_mon_intf.slv_mon_cb.rready==1 && slave_mon_intf.slv_mon_cb.rvalid==1 && slave_mon_intf.areset_n==1);
      pkt.rdata_hndshk[0] = $realtime();  //capturing timestamp for handshake.
      pkt.rid       = slave_mon_intf.slv_mon_cb.rid;
      pkt.rdata[0]  = slave_mon_intf.slv_mon_cb.rdata;
      pkt.rresp[0]  = response_t'(slave_mon_intf.slv_mon_cb.rresp);
      if(!read_data_array.exists(pkt.rid)) read_data_array[pkt.rid] = new();
      read_data_array[pkt.rid].put(pkt);
      i=i+1;
      last = slave_mon_intf.slv_mon_cb.rlast;
      @(slave_mon_intf.slv_mon_cb); //wait till next clk posedge
    end while( last ==0); //keeps sampling till last indicates end of data phase.
      pkt2sb = slave_seq_item :: type_id :: create("pkt2sb");
      //get  pkt with address info and add data info.//
      wait(read_address_array.exists(pkt.rid));
      read_address_array[pkt.rid].get(pkt2sb);  // this has address info for required rid pkt.
      no_of_beats = read_data_array[pkt.rid].num();
      pkt2sb.rid = pkt.rid;
      pkt2sb.rdata = new[no_of_beats];
      pkt2sb.rresp = new[no_of_beats];
      pkt2sb.rdata_hndshk = new[no_of_beats];
   //merging beats for which got rlast
   for(i=0 ; i<no_of_beats; i++)begin         //merges all beats with same rid to pkt having address info
      read_data_array[pkt2sb.rid].get(pkt);
      pkt2sb.rdata[i] = pkt.rdata[0];
      pkt2sb.rresp[i] = pkt.rresp[0];
      pkt2sb.rdata_hndshk[i] = pkt.rdata_hndshk[0];
   end
    //`uvm_info("slave_monitor :: capture_read_data","Sending pkt to SB",UVM_MEDIUM);
    //pkt2sb.print_read_txn(pkt2sb);
    mon_ap.write(pkt2sb); //write pkt to sb
 end
endtask

task slave_monitor :: merge_write_info();
slave_seq_item addr_pkt,data_pkt,merged_pkt;
int x ,no_addr, no_data; //indicates number of completed write transactions waiting for response.
  `uvm_info("slave_monitor :: merge_write_info","Triggred",UVM_MEDIUM);
  no_addr = write_address_mbx.num();
  no_data = write_data_mbx.num();
  x = (no_addr<no_data)? no_addr :no_data;
  repeat(x)begin
  merged_pkt = slave_seq_item :: type_id :: create("merged_pkt");
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
    //`uvm_info("slave_monitor :: merge_write_info",$sformatf("putting merged pkt to wresp_array awid = %b",merged_pkt.awid),UVM_MEDIUM);
    if(!wresp_array.exists(merged_pkt.awid)) wresp_array[merged_pkt.awid] = new();
    wresp_array[merged_pkt.awid].put(merged_pkt);
  end
endtask


task slave_monitor :: capture_reset();
 slave_seq_item     rst_pkt;
 `uvm_info("slave_monitor :: capture_reset","Triggred",UVM_MEDIUM);
 fork
  forever begin //reset deasserted
    @(posedge slave_mon_intf.areset_n) ;
    rst_pkt = slave_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_DEASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("slave_monitor :: capture_reset","reset_deasserted_pkt to SB",UVM_MEDIUM);
    mon_ap.write(rst_pkt);
  end
  forever begin //reset asserted
    @(negedge slave_mon_intf.areset_n) ;
    rst_pkt = slave_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_ASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("slave_monitor :: capture_reset","reset_asserted_pkt to SB",UVM_MEDIUM);
    mon_ap.write(rst_pkt);
  end
join
endtask
