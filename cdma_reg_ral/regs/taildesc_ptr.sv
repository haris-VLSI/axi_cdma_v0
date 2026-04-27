class TAILDESC_PTR_reg extends uvm_reg;
  `uvm_object_utils(TAILDESC_PTR_reg)

  uvm_reg_field tail_desc_ptr;
  uvm_reg_field rsvd_1;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    tail_desc_ptr = uvm_reg_field::type_id::create("tail_desc_ptr");
    tail_desc_ptr.configure(this, 26, 6, "RW", 0, 0, 1, 0, 0);
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 6, 0, "RO", 0, 0, 1, 0, 0);
  endfunction
endclass
