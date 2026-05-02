class base_master_sequence extends uvm_sequence #(reg_seq_item);
  `uvm_object_utils (base_master_sequence)

  uvm_phase             phase;
  cdma_reg_block        reg_block;
  uvm_status_e          status;
  uvm_reg_data_t        cdmasr_data;
  uvm_reg_data_t        cdmacr_data;
  uvm_reg_data_t        temp_data;
  reg_seq_item          regi;
  config_obj            obj;

  function new (string name = "base_master_sequence");
     super.new (name);
  endfunction

    task pre_body();
        phase   =   get_starting_phase();
        if(phase != null) begin
            phase.raise_objection(this);
            `uvm_info(get_full_name(),"inside_pre_body", UVM_MEDIUM)
        end
    endtask
    task post_body();
        if(phase != null) begin
            `uvm_info(get_full_name(),"inside_post_body", UVM_MEDIUM)
            phase.drop_objection(this);
        end
    endtask

  task body ();
    `uvm_info(get_full_name(),"inside base_master_sequence body", UVM_MEDIUM)
    if(!uvm_config_db #(config_obj) :: get(null, "", "config_obj", obj))
        `uvm_fatal (get_full_name(), "config_db_not_accessable");
    
    regi = reg_seq_item::type_id::create("regi");
    //reg_block = cdma_reg_block::type_id::create("reg_block");
    //if(!uvm_config_db#(cdma_reg_block)::get(null,get_full_name(),"reg_block",reg_block)) begin
    //    `uvm_fatal("SEQ", "Could not find cdma_reg_block in config_db!")
    //end

  endtask:body

endclass: base_master_sequence


class simple_mode_wr_rd_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_wr_rd_seq)
  
    function new(string name = "simple_mode_wr_rd_seq");
        super.new(name); 
    endfunction
    
    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_INCR_SEQ", "Starting Simple Mode INCR Transfer Sequence", UVM_MEDIUM)
        
        if(!regi.randomize() with {
            //regi.btt_s == MB;
            regi.btt_s == MIN;
            regi.sa_addr %16 == 1;
            regi.da_addr %16 == 0;
            regi.btt_bytes %16 == 0;
            })begin
            `uvm_error(get_full_name(), "randomization_failed")
        end
        
        do begin
            reg_block.cdmasr.read(status, cdmasr_data);
	    end while(cdmasr_data[1] == 0);
        `uvm_info("SIMPLE_MODE_INCR_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)

        `uvm_info("SIMPLE_MODE_INCR_SEQ", "Writing to registers", UVM_MEDIUM)
        reg_block.cdmacr.write(status, 32'h15000);

        reg_block.sa.write(status, regi.sa_addr);
        reg_block.da.write(status, regi.da_addr);
        reg_block.btt.write(status, regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_INCR_SEQ", $sformatf("Configured Registers: \nSA: %0d \nDA: %0d \nBTT: %0d \nTransfer started!",regi.sa_addr,regi.da_addr,regi.btt_bytes), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_INCR_SEQ", "BTT written - Seq starts", UVM_MEDIUM)

        reg_block.cdmasr.read(status, cdmasr_data);
        `uvm_info("SIMPLE_MODE_INCR_SEQ", $sformatf("Idle = %0h - Waiting for idle",cdmasr_data[1]), UVM_MEDIUM)
    endtask
endclass: simple_mode_wr_rd_seq


class simple_mode_interrupt_check extends base_master_sequence;
    `uvm_object_utils(simple_mode_interrupt_check)

    function new(string name = "simple_mode_interrupt_check");
        super.new(name); 
    endfunction

    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
        wait(obj.mas_if[0].cdma_introut);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)
        //14 6 5 4 ERR IRQ asserts only when ERR condition met
        if((cdmasr_data[6]||cdmasr_data[5]||cdmasr_data[4]) == 1) begin
            if(cdmasr_data[14] != 1) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "Err_Irq NOT asserted")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Err_Irq asserted",UVM_MEDIUM)
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Doing W1C to de-assert Err_Irq",UVM_MEDIUM)
                reg_block.cdmasr.write(status,32'h4000);
            end
            if(cdmasr_data[6]) begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "DMADecErr asserted",UVM_MEDIUM)
                reg_block.cdmacr.write(status,32'h4);
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Reset asserted", UVM_MEDIUM)
            end
            if(cdmasr_data[5]) begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "DMASlvErr asserted",UVM_MEDIUM)
                reg_block.cdmacr.write(status,32'h4);
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Reset asserted", UVM_MEDIUM)
            end
            if(cdmasr_data[4]) begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "DMAIntErr asserted",UVM_MEDIUM)
                reg_block.cdmacr.write(status,32'h4);
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Reset asserted", UVM_MEDIUM)
            end
        end
        // IOC IRQ should be asserted for every sequence which says the tx is
        // completed
        if(cdmasr_data[12] != 1) begin
            `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT asserted")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq asserted!", UVM_MEDIUM)
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Clearing IOC_Irq by doing W1C", UVM_MEDIUM)
            reg_block.cdmasr.write(status,32'h1000);
        end
        reg_block.cdmasr.read(status,cdmasr_data);
        if(cdmasr_data[12]) begin
            `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT Cleared after W1C!")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq Cleared!", UVM_MEDIUM)
        end
        // Checking if register values changed after clearing!
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Reading Status Registers after clearning", UVM_MEDIUM)
        reg_block.cdmasr.read(status,cdmasr_data);
        //14 12 6 5 4
        if((cdmasr_data[6]||cdmasr_data[5]||cdmasr_data[4]) != 0) begin
            if(cdmasr_data[14]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "Err_Irq not de-asserted")
            end
            if(cdmasr_data[6]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "DMADecErr NOT de-asserted")
            end
            if(cdmasr_data[5]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "DMASlvErr NOT de-asserted")
            end
            if(cdmasr_data[4]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "DMAIntErr NOT de-asserted")
            end
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Read Status Register Errs as 0. Clear is Success!", UVM_MEDIUM)
        end
    endtask
endclass: simple_mode_interrupt_check


class simple_mode_fixed_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_fixed_seq)

    function new(string name = "simple_mode_fixed_seq");
        super.new(name); 
    endfunction

    task body();
        super.body();

        if(!regi.randomize() with {
            regi.btt_s       == MIN;
            regi.sa_addr     == 'hfcc;
            regi.btt_bytes   == 'h100;
            })begin
            `uvm_error (get_full_name(), "randomization_failed")
        end

        `uvm_info("SIMPLE_MODE_FIXED_SEQ", "Starting Simple Mode Fixed Transfer Sequence", UVM_MEDIUM)
        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_FIXED_SEQ", $sformatf("Idle = %0h - wait cleared",cdmasr_data[1]), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_FIXED_SEQ", "Configuring CDMACR in Key Hole Mode", UVM_MEDIUM)
        reg_block.cdmacr.write(status,32'h15010);
        reg_block.cdmacr.read(status,cdmacr_data);
        `uvm_info("SIMPLE_MODE_FIXED_SEQ", $sformatf("CDMACR Key Hole Mode: Write: %0h | Read: %0h",cdmacr_data[5],cdmacr_data[4]), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_FIXED_SEQ", "Configuring Registers SA, DA, BTT", UVM_MEDIUM)
        reg_block.sa.write(status,regi.sa_addr);
        reg_block.da.write(status,regi.da_addr);
        reg_block.btt.write(status,regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_FIXED_SEQ", $sformatf("Configured BTT: %0d - Transfer started!",regi.btt_bytes), UVM_MEDIUM)
        reg_block.sa.read(status,temp_data);
        reg_block.da.read(status,temp_data);
        reg_block.btt.read(status,temp_data);
    endtask
endclass:simple_mode_fixed_seq


class simple_dma_slave_error_seq extends base_master_sequence;
    `uvm_object_utils(simple_dma_slave_error_seq)
    function new(string name="simple_dma_slave_error_seq");
        super.new(name);
    endfunction
    
    //rand longint btt_bytes,sa_addr,da_addr;

    task body();
        super.body();

        //std::randomize(btt_bytes) with { btt_bytes inside {['d1 : 'd1024]}; };
        //std::randomize(sa_addr);
        //std::randomize(da_addr);
        if(!regi.randomize() with {
            regi.btt_s==MIN;
            })begin
            `uvm_error (get_full_name(), "randomization_failed")
        end
        
        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", "Starting of DMA SLVERR Seq", UVM_MEDIUM)
        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", $sformatf("Idle = %0h - wait cleared",cdmasr_data[1]), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", "Configuring CDMACR in Simple Mode", UVM_MEDIUM)
        reg_block.cdmacr.write(status,32'h15000);
        reg_block.cdmacr.read(status,cdmacr_data);

        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", "Configuring Registers SA, DA & BTT", UVM_MEDIUM)
        reg_block.sa.write(status,regi.sa_addr);
        reg_block.da.write(status,regi.da_addr);
        reg_block.btt.write(status,regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", $sformatf("Configured BTT: %0d - Transfer started!",regi.btt_bytes), UVM_MEDIUM)

        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
        wait(obj.mas_if[0].cdma_introut);
        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)

        if(cdmasr_data[5] != 1) begin
            `uvm_error("SIMPLE_MODE_DMA_SLVERR_SEQ", "DMASlvErr NOT asserted")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", "DMASlvErr asserted",UVM_LOW)
        end
    endtask
endclass:simple_dma_slave_error_seq


class simple_dma_decode_error_seq extends base_master_sequence;
    `uvm_object_utils(simple_dma_decode_error_seq)
    function new(string name="simple_dma_decode_error_seq");
        super.new(name);
    endfunction
    
    //rand longint btt_bytes,sa_addr,da_addr;

    task body();
        super.body();

        //std::randomize(btt_bytes) with { btt_bytes inside {['d1 : 'd1024]}; };
        //std::randomize(sa_addr);
        //std::randomize(da_addr);
        if(!regi.randomize() with {
            regi.btt_s==MIN;
            })begin
            `uvm_error (get_full_name(), "randomization_failed")
        end
        
        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", "Starting of DMA SLVERR Seq", UVM_MEDIUM)
        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", $sformatf("Idle = %0h - wait cleared",cdmasr_data[1]), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", "Configuring CDMACR in Simple Mode", UVM_MEDIUM)
        reg_block.cdmacr.write(status,32'h15000);
        reg_block.cdmacr.read(status,cdmacr_data);

        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", "Configuring Registers SA, DA, BTT", UVM_MEDIUM)
        reg_block.sa.write(status,regi.sa_addr);
        reg_block.da.write(status,regi.da_addr);
        reg_block.btt.write(status,regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", $sformatf("Configured BTT: %0d - Transfer started!",regi.btt_bytes), UVM_MEDIUM)

        `uvm_info("SIMPLE_MODE_DMA_SLVERR_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
        wait(obj.mas_if[0].cdma_introut);
        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)

        if(cdmasr_data[6] != 1) begin
            `uvm_error("SIMPLE_MODE_DMA_DECERR_SEQ", "DMADecErr NOT asserted")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_DECERR_SEQ", "DMADecErr asserted",UVM_LOW)
        end
    endtask
endclass:simple_dma_decode_error_seq


class simple_dma_int_error_seq extends base_master_sequence;
    `uvm_object_utils(simple_dma_int_error_seq)
    function new(string name="simple_dma_int_error_seq");
        super.new(name);
    endfunction

    task body();
        super.body();

        if(!regi.randomize() with {
            regi.btt_s==MIN;
            //regi.da_addr == 'hffff_ffff_ffff_ffff;
            //regi.btt_bytes == 'h40;
            regi.btt_bytes == 0;
            })begin
            `uvm_error(get_full_name(), "randomization_failed")
        end
        
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Starting of DMAIntErr Seq", UVM_MEDIUM)
        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared",cdmasr_data[1]), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Configuring CDMACR in Simple Mode", UVM_MEDIUM)
        reg_block.cdmacr.write(status,32'h15000);
        reg_block.cdmacr.read(status,cdmacr_data);

        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Configuring Registers SA, DA, BTT", UVM_MEDIUM)
        reg_block.sa.write(status,regi.sa_addr);
        reg_block.da.write(status,regi.da_addr);
        //reg_block.da_msb.write(status,regi.da_addr);
        reg_block.btt.write(status,regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Configured Registers: \nSA: %0d \nDA: %0d \nBTT: %0d \nTransfer started!",regi.sa_addr,regi.da_addr,regi.btt_bytes), UVM_MEDIUM)

        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
        wait(obj.mas_if[0].cdma_introut);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)

        //reg_block.cdmasr.DMAIntErr.predict('b1);
        //reg_block.cdmasr.mirror(status,UVM_CHECK);
        if(cdmasr_data[4] != 1) begin
            `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "DMAIntErr NOT asserted")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "DMAIntErr asserted",UVM_LOW)
        end
    endtask
endclass:simple_dma_int_error_seq


class simple_dma_4k_boundary_seq extends base_master_sequence;
    `uvm_object_utils(simple_dma_4k_boundary_seq)
    function new(string name="simple_dma_4k_boundary_seq");
        super.new(name);
    endfunction

    task body();
        super.body();

        //if(!regi.randomize() with {
        assert(regi.randomize() with {
            //regi.btt_s==MIN;
            regi.sa_addr == 'hfe1;
            regi.da_addr == 'h2fe1;
            //regi.sa_addr == 'h1000;
            //regi.da_addr == 'h2000;
            regi.btt_bytes == 'h40;
            })
        //begin
        //    `uvm_error (get_full_name(), "randomization_failed")
        //end
        
        `uvm_info("SIMPLE_MODE_DMA_4KB_SEQ", "Starting of DMA SLVERR Seq", UVM_MEDIUM)
        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_4KB_SEQ", $sformatf("Idle = %0h - wait cleared",cdmasr_data[1]), UVM_MEDIUM)
        `uvm_info("SIMPLE_MODE_DMA_4KB_SEQ", "Configuring CDMACR in Simple Mode", UVM_MEDIUM)
        reg_block.cdmacr.write(status,32'h15000);
        reg_block.cdmacr.read(status,cdmacr_data);

        `uvm_info("SIMPLE_MODE_DMA_4KB_SEQ", "Configuring Registers SA, DA, BTT", UVM_MEDIUM)
        reg_block.sa.write(status,regi.sa_addr);
        reg_block.da.write(status,regi.da_addr);
        reg_block.btt.write(status,regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_DMA_4KB_SEQ", $sformatf("Configured BTT: %0d - Transfer started!",regi.btt_bytes), UVM_MEDIUM)

    endtask
endclass:simple_dma_4k_boundary_seq


class simple_mode_b2b_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_b2b_seq)
  
    function new(string name = "simple_mode_b2b_seq");
        super.new(name); 
    endfunction
    
    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_B2B_SEQ", "Starting Simple Mode INCR Transfer Sequence", UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status, cdmasr_data);
	    end while(cdmasr_data[1] == 0);
        `uvm_info("SIMPLE_MODE_B2B_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)
        repeat(4)begin
        regi = reg_seq_item::type_id::create("btt_pkt");
            if(!regi.randomize() with {
                regi.btt_s == SML;
                regi.sa_addr %16 == 0;
                regi.da_addr %16 == 0;
                regi.btt_bytes %16 == 0;
                })begin
                `uvm_error(get_full_name(), "randomization_failed")
            end

            `uvm_info("SIMPLE_MODE_B2B_SEQ", "Writing to registers", UVM_MEDIUM)
            reg_block.sa.write(status, regi.sa_addr);
            reg_block.da.write(status, regi.da_addr);
            reg_block.btt.write(status, regi.btt_bytes);
            `uvm_info("SIMPLE_MODE_B2B_SEQ", "BTT written - Seq starts", UVM_MEDIUM)
        end
        #2000;
    endtask
endclass: simple_mode_b2b_seq


class simple_mode_b2b_ioc_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_b2b_ioc_seq)
  
    function new(string name = "simple_mode_b2b_ioc_seq");
        super.new(name); 
    endfunction
    
    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_B2B_IOC_SEQ", "Starting Simple Mode INCR Transfer Sequence", UVM_MEDIUM)

        repeat(3)begin
        regi = reg_seq_item::type_id::create("btt_pkt");
            if(!regi.randomize() with {
                regi.btt_s == MIN;
                regi.sa_addr %16 == 0;
                regi.da_addr %16 == 0;
                regi.btt_bytes %16 == 0;
                })begin
                `uvm_error(get_full_name(), "randomization_failed")
            end

            do begin
                reg_block.cdmasr.read(status, cdmasr_data);
	        end while(cdmasr_data[1] == 0);
            `uvm_info("SIMPLE_MODE_B2B_IOC_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)

            `uvm_info("SIMPLE_MODE_B2B_IOC_SEQ", "Writing to registers", UVM_MEDIUM)
            reg_block.cdmacr.write(status, 32'h11000);
            reg_block.cdmacr.read(status, cdmacr_data);
            `uvm_info("SIMPLE_MODE_B2B_IOC_SEQ", $sformatf("Read CR: 0x%0h", cdmacr_data), UVM_MEDIUM)
            reg_block.sa.write(status, regi.sa_addr);
            reg_block.da.write(status, regi.da_addr);
            reg_block.btt.write(status, regi.btt_bytes);
            `uvm_info("SIMPLE_MODE_B2B_IOC_SEQ", "BTT written - Seq starts", UVM_MEDIUM)

            reg_block.cdmasr.read(status, cdmasr_data);
            `uvm_info("SIMPLE_MODE_B2B_IOC_SEQ", $sformatf("Idle = %0h - Waiting for idle",cdmasr_data[1]), UVM_MEDIUM)

            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
            wait(obj.mas_if[0].cdma_introut);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)

            do begin
                reg_block.cdmasr.read(status,cdmasr_data);
            end while(cdmasr_data[1]==0);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)
            //12 IOC IRQ
            if(cdmasr_data[12] != 1) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT asserted")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq asserted", UVM_LOW)
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Clearing IOC_Irq by W1C",UVM_LOW)
                reg_block.cdmasr.write(status,32'h1000);
                reg_block.cdmasr.read(status,cdmasr_data);
                if(cdmasr_data[12] == 0) begin
                    `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq Cleared",UVM_LOW)
                end
                else begin
                    `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT Cleared!")
                end
            end
        end
    endtask
endclass: simple_mode_b2b_ioc_seq


class simple_mode_alignment_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_alignment_seq)
  
    function new(string name = "simple_mode_alignment_seq");
        super.new(name); 
    endfunction
    
    byte r;

    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_ALIGN_SEQ", "Starting Simple Mode ALIGNED Transfer Sequence", UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status, cdmasr_data);
	    end while(cdmasr_data[1] == 0);
        `uvm_info("SIMPLE_MODE_ALIGN_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)
        reg_block.cdmacr.write(status, 32'h11000);

        repeat(4)begin
            regi = reg_seq_item::type_id::create("btt_pkt");
            if(r == 0) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     == 0;
                    regi.da_addr %16     == 0;
                    regi.btt_bytes %16   == 0;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 1) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     != 0;
                    regi.da_addr %16     == 0;
                    regi.btt_bytes %16   == 0;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 2) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     == 0;
                    regi.da_addr %16     != 0;
                    regi.btt_bytes %16   == 0;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 3) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     != 0;
                    regi.da_addr %16     != 0;
                    regi.btt_bytes %16   == 0;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end

            `uvm_info("SIMPLE_MODE_ALIGN_SEQ", "Writing to registers", UVM_MEDIUM)
            reg_block.sa.write(status, regi.sa_addr);
            reg_block.da.write(status, regi.da_addr);
            reg_block.btt.write(status, regi.btt_bytes);
            `uvm_info("SIMPLE_MODE_ALIGN_SEQ", "BTT written - Seq starts", UVM_MEDIUM)

            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
            wait(obj.mas_if[0].cdma_introut);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
    
            do begin
                reg_block.cdmasr.read(status,cdmasr_data);
            end while(cdmasr_data[1]==0);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)
            // IOC IRQ should be asserted for every sequence which says the tx is
            // completed
            if(cdmasr_data[12] != 1) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT asserted")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq asserted!", UVM_MEDIUM)
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Clearing IOC_Irq by doing W1C", UVM_MEDIUM)
                reg_block.cdmasr.write(status,32'h1000);
            end
            reg_block.cdmasr.read(status,cdmasr_data);
            if(cdmasr_data[12]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT Cleared after W1C!")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq Cleared!", UVM_MEDIUM)
            end

            r++;
        end
    endtask
endclass: simple_mode_alignment_seq


class simple_mode_btt_check_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_btt_check_seq)
  
    function new(string name = "simple_mode_btt_check_seq");
        super.new(name); 
    endfunction
    
    byte r;

    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_BTT_SEQ", "Starting Simple Mode ALIGNED Transfer Sequence", UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status, cdmasr_data);
	    end while(cdmasr_data[1] == 0);
        `uvm_info("SIMPLE_MODE_BTT_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)
        reg_block.cdmacr.write(status, 32'h11000);

        repeat(6)begin
            regi = reg_seq_item::type_id::create("btt_pkt");
            if(r == 0) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.btt_bytes       == 1;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 1) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.btt_bytes       == 16;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 2) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.btt_bytes       == 17;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 3) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     != 0;
                    regi.da_addr %16     != 0;
                    regi.btt_bytes       == 1;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 4) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     != 0;
                    regi.da_addr %16     != 0;
                    regi.btt_bytes       == 16;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 5) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr %16     != 0;
                    regi.da_addr %16     != 0;
                    regi.btt_bytes       == 17;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end

            `uvm_info("SIMPLE_MODE_BTT_SEQ", "Writing to registers", UVM_MEDIUM)
            reg_block.sa.write(status, regi.sa_addr);
            reg_block.da.write(status, regi.da_addr);
            reg_block.btt.write(status, regi.btt_bytes);
            `uvm_info("SIMPLE_MODE_BTT_SEQ", "BTT written - Seq starts", UVM_MEDIUM)

            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
            wait(obj.mas_if[0].cdma_introut);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
    
            do begin
                reg_block.cdmasr.read(status,cdmasr_data);
            end while(cdmasr_data[1]==0);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)
            // IOC IRQ should be asserted for every sequence which says the tx is
            // completed
            if(cdmasr_data[12] != 1) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT asserted")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq asserted!", UVM_MEDIUM)
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Clearing IOC_Irq by doing W1C", UVM_MEDIUM)
                reg_block.cdmasr.write(status,32'h1000);
            end
            reg_block.cdmasr.read(status,cdmasr_data);
            if(cdmasr_data[12]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT Cleared after W1C!")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq Cleared!", UVM_MEDIUM)
            end

            r++;
        end
    endtask
endclass: simple_mode_btt_check_seq


class simple_mode_4k_check_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_4k_check_seq)
  
    function new(string name = "simple_mode_4k_check_seq");
        super.new(name); 
    endfunction
    
    byte r;

    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_4K_SEQ", "Starting Simple Mode ALIGNED Transfer Sequence", UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status, cdmasr_data);
	    end while(cdmasr_data[1] == 0);
        `uvm_info("SIMPLE_MODE_4K_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)
        reg_block.cdmacr.write(status, 32'h11000);

        repeat(4)begin
            regi = reg_seq_item::type_id::create("btt_pkt");
            if(r == 0) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr         == 'hfa0;
                    regi.da_addr         == 'h1000;
                    regi.btt_bytes       == 'h100;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 1) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr         == 'h2000;
                    regi.da_addr         == 'h1fa0;
                    regi.btt_bytes       == 'h100;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 2) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr         == 'hfc3;
                    regi.da_addr         == 'h1fa0;
                    regi.btt_bytes       == 'h100;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end
            if(r == 3) begin
                if(!regi.randomize() with {
                    regi.btt_s           == MIN;
                    regi.sa_addr         == 'h0;
                    regi.da_addr         == 'h2000;
                    regi.btt_bytes       == 'h100f;
                    })begin
                    `uvm_error(get_full_name(), "randomization_failed")
                end
            end

            `uvm_info("SIMPLE_MODE_4K_SEQ", "Writing to registers", UVM_MEDIUM)
            reg_block.sa.write(status, regi.sa_addr);
            reg_block.da.write(status, regi.da_addr);
            reg_block.btt.write(status, regi.btt_bytes);
            `uvm_info("SIMPLE_MODE_4K_SEQ", "BTT written - Seq starts", UVM_MEDIUM)

            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
            wait(obj.mas_if[0].cdma_introut);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
    
            do begin
                reg_block.cdmasr.read(status,cdmasr_data);
            end while(cdmasr_data[1]==0);
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)
            // IOC IRQ should be asserted for every sequence which says the tx is
            // completed
            if(cdmasr_data[12] != 1) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT asserted")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq asserted!", UVM_MEDIUM)
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Clearing IOC_Irq by doing W1C", UVM_MEDIUM)
                reg_block.cdmasr.write(status,32'h1000);
            end
            reg_block.cdmasr.read(status,cdmasr_data);
            if(cdmasr_data[12]) begin
                `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT Cleared after W1C!")
            end
            else begin
                `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq Cleared!", UVM_MEDIUM)
            end

            r++;
        end
    endtask
endclass: simple_mode_4k_check_seq


class simple_mode_64mb_btt_seq extends base_master_sequence;
    `uvm_object_utils(simple_mode_64mb_btt_seq)
  
    function new(string name = "simple_mode_64mb_btt_seq");
        super.new(name); 
    endfunction
    
    task body();
        super.body();

        `uvm_info("SIMPLE_MODE_64MB_SEQ", "Starting Simple Mode ALIGNED Transfer Sequence", UVM_MEDIUM)

        do begin
            reg_block.cdmasr.read(status, cdmasr_data);
	    end while(cdmasr_data[1] == 0);
        `uvm_info("SIMPLE_MODE_64MB_SEQ", $sformatf("Idle = %0h - wait clear",cdmasr_data[1]), UVM_MEDIUM)
        reg_block.cdmacr.write(status, 32'h11000);

        if(!regi.randomize() with {
            regi.sa_addr         == 'h8000_0000;
            regi.da_addr         == 'h9000_0000;
            regi.btt_bytes       == 'h3ff_ffff;
            })begin
            `uvm_error(get_full_name(), "randomization_failed")
        end

        `uvm_info("SIMPLE_MODE_64MB_SEQ", "Writing to registers", UVM_MEDIUM)
        reg_block.sa.write(status, regi.sa_addr);
        reg_block.da.write(status, regi.da_addr);
        reg_block.btt.write(status, regi.btt_bytes);
        `uvm_info("SIMPLE_MODE_64MB_SEQ", "BTT written - Seq starts", UVM_MEDIUM)

        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
        wait(obj.mas_if[0].cdma_introut);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("cdma_introut: %0h", obj.mas_if[0].cdma_introut), UVM_MEDIUM)
    
        do begin
            reg_block.cdmasr.read(status,cdmasr_data);
        end while(cdmasr_data[1]==0);
        `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", $sformatf("Idle = %0h - wait cleared. Transfer completed!",cdmasr_data[1]), UVM_MEDIUM)
        // IOC IRQ should be asserted for every sequence which says the tx is
        // completed
        if(cdmasr_data[12] != 1) begin
            `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT asserted")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq asserted!", UVM_MEDIUM)
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "Clearing IOC_Irq by doing W1C", UVM_MEDIUM)
            reg_block.cdmasr.write(status,32'h1000);
        end
        reg_block.cdmasr.read(status,cdmasr_data);
        if(cdmasr_data[12]) begin
            `uvm_error("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq NOT Cleared after W1C!")
        end
        else begin
            `uvm_info("SIMPLE_MODE_DMA_INT_SEQ", "IOC_Irq Cleared!", UVM_MEDIUM)
        end
    endtask
endclass: simple_mode_64mb_btt_seq
