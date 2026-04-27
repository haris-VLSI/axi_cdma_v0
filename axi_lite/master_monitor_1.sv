class master_monitor extends uvm_monitor;
    `uvm_component_utils (master_monitor)
    uvm_analysis_port #(master_seq_item)   mon_ap;

    virtual master_intf.MON_MOD_master     master_mon_intf;

    master_seq_item write_addr[$],write_data[$],write_resp[$],read_data[$],read_addr[$];
    //master_seq_item pkt;

    function new (string name = "master_monitor" , uvm_component parent);
        super.new(name,parent);
    endfunction

    extern task main_phase (uvm_phase phase);
    extern function void build_phase (uvm_phase phase);
    extern task capture_write_address();
    extern task capture_write_data();
    extern task capture_write_response();
    extern task merge_write_info();
    extern task capture_read_address();
    extern task capture_read_data();
    extern task merge_read_info();

endclass :master_monitor

    function void master_monitor :: build_phase (uvm_phase phase);
      super.build_phase (phase);
      mon_ap = new ("mon_ap",this);
      //pkt = master_seq_item::type_id::create("pkt");
      `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
    endfunction : build_phase

    task master_monitor::main_phase(uvm_phase phase);
        `uvm_info(get_full_name(), "Starting Independent AXI Monitor", UVM_MEDIUM)
        fork
            capture_write_address();
            capture_write_data();
            capture_write_response();
            merge_write_info();
            
            capture_read_address();
            capture_read_data();
            merge_read_info();
        join
    endtask

    task master_monitor::capture_write_address();
        master_seq_item pkt;
        forever begin
            do begin
                @(master_mon_intf.mas_mon_cb);
            end while(!(master_mon_intf.mas_mon_cb.awready==1 && master_mon_intf.mas_mon_cb.awvalid==1 && master_mon_intf.areset_n==1));
            
            pkt = master_seq_item::type_id::create("pkt");
            pkt.awaddr = master_mon_intf.mas_mon_cb.awaddr;
            write_addr.push_back(pkt);
        end
    endtask

    task master_monitor::capture_write_data();
        master_seq_item pkt;
        forever begin
            do begin
                @(master_mon_intf.mas_mon_cb);
            end while(!(master_mon_intf.mas_mon_cb.wready==1 && master_mon_intf.mas_mon_cb.wvalid==1 && master_mon_intf.areset_n==1));
            
            pkt = master_seq_item::type_id::create("pkt");
            pkt.wdata = new[1];
            pkt.wdata[0] = master_mon_intf.mas_mon_cb.wdata;
            write_data.push_back(pkt);
        end
    endtask

    task master_monitor::capture_write_response();
        master_seq_item pkt;
        forever begin
            do begin
                @(master_mon_intf.mas_mon_cb);
            end while(!(master_mon_intf.mas_mon_cb.bready==1 && master_mon_intf.mas_mon_cb.bvalid==1 && master_mon_intf.areset_n==1));
            
            pkt = master_seq_item::type_id::create("pkt");
            pkt.bresp = response_t'(master_mon_intf.mas_mon_cb.bresp);
            write_resp.push_back(pkt);
        end
    endtask

    task master_monitor::merge_write_info();
        master_seq_item w_merge;
        forever begin
            wait(write_addr.size() > 0 && write_data.size() > 0 && write_resp.size() > 0);
            w_merge = master_seq_item::type_id::create("w_merge");
            w_merge.awaddr    = write_addr[0].awaddr;
            w_merge.wdata     = write_data[0].wdata;
            w_merge.bresp     = write_resp[0].bresp;
            w_merge.operation = WRITE;
            void'(write_addr.pop_front());
            void'(write_data.pop_front());
            void'(write_resp.pop_front());
            `uvm_info("PREDICTOR_DEBUG", $sformatf("Broadcasting WRITE to Addr: 0x%0h", w_merge.awaddr), UVM_MEDIUM)
            mon_ap.write(w_merge);
            `uvm_info("master_monitor_wr_data_pkt",w_merge.sprint(),UVM_MEDIUM);
        end
    endtask

    task  master_monitor :: capture_read_address();
        master_seq_item pkt;
        forever begin
            `uvm_info("master_monitor :: capture_read_address","Triggred",UVM_MEDIUM);
            do begin
                @(master_mon_intf.mas_mon_cb);
            end while(!(master_mon_intf.mas_mon_cb.arready==1 && master_mon_intf.mas_mon_cb.arvalid==1 && master_mon_intf.areset_n==1));
            //wait(master_mon_intf.mas_mon_cb.arready==1 && master_mon_intf.mas_mon_cb.arvalid==1 && master_mon_intf.areset_n==1);
            pkt = master_seq_item::type_id::create("pkt");
            pkt.araddr   = master_mon_intf.mas_mon_cb.araddr;
            pkt.operation = READ;
            read_addr.push_back(pkt);
            `uvm_info("master_monitor :: capture_read_address","captured read addr pkt put to read_addr",UVM_MEDIUM);
        end
    endtask
    
    task  master_monitor :: capture_read_data();
        master_seq_item pkt;
        forever begin
            `uvm_info("master_monitor :: capture_read_data","Triggred",UVM_MEDIUM);
            do begin
                @(master_mon_intf.mas_mon_cb);
            end while(!(master_mon_intf.mas_mon_cb.rready==1 && master_mon_intf.mas_mon_cb.rvalid==1 && master_mon_intf.areset_n==1));
            //wait(master_mon_intf.mas_mon_cb.rready==1 && master_mon_intf.mas_mon_cb.rvalid==1 && master_mon_intf.areset_n==1);
            pkt = master_seq_item::type_id::create("pkt");
            pkt.rdata   =   new[1];
            pkt.rresp   =   new[1];
            pkt.rdata[0]  = master_mon_intf.mas_mon_cb.rdata;
            pkt.rresp[0]  = response_t'(master_mon_intf.mas_mon_cb.rresp);
            pkt.operation = READ;
            read_data.push_back(pkt);
            `uvm_info("master_monitor :: capture_read_data","Sending pkt to read_data",UVM_MEDIUM);
        end
    endtask

    task master_monitor :: merge_read_info();
    master_seq_item r_merge;
        forever begin
        wait(read_addr.size() > 0 && read_data.size() > 0 );
        //if(read_addr.size() > 0 && read_data.size() > 0 ) begin
            r_merge = master_seq_item :: type_id :: create("r_merge");
            r_merge.araddr 	= read_addr[0].araddr;
            r_merge.rdata 	= read_data[0].rdata;
	        r_merge.rresp 	= read_data[0].rresp;
            r_merge.operation = READ;
            void'(read_addr.pop_front);
            void'(read_data.pop_front);
            mon_ap.write(r_merge);
            `uvm_info("master_monitor_rd_data_pkt",r_merge.sprint(),UVM_MEDIUM);
        end
	endtask
