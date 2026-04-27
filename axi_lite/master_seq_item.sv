class master_seq_item extends axi_base_seq_item;
    rand bit[63:0] sa_addr;
    rand bit[63:0] da_addr;
    rand bit[26:0] btt_bytes;
  //FACTORY REGISTRATION
   `uvm_object_utils_begin(master_seq_item)
      `uvm_field_int(sa_addr,UVM_ALL_ON)
      `uvm_field_int(da_addr,UVM_ALL_ON)
      `uvm_field_int(btt_bytes,UVM_ALL_ON)
      //`uvm_field_int(awid,UVM_ALL_ON)
      `uvm_field_int(awaddr,UVM_ALL_ON)
      //`uvm_field_int(awlen,UVM_ALL_ON)
      //`uvm_field_int(awsize,UVM_ALL_ON)
      //`uvm_field_enum(burst_type_t,awburst,UVM_ALL_ON)
      //`uvm_field_int(awlock,UVM_ALL_ON)
      //`uvm_field_int(awregion,UVM_ALL_ON)
      //`uvm_field_int(awcache,UVM_ALL_ON)
      `uvm_field_int(awvalid,UVM_ALL_ON)
      `uvm_field_int(awready,UVM_ALL_ON)
//-------------write data channel----------//  
      `uvm_field_array_int(wdata,UVM_ALL_ON)
      //`uvm_field_array_int(wstrobe,UVM_ALL_ON | UVM_BIN)
      //`uvm_field_int(wlast,UVM_ALL_ON)
      `uvm_field_int(wvalid,UVM_ALL_ON)
      `uvm_field_int(wready,UVM_ALL_ON)
//----------write response channel---------//
      `uvm_field_int(bid,UVM_ALL_ON)
      `uvm_field_enum(response_t,bresp,UVM_ALL_ON)
      `uvm_field_int(bvalid,UVM_ALL_ON)
      `uvm_field_int(bready,UVM_ALL_ON)
//-----------read address channel----------//  
      //`uvm_field_int(arid,UVM_ALL_ON)
      `uvm_field_int(araddr,UVM_ALL_ON)
      //`uvm_field_int(arlen,UVM_ALL_ON)
      //`uvm_field_int(arsize,UVM_ALL_ON)
      //`uvm_field_enum(burst_type_t,arburst,UVM_ALL_ON)
      //`uvm_field_int(arlock,UVM_ALL_ON)
      //`uvm_field_int(arprot,UVM_ALL_ON)
      //`uvm_field_int(arqos,UVM_ALL_ON)
      //`uvm_field_int(arregion,UVM_ALL_ON)
      //`uvm_field_int(arcache,UVM_ALL_ON)
      `uvm_field_int(arvalid,UVM_ALL_ON)
      `uvm_field_int(arready,UVM_ALL_ON)
     //-----------read data channel-------------//
      `uvm_field_array_int(rdata,UVM_ALL_ON)
      `uvm_field_array_enum(response_t,rresp,UVM_ALL_ON)
      //`uvm_field_int(rlast,UVM_ALL_ON)
      //`uvm_field_int(rid,UVM_ALL_ON)
      `uvm_field_int(rvalid,UVM_ALL_ON)
      `uvm_field_int(rready,UVM_ALL_ON)
      //`uvm_field_enum(slave_type,slave,UVM_ALL_ON)
      //`uvm_field_enum(master_type,master,UVM_ALL_ON)
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
   //rand delay_t add_valid_dly; // delay between writing address channel info and asserting valid
   //rand delay_t resp_ready_dly; // delay in asserting ready while write response handshake.
   //rand delay_t read_ready2ready_dly[]; // serves as ready2ready for ready
   //rand delay_t write_valid2valid_dly[];// valid2valid delay for write txn
   //
   //int rmndr;

  function new (string name = "master_seq_item");
     super.new (name);
  endfunction

  /***************** constraint for wdata ****************/
  constraint wdata_ct {
      wdata.size() == awlen+1;
      }
  /*constraint wdata_c { wdata.size() == awlen+1;
                       solve awsize before wdata;
                        foreach(wdata[i])
                          $countbits(wdata[i]) == (2**awsize)*8;
                      }*/

//  constraint c_wdata { solve awlen before wdata;
//                       solve awsize before wdata;
//                       wdata.size() == (awlen+1);
//                       foreach(wdata[i]) {
//                         if(awsize == 2)
//                          {
//                           wdata[i] inside {['h0000_0000:'hffff_ffff]};
//                           }
//                         if(awsize == 3)
//                          {
//                           wdata[i] inside {['h0000_0000_0000_0000:'hffff_ffff_ffff_ffff]};
//                           }
//                         if(awsize == 4)
//                          {
//                           wdata[i] inside {['h0000_0000_0000_0000_0000_0000_0000_0000:'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff]};
//                           }
//                         if(awsize == 5)
//                          {
//                           wdata[i] inside  {['h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff]};
//                          }
//	                 }
//                         }




  //constraint for awsize & arsize
  //constraint awsize_c{awsize inside {[0:5]};} //max 256 bit or 32 byte port
