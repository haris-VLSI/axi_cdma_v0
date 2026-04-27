class CDMASR_reg extends uvm_reg;
  `uvm_object_utils(CDMASR_reg)

  uvm_reg_field irq_delay_sts;
  uvm_reg_field irq_threshold_sts;
  uvm_reg_field rsvd_1;
  uvm_reg_field err_irq;
  uvm_reg_field dly_irq;
  uvm_reg_field ioc_irq;
  uvm_reg_field rsvd_2;
  uvm_reg_field sg_dec_err;
  uvm_reg_field sg_slv_err;
  uvm_reg_field sg_int_err;
  uvm_reg_field rsvd_3;
  uvm_reg_field dma_dec_err;
  uvm_reg_field dma_slv_err;
  uvm_reg_field dma_int_err;
  uvm_reg_field sg_incld;
  uvm_reg_field rsvd_4;
  uvm_reg_field idle;
  uvm_reg_field rsvd_5;

  function new(string name = "{reg_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    irq_delay_sts = uvm_reg_field::type_id::create("irq_delay_sts");
    irq_delay_sts.configure(this, 8, 24, "RO", 0, 00, 1, 0, 0);
    irq_threshold_sts = uvm_reg_field::type_id::create("irq_threshold_sts");
    irq_threshold_sts.configure(this, 8, 16, "RO", 0, 01, 1, 0, 0);
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 1, 15, "RO", 0, 0, 1, 0, 0);
    err_irq = uvm_reg_field::type_id::create("err_irq");
    err_irq.configure(this, 1, 14, "W1C", 0, 0, 1, 0, 0);
    dly_irq = uvm_reg_field::type_id::create("dly_irq");
    dly_irq.configure(this, 1, 13, "W1C", 0, 0, 1, 0, 0);
    ioc_irq = uvm_reg_field::type_id::create("ioc_irq");
    ioc_irq.configure(this, 1, 12, "W1C", 0, 0, 1, 0, 0);
    rsvd_2 = uvm_reg_field::type_id::create("rsvd_2");
    rsvd_2.configure(this, 1, 11, "RO", 0, 0, 1, 0, 0);
    sg_dec_err = uvm_reg_field::type_id::create("sg_dec_err");
    sg_dec_err.configure(this, 1, 10, "RO", 0, 0, 1, 0, 0);
    sg_slv_err = uvm_reg_field::type_id::create("sg_slv_err");
    sg_slv_err.configure(this, 1, 9, "RO", 0, 0, 1, 0, 0);
    sg_int_err = uvm_reg_field::type_id::create("sg_int_err");
    sg_int_err.configure(this, 1, 8, "RO", 0, 0, 1, 0, 0);
    rsvd_3 = uvm_reg_field::type_id::create("rsvd_3");
    rsvd_3.configure(this, 1, 7, "RO", 0, 0, 1, 0, 0);
    dma_dec_err = uvm_reg_field::type_id::create("dma_dec_err");
    dma_dec_err.configure(this, 1, 6, "RO", 0, 0, 1, 0, 0);
    dma_slv_err = uvm_reg_field::type_id::create("dma_slv_err");
    dma_slv_err.configure(this, 1, 5, "RO", 0, 0, 1, 0, 0);
    dma_int_err = uvm_reg_field::type_id::create("dma_int_err");
    dma_int_err.configure(this, 1, 4, "RO", 0, 0, 1, 0, 0);
    sg_incld = uvm_reg_field::type_id::create("sg_incld");
    sg_incld.configure(this, 1, 3, "RO", 0, 1, 1, 0, 0);
    rsvd_4 = uvm_reg_field::type_id::create("rsvd_4");
    rsvd_4.configure(this, 1, 2, "RO", 0, 0, 1, 0, 0);
    idle = uvm_reg_field::type_id::create("idle");
    idle.configure(this, 1, 1, "RO", 0, 1, 1, 0, 0);
    rsvd_5 = uvm_reg_field::type_id::create("rsvd_5");
    rsvd_5.configure(this, 1, 0, "RO", 0, 0, 1, 0, 0);
  endfunction
endclass
