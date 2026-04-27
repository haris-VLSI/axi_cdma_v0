class master_sequencer extends uvm_sequencer #(master_seq_item,master_seq_item);

   `uvm_component_utils (master_sequencer)

   function new (string name = "master_sequencer" , uvm_component parent);
      super.new(name,parent);
   endfunction
endclass :master_sequencer
