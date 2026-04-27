class cdma_reg_block extends uvm_reg_block;
  `uvm_object_utils(cdma_reg_block)

  CDMACR_reg cdmacr;
  CDMASR_reg cdmasr;
  CURDESC_PTR_reg curdesc_ptr;
  CURDESC_PTR_MSB_reg curdesc_ptr_msb;
  TAILDESC_PTR_reg taildesc_ptr;
  TAILDESC_PTR_MSB_reg taildesc_ptr_msb;
  SA_reg sa;
  SA_MSB_reg sa_msb;
  DA_reg da;
  DA_MSB_reg da_msb;
  BTT_reg btt;

  function new(string name = "cdma_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);

    cdmacr = CDMACR_reg::type_id::create("CDMACR");
    cdmacr.configure(this);
    cdmacr.build();
    default_map.add_reg(cdmacr, 'h00, "RW");
    
    cdmasr = CDMASR_reg::type_id::create("CDMASR");
    cdmasr.configure(this);
    cdmasr.build();
    default_map.add_reg(cdmasr, 'h04, "RW");
    
    curdesc_ptr = CURDESC_PTR_reg::type_id::create("CURDESC_PTR");
    curdesc_ptr.configure(this);
    curdesc_ptr.build();
    default_map.add_reg(curdesc_ptr, 'h08, "RW");
    
    curdesc_ptr_msb = CURDESC_PTR_MSB_reg::type_id::create("CURDESC_PTR_MSB");
    curdesc_ptr_msb.configure(this);
    curdesc_ptr_msb.build();
    default_map.add_reg(curdesc_ptr_msb, 'h0c, "RW");
    
    taildesc_ptr = TAILDESC_PTR_reg::type_id::create("TAILDESC_PTR");
    taildesc_ptr.configure(this);
    taildesc_ptr.build();
    default_map.add_reg(taildesc_ptr, 'h10, "RW");
    
    taildesc_ptr_msb = TAILDESC_PTR_MSB_reg::type_id::create("TAILDESC_PTR_MSB");
    taildesc_ptr_msb.configure(this);
    taildesc_ptr_msb.build();
    default_map.add_reg(taildesc_ptr_msb, 'h14, "RW");
    
    sa = SA_reg::type_id::create("SA");
    sa.configure(this);
    sa.build();
    default_map.add_reg(sa, 'h18, "RW");
    
    sa_msb = SA_MSB_reg::type_id::create("SA_MSB");
    sa_msb.configure(this);
    sa_msb.build();
    default_map.add_reg(sa_msb, 'h1c, "RW");
    
    da = DA_reg::type_id::create("DA");
    da.configure(this);
    da.build();
    default_map.add_reg(da, 'h20, "RW");
    
    da_msb = DA_MSB_reg::type_id::create("DA_MSB");
    da_msb.configure(this);
    da_msb.build();
    default_map.add_reg(da_msb, 'h24, "RW");
    
    btt = BTT_reg::type_id::create("BTT");
    btt.configure(this);
    btt.build();
    default_map.add_reg(btt, 'h28, "RW");
  endfunction
endclass
