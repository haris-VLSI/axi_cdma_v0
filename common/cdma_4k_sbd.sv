class cdma_sbd extends uvm_scoreboard;
`uvm_component_utils(cdma_sbd)
    
    uvm_tlm_analysis_fifo#(master_seq_item) master_af;
    uvm_tlm_analysis_fifo#(slave_seq_item) slave_af;

    master_seq_item cfg_pkt;
    slave_seq_item  slv_pkt;

    bit tx_start = 0;

    longint sa_pos, da_pos, btt_len;

    byte actual_data_q[$];
    byte expected_data_q[$];
    
    byte byte_t;
    byte byte_e;
    byte temp_b;
    int queue_s;
    int matchings;
    int mis_matchings;
    
    int start_len;
    
    function new(string name="cdma_sbd",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build();
        master_af = new("master_af",this);
        slave_af = new("slave_af",this);
    endfunction

    task main_phase(uvm_phase phase);
        fork
            get_config_pkt();
            get_slave_pkt();
            compare_slave_pkt();
        join
    endtask

    task get_config_pkt();
        forever begin
            master_af.get(cfg_pkt);
            `uvm_info("SBD_CHECK",$sformatf("cfg_pkt: %s",cfg_pkt.sprint()),UVM_LOW)
            if(cfg_pkt.awaddr == 'h18) begin
                sa_pos = cfg_pkt.wdata[0];
                `uvm_info("SBD_DATA",$sformatf("SA_ADDR: %0d",sa_pos),UVM_LOW)
            end
            if(cfg_pkt.awaddr == 'h20) begin
                da_pos = cfg_pkt.wdata[0];
                `uvm_info("SBD_DATA",$sformatf("DA_ADDR: %0d",da_pos),UVM_LOW)
            end
            if(cfg_pkt.awaddr == 'h28) begin
                btt_len = cfg_pkt.wdata[0];
                tx_start = 1;
                `uvm_info("SBD_DATA",$sformatf("BTT_LEN: %0d",btt_len),UVM_LOW)
            end
        end
    endtask

    task get_slave_pkt();
        forever begin
            slave_af.get(slv_pkt);

            `uvm_info("SBD_CHECK",$sformatf("slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)
            if(slv_pkt.operation == READ) begin
            `uvm_info("SBD_CHECK",$sformatf("read_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)

// checking SA = ARADDR
                //if(slv_pkt.araddr==0)begin
                //    `uvm_error("SBD_SA_ADDR_ERR",$sformatf("SA: %0d != ARADDR: %0d",sa_pos,slv_pkt.araddr))
                //end else begin
                    start_len = slv_pkt.araddr % 16;
                    `uvm_info("SBD_CHECK",$sformatf("start_len: %0d",start_len),UVM_LOW)
                    //`uvm_info("SBD_SA_ADDR_PASS",$sformatf("SA: %0d = ARADDR: %0d",sa_pos,slv_pkt.araddr),UVM_LOW)
                    //for(int i=0;i<btt_len;i++)begin
                    //for(int i=0;i<slv_pkt.rdata.size();i++)begin
                    foreach(slv_pkt.rdata[i])begin
                        for(int j=start_len; j<16; j++)begin
                            byte_t = (slv_pkt.rdata[i] >> (j*8)) & 8'hff;
                            expected_data_q.push_back(byte_t);
                        end
                        `uvm_info("SBD_READ_DATA",$sformatf("read_queue_data: %h",expected_data_q[i]),UVM_LOW)
                    //$display("SBD_i_value: %0d",i);
                    end
                    $displayh("%0t: SBD_READ_DATA_Q_D = %p",$time,expected_data_q);
                    `uvm_info("SBD_DATA_Q",$sformatf("expected_data_q: %h",expected_data_q.size()),UVM_LOW)
            //    end
            end
            else if(slv_pkt.operation == WRITE) begin
            `uvm_info("SBD_CHECK",$sformatf("write_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)

// checking DA = AWADDR
                if(slv_pkt.awaddr == 0) begin
                    `uvm_error("SBD_DA_ADDR_ERR","DA & AWADDR not same")
                end else begin
                    `uvm_info("SBD_DA_ADDR_PASS","DA & AWADDR same",UVM_LOW)
                    start_len = slv_pkt.awaddr % 16;
                    //for(int i=0;i<btt_len;i++)begin
                    foreach(slv_pkt.wdata[i])begin
                        for(int j=start_len; j<16; j++)begin
                            byte_e = (slv_pkt.wdata[i] >> (j*8)) & 8'hff;
                            actual_data_q.push_back(byte_e);
                        end
                        `uvm_info("SBD_WRITE_DATA",$sformatf("write_queue_data: %h",actual_data_q[i]),UVM_LOW)
                    end
                    $displayh("%0t: SBD_WRITE_DATA_Q_D = %p",$time,actual_data_q);
                    `uvm_info("SBD_DATA_Q",$sformatf("actual_data_q: %h",actual_data_q.size()),UVM_LOW)
                end
            end
        end
    endtask

    task compare_slave_pkt();
        `uvm_info("SBD_WAIT","Waiting at btt size equal!",UVM_LOW)
        wait(tx_start && actual_data_q.size() == btt_len && expected_data_q.size()==btt_len);
        `uvm_info("SBD_WAIT","Wait cleared!",UVM_LOW)
    // performed Read & Write queue sizes equals with provided BTT size
    // data integrity check
        for(int i=0;i<btt_len;i++)begin
            temp_b = expected_data_q.pop_front();
            byte_e = actual_data_q.pop_front();
            if(temp_b == byte_e)begin
                matchings++;
                `uvm_info("SBD_DATA_CHECK_PASS",$sformatf("RD_DATA: %h | WR_DATA: %h",temp_b,byte_e),UVM_LOW)
                `uvm_info("SBD_MATCHINGS",$sformatf("matchings: %0d",matchings),UVM_LOW)
            end
            else begin
                mis_matchings++;
                `uvm_info("SBD_DATA_CHECK_ERR",$sformatf("RD_DATA: %h | WR_DATA: %h",temp_b,byte_e),UVM_LOW)
                `uvm_info("SBD_MIS_MATCHINGS",$sformatf("mis_matchings: %0d",mis_matchings),UVM_LOW)
            end
        end
    endtask
endclass

/*
class cdma_sbd extends uvm_scoreboard;
    `uvm_component_utils(cdma_sbd)
    
    uvm_tlm_analysis_fifo#(master_seq_item) master_af;
    uvm_tlm_analysis_fifo#(slave_seq_item) slave_af;

    master_seq_item cfg_pkt;
    slave_seq_item  slv_pkt;

    bit tx_start = 0;
    longint sa_pos, da_pos, btt_len;
    
    longint expected_bytes_collected = 0;
    longint actual_bytes_collected = 0;

    byte actual_data_q[$];
    byte expected_data_q[$];
    
    int matchings = 0;
    int mis_matchings = 0;
    int start_lane;

    function new(string name="cdma_sbd",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master_af = new("master_af",this);
        slave_af = new("slave_af",this);
    endfunction

    task main_phase(uvm_phase phase);
        fork
            get_config_pkt();
            get_slave_pkt();
            compare_slave_pkt();
        join
    endtask

    // ---------------------------------------------------------
    // 1. CONFIGURATION
    // ---------------------------------------------------------
    task get_config_pkt();
        forever begin
            master_af.get(cfg_pkt);
            if(cfg_pkt.awaddr == 'h18) sa_pos = cfg_pkt.wdata[0];
            if(cfg_pkt.awaddr == 'h20) da_pos = cfg_pkt.wdata[0];
            if(cfg_pkt.awaddr == 'h28) begin
                btt_len = cfg_pkt.wdata[0];
                tx_start = 1;
                expected_bytes_collected = 0;
                actual_bytes_collected = 0;
                
                // DEBUG PRINT 1: Configuration Triggered
                `uvm_info("SBD_DEBUG_CFG",$sformatf("==> TRANSFER TRIGGERED! tx_start=1 | SA:%0h | DA:%0h | BTT:%0d", sa_pos, da_pos, btt_len), UVM_NONE)
            end
        end
    endtask

    // ---------------------------------------------------------
    // 2. DATA COLLECTION
    // ---------------------------------------------------------
    task get_slave_pkt();
        forever begin
            slave_af.get(slv_pkt);

            if(slv_pkt.operation == READ) begin
                start_lane = slv_pkt.araddr % 16; 
                
                foreach(slv_pkt.rdata[i]) begin
                    for(int j = start_lane; j < 16; j++) begin
                        if (expected_bytes_collected < btt_len) begin
                            byte byte_t = (slv_pkt.rdata[i] >> (j*8)) & 8'hff;
                            expected_data_q.push_back(byte_t);
                            expected_bytes_collected++;
                        end
                    end
                    start_lane = 0; 
                end
                // DEBUG PRINT 2: Read Collection Status
                `uvm_info("SBD_DEBUG_READ", $sformatf("==> READ BURST STORED. Expected Bytes Collected: %0d / %0d", expected_bytes_collected, btt_len), UVM_NONE)
            end
            
            else if(slv_pkt.operation == WRITE) begin
                foreach(slv_pkt.wdata[i]) begin
                    for(int j = 0; j < 16; j++) begin
                        if (slv_pkt.wstrobe[i][j] == 1'b1 && actual_bytes_collected < btt_len) begin
                            byte byte_e = (slv_pkt.wdata[i] >> (j*8)) & 8'hff;
                            actual_data_q.push_back(byte_e);
                            actual_bytes_collected++;
                        end
                    end
                end
                // DEBUG PRINT 3: Write Collection Status
                `uvm_info("SBD_DEBUG_WRITE", $sformatf("==> WRITE BURST STORED. Actual Bytes Collected: %0d / %0d", actual_bytes_collected, btt_len), UVM_NONE)
            end
        end
    endtask

    // ---------------------------------------------------------
    // 3. THE COMPARATOR
    // ---------------------------------------------------------
    task compare_slave_pkt();
        forever begin 
            // DEBUG PRINT 4: Status right before hitting the wait statement
            `uvm_info("SBD_DEBUG_WAIT", $sformatf("==> SCOREBOARD ENTERING WAIT STATE. Current Status -> tx_start:%0b | exp_collected:%0d/%0d | act_collected:%0d/%0d", 
                      tx_start, expected_bytes_collected, btt_len, actual_bytes_collected, btt_len), UVM_NONE)
                      
            // The blocking wait
            wait(tx_start == 1 && 
                 expected_bytes_collected == btt_len && 
                 actual_bytes_collected == btt_len);
                 
            // DEBUG PRINT 5: Wait cleared!
            `uvm_info("SBD_DEBUG_WAIT", "==> WAIT CLEARED! All conditions met. Starting comparison loop.", UVM_NONE)
            
            for(int i = 0; i < btt_len; i++) begin
                byte temp_b = expected_data_q.pop_front();
                byte byte_e = actual_data_q.pop_front();
                
                if(temp_b == byte_e) begin
                    matchings++;
                end else begin
                    mis_matchings++;
                    `uvm_error("SBD_FAIL",$sformatf("Mismatch at Byte %0d | RD: %0h | WR: %0h", i, temp_b, byte_e))
                end
            end
            
            if (mis_matchings == 0) begin
                `uvm_info("SBD_PASS", $sformatf("SUCCESS: All %0d bytes matched perfectly!", btt_len), UVM_NONE)
            end
            
            // Reset trackers
            expected_data_q.delete();
            actual_data_q.delete();
            tx_start = 0;
            matchings = 0;
            mis_matchings = 0;
        end
    endtask

    // ---------------------------------------------------------
    // 4. THE AUTOPSY (Runs when simulation ends)
    // ---------------------------------------------------------
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        // If simulation ends but the scoreboard is still expecting data, print a fatal warning!
        if (tx_start == 1 && (expected_bytes_collected < btt_len || actual_bytes_collected < btt_len)) begin
            `uvm_error("SBD_DEBUG_CRASH", $sformatf("==> SIMULATION ENDED PREMATURELY! The test dropped its objection while the Scoreboard was still waiting for data. \nFinal State -> tx_start:%0b | exp_collected:%0d/%0d | act_collected:%0d/%0d", 
                      tx_start, expected_bytes_collected, btt_len, actual_bytes_collected, btt_len))
        end
    endfunction

endclass

/*
class cdma_sbd extends uvm_scoreboard;
`uvm_component_utils(cdma_sbd)
    
    uvm_tlm_analysis_fifo#(master_seq_item) master_af;
    uvm_tlm_analysis_fifo#(slave_seq_item) slave_af;

    master_seq_item cfg_pkt;
    slave_seq_item  slv_pkt;

    longint sa_pos, da_pos, btt_len;
    longint temp_mod_s, temp_mod_d;
    longint nxt_sa_pos, nxt_da_pos;
    longint current_sa_pos, current_da_pos;

    int offset_s, offset_d;
    int current_sa_btt_offset, current_da_btt_offset;

    byte actual_data_q[$];
    byte expected_data_q[$];
    
    byte byte_t;
    byte byte_e;
    byte temp_b;

    int queue_s;
    int matchings;
    int mis_matchings;
    
    function new(string name="cdma_sbd",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build();
        master_af = new("master_af",this);
        slave_af = new("slave_af",this);
    endfunction

    task main_phase(uvm_phase phase);
        fork
            get_config_pkt();
            get_slave_pkt();
            compare_slave_pkt();
        join
    endtask

    task get_config_pkt();
        forever begin
            master_af.get(cfg_pkt);
            `uvm_info("SBD_CHECK",$sformatf("cfg_pkt: %s",cfg_pkt.sprint()),UVM_LOW)
            if(cfg_pkt.awaddr == 'h18) begin
                sa_pos = cfg_pkt.wdata[0];
                `uvm_info("SBD_DATA",$sformatf("SA_ADDR: %0d",sa_pos),UVM_LOW)
            end
            if(cfg_pkt.awaddr == 'h20) begin
                da_pos = cfg_pkt.wdata[0];
                `uvm_info("SBD_DATA",$sformatf("DA_ADDR: %0d",da_pos),UVM_LOW)
            end
            if(cfg_pkt.awaddr == 'h28) begin
                btt_len = cfg_pkt.wdata[0];
                `uvm_info("SBD_DATA",$sformatf("BTT_LEN: %0d",btt_len),UVM_LOW)
            end
        end
    endtask

    task get_slave_pkt();
        forever begin
            slave_af.get(slv_pkt);

            if(slv_pkt.operation == READ) begin
            `uvm_info("SBD_CHECK",$sformatf("read_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)

    // check 4K boundary
            if(sa_pos %'d4096 != 0) begin
                if(sa_pos < 'd4096) begin
                    offset_s = 'd4096 % sa_pos;
                    nxt_sa_pos = sa_pos + offset_s;
                    `uvm_info("SBD_DATA",$sformatf("nxt_sa_pos: %0h",nxt_sa_pos),UVM_LOW)
                    `uvm_info("SBD_DATA",$sformatf("offset_s: %0d",offset_s),UVM_LOW)
                end else begin
                    temp_mod_s = sa_pos % 'd4096;
                    offset_s = 'd4096-temp_mod_s;
                    nxt_sa_pos = sa_pos + offset_s;
                    `uvm_info("SBD_DATA",$sformatf("nxt_sa_pos: %0h",nxt_sa_pos),UVM_LOW)
                    `uvm_info("SBD_DATA",$sformatf("offset_s: %0d",offset_s),UVM_LOW)
                end
    // changing current_pos based on nxt_addr_pos
                if(matchings == offset_s) begin
                    current_sa_pos = nxt_sa_pos;
                    current_sa_btt_offset = offset_s;
                    `uvm_info("current_sa_pos",$sformatf("current_sa_pos: %h",current_sa_pos),UVM_LOW)
                    `uvm_info("current_sa_pos",$sformatf("matchings = %h | current_sa_pos: %h",matchings,current_sa_pos),UVM_LOW)
                end else begin
                    current_sa_pos = sa_pos;
                    current_sa_btt_offset = btt_len - offset_s;
                    `uvm_info("current_sa_pos",$sformatf("current_sa_pos: %h",current_sa_pos),UVM_LOW)
                    `uvm_info("current_sa_pos",$sformatf("matchings = %h | current_sa_pos: %h",matchings,current_sa_pos),UVM_LOW)
                end
            end else begin
                wait(btt_len > 0);
                current_sa_pos = sa_pos;
                current_sa_btt_offset = btt_len;
            end

            if(da_pos %'d4096 != 0) begin
                if(da_pos < 'd4096) begin
                    offset_d = 'd4096 % da_pos;
                    nxt_da_pos = da_pos + offset_d;
                    `uvm_info("SBD_DATA",$sformatf("nxt_da_pos: %0h",nxt_da_pos),UVM_LOW)
                    `uvm_info("SBD_DATA",$sformatf("offset_d: %0d",offset_d),UVM_LOW)
                end else begin
                    temp_mod_d = da_pos % 'd4096;
                    offset_d = 'd4096-temp_mod_d;
                    nxt_da_pos = da_pos + offset_d;
                    `uvm_info("SBD_DATA",$sformatf("nxt_da_pos: %0h",nxt_da_pos),UVM_LOW)
                    `uvm_info("SBD_DATA",$sformatf("offset_d: %0d",offset_d),UVM_LOW)
                end
    // changing current_pos based on nxt_addr_pos
                if(matchings == offset_d) begin
                    current_da_pos = nxt_da_pos;
                    current_da_btt_offset = offset_d;
                    `uvm_info("current_da_pos",$sformatf("current_da_pos: %h",current_da_pos),UVM_LOW)
                end else begin
                    current_da_pos = da_pos;
                    current_da_btt_offset = btt_len - offset_d;
                    `uvm_info("current_da_pos",$sformatf("current_da_pos: %h",current_da_pos),UVM_LOW)
                end
            end else begin
                wait(btt_len > 0);
                current_da_pos = da_pos;
                current_da_btt_offset = btt_len;
            end

    // checking SA = ARADDR
                if(!current_sa_pos==slv_pkt.araddr) begin
                //if(!sa_pos==slv_pkt.araddr) begin
                    `uvm_error("SBD_SA_ADDR_ERR",$sformatf("SA: %0d != ARADDR: %0d",current_sa_pos,slv_pkt.araddr))
                end else begin
                    //`uvm_info("SBD_SA_ADDR_PASS",$sformatf("SA: %0d = ARADDR: %0d",current_sa_pos,slv_pkt.araddr),UVM_LOW)
                    `uvm_info("SBD_DATA",$sformatf("current_sa_btt_offset: %0d",current_sa_btt_offset),UVM_LOW)
                    for(int i=0; i<current_sa_btt_offset; i++)begin
                        for(int j=0; j<16; j++)begin
                            byte_t = (slv_pkt.rdata[i] >> (j*8)) & 8'hff;
                            expected_data_q.push_back(byte_t);
                            //`uvm_info("SBD_READ_DATA",$sformatf("read_queue_data: %h",expected_data_q[i]),UVM_LOW)
                        end
                        //`uvm_info("SBD_READ_DATA",$sformatf("read_queue_data: %h",expected_data_q[i]),UVM_LOW)
                    end
                    `uvm_info("Final_SBD_expected_data_q_size",$sformatf("read_queue_data: %0d",expected_data_q.size()),UVM_LOW)
                end
            end
            else if(slv_pkt.operation == WRITE) begin
            `uvm_info("SBD_CHECK",$sformatf("write_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)

    // checking DA = AWADDR
                if(!current_da_pos==slv_pkt.awaddr) begin
                //if(!da_pos==slv_pkt.awaddr) begin
                    `uvm_error("SBD_DA_ADDR_ERR","DA & AWADDR not same")
                end else begin
                    `uvm_info("SBD_DA_ADDR_PASS","DA & AWADDR same",UVM_LOW)
                    `uvm_info("SBD_DATA",$sformatf("current_da_btt_offset: %0d",current_da_btt_offset),UVM_LOW)
                    for(int i=0;i<current_da_btt_offset;i++)begin
                        for(int j=0; j<16; j++)begin
                            byte_e = (slv_pkt.wdata[i] >> (j*8)) & 8'hff;
                            actual_data_q.push_back(byte_e);
                            //`uvm_info("SBD_WRITE_DATA",$sformatf("write_queue_data: %h",actual_data_q[i]),UVM_LOW)
                        end
                        //`uvm_info("SBD_WRITE_DATA",$sformatf("write_queue_data: %h",actual_data_q[i]),UVM_LOW)
                    end
                    `uvm_info("Final_SBD_actual_data_q_size",$sformatf("write_queue_data: %0d",actual_data_q.size()),UVM_LOW)
                end
            end
        end
    endtask

    task compare_slave_pkt();
    // performed Read & Write queue sizes equals with provided BTT size
        `uvm_info("SBD_WAIT","Waiting at queue and btt size...",UVM_LOW)
        wait(btt_len > 0);
        wait(actual_data_q.size() == btt_len*'d16 && expected_data_q.size() == btt_len*'d16);
        `uvm_info("SBD_WAIT","Wait cleared!",UVM_LOW)
        //if(actual_data_q.size() == expected_data_q.size() == (btt_len*16)) begin
    // data integrity check
        `uvm_info("SBD_COMPARE","Outside FOR LOOP!",UVM_LOW)
        `uvm_info("SBD_COMPARE",$sformatf("current_da_btt_offset: %0d",current_da_btt_offset),UVM_LOW)
        for(int i=0;i<current_da_btt_offset;i++)begin
            `uvm_info("SBD_COMPARE","Entered FOR LOOP!",UVM_LOW)
            temp_b = expected_data_q.pop_front();
            byte_e = actual_data_q.pop_front();
            if(temp_b == byte_e)begin
                matchings++;
                `uvm_info("SBD_DATA_CHECK_PASS",$sformatf("RD_DATA: %h | WR_DATA: %h",temp_b,byte_e),UVM_LOW)
                `uvm_info("SBD_Matchings",$sformatf("matchings: %0d",matchings),UVM_LOW)
            end
            else begin
                mis_matchings++;
                `uvm_info("SBD_DATA_CHECK_ERR",$sformatf("RD_DATA: %h | WR_DATA: %h",temp_b,byte_e),UVM_LOW)
                `uvm_info("SBD_Mis_Matchings",$sformatf("mis_matchings: %0d",mis_matchings),UVM_LOW)
            end
        end
    endtask
endclass
