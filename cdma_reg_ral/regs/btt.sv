class BTT_reg extends uvm_reg;
  `uvm_object_utils(BTT_reg)

  uvm_reg_field rsvd_1;
  uvm_reg_field btt_len;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 6, 26, "RO", 0, 0, 1, 0, 0);
    btt_len = uvm_reg_field::type_id::create("btt_len");
    btt_len.configure(this, 26, 0, "RW", 0, 0, 1, 0, 0);
  endfunction
endclass
