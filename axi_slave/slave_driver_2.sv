class slave_driver extends uvm_driver #(slave_seq_item,slave_seq_item);
    `uvm_component_utils (slave_driver)

    virtual slave_intf.DRV_MOD_slave        slave_drv_intf;
    mailbox #(slave_seq_item) waddress_mbx, wdata_mbx, raddress_mbx, rdata_mbx, wresponse_mbx;

    function new (string name = "slave_driver" , uvm_component parent);
        super.new(name,parent);
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
    `uvm_info(get_full_name(),"........slave_driver.......reset_phase Driving initial values to interface", UVM_LOW);
    slave_drv_intf.slv_drv_cb.arready <='b0;
    slave_drv_intf.slv_drv_cb.rdata   <='b0;
    //slave_drv_intf.slv_drv_cb.rid     <='b0;
    slave_drv_intf.slv_drv_cb.rlast   <='b0;
    slave_drv_intf.slv_drv_cb.rresp   <='b0;
    slave_drv_intf.slv_drv_cb.rvalid  <='b0;
    slave_drv_intf.slv_drv_cb.awready <='b0;
    slave_drv_intf.slv_drv_cb.bresp   <='b0;
    //slave_drv_intf.slv_drv_cb.bid     <='b0;
    slave_drv_intf.slv_drv_cb.bvalid  <='b0;
    slave_drv_intf.slv_drv_cb.wready  <='b0;
endtask :reset_phase

task slave_driver :: main_phase (uvm_phase phase);
    `uvm_info (get_full_name(), "main_phase started", UVM_MEDIUM)
    wait(slave_drv_intf.areset_n === 1'b1);

    fork
        get_packet();
        drive_write_add();
        drive_write_data();
        drive_write_resp();
        drive_read_add();
        drive_read_data();
    join
endtask : main_phase

task slave_driver :: get_packet();
    slave_seq_item pkt;
    wdata_mbx     = new();
    rdata_mbx     = new();
    waddress_mbx  = new();
    raddress_mbx  = new();
    wresponse_mbx = new();
    
    forever begin
        `uvm_info(get_full_name(), "inside forever", UVM_LOW);
        seq_item_port.get_next_item(pkt);
        `uvm_info(get_full_name(), $sformatf("Got packet -- operation = %s", pkt.operation.name()), UVM_LOW);
        
        if(pkt.operation == WRITE) begin
            waddress_mbx.put(pkt);
            wdata_mbx.put(pkt);
            `uvm_info(get_full_name(),"Got packet -- kept in write mailboxes", UVM_LOW);
        end else if(pkt.operation == READ) begin
            raddress_mbx.put(pkt);
            rdata_mbx.put(pkt);
            `uvm_info(get_full_name(),"Got packet -- kept in read mailboxes", UVM_LOW);
        end
        seq_item_port.item_done(pkt);
        `uvm_info(get_full_name(),"SEQ_ITEM_DONE", UVM_LOW);
    end
endtask

task slave_driver :: drive_write_add();
    slave_seq_item pkt;
    forever begin
        waddress_mbx.get(pkt);
        `uvm_info(get_full_name(),"Got packet -- got in write add mailbox", UVM_LOW);
        slave_drv_intf.slv_drv_cb.awready <= 'b1;
        do begin
            @(slave_drv_intf.slv_drv_cb);
        end while(slave_drv_intf.slv_drv_cb.awvalid == 1);
        //wait(slave_drv_intf.slv_drv_cb.awvalid == 1);
        `uvm_info(get_full_name(),"after awvalid", UVM_LOW);
        //@(slave_drv_intf.slv_drv_cb);
        slave_drv_intf.slv_drv_cb.awready <= 'b0;
        `uvm_info(get_full_name(),"end of write add", UVM_LOW);
    end
endtask

task slave_driver :: drive_write_data();
    slave_seq_item pkt;
    forever begin
        wdata_mbx.get(pkt);
        `uvm_info(get_full_name(),"Got packet -- got in write data mailbox", UVM_LOW);
        for(int i=0; i<=pkt.awlen; i++) begin
            slave_drv_intf.slv_drv_cb.wready <= 1;
            do begin
                @(slave_drv_intf.slv_drv_cb);
            end while(slave_drv_intf.slv_drv_cb.wvalid == 1);
            //slave_drv_intf.slv_drv_cb.wready <= 1;
            //wait(slave_drv_intf.slv_drv_cb.wvalid == 1);
            `uvm_info(get_full_name(),"after wvalid", UVM_LOW);
            if(pkt.wdata.size()==0)
                pkt.wdata = new[pkt.awlen+1];
            pkt.wdata[i] = slave_drv_intf.slv_drv_cb.wdata;
            @(slave_drv_intf.slv_drv_cb);
            slave_drv_intf.slv_drv_cb.wready <= 0;
        `uvm_info(get_full_name(),"end of write data", UVM_LOW);
        end
        wresponse_mbx.put(pkt);
        `uvm_info(get_full_name(),"kept pkt in write response", UVM_LOW);
    end
        `uvm_info(get_full_name(),"outside write data", UVM_LOW);
