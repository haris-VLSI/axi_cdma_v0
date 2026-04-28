class cdma_chk extends uvm_component;
    `uvm_component_utils(cdma_chk)

    cdma_reg_block  reg_block;
    uvm_status_e    status;

    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item) slave_af;

    master_seq_item cfg_pkt;
    slave_seq_item  slv_pkt;

    byte expected_data_q[$];
    byte actual_data_q[$];
    
    bit [1:0] exp_burst_r;
    bit [1:0] exp_burst_w;
    bit [31:0] exp_len_r;
    bit [31:0] exp_len_w;
    bit [31:0] burst_size;

    int bytes_per_beat;
    longint aligned_addr;
    longint next_expected_awaddr;
    longint expected_awaddr;
    longint remaining_write_bytes;
    int bytes_written;
    
    uvm_reg_data_t sa_loc;
    uvm_reg_data_t da_loc;
    uvm_reg_data_t btt_b;
    uvm_reg_data_t cr_t;
    uvm_reg_data_t sr_t;

    bit transfer_active = 0;

    function new(string name = "cdma_chk", uvm_component parent);
        super.new(name, parent);
    endfunction
  
    function void build_phase(uvm_phase phase);
        master_af = new("master_af",this);
        slave_af = new("slave_af",this);
    endfunction

    task main_phase (uvm_phase phase);
        fork
            predict_master_packet();
            compare_master_pkt();
        join
    endtask

    task predict_master_packet();
        `uvm_info("CHK","get_master_packets",UVM_LOW)
        forever begin
            master_af.get(cfg_pkt);
            //BTT
            if(cfg_pkt.awaddr == 'h28) begin
                cr_t = reg_block.cdmacr.get_mirrored_value();
                sr_t = reg_block.cdmasr.get_mirrored_value();
                sa_loc = reg_block.sa.get_mirrored_value();
                da_loc = reg_block.da.get_mirrored_value();
                expected_awaddr = da_loc;
                btt_b = reg_block.btt.get_mirrored_value();
                remaining_write_bytes = btt_b;
                transfer_active = 1;
                `uvm_info("CHK_PRE",$sformatf("cr_t configured: %0h", cr_t),UVM_LOW)
                `uvm_info("CHK_PRE",$sformatf("sr_t configured: %0h", sr_t),UVM_LOW)
                `uvm_info("CHK_PRE",$sformatf("sa_loc configured: %0h", sa_loc),UVM_LOW)
                `uvm_info("CHK_PRE",$sformatf("da_loc configured: %0h", da_loc),UVM_LOW)
                `uvm_info("CHK_PRE",$sformatf("btt_b configured decimal: %0d. Transfer Active!", btt_b),UVM_LOW)
            //ARLength Prediction
                burst_size = 2**4;
                exp_len_r = ((sa_loc+btt_b-1)/burst_size)-(sa_loc/burst_size);//+1;
            //AWLength Prediction
                burst_size = 2**4;
                exp_len_w = ((da_loc+btt_b-1)/burst_size)-(da_loc/burst_size);//+1;
            //ARBurst Prediction
                exp_burst_r = (cr_t[4] == 1'b1) ? FIXED : INCR;
            //AWBurst Prediction
                exp_burst_w = (cr_t[5] == 1'b1) ? FIXED : INCR;
            end
        end
    endtask

    task compare_master_pkt();
        
        wait(transfer_active == 1);
        `uvm_info("CHK","get_slave_packet",UVM_LOW)
        forever begin
            slave_af.get(slv_pkt);

            if(slv_pkt.operation == READ) begin
                //ArLen using SA and BTT
                if(slv_pkt.arlen == exp_len_r) begin
                    `uvm_info("CHK_RAL", $sformatf("ARLEN is matched: %0h", slv_pkt.arlen), UVM_LOW)
                end
                else begin
                    `uvm_error("CHK_RAL", $sformatf("ARLEN mismatch! Expected: %0h, Got: %0h", exp_len_r, slv_pkt.arlen)) 
                end

                //CDMACR for burst type
                if(slv_pkt.arburst == exp_burst_r) begin
                    `uvm_info("CHK_RAL", $sformatf("ARBURST is matched: %p", burst_type_t'(slv_pkt.arburst)), UVM_LOW)
                end
                else begin
                    `uvm_error("CHK_RAL", $sformatf("ARBURST mismatch! Expected: %p, Got: %p", exp_burst_r, slv_pkt.arburst)) 
                end
                //SA for ARADDR
                if(sa_loc != slv_pkt.araddr) begin
                    `uvm_error("CHK_RAL", $sformatf("ARADDR mismatch! Expected: %0h, Got: %0h", sa_loc, slv_pkt.araddr)) 
                end
                else begin
                    `uvm_info("CHK_RAL", $sformatf("ARADDR match. Expected: %0h | Got: %0h",sa_loc,slv_pkt.araddr),UVM_LOW)
                end
            end
            else if(slv_pkt.operation == WRITE) begin
                //ArLen using SA and BTT
                if(slv_pkt.awlen == exp_len_w) begin
                    `uvm_info("CHK_RAL", $sformatf("AWLEN is matched: %0h", slv_pkt.awlen), UVM_LOW)
                end
                else begin
                    `uvm_error("CHK_RAL", $sformatf("AWLEN mismatch! Expected: %0h, Got: %0h", exp_len_w, slv_pkt.awlen)) 
                end

                //CDMACR for burst type
                if(slv_pkt.awburst == exp_burst_w) begin
                    `uvm_info("CHK_RAL", $sformatf("AWBURST is matched: %p", burst_type_t'(slv_pkt.awburst)), UVM_LOW)
                end
                else begin
                    `uvm_error("CHK_RAL", $sformatf("AWBURST mismatch! Expected: %p, Got: %p", exp_burst_w, slv_pkt.awburst)) 
                end
                //DA for AWADDR
                //if(da_loc != slv_pkt.awaddr) begin
                //    `uvm_error("CHK_RAL", $sformatf("AWADDR mismatch! Expected: %0h, Got: %0h", da_loc, slv_pkt.awaddr)) 
                //end
                //else begin
                //    `uvm_info("CHK_RAL", $sformatf("AWADDR match. Expected: %0h | Got: %0h",da_loc,slv_pkt.awaddr),UVM_LOW)
                //end
            end
            if(slv_pkt.operation == WRITE) begin
                if(expected_awaddr != slv_pkt.awaddr) begin
                    `uvm_error("CHK_AWADDR", $sformatf("Mismatch! Exp: %0h, Got: %0h", expected_awaddr, slv_pkt.awaddr)) 
                end else begin
                    `uvm_info("CHK_AWADDR", $sformatf("Match! Address: %0h", expected_awaddr), UVM_LOW)
                end
                bytes_per_beat = (1 << slv_pkt.awsize); 
                aligned_addr = expected_awaddr & ~(bytes_per_beat - 1);
                next_expected_awaddr = aligned_addr + ((slv_pkt.awlen + 1) * bytes_per_beat);
                bytes_written = next_expected_awaddr - expected_awaddr;
                expected_awaddr = next_expected_awaddr;
                remaining_write_bytes = remaining_write_bytes - bytes_written;
                if (remaining_write_bytes < 0) begin
                    `uvm_error("CHK_BTT_OVERFLOW", $sformatf("Hardware wrote %0d MORE bytes than BTT configured!",remaining_write_bytes))
                end
            end
        end
    endtask
endclass: cdma_chk
