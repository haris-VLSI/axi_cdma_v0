class cdma_transfer_cfg extends uvm_object;
    bit [31:0] sa;
    bit [31:0] da;
    bit [31:0] cr;
    bit [31:0] btt;
    `uvm_object_utils(cdma_transfer_cfg)
    function new(string name="cdma_transfer_cfg");
        super.new(name);
    endfunction
endclass

`uvm_analysis_imp_decl(_cfg)
`uvm_analysis_imp_decl(_axi_rd)
`uvm_analysis_imp_decl(_axi_wr)

class cdma_sbd extends uvm_scoreboard;
    `uvm_component_utils(cdma_sbd)

    cdma_reg_block reg_block;
    int AXI_BUS_BYTES; 

    // TLM Ports
    uvm_analysis_imp_cfg    #(master_seq_item, cdma_sbd) cfg_export;
    uvm_analysis_imp_axi_rd #(slave_seq_item,  cdma_sbd) rd_export;
    uvm_analysis_imp_axi_wr #(slave_seq_item,  cdma_sbd) wr_export;

    // DRE Queues & Context Trackers
    cdma_transfer_cfg cfg_q[$];      
    slave_seq_item    expected_ar_q[$]; 
    slave_seq_item    expected_aw_q[$]; 
    
    bit [7:0] dre_fifo[$];  
    int       read_btt_q[$];
    int       write_btt_q[$];
    
    // Trackers to know if we are on the first burst or a continuation
    int       read_total_btt = 0;
    int       read_btt_remaining = 0;
    int       write_total_btt = 0;
    int       write_btt_remaining = 0;

    function new(string name = "cdma_sbd", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg_export  = new("cfg_export", this);
        rd_export   = new("rd_export", this);
        wr_export   = new("wr_export", this);

        if (!uvm_config_db#(int)::get(null, "", "AXI_BUS_BYTES", AXI_BUS_BYTES)) begin
            AXI_BUS_BYTES = 16;
        end
    endfunction

    task main_phase(uvm_phase phase);
        forever begin
            wait(cfg_q.size() > 0);
            predict_axi_traffic(cfg_q.pop_front());
        end
    endtask

    // PORT 1: CONFIGURATION CATCHER
    virtual function void write_cfg(master_seq_item pkt);
        if (pkt.operation == WRITE && pkt.awaddr == 'h28) begin
            cdma_transfer_cfg new_cfg = cdma_transfer_cfg::type_id::create("new_cfg");
            new_cfg.cr  = reg_block.cdmacr.get_mirrored_value();
            new_cfg.sa  = reg_block.sa.get_mirrored_value();
            new_cfg.da  = reg_block.da.get_mirrored_value();
            new_cfg.btt = pkt.wdata[0]; 

            `uvm_info("CHK_CFG", $sformatf("New Transfer Queued: SA=%0h, DA=%0h, BTT=%0d", 
                      new_cfg.sa, new_cfg.da, new_cfg.btt), UVM_LOW)
                      
            cfg_q.push_back(new_cfg);
            read_btt_q.push_back(new_cfg.btt);
            write_btt_q.push_back(new_cfg.btt);
        end
    endfunction

    virtual function bit [2:0] predict_axsize();
        return $clog2(AXI_BUS_BYTES); 
    endfunction

    virtual function int predict_axlen(longint start_addr, int burst_bytes, int axsize);
        int bytes_per_beat = 1 << axsize;
        int unaligned_offset = start_addr % bytes_per_beat;
        int total_bytes_needed = burst_bytes + unaligned_offset;
        return ((total_bytes_needed + bytes_per_beat - 1) / bytes_per_beat) - 1;
    endfunction

    // THE PREDICTOR 
    virtual function void predict_axi_traffic(cdma_transfer_cfg t);
        longint v_sa = t.sa; longint v_da = t.da;
        longint b_sa = t.sa; longint b_da = t.da;
        
        int rem_ar_btt = t.btt; int rem_aw_btt = t.btt;
        int bytes_to_4k, current_burst_bytes, exp_axsize;
        
        bit is_fixed_read  = (t.cr[4] == 1'b1);
        bit is_fixed_write = (t.cr[5] == 1'b1);
        
        slave_seq_item exp_ar, exp_aw;
        exp_axsize = predict_axsize();

        // 1. Predict AR Channel 
        while (rem_ar_btt > 0) begin
            bytes_to_4k = 4096 - (v_sa % 4096); 
            current_burst_bytes = rem_ar_btt;
            if (current_burst_bytes > bytes_to_4k) current_burst_bytes = bytes_to_4k;
            
            if (is_fixed_read && current_burst_bytes > (16 * AXI_BUS_BYTES)) 
                current_burst_bytes = 16 * AXI_BUS_BYTES;
            else if (!is_fixed_read && current_burst_bytes > (256 * AXI_BUS_BYTES)) 
                current_burst_bytes = 256 * AXI_BUS_BYTES;

            exp_ar = slave_seq_item::type_id::create("exp_ar");
            exp_ar.araddr  = b_sa;
            exp_ar.arsize  = exp_axsize;
            exp_ar.arlen   = predict_axlen(v_sa, current_burst_bytes, exp_axsize);
            exp_ar.arburst = is_fixed_read ? FIXED : INCR; 
            expected_ar_q.push_back(exp_ar);

            `uvm_info("CHK_PREDICT", $sformatf("Predicted AR: Addr=%0h, Len=%0d, Burst=%s", exp_ar.araddr, exp_ar.arlen, exp_ar.arburst.name()), UVM_LOW)

            v_sa += current_burst_bytes; 
            if (!is_fixed_read) b_sa += current_burst_bytes; 
            rem_ar_btt -= current_burst_bytes;
        end

        // 2. Predict AW Channel
        while (rem_aw_btt > 0) begin
            bytes_to_4k = 4096 - (v_da % 4096);
            current_burst_bytes = rem_aw_btt;
            if (current_burst_bytes > bytes_to_4k) current_burst_bytes = bytes_to_4k;
            
            if (is_fixed_write && current_burst_bytes > (16 * AXI_BUS_BYTES)) 
                current_burst_bytes = 16 * AXI_BUS_BYTES;
            else if (!is_fixed_write && current_burst_bytes > (256 * AXI_BUS_BYTES)) 
                current_burst_bytes = 256 * AXI_BUS_BYTES;

            exp_aw = slave_seq_item::type_id::create("exp_aw");
            exp_aw.awaddr  = b_da;
            exp_aw.awsize  = exp_axsize;
            exp_aw.awlen   = predict_axlen(v_da, current_burst_bytes, exp_axsize);
            exp_aw.awburst = is_fixed_write ? FIXED : INCR;
            expected_aw_q.push_back(exp_aw);

            `uvm_info("CHK_PREDICT", $sformatf("Predicted AW: Addr=%0h, Len=%0d, Burst=%s", exp_aw.awaddr, exp_aw.awlen, exp_aw.awburst.name()), UVM_LOW)

            v_da += current_burst_bytes;
            if (!is_fixed_write) b_da += current_burst_bytes;
            rem_aw_btt -= current_burst_bytes;
        end
    endfunction

    // PORT 2: AXI READ MONITOR (Byte Extractor)
    virtual function void write_axi_rd(slave_seq_item pkt);
        slave_seq_item exp;
        int start_offset;
        
        // Fetch new transfer context
        if (read_btt_remaining == 0 && read_btt_q.size() > 0) begin
            read_total_btt = read_btt_q.pop_front();
            read_btt_remaining = read_total_btt;
        end

        if (pkt.operation == READ) begin
            if (expected_ar_q.size() == 0) begin 
                `uvm_error("CHK_AR", "RTL issued AR, but Predictor queue is empty!")
            end else begin
                exp = expected_ar_q.pop_front();
                if (exp.araddr != pkt.araddr || exp.arlen != pkt.arlen || exp.arsize != pkt.arsize) begin
                    `uvm_error("CHK_AR", $sformatf("AR Mismatch! Exp: Addr=%0h Len=%0d | Got: Addr=%0h Len=%0d", 
                               exp.araddr, exp.arlen, pkt.araddr, pkt.arlen))
                end else begin
                    `uvm_info("CHK_AR", $sformatf("AR Match: %0h", pkt.araddr), UVM_LOW)
                end
            end

            if (pkt.rresp[0] != OKAY) begin
                `uvm_warning("CHK_ERR", $sformatf("Slave Error detected on Read! Flushing Queues."))
                expected_ar_q.delete(); expected_aw_q.delete(); dre_fifo.delete();
            end else begin
                // --- FIX: VIRTUAL ALIGNMENT CHECK ---
                if (read_btt_remaining == read_total_btt) begin
                    // This is the FIRST burst of the transfer. Use bus address offset.
                    start_offset = pkt.araddr % AXI_BUS_BYTES;
                end else begin
                    // This is a CONTINUATION burst. Virtual address is 4K aligned.
                    start_offset = 0;
                end
                
                for (int i = 0; i <= pkt.arlen; i++) begin
                    for (int byte_idx = 0; byte_idx < AXI_BUS_BYTES; byte_idx++) begin
                        if (i == 0 && byte_idx < start_offset) continue;
                        
                        if (read_btt_remaining > 0) begin
                            bit [7:0] extracted_byte = pkt.rdata[i][byte_idx*8 +: 8];
                            dre_fifo.push_back(extracted_byte);
                            read_btt_remaining--;
                        end
                    end
                end
                `uvm_info("CHK_DRE", $sformatf("Extracted bytes from Read. DRE FIFO size: %0d", dre_fifo.size()), UVM_HIGH)
            end
        end
    endfunction

    // ----------------------------------------------------
    // PORT 3: AXI WRITE MONITOR (Byte Comparator)
    // ----------------------------------------------------
    virtual function void write_axi_wr(slave_seq_item pkt);
        slave_seq_item exp_aw;
        int start_offset;
        bit error_flag;

        // Fetch new transfer context
        if (write_btt_remaining == 0 && write_btt_q.size() > 0) begin
            write_total_btt = write_btt_q.pop_front();
            write_btt_remaining = write_total_btt;
        end

        if (pkt.operation == WRITE) begin
            if (expected_aw_q.size() == 0) begin
                `uvm_error("CHK_AW", "RTL issued AW, but Predictor queue is empty!")
            end else begin
                exp_aw = expected_aw_q.pop_front();
                if (exp_aw.awaddr != pkt.awaddr || exp_aw.awlen != pkt.awlen || exp_aw.awsize != pkt.awsize) begin
                    `uvm_error("CHK_AW", $sformatf("AW Mismatch! Exp: Addr=%0h Len=%0d | Got: Addr=%0h Len=%0d", 
                               exp_aw.awaddr, exp_aw.awlen, pkt.awaddr, pkt.awlen))
                end else begin
                    `uvm_info("CHK_AW", $sformatf("AW Match: %0h", pkt.awaddr), UVM_LOW)
                end
            end

            // --- FIX: VIRTUAL ALIGNMENT CHECK ---
            if (write_btt_remaining == write_total_btt) begin
                start_offset = pkt.awaddr % AXI_BUS_BYTES;
            end else begin
                start_offset = 0;
            end

            error_flag = 0;
            for (int i = 0; i <= pkt.awlen; i++) begin
                for (int byte_idx = 0; byte_idx < AXI_BUS_BYTES; byte_idx++) begin
                    if (i == 0 && byte_idx < start_offset) continue;
                    
                    if (write_btt_remaining > 0) begin
                        if (dre_fifo.size() == 0) begin
                            `uvm_error("CHK_DRE", "Write Monitor expected a byte, but DRE FIFO is empty!")
                        end else begin
                            bit [7:0] exp_byte = dre_fifo.pop_front();
                            bit [7:0] act_byte = pkt.wdata[i][byte_idx*8 +: 8];
                            
                            if (exp_byte != act_byte && !error_flag) begin
                                `uvm_error("CHK_W_DATA", $sformatf("Byte Mismatch at Beat %0d, Lane %0d! Exp: %0h | Got: %0h", 
                                           i, byte_idx, exp_byte, act_byte))
                                error_flag = 1; 
                            end
                        end
                        write_btt_remaining--;
                    end
                end
            end
            
            if (!error_flag) `uvm_info("CHK_W_DATA", "Write Burst Data Matched Perfectly!", UVM_LOW)
            
            if (pkt.bresp[0] != OKAY) begin
                `uvm_warning("CHK_ERR", $sformatf("Slave Error detected on Write Response! BRESP=%s", pkt.bresp[0]))
            end
        end
    endfunction
endclass
