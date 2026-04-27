class virtual_sequence_base extends uvm_sequence;
   `uvm_object_utils(virtual_sequence_base)
   `uvm_declare_p_sequencer(virtual_sequencer)

   base_master_sequence m_seq;
   base_slave_sequence  s_seq;

   function new (string name = "virtual_sequence");
      super.new(name);
      m_seq   = base_master_sequence :: type_id :: create ("m_seq");
      s_seq   = base_slave_sequence  :: type_id :: create ("s_seq");
   endfunction

   task body ();
     `uvm_info(get_full_name(),"Invoking Sequnece start in V-sequence",UVM_LOW)
     fork
       s_seq.start(p_sequencer.s_seqr[0]);
     join_none
       m_seq.start(p_sequencer.m_seqr[0]);
   endtask : body
endclass : virtual_sequence_base


class cdma_simple_transfer_vseq extends virtual_sequence_base;
    `uvm_declare_p_sequencer(virtual_sequencer)
    `uvm_object_utils(cdma_simple_transfer_vseq)

    simple_mode_wr_rd_seq       master_reg_seq;
    base_slave_sequence         slave_resp_seq; 
    simple_mode_interrupt_check interrupt_seq; 

    function new(string name = "cdma_simple_transfer_vseq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("VSEQ", "Starting Virtual Sequence: Coordinating Master and Slave", UVM_LOW)
        master_reg_seq = simple_mode_wr_rd_seq::type_id::create("master_reg_seq");
        slave_resp_seq = base_slave_sequence::type_id::create("slave_resp_seq");
        interrupt_seq = simple_mode_interrupt_check::type_id::create("interrupt_seq");

        master_reg_seq.reg_block=p_sequencer.reg_block;
        interrupt_seq.reg_block=p_sequencer.reg_block;
        fork
            begin
                `uvm_info("VSEQ", "Starting Slave Responder...", UVM_LOW)
                slave_resp_seq.start(p_sequencer.s_seqr[0]); 
            end
            begin
                `uvm_info("VSEQ", "Starting Master Register Config...", UVM_LOW)
                master_reg_seq.start(p_sequencer.m_seqr[0]);
                `uvm_info("VSEQ", "Starting Interrupt Seq...", UVM_LOW)
                interrupt_seq.start(p_sequencer.m_seqr[0]);
            end
        join_any
        `uvm_info("VSEQ", "Virtual Sequence Complete!", UVM_LOW)
    endtask
endclass
