typedef struct {
    bit [31:0] cr_cfg;
    bit [31:0] sa_cfg;
    bit [31:0] da_cfg;
    bit [25:0] btt_cfg; // 26-bit BTT as per PG034
} cdma_cfg_t;

class cdma_chk extends uvm_component;
    `uvm_component_utils(cdma_chk)

    // TLM FIFOs for data collection
    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  rd_slave_af;
    uvm_tlm_analysis_fifo #(slave_seq_item)  wr_slave_af;

    cdma_reg_block  reg_block;
    cdma_cfg_t      cfg_tx_q[$];
    byte            expected_data_q[$];

    // Local configuration (matches Vivado IDE settings)
    int bus_width_bytes = 4; // Assuming 32-bit data width

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
        forever begin
            master_af.get(cfg_pkt);
            
            // Writing to BTT register (offset 28h) initiates the transfer[cite: 1]
            if(cfg_pkt.awaddr == 'h28 && cfg_pkt.write) begin
                cfg_tx.cr_cfg  = reg_block.cdmacr.get_mirrored_value();
                cfg_tx.sa_cfg  = reg_block.sa.get_mirrored_value();
                cfg_tx.da_cfg  = reg_block.da.get_mirrored_value();
                cfg_tx.btt_cfg = cfg_pkt.wdata[0][25:0]; // Ensure 26-bit slice[cite: 1]

                `uvm_info("CHK", "CDMA Transfer Triggered via BTT write", UVM_LOW)
                cfg_tx_q.push_back(cfg_tx);
                
                // Orchestrate the prediction for this command
                start_prediction(cfg_tx);
            end
        end
    endtask

    // --- Prediction Orchestrator ---
    task start_prediction(cdma_cfg_t cfg);
        bit [31:0] current_sa = cfg.sa_cfg;
        bit [31:0] current_da = cfg.da_cfg;
        int remaining_bytes   = cfg.btt_cfg;

        // BTT of 0 is illegal and triggers a DMA internal error[cite: 1]
        if (remaining_bytes == 0) begin
            predict_internal_error();
            return;
        end

        `uvm_info("STRT_PRED", $sformatf("Processing Command: SA=%h, DA=%h, BTT=%0d", 
                  current_sa, current_da, remaining_bytes), UVM_LOW)

        // Partition BTT into multiple bursts if 4KB boundaries are crossed[cite: 1]
        while (remaining_bytes > 0) begin
            int bytes_in_burst = calculate_4k_partition(current_sa, remaining_bytes);
            
            // Predict signal behavior for this specific burst
            predict_read_bus(current_sa, bytes_in_burst);
            predict_write_bus(current_da, bytes_in_burst);
            
            // Update pointers for the next partitioned burst[cite: 1]
            current_sa      += bytes_in_burst;
            current_da      += bytes_in_burst;
            remaining_bytes -= bytes_in_burst;
        end
    endtask

    // --- Signal and Address Math ---

    // AXI bursts cannot cross 4KB boundaries[cite: 1]
    
    function int calculate_4k_partition(bit [31:0] addr, int rem_btt);
        int bytes_to_4k = 4096 - (addr % 4096); 
        return (rem_btt < bytes_to_4k) ? rem_btt : bytes_to_4k;
    endfunction

    // Encodes ARSIZE/AWSIZE based on byte width
    function bit [2:0] predict_size();
        // size = log2(bus_width_bytes)
        return $clog2(bus_width_bytes); 
    endfunction

    // Standard AXI length: $$Length = (\frac{TotalBytes}{BytesPerBeat}) - 1$$
    function bit [7:0] predict_length(int bytes, bit [2:0] size);
        int bytes_per_beat = (1 << size);
        return (bytes / bytes_per_beat) - 1;
    endfunction

    // --- Error Prediction ---
    task predict_internal_error();
        bit [31:0] err_status = reg_block.cdmasr.get_mirrored_value();
        
        err_status[4] = 1'b1; // Set DMAIntErr (Bit 4)[cite: 1]
        err_status[1] = 1'b1; // Set Idle (Bit 1) on halt[cite: 1]
        
        void'(reg_block.cdmasr.predict(err_status)); // Update RAL mirrored value[cite: 1]
        `uvm_error("BTT_ZERO", "BTT write of 0 detected. CDMA Internal Error predicted.")
    endtask

    // --- Placeholders for Signal Matching ---
    task predict_read_bus(bit [31:0] addr, int bytes);
        // Next stage: Match ARLEN, ARSIZE, and collect RDATA into expected_data_q
    endtask

    task predict_write_bus(bit [31:0] addr, int bytes);
        // Next stage: Match AWADDR, AWLEN, and verify WDATA/WSTRB
    endtask

endclass: cdma_chk

