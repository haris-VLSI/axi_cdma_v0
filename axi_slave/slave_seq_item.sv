class slave_seq_item extends axi_base_seq_item;
  //FACTORY REGISTRATION
   `uvm_object_utils_begin(slave_seq_item)
      `uvm_field_int(awid,UVM_ALL_ON)
      `uvm_field_int(awaddr,UVM_ALL_ON)
      `uvm_field_int(awlen,UVM_ALL_ON)
      `uvm_field_int(awsize,UVM_ALL_ON)
      `uvm_field_enum(burst_type_t,awburst,UVM_ALL_ON)
      //`uvm_field_int(awlock,UVM_ALL_ON)
      //`uvm_field_int(awregion,UVM_ALL_ON)
      `uvm_field_int(awprot,UVM_ALL_ON)
      `uvm_field_int(awcache,UVM_ALL_ON)
      `uvm_field_int(awvalid,UVM_ALL_ON)
      `uvm_field_int(awready,UVM_ALL_ON)
//-------------write data channel----------//  
      `uvm_field_array_int(wdata,UVM_ALL_ON)
      `uvm_field_array_int(wstrobe,UVM_ALL_ON | UVM_BIN)
      `uvm_field_int(wlast,UVM_ALL_ON)
      `uvm_field_int(wvalid,UVM_ALL_ON)
      `uvm_field_int(wready,UVM_ALL_ON)
//----------write response channel---------//
      `uvm_field_int(bid,UVM_ALL_ON)
      `uvm_field_enum(response_t,bresp,UVM_ALL_ON)
      `uvm_field_int(bvalid,UVM_ALL_ON)
      `uvm_field_int(bready,UVM_ALL_ON)
//-----------read address channel----------//  
      `uvm_field_int(arid,UVM_ALL_ON)
      `uvm_field_int(araddr,UVM_ALL_ON)
      `uvm_field_int(arlen,UVM_ALL_ON)
      `uvm_field_int(arsize,UVM_ALL_ON)
      `uvm_field_enum(burst_type_t,arburst,UVM_ALL_ON)
      //`uvm_field_int(arlock,UVM_ALL_ON)
      //`uvm_field_int(arqos,UVM_ALL_ON)
      //`uvm_field_int(arregion,UVM_ALL_ON)
      `uvm_field_int(arprot,UVM_ALL_ON)
      `uvm_field_int(arcache,UVM_ALL_ON)
      `uvm_field_int(arvalid,UVM_ALL_ON)
      `uvm_field_int(arready,UVM_ALL_ON)
     //-----------read data channel-------------//
      `uvm_field_array_int(rdata,UVM_ALL_ON)
      `uvm_field_array_enum(response_t,rresp,UVM_ALL_ON)
      `uvm_field_int(rlast,UVM_ALL_ON)
      `uvm_field_int(rid,UVM_ALL_ON)
      `uvm_field_int(rvalid,UVM_ALL_ON)
      `uvm_field_int(rready,UVM_ALL_ON)
      //`uvm_field_enum(slave_type,slave,UVM_ALL_ON)
      //----------------------------------------//
      /*
      uvm_field_int(align_unaligned,UVM_ALL_ON)
      uvm_field_enum(command_t,operation,UVM_ALL_ON)
      uvm_field_enum(master_type,master,UVM_ALL_ON)
           uvm_field_enum(order_type_e_t,order_type,UVM_ALL_ON)
      //uvm_field_enum(cmmd,cmd,UVM_ALL_ON)
      //uvm_field_enum(burst_type,UVM_ALL_ON)
      */    
   `uvm_object_utils_end
  //MEMEBERS
  //delays
   //rand delay_t write_ready2ready_dly[]; // serves as ready2ready for write
   //rand delay_t read_valid2valid_dly[];// valid2valid delay for read txn
   //rand delay_t add_ready_dly; //ar_ready or aw_ready delay
   //rand delay_t data2resp_dly; //delay between write data and response phase


  function new (string name = "slave_seq_item");
     super.new (name);
  endfunction

  //CONSTRAINTS

  //constraint arsize_c{arsize inside {[0:5]};} //max 256 bit or 32 byte port
  //constraint awsize_c{awsize inside {[0:5]};} //max 256 bit or 32 byte port
  constraint rdata_c { rdata.size() == arlen +1;}
  //constraint wdata_c {wdata.size() == awlen+1;}
  //constraint bresp_c {soft bresp==OKAY;}
  constraint rresp_c {solve arlen before rresp;
                      rresp.size() == arlen+1;
                      foreach(rresp[i]) soft rresp[i]==OKAY;} //keeping default response okay


 constraint c_rdata { solve arlen before rdata;
                       solve arsize before rdata;
                       rdata.size() == (arlen+1);
                       foreach(rdata[i]) {
                         if(arsize == 2)
                          {
                           rdata[i] inside {['h0000_0000:'hffff_ffff]};
                           }
                         if(arsize == 3)
                          {
                           rdata[i] inside {['h0000_0000_0000_0000:'hffff_ffff_ffff_ffff]};
                           }
                         if(arsize == 4)
                          {
                           rdata[i] inside {['h0000_0000_0000_0000_0000_0000_0000_0000:'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff]};
                           }
                         if(arsize == 5)
                          {
                           rdata[i] inside  {['h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff]};
                          }
	                 }
                         }



  //delay constraints
  //constraint add_ready_dly_c{soft add_ready_dly inside {[2:10]};}
  //constraint write_ready2ready_dly_c{solve awlen before write_ready2ready_dly;
  //                                  write_ready2ready_dly.size()==awlen+1;
  //                                  foreach(write_ready2ready_dly[i])
  //                                  {soft write_ready2ready_dly[i] inside {[2:20]};}
  //                                  }
  //constraint read_valid2valid_dly_c{solve arlen before read_valid2valid_dly;
  //                                  read_valid2valid_dly.size()==arlen+1;
  //                                  foreach(read_valid2valid_dly[i])
  //                                  {read_valid2valid_dly[i] inside {[0:20]};}
  //                                  }
  //USER-DEFINED METHODS
endclass : slave_seq_item
