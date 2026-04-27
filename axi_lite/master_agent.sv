class master_agent extends uvm_agent;

   `uvm_component_utils (master_agent)
   master_monitor    mon;
   master_driver     drv;
   master_sequencer  sqr;
   uvm_active_passive_enum agt_active ;     //value set by env
   //config_obj        cfg;					//config_object

   function new (string name = "master_agent" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern function void build_phase   (uvm_phase phase);
   extern function void connect_phase (uvm_phase phase);

endclass :master_agent

function void master_agent :: build_phase (uvm_phase phase);
   //if (!uvm_config_db #(config_obj) :: get (this, "" , "config_obj" ,cfg )) begin
   //   `uvm_fatal(get_full_name(),"Config_obj get Failure");
   //end
   super.build_phase (phase);
   `uvm_info ("master_agent" , phase.get_name() , UVM_MEDIUM)
   mon = master_monitor :: type_id :: create ("mon",this);
   if (agt_active == UVM_ACTIVE) begin
      drv = master_driver::type_id::create ("drv",this);
      sqr = master_sequencer::type_id::create ("sqr",this);
   end
endfunction : build_phase

function void master_agent :: connect_phase (uvm_phase phase);
   super.connect_phase (phase);
   `uvm_info ("master_agent::connect" , phase.get_name() , UVM_MEDIUM)
endfunction : connect_phase