endtask

task slave_driver :: drive_write_resp(); 
    slave_seq_item pkt;
    forever begin
        wresponse_mbx.get(pkt);
        `uvm_info(get_full_name(),"Got packet -- got in write response mailbox", UVM_LOW);
        slave_drv_intf.slv_drv_cb.bresp  <= pkt.bresp;
        //slave_drv_intf.slv_drv_cb.bid    <= pkt.bid;
        slave_drv_intf.slv_drv_cb.bvalid <= 'b1;
        do begin
            @(slave_drv_intf.slv_drv_cb);
        end while(slave_drv_intf.slv_drv_cb.bready == 0);
        //wait(slave_drv_intf.slv_drv_cb.bready == 1);
        `uvm_info(get_full_name(),"after bready", UVM_LOW);
        //@(slave_drv_intf.slv_drv_cb);
        slave_drv_intf.slv_drv_cb.bvalid <= 'b0;
        `uvm_info(get_full_name(),"end of write response", UVM_LOW);
        `uvm_info("driver_write_pkt",pkt.sprint(),UVM_MEDIUM)
    end
endtask

task slave_driver :: drive_read_add();
    slave_seq_item pkt;
    forever begin
        raddress_mbx.get(pkt);
        `uvm_info(get_full_name(),"Got packet -- got in read add mailbox", UVM_LOW)
        slave_drv_intf.slv_drv_cb.arready <= 'b1;
        //wait(slave_drv_intf.slv_drv_cb.arvalid == 1);
        do begin
            @(slave_drv_intf.slv_drv_cb);
        end while(slave_drv_intf.slv_drv_cb.arvalid != 1);
        `uvm_info(get_full_name(),"after arvalid", UVM_LOW)
        //@(slave_drv_intf.slv_drv_cb);
        slave_drv_intf.slv_drv_cb.arready <= 'b0;
        `uvm_info(get_full_name(),"end of read add", UVM_LOW)
        //drive_read_data();
        //`uvm_info(get_full_name(),"calling read data", UVM_LOW);
    end
endtask

task slave_driver :: drive_read_data();
    slave_seq_item pkt;
    rdata_mbx.get(pkt); 
    //after getting the packet start the read operation things
        `uvm_info(get_full_name(),"Got packet -- got in read data mailbox", UVM_LOW);

    for(int i=0; i<=pkt.arlen; i++) begin
        slave_drv_intf.slv_drv_cb.rdata <= pkt.rdata[i];
        `uvm_info(get_full_name(),$sformatf("Read data = %0h",pkt.rdata[i]), UVM_LOW);
        slave_drv_intf.slv_drv_cb.rresp <= pkt.rresp[i];
        slave_drv_intf.slv_drv_cb.rlast <= (i == pkt.arlen) ? 1'b1 : 1'b0;
        slave_drv_intf.slv_drv_cb.rvalid <= 1;
        do begin
            @(slave_drv_intf.slv_drv_cb);
        end while(slave_drv_intf.slv_drv_cb.rready == 0);
        //wait(slave_drv_intf.slv_drv_cb.rready == 1);
        `uvm_info(get_full_name(),"after_rready", UVM_LOW);
        //@(slave_drv_intf.slv_drv_cb);
        if(i == pkt.arlen) begin
            slave_drv_intf.slv_drv_cb.rdata  <= 0;
            slave_drv_intf.slv_drv_cb.rlast  <= 0;
            slave_drv_intf.slv_drv_cb.rvalid <= 0;
        end
        `uvm_info(get_full_name(),"end_of_read_data", UVM_LOW);
        `uvm_info("driver_read_pkt",pkt.sprint(),UVM_MEDIUM)
    end
endtask

/*
class slave_driver_callback extends uvm_callback;
   `uvm_object_utils(slave_driver_callback)

   function new (string name = "slave_driver_callback");
      super.new(name);
   endfunction

   virtual task pre_drive (slave_seq_item pkt);
     `uvm_info (get_full_name () , "pre_drive :: executing slave_driver call back" , UVM_LOW)
   endtask : pre_drive
   virtual task post_drive (slave_seq_item pkt);
     `uvm_info (get_full_name () , "post_drive :: executing slave_driver call back" , UVM_LOW)
   endtask : post_drive
