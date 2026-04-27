class CURDESC_PTR_MSB_reg extends uvm_reg;
  `uvm_object_utils(CURDESC_PTR_MSB_reg)

  uvm_reg_field curr_desc_ptr_msb;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    curr_desc_ptr_msb = uvm_reg_field::type_id::create("curr_desc_ptr_msb");
    curr_desc_ptr_msb.configure(this, 32, 0, "RW", 0, 0, 1, 0, 0);
  endfunction
endclass
