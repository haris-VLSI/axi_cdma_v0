// User defined Parameter
parameter int AXI_DATA_WIDTH = 16;

typedef struct {
    bit [31:0] cr_cfg;
    bit [63:0] sa_cfg;  // 64-bit Source Address
    bit [63:0] da_cfg;  // 64-bit Destination Address
    bit [25:0] btt_cfg; // 26-bit Bytes to Transfer
    bit [1:0]  rd_burst;
    bit [1:0]  wr_burst;
} cdma_cfg_t;

// Update the class to accept the parameter for compile-time constants
class cdma_chk extends uvm_component;
    `uvm_component_utils(cdma_chk)

    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  rd_slave_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  wr_slave_af;

    cdma_reg_block  reg_block;
    config_obj            obj;
    cdma_cfg_t      cfg_tx_q[$];
    byte            expected_data_q[$];

    // Define local constants based on the parameter
    localparam BUS_BYTES = AXI_DATA_WIDTH;
    localparam STRB_WIDTH = BUS_BYTES;

    function new(string name="cdma_chk", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        master_af   = new("master_af", this);
        rd_slave_af = new("rd_slave_af", this);
        wr_slave_af = new("wr_slave_af", this);
        if(!uvm_config_db #(config_obj) :: get(null, "", "config_obj", obj))
            `uvm_fatal (get_full_name(), "config_db_not_accessable_in_checker");
    endfunction

    task main_phase(uvm_phase phase);
        fork
            get_config_data();
            reset_handler();
        join
    endtask

// --- Final Cleanup Check ---
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        
        // Check if all predicted data was actually moved to the destination
        if (expected_data_q.size() != 0) begin
            `uvm_error("EOT_CLEANUP", $sformatf("End of Test: %0d bytes still remaining in expected_data_q!", expected_data_q.size()))
        end else begin
            `uvm_info("EOT_CLEANUP", "End of Test: expected_data_q is empty. All data accounted for.", UVM_LOW)
        end
        
        // Check if all programmed configurations were processed
        if (cfg_tx_q.size() != 0) begin
            `uvm_error("EOT_CLEANUP", $sformatf("End of Test: %0d transfers were triggered but never completed!", cfg_tx_q.size()))
        end else begin
            `uvm_info("EOT_CLEANUP", "End of Test: All triggered transfers completed.", UVM_LOW)
        end
    endfunction