endclass : slave_driver_callback

class slave_driver extends uvm_driver #(slave_seq_item,slave_seq_item);
   `uvm_component_utils (slave_driver)
   `uvm_register_cb (slave_driver, slave_driver_callback)

   virtual slave_intf.DRV_MOD_slave        slave_drv_intf;
   mailbox #(slave_seq_item) waddress_mbx,wdata_mbx, raddress_mbx, rdata_mbx, wresponse_mbx; // mailboxes for read/write channels
   slave_seq_item pkt;

   function new (string name = "slave_driver" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern task main_phase  (uvm_phase phase);
   extern task reset_phase (uvm_phase phase);
   //extern task get_packet ();
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
     slave_drv_intf.slv_drv_cb.rid <='b0;
     slave_drv_intf.slv_drv_cb.rlast <='b0;
     slave_drv_intf.slv_drv_cb.rresp <='b0;
     slave_drv_intf.slv_drv_cb.rvalid <='b0;
     slave_drv_intf.slv_drv_cb.awready <='b0;
     slave_drv_intf.slv_drv_cb.bresp <='b0;
     slave_drv_intf.slv_drv_cb.bid <='b0;
     slave_drv_intf.slv_drv_cb.bvalid <='b0;
     slave_drv_intf.slv_drv_cb.wready <='b0;
endtask :reset_phase


task slave_driver :: main_phase(uvm_phase phase);
    `uvm_info(get_full_name(), "1. main_phase entered", UVM_LOW);
    
    wait(slave_drv_intf.areset_n === 1'b1);
    `uvm_info(get_full_name(), "2. Reset is 1. Waiting for clock edge...", UVM_LOW);
    
    forever begin
        @(slave_drv_intf.slv_drv_cb);
        `uvm_info(get_full_name(), "3. Clock ticked! Asking sequencer for item...", UVM_LOW);
        
        seq_item_port.get_next_item(pkt);
        `uvm_info(get_full_name(), $sformatf("4. Got packet! Operation: %s", pkt.operation.name()), UVM_LOW);
        
        if (pkt.operation == WRITE) begin
            fork
                drive_write_add();
                drive_write_data();
                drive_write_resp();
            join
        end else begin
            fork
                drive_read_add();
                drive_read_data();
            join
        end
        seq_item_port.item_done(pkt);
    end
endtask: main_phase

//task slave_driver :: main_phase (uvm_phase phase);
//      `uvm_info (get_full_name(), phase.get_name() , UVM_MEDIUM)
//
//   fork
//    get_packet();
//    drive_write_add();
//    drive_write_data();
//    drive_read_add();
//    drive_write_resp();
//   join
//
//  endtask : main_phase

//task slave_driver :: get_packet();
//    slave_seq_item pkt;
//    wdata_mbx=new();
//    rdata_mbx=new();
//    waddress_mbx=new();
//    raddress_mbx=new();
//    wresponse_mbx=new();
//    `uvm_info(get_full_name(),".......slave_driver.......get packet task triggred", UVM_LOW);
//   forever begin
//    `uvm_info("slave_driver","get packet task waiting for getting pkt from sequencer", UVM_LOW);
//    pkt = slave_seq_item :: type_id :: create("pkt");
//
//    seq_item_port.get_next_item(pkt);
//    `uvm_info("slave_driver","get packet task got pkt from sequencer", UVM_LOW);
//    `uvm_info(get_full_name(),$sformatf("........slave_driver.......main_phase got packet -- operation = %s",pkt.operation.name()), UVM_LOW);
//    if(pkt.operation == WRITE) begin
//        waddress_mbx.put(pkt);
//        wdata_mbx.put(pkt);
//    end
//    if(pkt.operation == READ) begin
//        raddress_mbx.put(pkt);
//        rdata_mbx.put(pkt);
//    end
//    seq_item_port.item_done(pkt);
//    `uvm_info(get_full_name(),".......slave_driver.......main.......phase after item done", UVM_LOW);
//  end
//endtask

task slave_driver :: drive_write_add();
slave_seq_item pkt;
`uvm_info(get_full_name(),"........slave_driver.......drive_write_add task triggred",  UVM_LOW);
 //forever begin
   waddress_mbx.get(pkt);
   `uvm_info(get_full_name(),"........slave_driver.......drive_write_add mailbox get",  UVM_LOW);
   wait(slave_drv_intf.slv_drv_cb.awvalid ==1);
   `uvm_info(get_full_name(),"........slave_driver.......drive_write_add after wait",  UVM_LOW);
   //repeat(pkt.add_ready_dly) @( slave_drv_intf.slv_drv_cb); // delay in asserting ready
   slave_drv_intf.slv_drv_cb.awready <='b1;
   @(slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.awready <='b0;
 //end
endtask

task slave_driver :: drive_read_add();
slave_seq_item pkt;
`uvm_info(get_full_name(),"........slave_driver.......drive_read_add task triggred",  UVM_LOW);
 //forever begin
   slave_drv_intf.slv_drv_cb.arready <='b1;
   raddress_mbx.get(pkt);
`uvm_info("slave_drivera::drive_read_add","........slave_driver.......WAITING for Valid ",  UVM_LOW);
   wait(slave_drv_intf.slv_drv_cb.arvalid == 1);
`uvm_info("slave_drivera::drive_read_add","........slave_driver.......GOT Valid ",  UVM_LOW);
   //repeat(pkt.add_ready_dly) @(slave_drv_intf.slv_drv_cb); //delay in asserting ready
   @(slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.arready <='b0;
   drive_read_data();
 //end
endtask

task slave_driver :: drive_write_resp();  //will trigger after data phase  // figure out what to do when this phase is triggred multiple times without the last one completing.
slave_seq_item pkt;
    `uvm_info(get_full_name(),"........slave_driver.......drive_write_resp task triggred",  UVM_LOW);
  //forever begin
   wresponse_mbx.get(pkt);
   //repeat(pkt.data2resp_dly) @( slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.bresp <= pkt.bresp;
   slave_drv_intf.slv_drv_cb.bid <= pkt.bid;
   slave_drv_intf.slv_drv_cb.bvalid <='b1;
   wait(slave_drv_intf.slv_drv_cb.bready ==1);
   @( slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.bvalid <='b0;
  //end
endtask

task slave_driver :: drive_write_data();
slave_seq_item pkt;
`uvm_info(get_full_name(),"........slave_driver.......drive_write_data task triggred",  UVM_LOW);
 //forever begin
    wdata_mbx.get(pkt);
    `uvm_info(get_full_name(),"........slave_driver.......drive_write_data task mbx.get(pkt) done",  UVM_LOW);
    //repeat(address2data_phase_delay) @( slave_drv_intf.mas_drv_cb);//controled by master
    for(int i=0;i<=pkt.awlen;i++)begin
    //capture beat info if required
    //repeat(pkt.write_ready2ready_dly[i]) @(slave_drv_intf.slv_drv_cb);
    wait(slave_drv_intf.slv_drv_cb.wvalid ==1);
    //repeat(pkt.write_ready2ready_dly[i]) @(slave_drv_intf.slv_drv_cb);
    slave_drv_intf.slv_drv_cb.wready <= 1;
    @(slave_drv_intf.slv_drv_cb);
    slave_drv_intf.slv_drv_cb.wready <= 0;
    end
    wresponse_mbx.put(pkt);
 //end
endtask

task slave_driver :: drive_read_data();
slave_seq_item pkt;
`uvm_info(get_full_name(),"........slave_driver.......drive_read_data task triggred",  UVM_LOW);
   slave_drv_intf.slv_drv_cb.rvalid <= 1;
   rdata_mbx.get(pkt); //must be blocking statement
   `uvm_info(get_full_name(),"........slave_driver.......drive_read_data task mbx.get(pkt) done",  UVM_LOW);
   //repeat(pkt.add2data_dly) @( slave_drv_intf.slv_drv_cb);
   for(int i=0;i<=pkt.arlen;i++) begin
   //assert beat data information on read data channel
   //assret rlast with last beat of data.
   slave_drv_intf.slv_drv_cb.rdata <= pkt.rdata[i];
   slave_drv_intf.slv_drv_cb.rid <= pkt.rid;
   slave_drv_intf.slv_drv_cb.rresp <= pkt.rresp[i];
   //repeat(pkt.read_valid2valid_dly[i]) @( slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.rlast <= (i== pkt.arlen ) ? 1'b1 : 1'b0;
   wait(slave_drv_intf.slv_drv_cb.rready ==1);
   @(slave_drv_intf.slv_drv_cb);
   slave_drv_intf.slv_drv_cb.rvalid <= 0;
   slave_drv_intf.slv_drv_cb.rlast  <= 0;
 end
endtask

*/
