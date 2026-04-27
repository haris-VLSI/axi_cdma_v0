class cdma_base_test extends uvm_test;
    `uvm_component_utils(cdma_base_test)

    function new(string name = "cdma_base_test", uvm_component parent);
        super.new(name,parent);
    endfunction
    
    cdma_env        env;
    config_obj      obj;					//config_object
    cdma_reg_block  reg_block;

    virtual reset_intf reset_if;

    //cdma_base_test:: build
    function void build_phase 			(uvm_phase phase);
        super.build_phase (phase);
        `uvm_info ("test::build_phase" , phase.get_name() , UVM_MEDIUM)
        env = cdma_env :: type_id :: create ("env", this);	//creating axi_cdma_env 

        if(!uvm_config_db #(config_obj) :: get(this, "", "config_obj", obj))
            `uvm_fatal (get_full_name(), "config_db_not_accessable");

        if(!uvm_config_db #(virtual reset_intf)::get(null,"","reset_if", reset_if))
            `uvm_fatal (get_full_name(), "reset_intf_not_accessable");

    endfunction : build_phase

  //cdma_base_test:: elaboration
  function void end_of_elaboration_phase 	(uvm_phase phase);
     super.end_of_elaboration_phase (phase);
    `uvm_info ("test::end_of_elaboration"  , phase.get_name() , UVM_MEDIUM)
    uvm_top.print_topology();								//printing topology
     
  endfunction : end_of_elaboration_phase

  //cdma_base_test:: reset_phase
    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        `uvm_info(get_full_name(),"inside_reset_phase", UVM_MEDIUM)
        phase.raise_objection(this);
        `uvm_info(get_full_name(),"inside_raise_objection", UVM_MEDIUM)
        wait (obj.mas_if[0].areset_n);
        //#1000;
        phase.drop_objection(this);
        `uvm_info(get_full_name(),"outside_drop_objection", UVM_MEDIUM)
    endtask: reset_phase
 endclass :cdma_base_test


`define TEST_INT(TESTNAME,MASTER_SEQ,SLAVE_SEQ,INT_SEQ) \
class TESTNAME extends cdma_base_test; \
    `uvm_component_utils(TESTNAME) \
    function new(string name="TESTNAME", uvm_component parent); \
        super.new(name,parent); \
    endfunction \
    MASTER_SEQ      master_seq; \
    SLAVE_SEQ       slave_seq; \
    INT_SEQ         interrupt_seq; \
    task main_phase(uvm_phase phase); \
        phase.raise_objection(this); \
            master_seq = MASTER_SEQ::type_id::create("master_seq"); \
            slave_seq  = SLAVE_SEQ::type_id::create("slave_seq"); \
            interrupt_seq = INT_SEQ::type_id::create("interrupt_seq"); \
            master_seq.reg_block = env.reg_block; \
            interrupt_seq.reg_block = env.reg_block; \
            fork \
                slave_seq.start(env.s_agt[0].sqr); \
            join_none \
            fork \
                master_seq.start(env.m_agt[0].sqr); \
                interrupt_seq.start(env.m_agt[0].sqr); \
            join \
        phase.drop_objection(this); \
    endtask \
endclass: TESTNAME


`define TEST(TESTNAME,MASTER_SEQ,SLAVE_SEQ) \
class TESTNAME extends cdma_base_test; \
    `uvm_component_utils(TESTNAME) \
    function new(string name="TESTNAME", uvm_component parent); \
        super.new(name,parent); \
    endfunction \
    MASTER_SEQ      master_seq; \
    SLAVE_SEQ       slave_seq; \
    task main_phase(uvm_phase phase); \
        phase.raise_objection(this); \
            master_seq = MASTER_SEQ::type_id::create("master_seq"); \
            slave_seq  = SLAVE_SEQ::type_id::create("slave_seq"); \
            master_seq.reg_block = env.reg_block; \
            fork \
                slave_seq.start(env.s_agt[0].sqr); \
            join_none \
            master_seq.start(env.m_agt[0].sqr); \
        phase.drop_objection(this); \
    endtask \
endclass: TESTNAME


class ral_reset_test extends cdma_base_test;
    `uvm_component_utils(ral_reset_test)

    function new(string name="ral_reset_test", uvm_component parent);
        super.new(name,parent);
    endfunction
    
    uvm_status_e status;
    uvm_reg_data_t value = 32'hffff_ffff;

    uvm_reg_hw_reset_seq reset_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
            reset_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
            reset_seq.model = env.reg_block;

            `uvm_info("RAL_RESET_TEST","RAL reset test starting",UVM_MEDIUM)
            reset_seq.start(null);
            `uvm_info("RAL_RESET_TEST","RAL reset test completed",UVM_MEDIUM)
        phase.drop_objection(this);
    endtask
endclass: ral_reset_test


class ral_intermediate_soft_reset_test extends cdma_base_test;
    `uvm_component_utils(ral_intermediate_soft_reset_test)

    function new(string name="ral_intermediate_soft_reset_test", uvm_component parent);
        super.new(name,parent);
    endfunction
    
    uvm_status_e    status;
    uvm_reg_data_t  value = 32'hffff_ffff;

    uvm_reg_hw_reset_seq reset_seq;

    task main_phase(uvm_phase phase);

        phase.raise_objection(this);
            reset_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
            reset_seq.model = env.reg_block;

            //writing random values before reset test
            env.reg_block.cdmacr.write(status,32'h10000);
            env.reg_block.cdmasr.write(status,value);
            env.reg_block.curdesc_pnt.write(status,value);
            env.reg_block.curdesc_pnt_msb.write(status,value);
            env.reg_block.taildesc_pnt.write(status,value);
            env.reg_block.taildesc_pnt_msb.write(status,value);
            env.reg_block.sa.write(status,value);
            env.reg_block.sa_msb.write(status,value);
            env.reg_block.da.write(status,value);
            env.reg_block.da_msb.write(status,value);
            //env.reg_block.btt.write(status,value);

            `uvm_info("RAL_RESET_TEST","Soft reset asserted",UVM_MEDIUM)
            env.reg_block.cdmacr.Reset.write(status,1'b1);
            do begin
                env.reg_block.cdmacr.Reset.read(status,value);
            end while(value == 1);
            `uvm_info("RAL_RESET_TEST","Soft reset cleared",UVM_MEDIUM)

            //clears RAL mirror values
            env.reg_block.reset();
            `uvm_info("RAL_RESET_TEST","RAL reset completed",UVM_MEDIUM)

            `uvm_info("RAL_RESET_TEST","RAL reset test starting",UVM_MEDIUM)
            reset_seq.start(null);
            `uvm_info("RAL_RESET_TEST","RAL reset test completed",UVM_MEDIUM)
        phase.drop_objection(this);
    endtask
endclass: ral_intermediate_soft_reset_test



class ral_intermediate_hard_reset_test extends cdma_base_test;
    `uvm_component_utils(ral_intermediate_hard_reset_test)

    function new(string name="ral_intermediate_hard_reset_test", uvm_component parent);
        super.new(name,parent);
    endfunction
    
    uvm_status_e    status;
    uvm_reg_data_t  value = 32'hffff_ffff;

    uvm_reg_hw_reset_seq reset_seq;

    task main_phase(uvm_phase phase);

        phase.raise_objection(this);
            reset_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
            reset_seq.model = env.reg_block;

            //writing random values before reset test
            env.reg_block.cdmacr.write(status,32'h0);
            env.reg_block.cdmasr.write(status,value);
            env.reg_block.curdesc_pnt.write(status,value);
            env.reg_block.curdesc_pnt_msb.write(status,value);
            env.reg_block.taildesc_pnt.write(status,value);
            env.reg_block.taildesc_pnt_msb.write(status,value);
            env.reg_block.sa.write(status,value);
            env.reg_block.sa_msb.write(status,value);
            env.reg_block.da.write(status,value);
            env.reg_block.da_msb.write(status,value);
            //env.reg_block.btt.write(status,value);

            `uvm_info("RAL_RESET_TEST",$sformatf("%0t: Hard reset asserted",$time),UVM_MEDIUM)
            reset_if.reset_n = 0;
            repeat(16)@(posedge obj.mas_if[0].aclk);
            reset_if.reset_n = 1;
            `uvm_info("RAL_RESET_TEST",$sformatf("%0t: Hard reset cleared",$time),UVM_MEDIUM)

            //clears RAL mirror values
            env.reg_block.reset();
            `uvm_info("RAL_RESET_TEST","RAL reset completed",UVM_MEDIUM)
            
            `uvm_info("RAL_RESET_TEST","RAL reset test starting",UVM_MEDIUM)
            reset_seq.start(null);
            `uvm_info("RAL_RESET_TEST","RAL reset test completed",UVM_MEDIUM)
        phase.drop_objection(this);
    endtask
endclass: ral_intermediate_hard_reset_test


class ral_bit_bash_test extends cdma_base_test;
  `uvm_component_utils(ral_bit_bash_test)
    
    uvm_status_e    status;
    uvm_reg_data_t  value = 32'h0001_0008;
    uvm_reg_data_t  rdata;

  function new(string name="ral_bit_bash_test", uvm_component parent);
    super.new(name,parent);
  endfunction

  uvm_reg_bit_bash_seq bit_bash_seq;
  
  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
        bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
        bit_bash_seq.model = env.reg_block;

        env.reg_block.cdmacr.write(status,value);
        env.reg_block.cdmacr.read(status,value);
        `uvm_info("DEBUG", $sformatf("Read CR: 0x%0h", value), UVM_MEDIUM)
        #10;
        env.reg_block.cdmacr.SGMode.read(status,value);
        `uvm_info("DEBUG", $sformatf("Read CR SGMode: 0x%0h", value), UVM_MEDIUM)
        #10;
        env.reg_block.cdmasr.read(status,value);
        `uvm_info("DEBUG", $sformatf("Read SR: 0x%0h", value), UVM_MEDIUM)
        #10;
        env.reg_block.cdmasr.Idle.read(status,value);
        `uvm_info("DEBUG", $sformatf("Read SR Idle: 0x%0h", value), UVM_MEDIUM)
        #10;
        //env.reg_block.curdesc_pnt.write(status,32'hFFFFFFFF);
        //env.reg_block.curdesc_pnt.read(status,rdata);
        //`uvm_info("DEBUG", $sformatf("Read: 0x%0h", rdata), UVM_MEDIUM)
        //#10;
        
        uvm_resource_db#(bit)::set({"REG::",env.reg_block.cdmacr.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::", env.reg_block.cdmacr.reset.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.cdmasr.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.curdesc_pnt.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.curdesc_pnt_msb.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.taildesc_pnt.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.taildesc_pnt_msb.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.sa.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.sa_msb.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.da.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.da_msb.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.btt.get_full_name()},"NO_REG_TESTS",1,this);

        fork
            bit_bash_seq.start(null);
            begin
                #1;
                bit_bash_seq.reg_seq.set_response_queue_error_report_disabled(1);
            end
        join

    phase.drop_objection(this);
    endtask
endclass : ral_bit_bash_test


class ral_access_test extends cdma_base_test;
    `uvm_component_utils(ral_access_test)
    uvm_status_e    status;
    uvm_reg_data_t  value;

    function new(string name="ral_access_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    uvm_reg_access_seq reg_access_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        reg_access_seq = uvm_reg_access_seq::type_id::create("reg_access_seq");
        reg_access_seq.model = env.reg_block;

        env.reg_block.cdmacr.write(status, 32'h10008);
        env.reg_block.cdmacr.read(status,value);
        `uvm_info("DEBUG", $sformatf("Read CR SGMode: 0x%0h", value[3]), UVM_MEDIUM)
        #10;

        uvm_resource_db#(bit)::set({"REG::",env.reg_block.cdmacr.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.cdmasr.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.curdesc_pnt.get_full_name()},"NO_REG_TESTS",1,this);
        uvm_resource_db#(bit)::set({"REG::",env.reg_block.taildesc_pnt.get_full_name()},"NO_REG_TESTS",1,this);
        //uvm_resource_db#(bit)::set({"REG::",env.reg_block.taildesc_pnt_msb.get_full_name()},"NO_REG_TESTS",1,this);
        
            reg_access_seq.start(null);
        phase.drop_objection(this);
    endtask
endclass: ral_access_test


class simple_mode_wr_rd_test extends cdma_base_test;
    `uvm_component_utils(simple_mode_wr_rd_test)
    
    cdma_simple_transfer_vseq vseq;

    function new(string name="simple_mode_wr_rd_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    task main_phase(uvm_phase phase);
        vseq = cdma_simple_transfer_vseq::type_id::create("vseq");
        
        phase.raise_objection(this);
            vseq.start(env.v_seqr);
        phase.drop_objection(this);
    endtask
endclass: simple_mode_wr_rd_test


class simple_mode_incr_transfer_test extends cdma_base_test;
    `uvm_component_utils(simple_mode_incr_transfer_test)
    
    function new(string name="simple_mode_incr_transfer_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_mode_wr_rd_seq           master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;
    
    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
            master_seq = simple_mode_wr_rd_seq::type_id::create("master_seq");
            slave_seq  = base_slave_sequence::type_id::create("slave_seq");
            interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass: simple_mode_incr_transfer_test


class simple_mode_fixed_transfer_test extends cdma_base_test;
    `uvm_component_utils(simple_mode_fixed_transfer_test)

    function new(string name="simple_mode_fixed_transfer_test", uvm_component parent);
        super.new(name,parent);
    endfunction
    
    simple_mode_fixed_seq           master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        master_seq = simple_mode_fixed_seq::type_id::create("master_seq");
        slave_seq = base_slave_sequence::type_id::create("slave_seq");
        interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

        master_seq.reg_block = env.reg_block;
        interrupt_seq.reg_block = env.reg_block;
        fork
            slave_seq.start(env.s_agt[0].sqr);
        join_none
        fork
            master_seq.start(env.m_agt[0].sqr);
            interrupt_seq.start(env.m_agt[0].sqr);
        join
        phase.drop_objection(this);
    endtask

endclass: simple_mode_fixed_transfer_test


class simple_dma_slave_error_test extends cdma_base_test;
    `uvm_component_utils(simple_dma_slave_error_test)
    function new(string name="simple_dma_slave_error_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_dma_slave_error_seq      master_seq;
    base_slave_error_sequence       slave_seq;
    simple_mode_interrupt_check     interrupt_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        master_seq = simple_dma_slave_error_seq::type_id::create("master_seq");
        slave_seq = base_slave_error_sequence::type_id::create("slave_seq");
        interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");
        
            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass:simple_dma_slave_error_test


class simple_dma_decode_error_test extends cdma_base_test;
    `uvm_component_utils(simple_dma_decode_error_test)
    function new(string name="simple_dma_decode_error_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_dma_decode_error_seq      master_seq;
    base_decode_error_sequence      slave_seq;
    simple_mode_interrupt_check     interrupt_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        master_seq = simple_dma_decode_error_seq::type_id::create("master_seq");
        slave_seq = base_decode_error_sequence::type_id::create("slave_seq");
        interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass:simple_dma_decode_error_test


class simple_dma_int_error_test extends cdma_base_test;
    `uvm_component_utils(simple_dma_int_error_test)
    function new(string name="simple_dma_int_error_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_dma_int_error_seq        master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        master_seq = simple_dma_int_error_seq::type_id::create("master_seq");
        slave_seq = base_slave_sequence::type_id::create("slave_seq");
        interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass:simple_dma_int_error_test


class simple_dma_4k_boundary_test extends cdma_base_test;
    `uvm_component_utils(simple_dma_4k_boundary_test)
    function new(string name="simple_dma_4k_boundary_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_dma_4k_boundary_seq      master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        master_seq = simple_dma_4k_boundary_seq::type_id::create("master_seq");
        slave_seq = base_slave_sequence::type_id::create("slave_seq");
        interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                interrupt_seq.start(env.m_agt[0].sqr);
            join
            phase.phase_done.set_drain_time(this, 1000ns);
        phase.drop_objection(this);
    endtask
endclass:simple_dma_4k_boundary_test


class simple_mode_alignment_test extends cdma_base_test;
    `uvm_component_utils(simple_mode_alignment_test)
    
    function new(string name="simple_mode_alignment_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_mode_alignment_seq         master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;
    
    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
            master_seq = simple_mode_alignment_seq::type_id::create("master_seq");
            slave_seq  = base_slave_sequence::type_id::create("slave_seq");
            interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                //interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass: simple_mode_alignment_test


class simple_mode_btt_check_test extends cdma_base_test;
    `uvm_component_utils(simple_mode_btt_check_test)
    
    function new(string name="simple_mode_btt_check_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_mode_btt_check_seq       master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;
    
    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
            master_seq = simple_mode_btt_check_seq::type_id::create("master_seq");
            slave_seq  = base_slave_sequence::type_id::create("slave_seq");
            interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                //interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass: simple_mode_btt_check_test


class simple_mode_4k_check_test extends cdma_base_test;
    `uvm_component_utils(simple_mode_4k_check_test)
    
    function new(string name="simple_mode_4k_check_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    simple_mode_4k_check_seq        master_seq;
    base_slave_sequence             slave_seq;
    simple_mode_interrupt_check     interrupt_seq;
    
    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
            master_seq = simple_mode_4k_check_seq::type_id::create("master_seq");
            slave_seq  = base_slave_sequence::type_id::create("slave_seq");
            interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

            master_seq.reg_block = env.reg_block;
            interrupt_seq.reg_block = env.reg_block;
            fork
                slave_seq.start(env.s_agt[0].sqr);
            join_none
            fork
                master_seq.start(env.m_agt[0].sqr);
                //interrupt_seq.start(env.m_agt[0].sqr);
            join
        phase.drop_objection(this);
    endtask
endclass: simple_mode_4k_check_test

`TEST(simple_mode_b2b_test,simple_mode_b2b_seq,base_slave_sequence)
`TEST(simple_mode_b2b_ioc_test,simple_mode_b2b_ioc_seq,base_slave_sequence)
`TEST(simple_mode_64mb_btt_test,simple_mode_64mb_btt_seq,base_slave_sequence)
