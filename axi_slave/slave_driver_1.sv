// callbacks--
class slave_driver_callback extends uvm_callback;
   `uvm_object_utils(slave_driver_callback)

   function new (string name = "slave_driver_callback");
      super.new(name);
   endfunction

   virtual task pre_drive (slave_seq_item pkt);
     `uvm_info (get_full_name(),"pre_drive :: executing slave_driver call back" , UVM_LOW)
   endtask : pre_drive
   virtual task post_drive (slave_seq_item pkt);
     `uvm_info (get_full_name(),"post_drive :: executing slave_driver call back" , UVM_LOW)
   endtask : post_drive
endclass : slave_driver_callback

class slave_driver extends uvm_driver #(slave_seq_item,slave_seq_item);
   `uvm_component_utils (slave_driver)
   `uvm_register_cb (slave_driver , slave_driver_callback)
    
   slave_seq_item pkt;
   virtual slave_intf.DRV_MOD_slave        slave_drv_intf;
   mailbox #(slave_seq_item) waddress_mbx,wdata_mbx, raddress_mbx, rdata_mbx, wresponse_mbx; // mailboxes for read/write channels

   function new (string name = "slave_driver" , uvm_component parent);
      super.new(name,parent);
   endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Initialize ALL mailboxes here
        waddress_mbx  = new();
        wdata_mbx     = new();
        raddress_mbx  = new();
        rdata_mbx     = new();
        wresponse_mbx = new();
    endfunction

   extern task main_phase  (uvm_phase phase);
   extern task reset_phase (uvm_phase phase);
   extern task get_packet ();
   extern task drive_write_add ();
   extern task drive_write_data ();
   extern task drive_read_add ();
   extern task drive_read_data ();
   extern task drive_write_resp ();
endclass :slave_driver

task slave_driver :: reset_phase (uvm_phase phase);
     `uvm_info (get_full_name(), phase.get_name() , UVM_MEDIUM)
     //drive initial value to 0
     `uvm_info(get_full_name(),"........slave_driver.......reset_phase Driving initial values to interface", UVM_LOW);
     slave_drv_intf.slv_drv_cb.arready <='b0;
     slave_drv_intf.slv_drv_cb.rdata <='b0;
     //slave_drv_intf.slv_drv_cb.rid <='b0;
     slave_drv_intf.slv_drv_cb.rlast <='b0;
     slave_drv_intf.slv_drv_cb.rresp <='b0;
     slave_drv_intf.slv_drv_cb.rvalid <='b0;
     slave_drv_intf.slv_drv_cb.awready <='b0;
     slave_drv_intf.slv_drv_cb.bresp <='b0;
     //slave_drv_intf.slv_drv_cb.bid <='b0;
     slave_drv_intf.slv_drv_cb.bvalid <='b0;
     slave_drv_intf.slv_drv_cb.wready <='b0;
endtask :reset_phase

task slave_driver :: main_phase (uvm_phase phase);
      `uvm_info (get_full_name(), phase.get_name() , UVM_MEDIUM)

   fork
    get_packet();
    drive_write_add();
    drive_write_data();
    drive_read_add();
    drive_write_resp();
    join

  endtask : main_phase

task slave_driver :: get_packet();
    forever begin
        wait(slave_drv_intf.slv_drv_cb.awvalid == 1 || slave_drv_intf.slv_drv_cb.arvalid == 1);
        seq_item_port.get_next_item(pkt);
        if (slave_drv_intf.slv_drv_cb.awvalid) begin
            pkt.operation = WRITE;
            pkt.awaddr    = slave_drv_intf.slv_drv_cb.awaddr;
            waddress_mbx.put(pkt);
            wdata_mbx.put(pkt);
        end else begin
            pkt.operation = READ;
            pkt.araddr    = slave_drv_intf.slv_drv_cb.araddr;
            raddress_mbx.put(pkt);
            rdata_mbx.put(pkt);
        end
        seq_item_port.item_done();
        @(slave_drv_intf.slv_drv_cb);
    end
endtask


