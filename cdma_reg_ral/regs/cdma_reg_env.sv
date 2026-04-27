class cdma_reg_env extends uvm_env;
  `uvm_component_utils(cdma_reg_env)

  cdma_reg_block     reg_block;
  cdma_reg_adapter   reg_adapter;
  cdma_reg_predictor reg_predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reg_block     = cdma_reg_block::type_id::create("reg_block", this);
    reg_adapter   = cdma_reg_adapter::type_id::create("reg_adapter");
    reg_predictor = cdma_reg_predictor::type_id::create("reg_predictor", this);
    reg_block.build();
    reg_block.lock_model();
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //reg_block.default_map.set_sequencer(axi_sequencer, reg_adapter);
    reg_predictor.map = reg_block.default_map;
    reg_predictor.adapter = reg_adapter;
    //axi_monitor.ap.connect(reg_predictor.bus_in);
  endfunction
endclass