/*  constraint awsize_c{solve master before awsize;
		      master == m0 -> awsize inside {[0:3]};
		      master == m1 -> awsize inside {[0:4]};
                      master == m2 -> awsize inside {[0:5]};
                      master == m3 -> awsize inside {[0:2]};
                      }

//constraint arsize_c{arsize inside {[0:5]};} //max 256 bit or 32 byte port
  constraint arsize_c{solve master before arsize;
		      master == m0 -> arsize inside {[0:3]};
		      master == m1 -> arsize inside {[0:4]};
                      master == m2 -> arsize inside {[0:5]};
                      master == m3 -> arsize inside {[0:2]};
                      }
*/
  //constraint for rresp & rdata
  constraint rresp_c { rresp.size() == 1;}
  constraint rdata_c { rdata.size() == 1;}

  //constraint for arlen && awlen
/*  constraint arlen_c{solve arburst before arlen;
                             arburst==2'b00 -> {arlen inside{[0:15]};}		//FIXED
                             arburst==2'b01 -> {arlen inside {[0:255]};}	//INCR
                             arburst==2'b10 -> {arlen inside {1,3,7,15};} }	//WRAP
  constraint awlen_c{solve awburst before awlen;
                             awburst==2'b00 -> {awlen inside{[0:15]};}
                             awburst==2'b01 -> {awlen inside {[0:255]};}
                             awburst==2'b10 -> {awlen inside {1,3,7,15};} }
//constraint for wstrobe
  constraint wstrobe_c {solve awlen before wstrobe;
                            wstrobe.size() == awlen+1;
                            solve awsize before wstrobe;
                            foreach(wstrobe[i])
                            {$countones(wstrobe[i])<= 2**awsize;} 	// for unaligned address
                              wstrobe[i] == (2**(2**awsize))-1;} 	// only if address is aligned
*/
//   function void post_randomize();
//      rmndr=awaddr%(2**awsize);
//         if(rmndr > 0) wstrobe[0] = wstrobe[0] << rmndr; //1111_1110<= 1111_1111 << 1
//   endfunction

 //delay constraints
//  constraint resp_ready_dly_c {soft resp_ready_dly inside {[2:10]};}
//  constraint add_valid_dly_c{soft add_valid_dly inside {[2:10]};}
//  constraint write_valid2valid_dly_c{solve awlen before write_valid2valid_dly;
//                                    write_valid2valid_dly.size()==awlen+1;
//                                    foreach(write_valid2valid_dly[i])
//                                    {soft write_valid2valid_dly[i] inside {[2:20]};}
//                                    }
//  constraint read_ready2ready_dly_c{solve arlen before read_ready2ready_dly;
//                                    read_ready2ready_dly.size()==arlen+1;
//                                    foreach(read_ready2ready_dly[i])
//                                    {read_ready2ready_dly[i] inside {[0:20]};}
//                                    }
  

  /********  Address Alignment and Unalignment Consatraint *********/
/* constraint align_awaddr {awaddr%(2**awsize)==0;}		//
 constraint slave_awaddr_align{ //solve slave before awaddr;
                                 if      (slave==s0) awaddr%4==0;
                           	 else if (slave==s1) awaddr%8==0;
                           	 else if (slave==s2) awaddr%16==0;
                           	 else if (slave==s3) awaddr%32==0;
                        	}

 constraint align_araddr {araddr%(2**arsize)==0;}		//
 constraint slave_araddr_align{ //solve slave before awaddr;
                                 if      (slave==s0) araddr%4==0;
                           	 else if (slave==s1) araddr%8==0;
                           	 else if (slave==s2) araddr%16==0;
                           	 else if (slave==s3) araddr%32==0;
                        	}

 //constraint align_awaddr {awaddr%(2**awsize)!=0;}		
 constraint slave_awaddr_unalign{ //solve slave before awaddr;
                                if      (slave==s0) awaddr%4  !=0;
                           	else if (slave==s1) awaddr%8  !=0;
                           	else if (slave==s2) awaddr%16 !=0;
                           	else if (slave==s3) awaddr%32 !=0;
                        	}
 
 //constraint align_araddr {araddr%(2**arsize)!=0;}		//
 constraint slave_araddr_unalign{ //solve slave before awaddr;
                                if      (slave==s0) araddr%4  !=0;
                           	else if (slave==s1) araddr%8  !=0;
                           	else if (slave==s2) araddr%16 !=0;
                           	else if (slave==s3) araddr%32 !=0;
                        	}
*/

  
  /************ constraint for awaddr && araddr ***************/
  constraint slave_awaddr{ solve slave before awaddr;
                           if      (slave==s0) soft awaddr inside {[32'h44A0_0000:32'h44A0_FFFF]};
                           else if (slave==s1) soft awaddr inside {[32'h44A1_0000:32'h44A1_7FFF]};
                           else if (slave==s2) soft awaddr inside {[32'h44A2_0000:32'h44A2_3FFF]};
                           else if (slave==s3) soft awaddr inside {[32'h44A3_0000:32'h44A3_1FFF]};
                        }
 
  constraint slave_araddr{ solve slave before araddr;
                        (slave==s0) -> soft araddr inside {[32'h44A0_0000:32'h44A0_FFFF]};
                        (slave==s1) -> soft araddr inside {[32'h44A1_0000:32'h44A1_7FFF]};
                        (slave==s2) -> soft araddr inside {[32'h44A2_0000:32'h44A2_3FFF]};
                        (slave==s3) -> soft araddr inside {[32'h44A3_0000:32'h44A3_1FFF]};
                        }