//task slave_driver :: get_packet(); // to get new packets from seq and populate respective queues with relevent data.
//    slave_seq_item pkt;
//    wdata_mbx=new();
//    rdata_mbx=new();
//    waddress_mbx=new();
//    raddress_mbx=new();
//    wresponse_mbx=new();
//    `uvm_info(get_full_name(),"........slave_driver.......get packet task triggred",  UVM_LOW);
//   forever begin
//    `uvm_info("slave_driver","get packet task waiting for getting pkt from sequencer",  UVM_LOW);
// pkt = slave_seq_item :: type_id :: create("pkt");
//
//      seq_item_port.get_next_item(pkt);
//    `uvm_info("slave_driver","get packet task got pkt from sequencer",  UVM_LOW);
//      //pre_drive task to corrupt packet here
//      `uvm_do_callbacks(slave_driver,slave_driver_callback,pre_drive(pkt));
//      `uvm_info(get_full_name(),$sformatf("........slave_driver.......main_phase got packet -- operation = %s",pkt.operation.name()),  UVM_LOW);
//    if(pkt.operation == WRITE ) begin
//      wdata_mbx.put(pkt);
//      waddress_mbx.put(pkt);
//    end
//    if(pkt.operation == READ) begin
//      rdata_mbx.put(pkt);
//      raddress_mbx.put(pkt);
//    end
//    seq_item_port.item_done(pkt);
//    `uvm_info(get_full_name(),"........slave_driver.......main.......phase after item done", UVM_LOW);
//  end
//endtask

task slave_driver :: drive_write_add();
slave_seq_item pkt;
`uvm_info(get_full_name(),"........slave_driver.......drive_write_add task triggred",  UVM_LOW);
 forever begin
   waddress_mbx.get(pkt);
   wait(slave_drv_intf.slv_drv_cb.awvalid ==1);
   //repeat(pkt.add_ready_dly) @( slave_drv_intf.slv_drv_cb); // delay in asserting ready
   slave_drv_intf.slv_drv_cb.awready <='b1;
   @( slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.awready <='b0;
 end
endtask

//task slave_driver :: drive_read_add();
//    slave_seq_item pkt;
//    `uvm_info(get_full_name(),"........slave_driver.......drive_read_add task triggred", UVM_LOW);
//    forever begin
//        raddress_mbx.get(pkt);
//        `uvm_info("slave_driver::drive_read_add", "........slave_driver.......WAITING for Valid", UVM_LOW);
//        slave_drv_intf.slv_drv_cb.arready <= 1'b1;
//        do begin
//            @(slave_drv_intf.slv_drv_cb);
//        end while (slave_drv_intf.slv_drv_cb.arvalid != 1'b1);
//        `uvm_info("slave_driver::drive_read_add", "........slave_driver.......GOT Valid", UVM_LOW);
//        slave_drv_intf.slv_drv_cb.arready <= 1'b0;
//    end
//endtask

