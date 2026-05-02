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

class cdma_chk extends uvm_component;
    `uvm_component_utils(cdma_chk)

    cdma_reg_block reg_block;
    int AXI_BUS_BYTES; 

    // TLM Ports
    uvm_analysis_imp_cfg    #(master_seq_item, cdma_chk) cfg_export;
    uvm_analysis_imp_axi_rd #(slave_seq_item, cdma_chk) rd_export;
    uvm_analysis_imp_axi_wr #(slave_seq_item, cdma_chk) wr_export;

    // DRE Queues & Context Trackers
    cdma_transfer_cfg   cfg_q[$];      
    slave_seq_item      expected_ar_q[$]; 
    slave_seq_item      expected_aw_q[$]; 
    bit [127:0]         expected_wstrb_q[$];
    
    bit [7:0] dre_fifo[$];  
    int       read_btt_q[$];
    int       write_btt_q[$];
    
    // Trackers to know if we are on the first burst or a continuation
    int       read_total_btt = 0;
    int       read_btt_remaining = 0;
    int       write_total_btt = 0;
    int       write_btt_remaining = 0;

    function new(string name = "cdma_chk", uvm_component parent);
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
            
            for (int b = 0; b <= exp_aw.awlen; b++) begin
                expected_wstrb_q.push_back(get_expected_wstrb(b, v_da, exp_aw.awlen, current_burst_bytes));
            end
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

    // PORT 3: AXI WRITE MONITOR (Byte Comparator)
    // HELPER MATH: WSTRB Prediction
    virtual function bit [127:0] get_expected_wstrb(int beat, longint addr, int awlen, int burst_bytes);
        int start_offset = addr % AXI_BUS_BYTES;
        bit [127:0] strb = 0;

        if (awlen == 0) begin
            // Single beat burst: Mask the start AND the end
            strb = ((1 << burst_bytes) - 1) << start_offset;
        end else if (beat == 0) begin
            // First beat of a multi-beat burst: Mask the start
            strb = ((1 << (AXI_BUS_BYTES - start_offset)) - 1) << start_offset;
        end else if (beat == awlen) begin
            // Last beat: Mask the end
            int end_offset = (addr + burst_bytes) % AXI_BUS_BYTES;
            strb = (end_offset == 0) ? ((1 << AXI_BUS_BYTES) - 1) : ((1 << end_offset) - 1);
        end else begin
            // Middle beats: All valid
            strb = (1 << AXI_BUS_BYTES) - 1;
        end
        return strb;
    endfunction

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
// 2. Check Data Phase and WSTRB
            if (expected_aw_q.size() == 0) begin
                `uvm_error("CHK_W", "Write Data arrived, but no Read Data was buffered!")
            end else begin
                exp_aw = expected_aw_q.pop_front();
                error_flag = 0;
                
                // Loop through every beat of the AWLEN
                for (int i = 0; i <= pkt.awlen; i++) begin
                    
                    // Pop our mathematically perfect WSTRB prediction
                    bit [127:0] exp_strb = expected_wstrb_q.pop_front();
                    
                    // A) Check if RTL drove the correct Strobe
                    if (pkt.wstrobe[i] != exp_strb) begin
                        `uvm_error("CHK_WSTRB", $sformatf("WSTRB Mismatch at Beat %0d! Exp: %0h | Got: %0h", 
                                   i, exp_strb, pkt.wstrobe[i]))
                        error_flag = 1;
                    end
                    
                    // B) Check the Data Payload ONLY where the expected strobe is 1
                    for (int byte_idx = 0; byte_idx < AXI_BUS_BYTES; byte_idx++) begin
                        if (exp_strb[byte_idx] == 1'b1) begin
                            // This is a valid byte! Pop from DRE and compare.
                            if (dre_fifo.size() == 0) begin
                                `uvm_error("CHK_DRE", "DRE FIFO empty but expected valid data!")
                            end else begin
                                bit [7:0] exp_byte = dre_fifo.pop_front();
                                bit [7:0] act_byte = pkt.wdata[i][byte_idx*8 +: 8];
                                
                                if (exp_byte != act_byte && !error_flag) begin
                                    `uvm_error("CHK_W_DATA", $sformatf("Data Mismatch at Beat %0d, Lane %0d! Exp: %0h | Got: %0h", 
                                               i, byte_idx, exp_byte, act_byte))
                                    error_flag = 1; 
                                end
                            end
                        end
                    end
                end
                if (!error_flag) `uvm_info("CHK_W_DATA", "Write Burst Data & Strobes Matched Perfectly!", UVM_LOW) 
            end
            
            if (pkt.bresp[0] != OKAY) begin
                `uvm_warning("CHK_ERR", $sformatf("Slave Error detected on Write Response! BRESP=%s", pkt.bresp[0]))
            end
        end
    endfunction
endclass: cdma_chk
