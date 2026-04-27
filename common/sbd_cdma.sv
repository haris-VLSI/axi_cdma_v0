class cdma_sbd extends uvm_scoreboard;
    `uvm_component_utils(cdma_sbd)
    
    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  slave_af;

    cdma_reg_block reg_block;

    master_seq_item cfg_pkt;
    slave_seq_item  slv_pkt;

    bit tx_start = 0;
    longint sa_pos, da_pos, btt_len;

    byte expected_data_q[$];
    byte actual_data_q[$];
    byte exp_byte, act_byte;

    int matchings;
    int mis_matchings;
    int start_len;
    int byte_t;
    int burst_size;
    
    function new(string name="cdma_sbd", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build();
        master_af = new("master_af", this);
        slave_af  = new("slave_af",  this);
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
            
            if(cfg_pkt.awaddr == 'h18) begin
                sa_pos = cfg_pkt.wdata[0];
                `uvm_info("SBD_CFG", $sformatf("Captured SA_ADDR: 'h%0h", sa_pos), UVM_LOW)
            end
            if(cfg_pkt.awaddr == 'h20) begin
                da_pos = cfg_pkt.wdata[0];
                `uvm_info("SBD_CFG", $sformatf("Captured DA_ADDR: 'h%0h", da_pos), UVM_LOW)
            end
            if(cfg_pkt.awaddr == 'h28) begin
                btt_len = cfg_pkt.wdata[0];
                tx_start = 1;
                `uvm_info("SBD_CFG", $sformatf("Captured BTT_LEN: %0d bytes. Transfer started!", btt_len), UVM_LOW)
            end
        end
    endtask

    task get_slave_pkt();
        forever begin
            slave_af.get(slv_pkt);
            
            wait(tx_start == 1);

            if(slv_pkt.operation == READ) begin
                `uvm_info("SBD_READ_CHECK",$sformatf("read_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)
                burst_size = 2**slv_pkt.arsize;

                foreach(slv_pkt.rdata[i]) begin
                    if(i == 0)begin
                        start_len = slv_pkt.araddr % burst_size;
                    end
                    else begin
                        start_len = 0;
                    end
                    for(int j = start_len; j < burst_size; j++) begin
                        if (expected_data_q.size() < btt_len) begin
                            byte_t = slv_pkt.rdata[i] >> (j*8) & 8'hff;
                            expected_data_q.push_back(byte_t);
                        end
                    end
                end
                `uvm_info("SBD_READ", $sformatf("Extracted READ packet. Current expected_data_q size: %0d", expected_data_q.size()), UVM_LOW)
            end
            else if(slv_pkt.operation == WRITE) begin
                `uvm_info("SBD_WRITE_CHECK",$sformatf("write_slv_pkt: %s",slv_pkt.sprint()),UVM_LOW)
                burst_size = 2**slv_pkt.awsize;

                foreach(slv_pkt.wdata[i]) begin
                    if(i == 0)begin
                        start_len = slv_pkt.awaddr % burst_size;
                    end
                    else begin
                        start_len = 0;
                    end
                    for(int j = start_len; j < burst_size; j++) begin
                        if(slv_pkt.wstrobe[i][j] == 1'b1 && actual_data_q.size() < btt_len) begin
                            byte_t = slv_pkt.wdata[i] >> (j*8) & 8'hff;
                            actual_data_q.push_back(byte_t);
                        end
                    end
                end
                `uvm_info("SBD_WRITE", $sformatf("Extracted WRITE packet. Current actual_data_q size: %0d", actual_data_q.size()), UVM_LOW)
            end
        end
    endtask

    task compare_slave_pkt();
        forever begin
            wait(tx_start == 1 && actual_data_q.size() == btt_len && expected_data_q.size() == btt_len);
            
            `uvm_info("SBD_COMPARE", $sformatf("Initiating comparison for %0d bytes...", btt_len), UVM_LOW)
            
            matchings = 0;
            mis_matchings = 0;

            for(int i = 0; i < btt_len; i++) begin
                exp_byte = expected_data_q.pop_front();
                act_byte = actual_data_q.pop_front();
                
                if(exp_byte == act_byte) begin
                    matchings++;
                    `uvm_info("SBD_MATCHINGS", $sformatf("Byte: %0d | Match: Exp: %0h | Act: %0h", i, exp_byte, act_byte), UVM_LOW)
                end
                else begin
                    mis_matchings++;
                    `uvm_error("SBD_MIS-MATCHINGS", $sformatf("Byte: %0d | Mismatch! Exp: %0h | Act: %0h", i, exp_byte, act_byte))
                end
            end

            if(mis_matchings == 0) begin
                `uvm_info("SBD_PASS", $sformatf("Transfer Successful! %0d/%0d bytes matched.", matchings, btt_len), UVM_LOW)
            end else begin
                `uvm_error("SBD_FAIL", $sformatf("Transfer Failed! %0d bytes mismatched.", mis_matchings))
            end
            tx_start = 0;
        end
    endtask
endclass
