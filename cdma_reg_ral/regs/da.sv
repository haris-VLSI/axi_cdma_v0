class DA_reg extends uvm_reg;
  `uvm_object_utils(DA_reg)

  uvm_reg_field dest_addr;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    dest_addr = uvm_reg_field::type_id::create("dest_addr");
    dest_addr.configure(this, 32, 0, "RW", 0, 0, 1, 0, 0);
  endfunction
endclass