// 512 bytes boundary
  constraint awaddr_boundary {solve awlen before awsize; 
                              ((2**awsize)*(awlen+1))<=4096;
                             }

  constraint araddr_boundary {solve arlen before arsize; 
                              ((2**arsize)*(arlen+1))<=4096;
                              }



    //USER-DEFINED METHODS
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

    // 1. To PREVENT 4KB boundary crossings (Keep it within a single page):
    // constraint prevent_4kb_crossing_ct {
    //     soft (sa_addr % 4096) + btt_bytes <= 4096;
    //     soft (da_addr % 4096) + btt_bytes <= 4096;
    // }
    
    // 2. To FORCE a 4KB boundary crossing (Great for edge-case test sequences):
    // constraint force_4kb_crossing_ct {
    //     // This forces the start address to be near the end of a 4K page, 
    //     // ensuring the requested BTT bytes spill over the boundary.
    //     soft (sa_addr % 4096) + btt_bytes > 4096;
    //     soft (da_addr % 4096) + btt_bytes > 4096;
    // }
   /*
    constraint order_ct{
        solve btt_s before sa_addr, da_addr, btt_bytes;
        solve btt_bytes before sa_addr, da_addr;
        //solve da_addr before sa_addr;
    }

    constraint sa_addr_ct{
        if(btt_s == MIN | ONE | SML)
            soft sa_addr inside {[64'h0000_0000_0000_0000 : 64'h0000_0000_0000_0400]};
        else if(btt_s == MED | MB)
            soft sa_addr inside {[64'h0000_0000_1000_0000 : 64'h0000_0000_2000_0000]};
        else if(btt_s == MAX)
            soft sa_addr inside {[64'h0000_1000_0000_0000 : 64'h0000_2000_0000_0000]};
        else
            soft sa_addr inside {[64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_F000_0000]};
        }

    constraint da_addr_ct{
        if(btt_s == MIN | ONE | SML)
            soft da_addr inside {[64'h1000_0000_0000_0000 : 64'h1000_0000_0000_2000]};
        else if(btt_s == MED | MB)
            soft da_addr inside {[64'h1000_0000_1000_0000 : 64'h1000_0000_2000_0000]};
        else if(btt_s == MAX)
            soft da_addr inside {[64'h1000_1000_0000_0000 : 64'h1000_2000_0000_0000]};
        else
            soft da_addr inside {[64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_F000_0000]};
        }

    constraint btt_bytes_ct{
        if(btt_s == ONE)
            soft btt_bytes == 'd1;
        else if(btt_s == MB)
            soft btt_bytes == 'h10_0000;
        else if(btt_s == SML)
            soft btt_bytes == 'd64;
        else if(btt_s == MIN)
            soft btt_bytes inside {['d65 : 'd1024]};
        else if(btt_s == MED)
            soft btt_bytes inside {['d1025 : 'd4096]};
        else if(btt_s == MAX)
            soft btt_bytes == 'h3ff_ffff;
        else if(btt_s == MAXP)
            soft btt_bytes == 'h400_0000;
        }

    constraint overlapp_ct{
        soft (sa_addr + btt_bytes) <= 64'hFFFF_FFFF_FFFF_FFFF;
        soft (da_addr + btt_bytes) <= 64'hFFFF_FFFF_FFFF_FFFF;
        soft (da_addr + btt_bytes < sa_addr) || (sa_addr + btt_bytes < da_addr);
        }

  /********  Address Alignment *********/
/*    constraint alignment_ct{
        soft sa_addr %16 == 0;
        soft da_addr %16 == 0;
        }

  /********  BTT Alignment *********/
/*    constraint BTT_alignment_ct{
        soft btt_bytes %16 == 0;
        }

  /********  4KB Boundary *********/
//    constraint no_4kb_crossing_ct {
//        soft (sa_addr % 4096) + btt_bytes <= 4096;
//        soft (da_addr % 4096) + btt_bytes <= 4096;
//        }
endclass : master_seq_item
