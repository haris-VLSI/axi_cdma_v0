class CDMACR_reg extends uvm_reg;
  `uvm_object_utils(CDMACR_reg)

  rand uvm_reg_field irq_delay;
  rand uvm_reg_field irq_threshold;
  uvm_reg_field rsvd_1;
  rand uvm_reg_field err_irq_en;
  rand uvm_reg_field dly_irq_en;
  rand uvm_reg_field ioc_irq_en;
  uvm_reg_field rsvd_2;
  rand uvm_reg_field cyc_bd_enable;
  rand uvm_reg_field keyhole_write;
  rand uvm_reg_field keyhole_read;
  rand uvm_reg_field sg_mode;
  rand uvm_reg_field reset;
  uvm_reg_field tail_ptr_en;
  uvm_reg_field rsvd_3;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    irq_delay = uvm_reg_field::type_id::create("irq_delay");
    irq_delay.configure(this, 8, 24, "RW", 0, 00, 1, 1, 0);
    irq_threshold = uvm_reg_field::type_id::create("irq_threshold");
    irq_threshold.configure(this, 8, 16, "RW", 0, 01, 1, 1, 0);
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 1, 15, "RO", 0, 0, 1, 0, 0);
    err_irq_en = uvm_reg_field::type_id::create("err_irq_en");
    err_irq_en.configure(this, 1, 14, "RW", 0, 0, 1, 1, 0);
    dly_irq_en = uvm_reg_field::type_id::create("dly_irq_en");
    dly_irq_en.configure(this, 1, 13, "RW", 0, 0, 1, 1, 0);
    ioc_irq_en = uvm_reg_field::type_id::create("ioc_irq_en");
    ioc_irq_en.configure(this, 1, 12, "RW", 0, 0, 1, 1, 0);
    rsvd_2 = uvm_reg_field::type_id::create("rsvd_2");
    rsvd_2.configure(this, 5, 7, "RO", 0, 0, 1, 0, 0);
    cyc_bd_enable = uvm_reg_field::type_id::create("cyc_bd_enable");
    cyc_bd_enable.configure(this, 1, 6, "RW", 0, 0, 1, 1, 0);
    keyhole_write = uvm_reg_field::type_id::create("keyhole_write");
    keyhole_write.configure(this, 1, 5, "RW", 0, 0, 1, 1, 0);
    keyhole_read = uvm_reg_field::type_id::create("keyhole_read");
    keyhole_read.configure(this, 1, 4, "RW", 0, 0, 1, 1, 0);
    sg_mode = uvm_reg_field::type_id::create("sg_mode");
    sg_mode.configure(this, 1, 3, "RW", 0, 0, 1, 1, 0);
    reset = uvm_reg_field::type_id::create("reset");
    reset.configure(this, 1, 2, "RW", 0, 0, 1, 1, 0);
    tail_ptr_en = uvm_reg_field::type_id::create("tail_ptr_en");
    tail_ptr_en.configure(this, 1, 1, "RO", 0, 1, 1, 0, 0);
    rsvd_3 = uvm_reg_field::type_id::create("rsvd_3");
    rsvd_3.configure(this, 1, 0, "RO", 0, 0, 1, 0, 0);
  endfunction
endclass
