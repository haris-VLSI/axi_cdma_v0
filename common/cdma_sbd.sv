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
                if(!sa_pos==slv_pkt.araddr) begin
                    `uvm_error("SBD_SA_ADDR_ERR",$sformatf("SA: %0d != ARADDR: %0d",sa_pos,slv_pkt.araddr))
                end else begin
                    `uvm_info("SBD_SA_ADDR_PASS",$sformatf("SA: %0d = ARADDR: %0d",sa_pos,slv_pkt.araddr),UVM_LOW)
                    for(int i=0;i<btt_len;i++)begin
                        for(int j=0; j<16; j++)begin
                            byte_t = (slv_pkt.rdata[i] >> (j*8)) & 8'hff;
                            expected_data_q.push_back(byte_t);
                            //`uvm_info("SBD_READ_DATA",$sformatf("read_queue_data: %h",expected_data_q[j]),UVM_LOW)
                        end
                        `uvm_info("SBD_READ_DATA",$sformatf("read_queue_data: %h",expected_data_q[i]),UVM_LOW)
                    end
                    `uvm_info("SBD_DATA_Q",$sformatf("expected_data_q: %h",expected_data_q.size()),UVM_LOW)
                end
            end
            else if(slv_pkt.operation == WRITE) begin
            `uvm_info("SBD_CHECK",$sformatf("write_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)

// checking DA = AWADDR
                if(!da_pos==slv_pkt.awaddr) begin
                    `uvm_error("SBD_DA_ADDR_ERR","DA & AWADDR not same")
                end else begin
                    `uvm_info("SBD_DA_ADDR_PASS","DA & AWADDR same",UVM_LOW)
                    for(int i=0;i<btt_len;i++)begin
                        for(int j=0; j<16; j++)begin
                            byte_e = (slv_pkt.wdata[i] >> (j*8)) & 8'hff;
                            actual_data_q.push_back(byte_e);
                            //`uvm_info("SBD_WRITE_DATA",$sformatf("write_queue_data: %h",actual_data_q[j]),UVM_LOW)
                        end
                        `uvm_info("SBD_WRITE_DATA",$sformatf("write_queue_data: %h",actual_data_q[i]),UVM_LOW)
                    end
                    `uvm_info("SBD_DATA_Q",$sformatf("actual_data_q: %h",actual_data_q.size()),UVM_LOW)
                end
            end
        end
    endtask

    task compare_slave_pkt();
        `uvm_info("SBD_WAIT","Waiting at btt size equal!",UVM_LOW)
        wait(tx_start && actual_data_q.size() == btt_len*'d16 && expected_data_q.size()==btt_len*'d16);
        //wait((actual_data_q.size()/16) == (btt_len) && (expected_data_q.size()/16) == (btt_len));
        `uvm_info("SBD_WAIT","Wait cleared!",UVM_LOW)
    // performed Read & Write queue sizes equals with provided BTT size
    // data integrity check
        for(int i=0;i<btt_len;i++)begin
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
