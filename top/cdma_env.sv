class cdma_env extends uvm_env;
  `uvm_component_utils(cdma_env)

  cdma_reg_block        reg_block;
  cdma_reg_adapter      reg_adapter;
  //cdma_reg_predictor    reg_predictor;
  uvm_reg_predictor#(master_seq_item) reg_predictor;

  master_agent          m_agt[];
  slave_agent           s_agt[];
  virtual_sequencer     v_seqr;
  cdma_sbd              sbd;
  cdma_cov              cov;
  
  config_obj            obj;

  function new (string name = "cdma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("cdma_env::build", phase.get_name(), UVM_MEDIUM)
    reg_block     = cdma_reg_block::type_id::create("reg_block", this);
    reg_adapter   = cdma_reg_adapter::type_id::create("reg_adapter", this);
    //reg_predictor = cdma_reg_predictor::type_id::create("reg_predictor", this);
    reg_predictor = uvm_reg_predictor#(master_seq_item)::type_id::create("reg_predictor", this);
    reg_block.build();
  
    //uvm_config_db#(cdma_reg_block)::set(null, "*", "reg_block", reg_block);

    v_seqr = virtual_sequencer::type_id::create("v_seqr", this);

    if(!uvm_config_db #(config_obj)::get(this,"","config_obj",obj))
      `uvm_fatal(get_full_name(),"Config_obj get Failure");

    m_agt = new[obj.no_of_masters];
    s_agt = new[obj.no_of_slaves];

    for (int i = 0; i < obj.no_of_masters; i++) begin
      m_agt[i] = master_agent::type_id::create($sformatf("m_agt[%0d]", i), this);
      m_agt[i].agt_active = obj.mas_is_active[i];
    end

    for (int i = 0; i < obj.no_of_slaves; i++) begin
      s_agt[i] = slave_agent::type_id::create($sformatf("s_agt[%0d]", i), this);
      s_agt[i].agt_active = obj.slv_is_active[i];
    end
      sbd = cdma_sbd::type_id::create("sbd",this);
      cov = cdma_cov::type_id::create("cov",this);
  endfunction

  function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("cdma_env::connect", "inside_cdma_env_connect_phase", UVM_MEDIUM)

    sbd.reg_block           =   reg_block;
    reg_predictor.map       =   reg_block.default_map;
    reg_predictor.adapter   =   reg_adapter;
    //for explict prediction
    reg_block.default_map.set_auto_predict(0);
    //automatic prediction while performing READ
    reg_block.default_map.set_check_on_read(1);

    v_seqr.reg_block        =   reg_block;

    for (int i = 0; i < obj.no_of_masters; i++) begin
      m_agt[i].mon.master_mon_intf = obj.mas_if[i];
      if (obj.mas_is_active[i] == UVM_ACTIVE) begin
        if (m_agt[i].sqr == null) begin
          `uvm_warning("CONNECT", $sformatf("master agent %0d sequencer is null", i))
        end else begin
          //v_seqr.m_seqr[i] = m_agt[i].sqr;
          m_agt[i].drv.master_drv_intf = obj.mas_if[i];
          m_agt[i].drv.seq_item_port.connect(m_agt[i].sqr.seq_item_export);
          m_agt[i].mon.mon_ap.connect(sbd.master_af.analysis_export);
          m_agt[i].mon.mon_ap.connect(cov.analysis_export);

          reg_block.default_map.set_sequencer(m_agt[i].sqr, reg_adapter);
          `uvm_info("CONNECT", $sformatf("map -> sequencer_set_for_master %0d", i), UVM_MEDIUM)
        end
      end else begin
        `uvm_info("CONNECT", $sformatf("master %0d inactive, skipping driver/seq connect", i), UVM_MEDIUM)
      end
      if (m_agt[i].mon != null) begin
        m_agt[i].mon.mon_ap.connect(reg_predictor.bus_in);
        `uvm_info("CONNECT", $sformatf("mon_ap connected for master %0d", i), UVM_MEDIUM)
      end else begin
        `uvm_warning("CONNECT", $sformatf("master %0d monitor is null", i))
      end
    end

    for (int i = 0; i < obj.no_of_slaves; i++) begin
        s_agt[i].mon.slave_mon_intf = obj.slv_if[i];
        if (obj.slv_is_active[i] == UVM_ACTIVE) begin
            //v_seqr.s_seqr[i] = s_agt[i].sqr;
            
            s_agt[i].sqr.vif = obj.slv_if[i];

            s_agt[i].drv.slave_drv_intf = obj.slv_if[i];
            s_agt[i].drv.seq_item_port.connect(s_agt[i].sqr.seq_item_export);
            s_agt[i].mon.mon_ap.connect(sbd.slave_af.analysis_export);

            //connected in slave agent
            //s_agt[i].mon.resp_ap.connect(s_agt[i].sqr.resp_af.analysis_export);
            `uvm_info("CONNECT", $sformatf("slave driver connected for slave %0d", i), UVM_MEDIUM);
        end
    end
  endfunction

  function void start_of_simulation_phase (uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("cdma_env::sim", phase.get_name(), UVM_MEDIUM)
        `uvm_info("RUNTIME_CHECK", $sformatf("auto_predict=%0d", reg_block.default_map.get_auto_predict()), UVM_MEDIUM);
        reg_block.default_map.print();
        reg_block.print();
  endfunction

  task main_phase (uvm_phase phase);
        `uvm_info("cdma_env::main", phase.get_name(), UVM_MEDIUM)
  endtask

endclass : cdma_env
