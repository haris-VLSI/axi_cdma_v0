class slave_agent extends uvm_agent;
   `uvm_component_utils (slave_agent)
   slave_sequencer  sqr;
   slave_driver     drv;
   slave_monitor    mon;

   //mem_module       mem_m;
   uvm_active_passive_enum agt_active ; // value set by env

   function new (string name = "slave_agent" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern function void build_phase              (uvm_phase phase);
   extern function void connect_phase            (uvm_phase phase);
endclass :slave_agent

function void slave_agent :: build_phase (uvm_phase phase);
     //if (!uvm_config_db #(config_obj) :: get (this , "" , "config_obj" ,cfg )) begin
     //   `uvm_warning("\t PLEASE SET THE CONFIG OBJECT","slave_agent");
     //end
     super.build_phase (phase);
     `uvm_info ("slave_agent" , phase.get_name() , UVM_MEDIUM)
     mon = slave_monitor :: type_id :: create ("mon",this);
     if (agt_active == UVM_ACTIVE) begin
        drv = slave_driver :: type_id :: create ("drv",this);
        sqr = slave_sequencer   :: type_id :: create ("sqr",this);
        //mem_m = mem_module   :: type_id :: create ("mem_m",this);
     end
  endfunction : build_phase

  function void slave_agent :: connect_phase (uvm_phase phase);
     super.connect_phase (phase);
     `uvm_info ("slave_agent::connect" , phase.get_name() , UVM_MEDIUM)
    
    //The Monitor drops the "Transaction Finished" letter in, and the Sequencer holds it until the Sequence is ready to read it.
     mon.resp_ap.connect(sqr.resp_af.analysis_export);
  endfunction : connect_phase