// --- Configuration Monitoring with Diagnostic Prints ---
    task get_config_data();
        master_seq_item cfg_pkt;
        cdma_cfg_t      cfg_tx;
        bit [31:0] sa_lsb, sa_msb, da_lsb, da_msb;

        forever begin
            master_af.get(cfg_pkt);
            // BTT write triggers the Simple DMA transfer
            if(cfg_pkt.awaddr == 'h28 && cfg_pkt.operation == WRITE) begin
                `uvm_info("CFG_DIAG", "--------------------------------------------------", UVM_LOW)
                `uvm_info("CFG_DIAG", "BTT TRIGGER DETECTED: Analyzing Control Register", UVM_LOW)
                
                cfg_tx.cr_cfg = reg_block.cdmacr.get_mirrored_value();
                
                // --- DEBUG PRINTS FOR KEYHOLE BITS ---
                `uvm_info("BIT_WATCH", $sformatf("Raw CDMACR: 0x%0h", cfg_tx.cr_cfg), UVM_LOW)
                `uvm_info("BIT_WATCH", $sformatf("Bit [4] (Read Keyhole Target): %b", cfg_tx.cr_cfg[4]), UVM_LOW)
                `uvm_info("BIT_WATCH", $sformatf("Bit [5] (Write Keyhole Target): %b", cfg_tx.cr_cfg[5]), UVM_LOW)
                
                // Temporarily assign based on your current mapping to see the impact
                cfg_tx.rd_burst = cfg_tx.cr_cfg[4] ? FIXED : INCR;
                cfg_tx.wr_burst = cfg_tx.cr_cfg[5] ? FIXED : INCR;

                `uvm_info("MODE_SEL", $sformatf("Predicted Mode -> Read: %s | Write: %s", 
                          (cfg_tx.rd_burst == FIXED) ? "FIXED" : "INCR",
                          (cfg_tx.wr_burst == FIXED) ? "FIXED" : "INCR"), UVM_LOW)

                sa_lsb = reg_block.sa.get_mirrored_value();
                sa_msb = reg_block.sa_msb.get_mirrored_value();
                da_lsb = reg_block.da.get_mirrored_value();
                da_msb = reg_block.da_msb.get_mirrored_value();
                cfg_tx.btt_cfg = cfg_pkt.wdata[0];

                cfg_tx.sa_cfg  = {sa_msb, sa_lsb};
                cfg_tx.da_cfg  = {da_msb, da_lsb};

                `uvm_info("CFG_DIAG", $sformatf("SA: 0x%0h | DA: 0x%0h | BTT: %0d", cfg_tx.sa_cfg, cfg_tx.da_cfg, cfg_tx.btt_cfg), UVM_LOW)
                `uvm_info("CFG_DIAG", "--------------------------------------------------", UVM_LOW)

                cfg_tx_q.push_back(cfg_tx);
                start_prediction(cfg_tx);
            end
        end
    endtask: get_config_data
    
    // --- dispatcher ---
    task start_prediction(cdma_cfg_t cfg);
        if (cfg.btt_cfg == 0) begin
            predict_internal_error();
            return;
        end

        fork
            // MM2S (Read) Dispatcher
            begin
                if (cfg.rd_burst == FIXED) predict_keyhole_read(cfg);
                else                       predict_incr_read(cfg);
            end

            // S2MM (Write) Dispatcher
            begin
                if (cfg.wr_burst == FIXED) predict_keyhole_write(cfg);
                else                       predict_incr_write(cfg);
            end
        join

        predict_interrupt();
        void'(cfg_tx_q.pop_front());
    endtask

    // --- Path 1: The Known-Good Incremental Logic ---
    task predict_incr_read(cdma_cfg_t cfg);
        bit [63:0] cur_addr = cfg.sa_cfg;
        int rem_btt = cfg.btt_cfg;
        while (rem_btt > 0) begin
            int split = calculate_4k_partition(cur_addr, rem_btt);
            predict_read_bus(cur_addr, split);
            cur_addr += split;
            rem_btt  -= split;
        end
    endtask

    task predict_incr_write(cdma_cfg_t cfg);
        bit [63:0] cur_addr = cfg.da_cfg;
        int rem_btt = cfg.btt_cfg;
        while (rem_btt > 0) begin
            int split = calculate_4k_partition(cur_addr, rem_btt);
            predict_write_bus(cur_addr, split);
            cur_addr += split;
            rem_btt  -= split;
        end
    endtask

    task predict_keyhole_read(cdma_cfg_t cfg);
        bit [63:0] bus_addr  = cfg.sa_cfg; 
        bit [63:0] virt_addr = cfg.sa_cfg; 
        bit [63:0] math_addr;
        int rem_btt = cfg.btt_cfg;
        bit is_first = 1'b1;
        
        while (rem_btt > 0) begin
            // Track the 4KB boundary using the incrementing virtual pointer
            int split = calculate_4k_partition(virt_addr, rem_btt);
            
            // KEY: Use bus_addr for the 1st burst, realigned base for the rest
            math_addr = (is_first) ? bus_addr : (bus_addr & ~(BUS_BYTES-1)); 
            
            `uvm_info("KEYHOLE_RD", $sformatf("Fixed BusAddr: 0x%0h | MathAddr: 0x%0h | Split: %0d", 
                      bus_addr, math_addr, split), UVM_MEDIUM)
            
            predict_read_bus(bus_addr, split, math_addr);
            
            virt_addr += split; // Advance virtual pointer to detect next boundary
            rem_btt   -= split;
            is_first   = 1'b0;
        end
    endtask

    task predict_keyhole_write(cdma_cfg_t cfg);
        bit [63:0] bus_addr  = cfg.da_cfg;
        bit [63:0] virt_addr = cfg.da_cfg;
        bit [63:0] math_addr;
        int rem_btt = cfg.btt_cfg;
        bit is_first = 1'b1;
        
        while (rem_btt > 0) begin
            int split = calculate_4k_partition(virt_addr, rem_btt);
            
            math_addr = (is_first) ? bus_addr : (bus_addr & ~(BUS_BYTES-1)); 
            
            `uvm_info("KEYHOLE_WR", $sformatf("Fixed BusAddr: 0x%0h | MathAddr: 0x%0h | Split: %0d", 
                      bus_addr, math_addr, split), UVM_MEDIUM)
            
            predict_write_bus(bus_addr, split, math_addr);
            
            virt_addr += split;
            rem_btt   -= split;
            is_first   = 1'b0;
        end
    endtask

    // DataMover ensures no burst crosses 4KB boundary[cite: 1]
    function int calculate_4k_partition(bit [63:0] addr, int rem_btt);
        int bytes_to_4k = 4096 - (addr % 4096);
        return (rem_btt < bytes_to_4k) ? rem_btt : bytes_to_4k;
    endfunction

    function bit [2:0] predict_size();
        return $clog2(BUS_BYTES); 
    endfunction

    //function bit [7:0] predict_length(int bytes, bit [2:0] size);
    //    return (bytes / (1 << size)) - 1;
    //endfunction
    function bit [7:0] predict_length(bit [63:0] addr, int bytes);
        int start_offset = addr % BUS_BYTES;
        int total_span   = start_offset + bytes;
        int num_beats;
        
        // Calculate number of beats (rounding up)
        num_beats = (total_span + BUS_BYTES - 1) / BUS_BYTES;
        
        return num_beats - 1;
    endfunction

    task predict_read_bus(bit [63:0] addr, int bytes, bit [63:0] math_addr = 0);
        slave_seq_item act_rd;
        int current_beat_start_lane;
        // Use math_addr for all internal stream calculations (length, lanes)
        bit [63:0] target_len_addr = (math_addr == 0) ? addr : math_addr;
        
        bit [2:0] exp_size = predict_size();
        bit [7:0] exp_len  = predict_length(target_len_addr, bytes);
        int bytes_pushed = 0;
        
        rd_slave_af.get(act_rd);
        
        `uvm_info("RD_CHECK", $sformatf("Read Tracking: BusAddr=0x%0h | MathAddr=0x%0h | ExpLen=%0d", 
                  addr, target_len_addr, exp_len), UVM_HIGH)
        
        // Physical Address Check
        if (act_rd.araddr !== addr)    `uvm_error("AR_MISMATCH", $sformatf("Exp ADDR: %h, Act: %h", addr, act_rd.araddr))
        // Realignment-aware Length Check
        if (act_rd.arlen  !== exp_len) `uvm_error("AR_MISMATCH", $sformatf("Exp ARLEN: %0d, Act: %0d", exp_len, act_rd.arlen))
        
        foreach (act_rd.rdata[beat]) begin
            check_read_response(act_rd.rresp[beat], beat);
            
            // Calculate lane start: use target_len_addr to handle realignment to Lane 0
            current_beat_start_lane = (beat == 0) ? (target_len_addr % BUS_BYTES) : 0;

            for (int i = current_beat_start_lane; i < BUS_BYTES; i++) begin
                if (bytes_pushed < bytes) begin
                    expected_data_q.push_back(act_rd.rdata[beat][(i*8) +: 8]);
                    bytes_pushed++;
                end
            end
        end
        `uvm_info("RD_DATA", $sformatf("Burst Complete: Pushed %0d bytes to expected_data_q", bytes_pushed), UVM_MEDIUM)
    endtask
    
    task predict_write_bus(bit [63:0] addr, int bytes, bit [63:0] math_addr = 0);
        slave_seq_item act_wr;
        bit [63:0] target_len_addr = (math_addr == 0) ? addr : math_addr;
        
        bit [2:0] exp_size = predict_size();
        bit [7:0] exp_len  = predict_length(target_len_addr, bytes);
        bit [STRB_WIDTH-1:0] exp_wstrb; 
        byte exp_byte, act_byte;

        wr_slave_af.get(act_wr);

        `uvm_info("WR_CHECK", $sformatf("Write Tracking: BusAddr=0x%0h | MathAddr=0x%0h | ExpLen=%0d", 
                  addr, target_len_addr, exp_len), UVM_HIGH)

        if (act_wr.awaddr !== addr)    `uvm_error("AW_MISMATCH", $sformatf("Exp AWADDR: %h, Act: %h", addr, act_wr.awaddr))
        if (act_wr.awlen  !== exp_len) `uvm_error("AW_MISMATCH", $sformatf("Exp AWLEN: %0d, Act: %0d", exp_len, act_wr.awlen))

        for (int beat = 0; beat <= exp_len; beat++) begin
            // predict_wstrb MUST use target_len_addr to correctly mask realigned lanes
            exp_wstrb = predict_wstrb(target_len_addr, beat, exp_len, bytes);
            
            if (act_wr.wstrobe[beat] !== exp_wstrb)
                `uvm_error("WSTRB_MISMATCH", $sformatf("Beat %0d | Exp: %b, Act: %b", beat, exp_wstrb, act_wr.wstrobe[beat]))
            else
                `uvm_info("WSTRB_MATCH", $sformatf("Beat %0d | Exp: %b, Act: %b", beat, exp_wstrb, act_wr.wstrobe[beat]),UVM_LOW)

            for (int i = 0; i < BUS_BYTES; i++) begin
                if (exp_wstrb[i]) begin
                    // Safety check to prevent popping from empty queue during desync
                    if (expected_data_q.size() == 0) begin
                        `uvm_error("QUEUE_EMPTY", $sformatf("Beat %0d Lane %0d: Data missing from Read side!", beat, i))
                        return; 
                    end
                    
                    exp_byte = expected_data_q.pop_front();
                    act_byte = act_wr.wdata[beat][(i*8) +: 8];
                    
                    if (act_byte !== exp_byte)
                        `uvm_error("WDATA_MISMATCH", $sformatf("Beat %0d Byte %0d | Exp: %h, Act: %h", beat, i, exp_byte, act_byte))
                    else
                        `uvm_info("WDATA_MATCH", $sformatf("Beat %0d Byte %0d | Exp: %h, Act: %h", beat, i, exp_byte, act_byte),UVM_LOW)
                end
            end
        end
        check_write_response(act_wr);
    endtask

    function bit [STRB_WIDTH-1:0] predict_wstrb(bit [63:0] addr, int beat, int total_len, int total_bytes);
        bit [STRB_WIDTH-1:0] strobe = {STRB_WIDTH{1'b1}}; 
        int start_offset = addr % BUS_BYTES;
        int end_offset   = (addr + total_bytes) % BUS_BYTES;

        // Mask lower lanes for unaligned start[cite: 1]
        if (beat == 0) strobe = strobe << start_offset;

        // Mask upper lanes for unaligned end[cite: 1]
        if (beat == total_len && end_offset != 0) begin
            strobe &= ({STRB_WIDTH{1'b1}} >> (BUS_BYTES - end_offset));
        end
        return strobe;
    endfunction

    task predict_internal_error();
        bit [31:0] err_status = reg_block.cdmasr.get_mirrored_value();
        while (reg_block.cdmasr.is_busy())begin
            @(posedge obj.mas_if[0].aclk);
        end
        err_status[4] = 1'b1; // DMAIntErr[cite: 1]
        err_status[1] = 1'b1; // Idle[cite: 1]
        void'(reg_block.cdmasr.predict(err_status));
        `uvm_info("STATUS_UPD", $sformatf("BTT=0 detected. Mirrored CDMASR: 0x%h", err_status), UVM_LOW)
    endtask

// Task to predict status register updates and interrupt pin assertion
    task predict_interrupt();
        bit [31:0] current_cr     = reg_block.cdmacr.get_mirrored_value();
        bit [31:0] next_sr        = reg_block.cdmasr.get_mirrored_value();
        bit        expect_introut = 1'b0;

        `uvm_info("INT_PRED", "Transfer complete: Calculating interrupt and status response...", UVM_LOW)

        // 1. Predict Status Register Bits
        next_sr[1]  = 1'b1; // Idle: Transfer completed
        next_sr[12] = 1'b1; // IOC_Irq: Interrupt on Complete

        // 2. Predict Interrupt Pin (cdma_introut)
        // Signal drives High if (Event occurred AND Event enabled)[cite: 1]
        if (current_cr[12] && next_sr[12]) begin // IOC_IrqEn & IOC_Irq[cite: 1]
            expect_introut = 1'b1;
        end
        
        // Handling Error Interrupts[cite: 1]
        if (current_cr[14] && next_sr[14]) begin // Err_IrqEn & Err_Irq[cite: 1]
            expect_introut = 1'b1;
        end

        while (reg_block.cdmasr.is_busy()) begin
            @(posedge obj.mas_if[0].aclk); 
        end
        
        // 3. Update RAL Mirror[cite: 1]
        void'(reg_block.cdmasr.predict(next_sr));

        // 4. Log the prediction
        `uvm_info("INT_PRED", $sformatf("Status predicted: 0x%h | cdma_introut predicted: %b", next_sr, expect_introut), UVM_LOW)
        // Wait for a maximum amount of time for the interrupt to hit
        if (expect_introut) begin
            fork
                begin
                    // Wait for the physical pin on your virtual interface (obj.mas_if[0])
                    wait(obj.mas_if[0].cdma_introut === 1'b1);
                    `uvm_info("INT_PASS", "Interrupt signal observed on bus", UVM_LOW)
                end
                begin
                    // Timeout logic: if it doesn't happen in 100 clock cycles, fail
                    repeat(100) @(posedge obj.mas_if[0].aclk);
                    `uvm_error("INT_TIMEOUT", "Interrupt failed to assert within 100 cycles!")
                end
            join_any
            disable fork;
        end 
        // Check the actual cdma_introut pin
        if (obj.mas_if[0].cdma_introut !== expect_introut)
            `uvm_error("INT_MISMATCH", "Interrupt signal mismatch!")
    endtask

    // --- Reset Logic ---
    task reset_handler();
        forever begin
            // 1. Wait for either Hardware Reset (Active Low) or Software Reset bit (Self-clearing)
            // Hardware reset: s_axi_lite_aresetn
            // Software reset: CDMACR Bit 2
            wait(obj.mas_if[0].areset_n === 1'b0 || reg_block.cdmacr.Reset.get_mirrored_value() == 1'b1);
            
            `uvm_info("RESET_EXE", "Reset Event Detected: Flushing all internal pipes", UVM_LOW)
            
            // 2. Clear internal queues immediately to prevent stale data matching
            cfg_tx_q.delete();
            expected_data_q.delete();
            
            // 3. Reset the RAL model to its power-on state
            reg_block.reset(); 

            // 4. Wait for the reset condition to be released
            // Note: Software reset is self-clearing once the internal reset is complete
            wait(obj.mas_if[0].areset_n === 1'b1);
            
            // Wait for software reset bit to clear if it was triggered
            if (reg_block.cdmacr.Reset.get_mirrored_value() == 1'b1) begin
                wait(reg_block.cdmacr.Reset.get_mirrored_value() == 1'b0);
            end

            `uvm_info("RESET_EXE", "Reset Release: Checker is synchronized and ready.", UVM_LOW)
        end
    endtask: reset_handler

    // --- Specific Write Response Verification ---
    task check_write_response(slave_seq_item act_wr);
        // AXI Responses: 00=OKAY, 01=EXOKAY, 10=SLVERR, 11=DECERR
        case (act_wr.bresp)
            2'b00, 2'b01: begin
                `uvm_info("WR_RESP", $sformatf("Write Transaction OKAY (0x%h)", act_wr.bresp), UVM_LOW)
            end
            
            2'b10: begin // SLVERR
                `uvm_error("WR_RESP_ERR", "AXI Slave Error (SLVERR) detected on S2MM interface!")
                predict_specific_error(5); // Set Bit 5: DMASlvErr
            end
            
            2'b11: begin // DECERR
                `uvm_error("WR_RESP_ERR", "AXI Decode Error (DECERR) detected on S2MM interface!")
                predict_specific_error(6); // Set Bit 6: DMADecErr
            end
            
            default: begin
                `uvm_error("WR_RESP_ERR", $sformatf("Unknown AXI Response received: 0x%h", act_wr.bresp))
            end
        endcase
    endtask

// --- Specific Read Response Verification ---
    task check_read_response(bit [1:0] rresp, int beat_idx);
        case (rresp)
            2'b00, 2'b01: begin
                // OKAY or EXOKAY - No action needed
            end
            
            2'b10: begin // SLVERR
                `uvm_error("RD_RESP_ERR", $sformatf("AXI Slave Error (SLVERR) on Read Beat %0d!", beat_idx))
                predict_specific_error(5); // Set Bit 5: DMASlvErr
            end
            
            2'b11: begin // DECERR
                `uvm_error("RD_RESP_ERR", $sformatf("AXI Decode Error (DECERR) on Read Beat %0d!", beat_idx))
                predict_specific_error(6); // Set Bit 6: DMADecErr
            end
            
            default: begin
                `uvm_error("RD_RESP_ERR", $sformatf("Unknown RRESP on Beat %0d: 0x%h", beat_idx, rresp))
            end
        endcase
    endtask

    // Updated helper to set specific error bits in CDMASR
    task predict_specific_error(int bit_idx);
        bit [31:0] err_status = reg_block.cdmasr.get_mirrored_value();
        
        while (reg_block.cdmasr.is_busy()) begin
            @(posedge obj.mas_if[0].aclk); 
        end
        // 1. Set the specific error bit (5 for Slave, 6 for Decode)
        err_status[bit_idx] = 1'b1; 
        
        // 2. CDMA always transitions to Idle when a fatal error occurs
        err_status[1] = 1'b1; 
        
        void'(reg_block.cdmasr.predict(err_status));
        `uvm_info("STATUS_UPD", $sformatf("Predicted CDMASR update for Bit %0d: 0x%h", bit_idx, err_status), UVM_LOW)
    endtask
endclass: cdma_chk
