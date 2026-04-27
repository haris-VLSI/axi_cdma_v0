class cdma_reg_predictor extends uvm_reg_predictor #(master_seq_item);
  `uvm_component_utils(cdma_reg_predictor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void write(master_seq_item tr);
	  uvm_reg rg;
	  uvm_reg_bus_op rw;

	  super.write(tr);
	  adapter.bus2reg(tr,rw);
	  rg = map.get_reg_by_offset(rw.addr,(rw.kind == UVM_READ));
	  rg.sample_values();
	endfunction
endclass
