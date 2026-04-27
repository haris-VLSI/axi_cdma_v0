class SA_MSB_reg extends uvm_reg;
  `uvm_object_utils(SA_MSB_reg)

  uvm_reg_field src_addr_msb;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    src_addr_msb = uvm_reg_field::type_id::create("src_addr_msb");
    src_addr_msb.configure(this, 32, 0, "RW", 0, 0, 1, 0, 0);
  endfunction
endclass
