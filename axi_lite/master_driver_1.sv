class master_driver extends uvm_driver #(master_seq_item,master_seq_item);
   `uvm_component_utils (master_driver)
   virtual master_intf.DRV_MOD_master        master_drv_intf;
   mailbox #(master_seq_item)waddress_mbx, wdata_mbx, raddress_mbx, rdata_mbx, wresponse_mbx;

    config_obj          obj;
    master_seq_item     pkt,rsp;

   function new (string name = "master_driver", uvm_component parent);
      super.new(name,parent);
   endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(config_obj) :: get(this, "", "config_obj", obj))begin
            `uvm_fatal (get_full_name(), "config_db_not_accessable");
        end
        waddress_mbx   = new();
        wdata_mbx      = new();
        wresponse_mbx  = new();
        raddress_mbx   = new();
        rdata_mbx      = new();
    endfunction

    task reset_phase(uvm_phase phase);
      `uvm_info(get_full_name(), phase.get_name(), UVM_MEDIUM)
      `uvm_info(get_full_name(),"AXI-Lite reset_phase: Driving initial values to interface", UVM_LOW);
      master_drv_intf.mas_drv_cb.awaddr  <= 'b0;
      master_drv_intf.mas_drv_cb.awvalid <= 'b0;
      master_drv_intf.mas_drv_cb.wdata   <= 'b0;
      master_drv_intf.mas_drv_cb.wstrobe <= 'b0;
      master_drv_intf.mas_drv_cb.wvalid  <= 'b0;
      master_drv_intf.mas_drv_cb.bready  <= 'b0;
      master_drv_intf.mas_drv_cb.araddr  <= 'b0;
      master_drv_intf.mas_drv_cb.arvalid <= 'b0;
      master_drv_intf.mas_drv_cb.rready  <= 'b0;
    endtask : reset_phase
    
    task main_phase(uvm_phase phase);
        `uvm_info(get_full_name(), "1. main_phase entered", UVM_LOW);
        
        wait(master_drv_intf.areset_n === 1'b1);
        `uvm_info(get_full_name(), "2. Reset is 1. Waiting for clock edge...", UVM_LOW);
        
        forever begin
            @(master_drv_intf.mas_drv_cb);
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


    task drive_write_add();
        `uvm_info(get_full_name(),"AXI-Lite drive_write_add -- task triggered", UVM_LOW);
        master_drv_intf.mas_drv_cb.awaddr  <= pkt.awaddr;
        master_drv_intf.mas_drv_cb.awvalid <= 1;
        //wait(master_drv_intf.mas_drv_cb.awready == 1);
        do begin
            @(master_drv_intf.mas_drv_cb);
        end while (master_drv_intf.mas_drv_cb.awready == 0);    
        //@(master_drv_intf.mas_drv_cb);
        master_drv_intf.mas_drv_cb.awvalid <= 0;
        master_drv_intf.mas_drv_cb.awaddr  <= 0;
        `uvm_info(get_full_name(),"AXI-Lite drive_write_add -- address handshake complete", UVM_LOW);
    endtask
    
    task drive_write_data();
        `uvm_info(get_full_name(),"AXI-Lite drive_write_data -- task triggered", UVM_LOW);
        master_drv_intf.mas_drv_cb.wdata   <= pkt.wdata[0];
        master_drv_intf.mas_drv_cb.wvalid  <= 1;
        //wait(master_drv_intf.mas_drv_cb.wready == 1);
        do begin
            @(master_drv_intf.mas_drv_cb);
        end while (master_drv_intf.mas_drv_cb.wready == 0); 
        //@(master_drv_intf.mas_drv_cb);
        master_drv_intf.mas_drv_cb.wvalid  <= 0;
        master_drv_intf.mas_drv_cb.wdata   <= 0;
        `uvm_info(get_full_name(),"AXI-Lite drive_write_data -- data handshake complete", UVM_LOW);
    endtask
    
    task drive_write_resp();
        `uvm_info(get_full_name(),"AXI-Lite drive_write_resp -- task triggered", UVM_LOW);
        master_drv_intf.mas_drv_cb.bready <= 1;
        `uvm_info(get_full_name(),"AXI-Lite drive_write_resp -- waiting for BVALID", UVM_LOW);
        //wait(master_drv_intf.mas_drv_cb.bvalid == 1);
        do begin
            @(master_drv_intf.mas_drv_cb);
        end while (master_drv_intf.mas_drv_cb.bvalid == 0);
        pkt.bresp = response_t'(master_drv_intf.mas_drv_cb.bresp);    
        //@(master_drv_intf.mas_drv_cb);
        master_drv_intf.mas_drv_cb.bready <= 0;
        //seq_item_port.put_response(rsp);
        `uvm_info(get_full_name(),"AXI-Lite drive_write_resp -- transaction complete", UVM_LOW);
        `uvm_info("driver_pkt_from_write_resp",pkt.sprint(),UVM_MEDIUM)
    endtask
    
    
    task drive_read_add();
        `uvm_info(get_full_name(),"MI_drive_read_add -- task triggered", UVM_LOW);
        master_drv_intf.mas_drv_cb.araddr  <= pkt.araddr;
        master_drv_intf.mas_drv_cb.arvalid <= 1;
        //wait(master_drv_intf.mas_drv_cb.arready == 1);
        do begin
            @(master_drv_intf.mas_drv_cb);
        end while (master_drv_intf.mas_drv_cb.arready == 0); 
        //@(master_drv_intf.mas_drv_cb);
        master_drv_intf.mas_drv_cb.arvalid <= 0;
        master_drv_intf.mas_drv_cb.araddr  <= 'h0;
        `uvm_info(get_full_name(),"MI_drive_read_add -- address handshake complete", UVM_LOW);
    endtask
    
    task drive_read_data();
      `uvm_info(get_full_name(),"AXI-Lite drive_read_data -- task triggered", UVM_LOW);
        master_drv_intf.mas_drv_cb.rready <= 1;
        //wait(master_drv_intf.mas_drv_cb.rvalid == 1);
        do begin
            @(master_drv_intf.mas_drv_cb);
        end while (master_drv_intf.mas_drv_cb.rvalid == 0); 
        pkt.rdata[0] = master_drv_intf.mas_drv_cb.rdata;
        pkt.rresp[0] = response_t'(master_drv_intf.mas_drv_cb.rresp);
        //@(master_drv_intf.mas_drv_cb);
        master_drv_intf.mas_drv_cb.rready <= 0;
        //seq_item_port.put_response(rsp);    
        `uvm_info("driver_pkt_last",pkt.sprint(),UVM_MEDIUM)
    endtask
endclass :master_driver
