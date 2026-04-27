import uvm_pkg::*;
`include "uvm_macros.svh"

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

  function new(string name = "CDMACR_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 1, 0, "RO", 0, 0, 1, 0, 0);
    tail_ptr_en = uvm_reg_field::type_id::create("tail_ptr_en");
    tail_ptr_en.configure(this, 1, 1, "RO", 0, 1, 1, 0, 0);
    reset = uvm_reg_field::type_id::create("reset");
    reset.configure(this, 1, 2, "RW", 1, 0, 1, 1, 0);
    sg_mode = uvm_reg_field::type_id::create("sg_mode");
    sg_mode.configure(this, 1, 3, "RW", 0, 0, 1, 1, 0);
    keyhole_read = uvm_reg_field::type_id::create("keyhole_read");
    keyhole_read.configure(this, 1, 4, "RW", 0, 0, 1, 1, 0);
    keyhole_write = uvm_reg_field::type_id::create("keyhole_write");
    keyhole_write.configure(this, 1, 5, "RW", 0, 0, 1, 1, 0);
    cyc_bd_enable = uvm_reg_field::type_id::create("cyc_bd_enable");
    cyc_bd_enable.configure(this, 1, 6, "RW", 0, 0, 1, 1, 0);
    rsvd_2 = uvm_reg_field::type_id::create("rsvd_2");
    rsvd_2.configure(this, 5, 7, "RO", 0, 0, 1, 0, 0);
    ioc_irq_en = uvm_reg_field::type_id::create("ioc_irq_en");
    ioc_irq_en.configure(this, 1, 12, "RW", 0, 0, 1, 1, 0);
    dly_irq_en = uvm_reg_field::type_id::create("dly_irq_en");
    dly_irq_en.configure(this, 1, 13, "RW", 0, 0, 1, 1, 0);
    err_irq_en = uvm_reg_field::type_id::create("err_irq_en");
    err_irq_en.configure(this, 1, 14, "RW", 0, 0, 1, 1, 0);
    rsvd_3 = uvm_reg_field::type_id::create("rsvd_3");
    rsvd_3.configure(this, 1, 15, "RO", 0, 0, 1, 0, 0);
    irq_threshold = uvm_reg_field::type_id::create("irq_threshold");
    irq_threshold.configure(this, 8, 16, "RW", 0, 8'h01, 1, 1, 0);
    irq_delay = uvm_reg_field::type_id::create("irq_delay");
    irq_delay.configure(this, 8, 24, "RW", 0, 8'h00, 1, 1, 0);
  endfunction
endclass

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

  function new(string name = "CDMASR_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rsvd_5 = uvm_reg_field::type_id::create("rsvd_5");
    rsvd_5.configure(this, 1, 0, "RO", 0, 0, 1, 0, 0);
    idle = uvm_reg_field::type_id::create("idle");
    idle.configure(this, 1, 1, "RO", 1, 1, 1, 0, 0);
    rsvd_4 = uvm_reg_field::type_id::create("rsvd_4");
    rsvd_4.configure(this, 1, 2, "RO", 0, 0, 1, 0, 0);
    sg_incld = uvm_reg_field::type_id::create("sg_incld");
    sg_incld.configure(this, 1, 3, "RO", 0, 1, 1, 0, 0);
    dma_int_err = uvm_reg_field::type_id::create("dma_int_err");
    dma_int_err.configure(this, 1, 4, "RO", 1, 0, 1, 0, 0);
    dma_slv_err = uvm_reg_field::type_id::create("dma_slv_err");
    dma_slv_err.configure(this, 1, 5, "RO", 1, 0, 1, 0, 0);
    dma_dec_err = uvm_reg_field::type_id::create("dma_dec_err");
    dma_dec_err.configure(this, 1, 6, "RO", 1, 0, 1, 0, 0);
    rsvd_3 = uvm_reg_field::type_id::create("rsvd_3");
    rsvd_3.configure(this, 1, 7, "RO", 0, 0, 1, 0, 0);
    sg_int_err = uvm_reg_field::type_id::create("sg_int_err");
    sg_int_err.configure(this, 1, 8, "RO", 1, 0, 1, 0, 0);
    sg_slv_err = uvm_reg_field::type_id::create("sg_slv_err");
    sg_slv_err.configure(this, 1, 9, "RO", 1, 0, 1, 0, 0);
    sg_dec_err = uvm_reg_field::type_id::create("sg_dec_err");
    sg_dec_err.configure(this, 1, 10, "RO", 1, 0, 1, 0, 0);
    rsvd_2 = uvm_reg_field::type_id::create("rsvd_2");
    rsvd_2.configure(this, 1, 11, "RO", 0, 0, 1, 0, 0);
    ioc_irq = uvm_reg_field::type_id::create("ioc_irq");
    ioc_irq.configure(this, 1, 12, "W1C", 1, 0, 1, 0, 0);
    dly_irq = uvm_reg_field::type_id::create("dly_irq");
    dly_irq.configure(this, 1, 13, "W1C", 1, 0, 1, 0, 0);
    err_irq = uvm_reg_field::type_id::create("err_irq");
    err_irq.configure(this, 1, 14, "W1C", 1, 0, 1, 0, 0);
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 1, 15, "RO", 0, 0, 1, 0, 0);
    irq_threshold_sts = uvm_reg_field::type_id::create("irq_threshold_sts");
    irq_threshold_sts.configure(this, 8, 16, "RO", 0, 8'h01, 1, 0, 0);
    irq_delay_sts = uvm_reg_field::type_id::create("irq_delay_sts");
    irq_delay_sts.configure(this, 8, 24, "RO", 0, 8'h00, 1, 0, 0);
  endfunction
endclass

class CURDESC_PTR_reg extends uvm_reg;
  `uvm_object_utils(CURDESC_PTR_reg)

  rand uvm_reg_field curr_desc_ptr;
  uvm_reg_field rsvd_1;

  function new(string name = "CURDESC_PTR_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 6, 0, "RO", 0, 0, 1, 0, 1);
    curr_desc_ptr = uvm_reg_field::type_id::create("curr_desc_ptr");
    curr_desc_ptr.configure(this, 26, 6, "RW", 0, 0, 1, 1, 1);
  endfunction
endclass

class CURDESC_PTR_MSB_reg extends uvm_reg;
  `uvm_object_utils(CURDESC_PTR_MSB_reg)

  rand uvm_reg_field curr_desc_ptr_msb;

  function new(string name = "CURDESC_PTR_MSB_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    curr_desc_ptr_msb = uvm_reg_field::type_id::create("curr_desc_ptr_msb");
    curr_desc_ptr_msb.configure(this, 32, 0, "RW", 1, 0, 1, 1, 0);
  endfunction
endclass

class TAILDESC_PTR_reg extends uvm_reg;
  `uvm_object_utils(TAILDESC_PTR_reg)

  rand uvm_reg_field tail_desc_ptr;
  uvm_reg_field rsvd_1;

  function new(string name = "TAILDESC_PTR_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 6, 0, "RO", 0, 0, 1, 0, 0);
    tail_desc_ptr = uvm_reg_field::type_id::create("tail_desc_ptr");
    tail_desc_ptr.configure(this, 26, 6, "RW", 0, 0, 1, 1, 0);
  endfunction
endclass

class TAILDESC_PTR_MSB_reg extends uvm_reg;
  `uvm_object_utils(TAILDESC_PTR_MSB_reg)

  rand uvm_reg_field tail_desc_ptr_msb;

  function new(string name = "TAILDESC_PTR_MSB_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    tail_desc_ptr_msb = uvm_reg_field::type_id::create("tail_desc_ptr_msb");
    tail_desc_ptr_msb.configure(this, 32, 0, "RW", 0, 0, 1, 1, 0);
  endfunction
endclass

class SA_reg extends uvm_reg;
  `uvm_object_utils(SA_reg)

  rand uvm_reg_field src_addr;

  function new(string name = "SA_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    src_addr = uvm_reg_field::type_id::create("src_addr");
    src_addr.configure(this, 32, 0, "RW", 0, 0, 1, 1, 0);
  endfunction
endclass

class SA_MSB_reg extends uvm_reg;
  `uvm_object_utils(SA_MSB_reg)

  rand uvm_reg_field src_addr_msb;

  function new(string name = "SA_MSB_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    src_addr_msb = uvm_reg_field::type_id::create("src_addr_msb");
    src_addr_msb.configure(this, 32, 0, "RW", 0, 0, 1, 1, 0);
  endfunction
endclass

class DA_reg extends uvm_reg;
  `uvm_object_utils(DA_reg)

  rand uvm_reg_field dest_addr;

  function new(string name = "DA_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    dest_addr = uvm_reg_field::type_id::create("dest_addr");
    dest_addr.configure(this, 32, 0, "RW", 0, 0, 1, 1, 0);
  endfunction
endclass

class DA_MSB_reg extends uvm_reg;
  `uvm_object_utils(DA_MSB_reg)

  rand uvm_reg_field dest_addr_msb;

  function new(string name = "DA_MSB_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    dest_addr_msb = uvm_reg_field::type_id::create("dest_addr_msb");
    dest_addr_msb.configure(this, 32, 0, "RW", 0, 0, 1, 1, 0);
  endfunction
endclass

class BTT_reg extends uvm_reg;
  `uvm_object_utils(BTT_reg)

  uvm_reg_field rsvd_1;
  rand uvm_reg_field btt_len;

  function new(string name = "BTT_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    btt_len = uvm_reg_field::type_id::create("btt_len");
    btt_len.configure(this, 26, 0, "RW", 0, 0, 1, 1, 0);
    rsvd_1 = uvm_reg_field::type_id::create("rsvd_1");
    rsvd_1.configure(this, 6, 26, "RO", 0, 0, 1, 0, 0);
  endfunction
endclass

class cdma_reg_block extends uvm_reg_block;
  `uvm_object_utils(cdma_reg_block)

  rand CDMACR_reg CDMACR;
  rand CDMASR_reg CDMASR;
  rand CURDESC_PTR_reg CURDESC_PTR;
  rand CURDESC_PTR_MSB_reg CURDESC_PTR_MSB;
  rand TAILDESC_PTR_reg TAILDESC_PTR;
  rand TAILDESC_PTR_MSB_reg TAILDESC_PTR_MSB;
  rand SA_reg SA;
  rand SA_MSB_reg SA_MSB;
  rand DA_reg DA;
  rand DA_MSB_reg DA_MSB;
  rand BTT_reg BTT;

  function new(string name = "cdma_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN, 1);

    CDMACR = CDMACR_reg::type_id::create("CDMACR");
    CDMACR.configure(this, null, "CDMACR");
    CDMACR.build();
    default_map.add_reg(CDMACR, 'h00, "RW");

    CDMASR = CDMASR_reg::type_id::create("CDMASR");
    CDMASR.configure(this, null, "CDMASR");
    CDMASR.build();
    default_map.add_reg(CDMASR, 'h04, "RW");

    CURDESC_PTR = CURDESC_PTR_reg::type_id::create("CURDESC_PTR");
    CURDESC_PTR.configure(this, null, "CURDESC_PTR");
    CURDESC_PTR.build();
    default_map.add_reg(CURDESC_PTR, 'h08, "RW");

    CURDESC_PTR_MSB = CURDESC_PTR_MSB_reg::type_id::create("CURDESC_PTR_MSB");
    CURDESC_PTR_MSB.configure(this, null, "CURDESC_PTR_MSB");
    CURDESC_PTR_MSB.build();
    default_map.add_reg(CURDESC_PTR_MSB, 'h0c, "RW");

    TAILDESC_PTR = TAILDESC_PTR_reg::type_id::create("TAILDESC_PTR");
    TAILDESC_PTR.configure(this, null, "TAILDESC_PTR");
    TAILDESC_PTR.build();
    default_map.add_reg(TAILDESC_PTR, 'h10, "RW");

    TAILDESC_PTR_MSB = TAILDESC_PTR_MSB_reg::type_id::create("TAILDESC_PTR_MSB");
    TAILDESC_PTR_MSB.configure(this, null, "TAILDESC_PTR_MSB");
    TAILDESC_PTR_MSB.build();
    default_map.add_reg(TAILDESC_PTR_MSB, 'h14, "RW");

    SA = SA_reg::type_id::create("SA");
    SA.configure(this, null, "SA");
    SA.build();
    default_map.add_reg(SA, 'h18, "RW");

    SA_MSB = SA_MSB_reg::type_id::create("SA_MSB");
    SA_MSB.configure(this, null, "SA_MSB");
    SA_MSB.build();
    default_map.add_reg(SA_MSB, 'h1c, "RW");

    DA = DA_reg::type_id::create("DA");
    DA.configure(this, null, "DA");
    DA.build();
    default_map.add_reg(DA, 'h20, "RW");

    DA_MSB = DA_MSB_reg::type_id::create("DA_MSB");
    DA_MSB.configure(this, null, "DA_MSB");
    DA_MSB.build();
    default_map.add_reg(DA_MSB, 'h24, "RW");

    BTT = BTT_reg::type_id::create("BTT");
    BTT.configure(this, null, "BTT");
    BTT.build();
    default_map.add_reg(BTT, 'h28, "RW");

    lock_model();
  endfunction
endclass
