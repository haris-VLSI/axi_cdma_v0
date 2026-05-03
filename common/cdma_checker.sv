// User defined Parameter
parameter int AXI_DATA_WIDTH = 128;

typedef struct {
    bit [31:0] cr_cfg;
    bit [63:0] sa_cfg;  // 64-bit Source Address
    bit [63:0] da_cfg;  // 64-bit Destination Address
    bit [25:0] btt_cfg; // 26-bit Bytes to Transfer
} cdma_cfg_t;

// Update the class to accept the parameter for compile-time constants
class cdma_chk extends uvm_component;
    `uvm_component_param_utils(cdma_chk)

    // Define local constants based on the parameter
    localparam BUS_BYTES = AXI_DATA_WIDTH / 8;
    localparam STRB_WIDTH = BUS_BYTES;

    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  rd_slave_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  wr_slave_af;

    cdma_reg_block  reg_block;
    cdma_cfg_t      cfg_tx_q[$];
    byte            expected_data_q[$];

    function new(string name="cdma_chk", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        master_af   = new("master_af", this);
        rd_slave_af = new("rd_slave_af", this);
        wr_slave_af = new("wr_slave_af", this);
    endfunction

    task main_phase(uvm_phase phase);
        get_config_data();
    endtask

    // --- Configuration Monitoring ---
    task get_config_data();
        master_seq_item cfg_pkt;
        cdma_cfg_t      cfg_tx;
        bit [31:0] sa_lsb, sa_msb, da_lsb, da_msb;

        forever begin
            master_af.get(cfg_pkt);
            // BTT write triggers the Simple DMA transfer
            if(cfg_pkt.awaddr == 'h28 && cfg_pkt.operation == WRITE) begin
                `uvm_info("CFG_CAP", "--------------------------------------------------", UVM_LOW)
                `uvm_info("CFG_CAP", "BTT TRIGGER DETECTED: Latched Configuration", UVM_LOW)
                
                cfg_tx.cr_cfg  = reg_block.cdmacr.get_mirrored_value();
                sa_lsb = reg_block.sa.get_mirrored_value();
                sa_msb = reg_block.sa_msb.get_mirrored_value();
                da_lsb = reg_block.da.get_mirrored_value();
                da_msb = reg_block.da_msb.get_mirrored_value();
                cfg_tx.btt_cfg = cfg_pkt.wdata[0][25:0]; // Ensure 26-bit slice
                
                cfg_tx.sa_cfg  = {sa_msb, sa_lsb};
                cfg_tx.da_cfg  = {da_msb, da_lsb};

                `uvm_info("CFG_CAP", $sformatf("SA Combined: 0x%0h (MSB: 0x%h, LSB: 0x%h)", cfg_tx.sa_cfg, sa_msb, sa_lsb), UVM_LOW)
                `uvm_info("CFG_CAP", $sformatf("DA Combined: 0x%0h (MSB: 0x%h, LSB: 0x%h)", cfg_tx.da_cfg, da_msb, da_lsb), UVM_LOW)
                `uvm_info("CFG_CAP", $sformatf("Control: 0x%h | BTT: %0d bytes", cfg_tx.cr_cfg, cfg_tx.btt_cfg), UVM_LOW)
                `uvm_info("CFG_CAP", "--------------------------------------------------", UVM_LOW)

                cfg_tx_q.push_back(cfg_tx);
                start_prediction(cfg_tx);
            end
        end
    endtask

    task start_prediction(cdma_cfg_t cfg);
        bit [63:0] current_sa = cfg.sa_cfg;
        bit [63:0] current_da = cfg.da_cfg;
        int remaining_bytes   = cfg.btt_cfg;

        if (remaining_bytes == 0) begin
            `uvm_info("PRED_STATUS", "BTT=0 detected: Predicting Internal Error (DMAIntErr)[cite: 1]", UVM_LOW)
            predict_internal_error();
            return;
        end

        `uvm_info("PRED_STATUS", $sformatf("Initiating Burst Sequencer for BTT: %0d", remaining_bytes), UVM_LOW)

        while (remaining_bytes > 0) begin
            int bytes_in_burst = calculate_4k_partition(current_sa, remaining_bytes);
            
            `uvm_info("PARTITION", $sformatf("Splitting Burst: StartAddr=0x%0h, Size=%0d bytes", current_sa, bytes_in_burst), UVM_LOW)

            predict_read_bus(current_sa, bytes_in_burst);
            predict_write_bus(current_da, bytes_in_burst);
            
            current_sa      += bytes_in_burst;
            current_da      += bytes_in_burst;
            remaining_bytes -= bytes_in_burst;
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

    function bit [7:0] predict_length(int bytes, bit [2:0] size);
        return (bytes / (1 << size)) - 1;
    endfunction

    task predict_read_bus(bit [63:0] addr, int bytes);
        slave_seq_item act_rd;
        bit [2:0] exp_size = predict_size();
        bit [7:0] exp_len  = predict_length(bytes, exp_size);
        
        rd_slave_af.get(act_rd);
        
        `uvm_info("RD_CHECK", $sformatf("Checking Read Signal: Exp Addr=0x%0h, Len=%0d, Size=%0d", addr, exp_len, exp_size), UVM_LOW)
        
        if (act_rd.araddr !== addr) `uvm_error("AR_MISMATCH", $sformatf("Exp ARADDR: %h, Act: %h", addr, act_rd.araddr))
        if (act_rd.arlen  !== exp_len) `uvm_error("AR_MISMATCH", $sformatf("Exp ARLEN: %0d, Act: %0d", exp_len, act_rd.arlen))
        
        foreach (act_rd.rdata[beat]) begin
            for (int i = 0; i < BUS_BYTES; i++) begin
                expected_data_q.push_back(act_rd.rdata[beat][(i*8) +: 8]);
            end
            `uvm_info("RD_DATA", $sformatf("Beat %0d: Captured %0d bytes into expected pipe", beat, BUS_BYTES), UVM_HIGH)
        end
    endtask

    task predict_write_bus(bit [63:0] addr, int bytes);
        slave_seq_item act_wr;
        bit [2:0] exp_size = predict_size();
        bit [7:0] exp_len  = predict_length(bytes, exp_size);
        bit [STRB_WIDTH-1:0] exp_wstrb; 

        wr_slave_af.get(act_wr);

        `uvm_info("WR_CHECK", $sformatf("Checking Write Signal: Exp Addr=0x%0h, Len=%0d", addr, exp_len), UVM_LOW)

        if (act_wr.awaddr !== addr) `uvm_error("AW_MISMATCH", $sformatf("Exp AWADDR: %h, Act: %h", addr, act_wr.awaddr))
        if (act_wr.awlen  !== exp_len) `uvm_error("AW_MISMATCH", $sformatf("Exp AWLEN: %0d, Act: %0d", exp_len, act_wr.awlen))

        for (int beat = 0; beat <= exp_len; beat++) begin
            exp_wstrb = predict_wstrb(addr, beat, exp_len, bytes);
            
            `uvm_info("STRB_DEBUG", $sformatf("Beat %0d | Predicted WSTROBE: %b", beat, exp_wstrb), UVM_HIGH)

            if (act_wr.wstrobe[beat] !== exp_wstrb)
                `uvm_error("WSTRB_MISMATCH", $sformatf("Beat %0d | Exp: %b, Act: %b", beat, exp_wstrb, act_wr.wstrobe[beat]))

            for (int i = 0; i < BUS_BYTES; i++) begin
                if (exp_wstrb[i]) begin
                    byte exp_byte = expected_data_q.pop_front();
                    byte act_byte = act_wr.wdata[beat][(i*8) +: 8];
                    if (act_byte !== exp_byte)
                        `uvm_error("WDATA_MISMATCH", $sformatf("Beat %0d Byte %0d | Exp: %h, Act: %h", beat, i, exp_byte, act_byte))
                end
            end
        end
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
        err_status[4] = 1'b1; // DMAIntErr[cite: 1]
        err_status[1] = 1'b1; // Idle[cite: 1]
        void'(reg_block.cdmasr.predict(err_status));
        `uvm_info("STATUS_UPD", $sformatf("BTT=0 detected. Mirrored CDMASR: 0x%h", err_status), UVM_LOW)
    endtask
endclass: cdma_chk

/*
parameter int AXI_DATA_WIDTH = 128;
typedef struct {
    bit [31:0] cr_cfg;
    bit [63:0] sa_cfg;  // 64-bit Source Address
    bit [63:0] da_cfg;  // 64-bit Destination Address
    bit [25:0] btt_cfg; // 26-bit Bytes to Transfer
} cdma_cfg_t;

// 1. Update the class to accept a parameter for Data Width
class cdma_chk extends uvm_component;
    `uvm_component_param_utils(cdma_chk)

    // 2. Define local constants based on the parameter
    localparam BUS_BYTES = AXI_DATA_WIDTH / 8;
    localparam STRB_WIDTH = BUS_BYTES;

    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  rd_slave_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  wr_slave_af;

    cdma_reg_block  reg_block;
    cdma_cfg_t      cfg_tx_q[$];
    byte            expected_data_q[$];

    function new(string name="cdma_chk", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        master_af   = new("master_af", this);
        rd_slave_af = new("rd_slave_af", this);
        wr_slave_af = new("wr_slave_af", this);
    endfunction

    task main_phase(uvm_phase phase);
        get_config_data();
    endtask

    // --- Configuration Monitoring ---
    task get_config_data();
        master_seq_item cfg_pkt;
        cdma_cfg_t      cfg_tx;
        bit [31:0] sa_lsb, sa_msb, da_lsb, da_msb;

        forever begin
            master_af.get(cfg_pkt);
            if(cfg_pkt.awaddr == 'h28 && cfg_pkt.operation == WRITE) begin
                cfg_tx.cr_cfg  = reg_block.cdmacr.get_mirrored_value();
                sa_lsb = reg_block.sa.get_mirrored_value();
                sa_msb = reg_block.sa_msb.get_mirrored_value();
                da_lsb = reg_block.da.get_mirrored_value();
                da_msb = reg_block.da_msb.get_mirrored_value();
                cfg_tx.btt_cfg = cfg_pkt.wdata[0];
                
                cfg_tx.sa_cfg  = {sa_msb, sa_lsb};
                cfg_tx.da_cfg  = {da_msb, da_lsb};

                `uvm_info("CFG_CAP", $sformatf("SAs: LSB=%h, MSB=%h | Combined SA=0x%0h", sa_lsb, sa_msb, cfg_tx.sa_cfg), UVM_LOW)
                `uvm_info("CFG_CAP", $sformatf("DAs: LSB=%h, MSB=%h | Combined DA=0x%0h", da_lsb, da_msb, cfg_tx.da_cfg), UVM_LOW)
                `uvm_info("CFG_CAP", $sformatf("CR=%h, BTT=%0d", cfg_tx.cr_cfg, cfg_tx.btt_cfg), UVM_LOW)

                cfg_tx_q.push_back(cfg_tx);
                start_prediction(cfg_tx);
            end
        end
    endtask

    task start_prediction(cdma_cfg_t cfg);
        bit [63:0] current_sa = cfg.sa_cfg;
        bit [63:0] current_da = cfg.da_cfg;
        int remaining_bytes   = cfg.btt_cfg;

        if (remaining_bytes == 0) begin
            predict_internal_error();
            return;
        end

        while (remaining_bytes > 0) begin
            int bytes_in_burst = calculate_4k_partition(current_sa, remaining_bytes);
            predict_read_bus(current_sa, bytes_in_burst);
            predict_write_bus(current_da, bytes_in_burst);
            
            current_sa      += bytes_in_burst;
            current_da      += bytes_in_burst;
            remaining_bytes -= bytes_in_burst;
        end
    endtask

    function int calculate_4k_partition(bit [63:0] addr, int rem_btt);
        int bytes_to_4k = 4096 - (addr % 4096);
        return (rem_btt < bytes_to_4k) ? rem_btt : bytes_to_4k;
    endfunction

    function bit [2:0] predict_size();
        return $clog2(BUS_BYTES); 
    endfunction

    function bit [7:0] predict_length(int bytes, bit [2:0] size);
        return (bytes / (1 << size)) - 1;
    endfunction

    task predict_read_bus(bit [63:0] addr, int bytes);
        slave_seq_item act_rd;
        bit [2:0] exp_size = predict_size();
        bit [7:0] exp_len  = predict_length(bytes, exp_size);
        
        rd_slave_af.get(act_rd);
        if (act_rd.araddr !== addr) `uvm_error("AR_MISMATCH", $sformatf("Exp: %h, Act: %h", addr, act_rd.araddr))
        
        foreach (act_rd.rdata[beat]) begin
            for (int i = 0; i < BUS_BYTES; i++) begin
                expected_data_q.push_back(act_rd.rdata[beat][(i*8) +: 8]);
            end
        end
    endtask

    task predict_write_bus(bit [63:0] addr, int bytes);
        slave_seq_item act_wr;
        bit [2:0] exp_size = predict_size();
        bit [7:0] exp_len  = predict_length(bytes, exp_size);
        // FIX: Variable is now declared using the localparam
        bit [STRB_WIDTH-1:0] exp_wstrb; 

        wr_slave_af.get(act_wr);

        for (int beat = 0; beat <= exp_len; beat++) begin
            exp_wstrb = predict_wstrb(addr, beat, exp_len, bytes);
            
            if (act_wr.wstrobe[beat] !== exp_wstrb)
                `uvm_error("WSTRB_MISMATCH", $sformatf("Beat %0d | Exp: %b, Act: %b", beat, exp_wstrb, act_wr.wstrobe[beat]))

            for (int i = 0; i < BUS_BYTES; i++) begin
                if (exp_wstrb[i]) begin
                    byte exp_byte = expected_data_q.pop_front();
                    byte act_byte = act_wr.wdata[beat][(i*8) +: 8];
                    if (act_byte !== exp_byte)
                        `uvm_error("WDATA_MISMATCH", $sformatf("Beat %0d Byte %0d | Exp: %h, Act: %h", beat, i, exp_byte, act_byte))
                end
            end
        end
    endtask

    // Helper for Unaligned Strobes (Generic for any bus width)
    function bit [STRB_WIDTH-1:0] predict_wstrb(bit [63:0] addr, int beat, int total_len, int total_bytes);
        bit [STRB_WIDTH-1:0] strobe = {STRB_WIDTH{1'b1}}; 
        int start_offset = addr % BUS_BYTES;
        int end_offset   = (addr + total_bytes) % BUS_BYTES;

        if (beat == 0) strobe = strobe << start_offset;

        if (beat == total_len) begin
            if (end_offset != 0) strobe &= ({STRB_WIDTH{1'b1}} >> (BUS_BYTES - end_offset));
        end
        return strobe;
    endfunction

    task predict_internal_error();
        bit [31:0] err_status = reg_block.cdmasr.get_mirrored_value();
        err_status[4] = 1'b1; // DMAIntErr
        err_status[1] = 1'b1; // Idle
        void'(reg_block.cdmasr.predict(err_status));
    endtask
endclass: cdma_chk