/*
typedef struct {
    bit [31:0] cr_cfg;
    bit [31:0] sa_cfg;
    bit [31:0] da_cfg;
    bit [25:0] btt_cfg;
} cdma_cfg_t;

class cdma_chk extends uvm_component;
    `uvm_component_utils(cdma_chk)

    uvm_tlm_analysis_fifo #(master_seq_item) master_af;
    uvm_tlm_analysis_fifo #(slave_seq_item) rd_slave_af;
    uvm_tlm_analysis_fifo #(slave_seq_item) wr_slave_af;

    cdma_reg_block      reg_block;
    master_seq_item     cfg_pkt;
    cdma_cfg_t          cfg_tx_q[$];
    cdma_cfg_t          cfg_tx;

    byte                expected_data_q[$];

    function new(string name="cdma_chk",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        master_af = new("master_af",this);
        rd_slave_af = new("rd_slave_af",this);
        wr_slave_af = new("wr_slave_af",this);
    endfunction

    task main_phase(uvm_phase phase);
        get_config_data();
    endtask
    
    task get_config_data();
        forever begin
            master_af.get(cfg_pkt);
            `uvm_info("CHECKER",$sformatf("CFG_PKT_from_the_checker: %s",cfg_pkt.sprint()),UVM_LOW)
            if(cfg_pkt.awaddr == 'h28) begin
                `uvm_info("CHECKER",$sformatf("BTT_PKT_from_the_checker: %s",cfg_pkt.sprint()),UVM_LOW)
                cfg_tx.cr_cfg = reg_block.cdmacr.get_mirrored_value();
                cfg_tx.sa_cfg = reg_block.sa.get_mirrored_value();
                cfg_tx.da_cfg = reg_block.da.get_mirrored_value();
                cfg_tx.btt_cfg = cfg_pkt.wdata[0];
            //for back to back transaction, stores the cfg data
                cfg_tx_q.push_back(cfg_tx);
                //$displayh("CONFIGURE_TX_Q:\n%p",cfg_tx_q);
                start_prediction(cfg_tx);
            end
        end
    endtask

    task start_prediction(cdma_cfg_t cfg);
        bit [31:0] current_sa = cfg.sa_cfg;
        bit [31:0] current_da = cfg.da_cfg;
        int remaining_bytes   = cfg.btt_cfg;
    
        // BTT of 0 is not allowed and causes a DMA Internal Error
        if (remaining_bytes == 0) begin
            predict_internal_error(); 
            return;
        end
    
        `uvm_info("STRT_PRED", $sformatf("Starting Prediction: SA=%h, DA=%h, BTT=%0d", 
                  current_sa, current_da, remaining_bytes), UVM_LOW)
    
        // Loop until all bytes from the BTT register are accounted for
        while (remaining_bytes > 0) begin
            // 1. Calculate how many bytes this specific AXI burst will move
            int bytes_in_this_burst = calculate_4k_partition(current_sa, remaining_bytes);
            
            `uvm_info("PARTITION", $sformatf("Burst Partition: %0d bytes", bytes_in_this_burst), UVM_HIGH)
    
            // 2. Predict Read side (ARADDR, ARLEN, etc.)
            predict_read_bus(current_sa, bytes_in_this_burst);
            
            // 3. Predict Write side (AWADDR, AWLEN, WSTRB, etc.)
            predict_write_bus(current_da, bytes_in_this_burst);
            
            // 4. Update pointers for the next burst in this transfer
            current_sa      += bytes_in_this_burst;
            current_da      += bytes_in_this_burst;
            remaining_bytes -= bytes_in_this_burst;
        end
    endtask
    
    // Functional method to ensure no burst crosses a 4KB boundary
    function int calculate_4k_partition(bit [31:0] addr, int rem_btt);
        int bytes_to_4k;
        int max_burst_bytes;
        
        // AXI protocol: bursts cannot cross 4KB (0x1000) boundaries
        bytes_to_4k = 4096 - (addr % 4096);
        
        // The burst size is the lesser of: 
        // a) Remaining BTT 
        // b) Bytes available until the next 4K boundary
        if (rem_btt < bytes_to_4k) 
            return rem_btt;
        else 
            return bytes_to_4k;
    endfunction
    
    // Task to predict register status when BTT = 0 is detected
    task predict_internal_error();
        bit [31:0] next_status;

        // 1. Fetch current mirrored status to preserve other bits (like SGInclid)
        next_status = reg_block.cdmasr.get_mirrored_value();

        // 2. Set DMAIntErr (Bit 4): BTT of 0 causes a DMA internal error
        next_status[4] = 1'b1;

        // 3. Set Idle (Bit 1): On error detection, CDMA halts gracefully
        // Per PG034, IDLE bit is set when the CDMA has completed shutdown
        next_status[1] = 1'b1;

        // 4. Update the RAL model mirrored value
        // This allows your reg_predictor/checker to compare actual vs. predicted
        void'(reg_block.cdmasr.predict(next_status));

        `uvm_info("PRED_ERR", $sformatf("BTT=0 detected. Predicted CDMASR: %h (DMAIntErr & Idle set)", next_status), UVM_LOW)
    endtask
    
    function bit [2:0] predict_size();
        // Logic based on C_M_AXI_DATA_WIDTH
    endfunction
    
    function bit [7:0] predict_length(int bytes, bit [2:0] size);
        // bytes / (2^size) - 1
    endfunction
endclass: cdma_chk
