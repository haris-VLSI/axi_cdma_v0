class reg_seq_item extends uvm_sequence_item;
    rand bit [31:0] cdmacr;
    rand bit [31:0] cdmasr;
    rand bit [31:0] curdesc_pntr;
    rand bit [31:0] curdesc_pntr_msb;
    rand bit [31:0] taildesc_pntr;
    rand bit [31:0] taildesc_pntr_msb;
    rand bit [31:0] sa_addr;
    rand bit [31:0] sa_msb;
    rand bit [31:0] da_addr;
    rand bit [31:0] da_msb;
    rand bit [26:0] btt_bytes;

    rand btt_type_t btt_s;

    `uvm_object_utils_begin(reg_seq_item)
      `uvm_field_int(cdmacr,            UVM_ALL_ON)
      `uvm_field_int(cdmasr,            UVM_ALL_ON)
      `uvm_field_int(curdesc_pntr,      UVM_ALL_ON)
      `uvm_field_int(curdesc_pntr_msb,  UVM_ALL_ON)
      `uvm_field_int(taildesc_pntr,     UVM_ALL_ON)
      `uvm_field_int(taildesc_pntr_msb, UVM_ALL_ON)
      `uvm_field_int(sa_addr,           UVM_ALL_ON)
      `uvm_field_int(sa_msb,            UVM_ALL_ON)
      `uvm_field_int(da_addr,           UVM_ALL_ON)
      `uvm_field_int(da_msb,            UVM_ALL_ON)
      `uvm_field_int(btt_bytes,         UVM_ALL_ON)
      `uvm_field_enum(btt_type_t,btt_s, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "cdma_reg_seq_item");
      super.new(name);
    endfunction

    constraint order_ct {
        solve btt_s before btt_bytes;
        solve btt_bytes before sa_addr, da_addr;
    }

    constraint btt_bytes_ct {
        if(btt_s == ONE)       soft btt_bytes == 'd1;
        else if(btt_s == SML)  soft btt_bytes == 'd64;
        else if(btt_s == MIN)  soft btt_bytes inside {['d65   : 'd1024]};
        else if(btt_s == MED)  soft btt_bytes inside {['d1025 : 'd4096]};
        else if(btt_s == MB)   soft btt_bytes == 'h10_0000;
        else if(btt_s == MAX)  soft btt_bytes == 'h3FF_FFFF;
        else if(btt_s == MAXP) soft btt_bytes == 'h400_0000;
    }

    constraint sa_addr_ct {
        if(btt_s inside {MIN, ONE, SML}) 
            soft sa_addr inside {[64'h0000_0000_0000_0000 : 64'h0000_0000_0000_0400]};
        else if(btt_s inside {MED, MB}) 
            soft sa_addr inside {[64'h0000_0000_1000_0000 : 64'h0000_0000_2000_0000]};
        else if(btt_s == MAX) 
            soft sa_addr inside {[64'h0000_1000_0000_0000 : 64'h0000_2000_0000_0000]};
        else 
            soft sa_addr inside {[64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_F000_0000]};
    }

    constraint da_addr_ct {
        if(btt_s inside {MIN, ONE, SML}) 
            soft da_addr inside {[64'h1000_0000_0000_0000 : 64'h1000_0000_0000_2000]};
        else if(btt_s inside {MED, MB}) 
            soft da_addr inside {[64'h1000_0000_1000_0000 : 64'h1000_0000_2000_0000]};
        else if(btt_s == MAX) 
            soft da_addr inside {[64'h1000_1000_0000_0000 : 64'h1000_2000_0000_0000]};
        else 
            soft da_addr inside {[64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_F000_0000]};
    }

    constraint overlapp_ct {
        soft (sa_addr + btt_bytes) <= 64'hFFFF_FFFF_FFFF_FFFF;
        soft (da_addr + btt_bytes) <= 64'hFFFF_FFFF_FFFF_FFFF;
        soft ((da_addr + btt_bytes) < sa_addr) || ((sa_addr + btt_bytes) < da_addr);
    }

    constraint alignment_ct {
        soft sa_addr   % 16 == 0;
        soft da_addr   % 16 == 0;
        soft btt_bytes % 16 == 0;
    }
endclass: reg_seq_item