task slave_driver :: drive_read_add();
    slave_seq_item pkt;
    `uvm_info(get_full_name(),"........slave_driver.......drive_read_add task triggred",  UVM_LOW);
    forever begin
        slave_drv_intf.slv_drv_cb.arready <='b1;
        raddress_mbx.get(pkt);
        `uvm_info("slave_drivera::drive_read_add","........slave_driver.......WAITING for Valid ",  UVM_LOW);
        //wait(slave_drv_intf.slv_drv_cb.arvalid ==1);
        do begin
            @(slave_drv_intf.slv_drv_cb);
        end while (slave_drv_intf.slv_drv_cb.arvalid != 1'b1);
        `uvm_info("slave_drivera::drive_read_add","........slave_driver.......GOT Valid ",  UVM_LOW);
        @(slave_drv_intf.slv_drv_cb);
        slave_drv_intf.slv_drv_cb.arready <='b0;
        drive_read_data();
    end
endtask

task slave_driver :: drive_write_resp();  //will trigger after data phase  // figure out what to do when this phase is triggred multiple times without the last one completing.
slave_seq_item pkt;
    `uvm_info(get_full_name(),"........slave_driver.......drive_write_resp task triggred",  UVM_LOW);
  //forever begin
   wresponse_mbx.get(pkt);
   //repeat(pkt.data2resp_dly) @( slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.bresp <= pkt.bresp;
   //slave_drv_intf.slv_drv_cb.bid <= pkt.bid;
   slave_drv_intf.slv_drv_cb.bvalid <='b1;
   wait(slave_drv_intf.slv_drv_cb.bready ==1);
   @( slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.bvalid <='b0;
   //Post drive callback
   `uvm_do_callbacks(slave_driver,slave_driver_callback,post_drive(pkt));
  //end
endtask

task slave_driver :: drive_write_data();
  forever begin
    wdata_mbx.get(pkt);
    for(int i=0; i<=pkt.awlen; i++) begin
       wait(slave_drv_intf.slv_drv_cb.wvalid == 1);
       pkt.wdata[i] = slave_drv_intf.slv_drv_cb.wdata; 
       
       slave_drv_intf.slv_drv_cb.wready <= 1;
       @(slave_drv_intf.slv_drv_cb);
       slave_drv_intf.slv_drv_cb.wready <= 0;
    end
    wresponse_mbx.put(pkt);
  end
endtask

//task slave_driver :: drive_write_data();
//slave_seq_item pkt;
//`uvm_info(get_full_name(),"........slave_driver.......drive_write_data task triggred",  UVM_LOW);
// forever begin
//   wdata_mbx.get(pkt);
//   `uvm_info(get_full_name(),"........slave_driver.......drive_write_data task mbx.get(pkt) done",  UVM_LOW);
//   //repeat(address2data_phase_delay) @( slave_drv_intf.mas_drv_cb);//controled by master
//   for(int i=0;i<=pkt.awlen;i++)begin
//   //capture beat info if required
//   //repeat(pkt.write_ready2ready_dly[i]) @(slave_drv_intf.slv_drv_cb);
//   wait(slave_drv_intf.slv_drv_cb.wvalid ==1);
//   @(slave_drv_intf.slv_drv_cb);
//   slave_drv_intf.slv_drv_cb.wready <= 1;
//   @( slave_drv_intf.slv_drv_cb);
//   slave_drv_intf.slv_drv_cb.wready <= 0;
//   end
//  wresponse_mbx.put(pkt);
// end
//endtask

task slave_driver :: drive_read_data();
    slave_seq_item pkt;
    `uvm_info(get_full_name(),"........slave_driver.......drive_read_data task started", UVM_LOW);
    forever begin
        rdata_mbx.get(pkt);
        `uvm_info(get_full_name(),"........slave_driver.......drive_read_data task mbx.get(pkt) done", UVM_LOW);
        @(slave_drv_intf.slv_drv_cb);
        for(int i=0; i<=pkt.arlen; i++) begin
            slave_drv_intf.slv_drv_cb.rdata  <= pkt.rdata[i];
            slave_drv_intf.slv_drv_cb.rresp  <= pkt.rresp[i];
            slave_drv_intf.slv_drv_cb.rvalid <= 1'b1;
            slave_drv_intf.slv_drv_cb.rlast  <= (i == pkt.arlen) ? 1'b1 : 1'b0;
            do begin
                @(slave_drv_intf.slv_drv_cb);
            end while (slave_drv_intf.slv_drv_cb.rready != 1'b1);
            slave_drv_intf.slv_drv_cb.rvalid <= 1'b0;
            slave_drv_intf.slv_drv_cb.rlast  <= 1'b0;
            `uvm_do_callbacks(slave_driver, slave_driver_callback, post_drive(pkt));
        end
    end
endtask

//task slave_driver :: drive_read_data();
//slave_seq_item pkt;
//`uvm_info(get_full_name(),"........slave_driver.......drive_read_data task triggred",  UVM_LOW);
//   rdata_mbx.get(pkt); //must be blocking statement
//   `uvm_info(get_full_name(),"........slave_driver.......drive_read_data task mbx.get(pkt) done",  UVM_LOW);
//   repeat(pkt.add2data_dly) @( slave_drv_intf.slv_drv_cb);
//   for(int i=0;i<=pkt.arlen;i++) begin
//   //assert beat data information on read data channel
//   //assret rlast with last beat of data.
//   slave_drv_intf.slv_drv_cb.rdata <= pkt.rdata[i];
//   //slave_drv_intf.slv_drv_cb.rid <= pkt.rid;
//   slave_drv_intf.slv_drv_cb.rresp <= pkt.rresp[i];
//   @( slave_drv_intf.slv_drv_cb);
//   slave_drv_intf.slv_drv_cb.rvalid <= 1;
//   slave_drv_intf.slv_drv_cb.rlast <= (i== pkt.arlen ) ? 1'b1 : 1'b0;
//   wait(slave_drv_intf.slv_drv_cb.rready ==1);
//   @( slave_drv_intf.slv_drv_cb);
//   slave_drv_intf.slv_drv_cb.rvalid <= 0;
//   slave_drv_intf.slv_drv_cb.rlast  <= 0;
//  //Post drive callback
//  `uvm_do_callbacks(slave_driver,slave_driver_callback,post_drive(pkt));
// end
//endtask
