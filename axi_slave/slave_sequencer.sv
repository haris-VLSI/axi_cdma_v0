class slave_sequencer extends uvm_sequencer #(slave_seq_item,slave_seq_item);
    `uvm_component_utils (slave_sequencer)
    uvm_tlm_analysis_fifo #(slave_seq_item) resp_af;
    virtual slave_intf vif;

    function new (string name = "slave_sequencer" , uvm_component parent);
        super.new(name,parent);
        resp_af = new ("resp_af",this);
    endfunction

    extern task main_phase (uvm_phase phase);
endclass :slave_sequencer

task slave_sequencer :: main_phase (uvm_phase phase);
    `uvm_info (get_full_name(),"slave_sequencer :: main_phase Triggred"  , UVM_MEDIUM)
endtask : main_phase
