//base sequence item

class axi_base_seq_item extends uvm_sequence_item;
  //FACTORY REGISTRATION
  `uvm_object_utils(axi_base_seq_item)

  //MEMEBERS
  string str ; /// just for testing wrapper
   //Write address channel
   rand   id_t          awid;
   rand   address_t     awaddr;
   rand   burst_len_t   awlen;
   rand   burst_type_t  awburst;
   rand   burst_size_t  awsize;
   valid_t     awvalid;
   ready_t     awready;
   rand lock_t      awlock;
   rand prot_t      awprot;
   rand qos_t       awqos;
   rand region_t    awregion;
   rand cache_t     awcache;
   //write response channel
   rand   id_t         bid;
   rand   response_t   bresp;
   valid_t             bvalid;
   ready_t             bready;
   //write data channel
   rand   data_t     wdata[];
   rand   strobe_t   wstrobe[];
   last_t            wlast;
   valid_t           wvalid;
   ready_t           wready;
   // read address channel
   rand   id_t           arid;
   rand   address_t      araddr;
   rand   burst_len_t    arlen;
   rand   burst_type_t   arburst;
   rand   burst_size_t   arsize;
   valid_t   arvalid;
   ready_t   arready;
   rand lock_t    arlock;
   rand prot_t    arprot;
   rand qos_t     arqos;
   rand region_t  arregion;
   rand cache_t   arcache;
   // read data channel
   rand      id_t     rid;
   rand response_t    rresp[];
   rand      data_t   rdata[];
   last_t    rlast;
   valid_t   rvalid;
   ready_t   rready;
   rand slave_type slave;
   rand master_type master;
   rand btt_type_t btt_s;


   //Delays
   rand delay_t cmd2cmd_dly , add2data_dly;
   rand command_t operation;

   //Timestamps to store meaningfull events (capture whenever ready and valid are high )
   realtime radd_hndshk, rdata_hndshk[], wadd_hndshk, wdata_hndshk[], wresp_hndshk;  // to capture timing when handshakes happen
   reset_info_t reset_op = NO_RESET; //monitor signals reset info to sb using this enum //setting default value to be NO_RESET
   realtime reset_asserted, reset_deasserted;  //to hold reset timestamp info

  function new (string name = "axi_base_seq_item");
     super.new (name);
  endfunction
  extern function bit comp_read_add   (axi_base_seq_item obj1, obj2);
  extern function bit comp_read_data  (axi_base_seq_item obj1, obj2);
  extern function bit comp_write_add  (axi_base_seq_item obj1, obj2);
  extern function bit comp_write_data (axi_base_seq_item obj1, obj2);
  extern function bit comp_write_resp (axi_base_seq_item obj1, obj2);
  extern function bit comp_write_txn  (axi_base_seq_item obj1, obj2);
  extern function bit comp_read_txn   (axi_base_seq_item obj1, obj2);
  extern function void print_read_txn      (axi_base_seq_item obj);
  extern function void print_write_txn     (axi_base_seq_item obj);
  extern function void print_write_resp    (axi_base_seq_item obj);
  extern function void print_write_addr    (axi_base_seq_item obj);
  extern function void print_write_data    (axi_base_seq_item obj);
  extern function void print_read_addr     (axi_base_seq_item obj);
  extern function void print_read_data     (axi_base_seq_item obj);
  extern function void axi_protocol_check  (axi_base_seq_item pkt);

  //CONSTRAINTS
  //write related
  //constraint wdata_hndshk_c {wdata_hndshk.size() == awlen+1;}
  //read related
  //constraint rdata_hndshk_c {rdata_hndshk.size() == arlen +1;}
  //delay related
  constraint cmd2cmd_dly_c {cmd2cmd_dly inside {[0:10]};}
  constraint add2data_dly_c{add2data_dly inside {[0:10]};}
endclass : axi_base_seq_item

  //USER-DEFINED METHODS compare and print
function bit axi_base_seq_item :: comp_read_add (axi_base_seq_item obj1, obj2); // compare read address channel
   bit result =1;
   if (obj1.arid != obj2.arid)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arid MISMATCH => %d != %d",obj1.arid,obj2.arid));
   result =0;
   end
   if ( obj1.araddr != obj2.araddr)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] araddr MISMATCH => %d != %d",obj1.araddr,obj2.araddr));
   result =0;
   end
   if (obj1.arlen != obj2.arlen)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arlen MISMATCH => %d != %d",obj1.arlen,obj2.arlen));
   result =0;
   end
   if (obj1.arburst != obj2.arburst)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arburst MISMATCH => %b != %b",obj1.arburst,obj2.arburst));
   result =0;
   end
   if (obj1.arsize != obj2.arsize)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arsize MISMATCH => %d != %d",obj1.arsize,obj2.arsize));
   result =0;
   end
   if (obj1.arprot != obj2.arprot)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arsize MISMATCH => %d != %d",obj1.arprot,obj2.arprot));
   result =0;
   end
   if (obj1.arqos != obj2.arqos)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arsize MISMATCH => %d != %d",obj1.arqos,obj2.arqos));
   result =0;
   end
   if (obj1.arregion != obj2.arregion)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arsize MISMATCH => %d != %d",obj1.arregion,obj2.arregion));
   result =0;
   end
   if (obj1.arcache != obj2.arcache)begin
   `uvm_error("compare_read_address_phase",$sformatf("[COMPARE] arsize MISMATCH => %d != %d",obj1.arcache,obj2.arcache));
   result =0;
   end
   return result; //return 1 only if all matched
endfunction

function bit axi_base_seq_item :: comp_read_data (axi_base_seq_item obj1, obj2); // compare read data channel
   bit result=1;
   if (obj1.rid != obj2.rid)begin
   `uvm_error("compare_read_data_phase",$sformatf("[COMPARE] rid MISMATCH => %d != %d",obj1.rid,obj2.rid));
   result =0;
   end
 foreach (obj1.rdata[i]) if (obj1.rdata[i] != obj2.rdata[i])begin
   `uvm_error("compare_read_data_phase",$sformatf("[COMPARE] rdata MISMATCH => %p != %p",obj1.rdata,obj2.rdata));
   result =0;
   break;
   end
 foreach (obj1.rresp[i]) if ( obj1.rresp[i] != obj2.rresp[i])begin
   `uvm_error("compare_read_data_phase",$sformatf("[COMPARE] rresp MISMATCH => %p != %p",obj1.rresp,obj2.rresp));
   result =0;
   break;
   end
   return result;
endfunction

function bit axi_base_seq_item :: comp_write_add (axi_base_seq_item obj1, obj2); // compare write address channel
   bit result=1;
   if (obj1.awid != obj2.awid)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awid MISMATCH => %d != %d",obj1.awid,obj2.awid));
   result =0;
   end
   if ( obj1.awaddr != obj2.awaddr)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awaddr MISMATCH => %d != %d",obj1.awaddr,obj2.awaddr));
   result =0;
   end
   if (obj1.awlen != obj2.awlen)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awlen MISMATCH => %d != %d",obj1.awlen,obj2.awlen));
   result =0;
   end
   if (obj1.awburst != obj2.awburst)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awburst MISMATCH => %b != %b",obj1.awburst,obj2.awburst));
   result =0;
   end
   if (obj1.awsize != obj2.awsize)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awsize MISMATCH => %d != %d",obj1.awsize,obj2.awsize));
   result =0;
   end
   if (obj1.awprot != obj2.awprot)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awsize MISMATCH => %d != %d",obj1.awprot,obj2.awprot));
   result =0;
   end
   if (obj1.awqos != obj2.awqos)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awsize MISMATCH => %d != %d",obj1.awqos,obj2.awqos));
   result =0;
   end
   if (obj1.awregion != obj2.awregion)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awsize MISMATCH => %d != %d",obj1.awregion,obj2.awregion));
   result =0;
   end
   if (obj1.awcache != obj2.awcache)begin
   `uvm_error("compare_write_address_phase",$sformatf("[COMPARE] awsize MISMATCH => %d != %d",obj1.awcache,obj2.awcache));
   result =0;
   end
   return result; //return 1 only if all matched
endfunction

function bit axi_base_seq_item :: comp_write_data (axi_base_seq_item obj1, obj2); // compare write data channel
   bit  result =1;
 foreach (obj1.wdata[i]) if ( obj1.wdata[i] != obj2.wdata[i])begin
   `uvm_error("compare_write_data_phase",$sformatf("[COMPARE] wdata MISMATCH => %p != %p",obj1.wdata,obj2.wdata));
   result =0;
   break;
   end
 foreach (obj1.wstrobe[i]) if ( obj1.wstrobe[i] != obj2.wstrobe[i])begin
   `uvm_error("compare_write_data_phase",$sformatf("[COMPARE] wstrobe MISMATCH => %p != %p",obj1.wstrobe,obj2.wstrobe));
   result =0;
   break;
   end
   return result;
endfunction

function bit axi_base_seq_item :: comp_write_resp (axi_base_seq_item obj1, obj2); // compare write response channel
   bit result =1;
   if (obj1.bid != obj2.bid)begin
   `uvm_error("compare_write_response_phase",$sformatf("[COMPARE] bid MISMATCH => %d != %d",obj1.bid,obj2.bid));
   result =0;
   end
    if (obj1.bresp != obj2.bresp)begin
   `uvm_error("compare_write_response_phase",$sformatf("[COMPARE] bresp MISMATCH => %b != %b",obj1.bresp,obj2.bresp));
   result =0;
   end
   return result;
endfunction


function bit axi_base_seq_item :: comp_write_txn (axi_base_seq_item obj1, obj2); // compare add data and resp phase for a write transaction
   bit result;
   if (comp_write_add(obj1,obj2) && comp_write_data(obj1,obj2) && comp_write_resp(obj1,obj2)) result = 1 ;
   else begin
   result = 0 ;
   `uvm_error("compare_write_transaction","[COMPARE] Write transaction MISMATCH");
   end
   return result;
endfunction

function bit axi_base_seq_item :: comp_read_txn (axi_base_seq_item obj1, obj2); // compare add and data phase for a read transaction
   bit result;
   if (comp_read_add(obj1,obj2) && comp_read_data(obj1,obj2) ) result = 1 ;
   else begin
   result = 0 ;
   `uvm_error("compare_read_transaction","[COMPARE] Read transaction MISMATCH");
   end
   return result;
endfunction

//print methods -- phase wise

function void axi_base_seq_item :: print_write_data (axi_base_seq_item obj); // print write response channel
   string str ,data_str,strobe_str;
   //str = $sformatf("\n Write_Data_phase_print \n wdata = %p , wstrobe =%p ",obj.wdata,obj.wstrobe);
   foreach(obj.wdata[i])begin
   data_str =$sformatf("%s \n %h",data_str,obj.wdata[i]);
   strobe_str =$sformatf("%s  %h,",strobe_str,obj.wstrobe[i]);
   end
   str = $sformatf("Write_Data_phase_print \n data  ->  %s \n strobe -> %s",data_str,strobe_str);
  `uvm_info("print_write_data",str,UVM_MEDIUM);
endfunction

function void axi_base_seq_item :: print_write_addr (axi_base_seq_item obj); // print write response channel
   string str;
   str = $sformatf("\n Write_Address_phase_print \n awid = %d ,awaddr = %h, awlen =%d, awsize =%d, awburst= %d ",obj.awid,obj.awaddr,obj.awlen,obj.awsize,obj.awburst);
  `uvm_info("print_write_addr",str,UVM_MEDIUM);
endfunction

function void axi_base_seq_item :: print_write_resp (axi_base_seq_item obj); // print write response channel
   string str;
   str = $sformatf("\n Write_response_phase_print \n bid = %d ,bresp = %p",obj.bid,obj.bresp);
  `uvm_info("print_write_resp",str,UVM_MEDIUM);
endfunction

function void axi_base_seq_item :: print_read_data (axi_base_seq_item obj); // print read data channel
   string str ,data_str;
   foreach(obj.rdata[i])
   data_str =$sformatf("%s \n %h",data_str,obj.rdata[i]);
   str = $sformatf("Read_Data_phase_print \n rid -> %d \n data  ->  %s \n rresp -> %p",rid,data_str,obj.rresp);
  `uvm_info("print_read_data",str,UVM_MEDIUM);

endfunction

function void axi_base_seq_item :: print_read_addr (axi_base_seq_item obj); // print read address channel
   string str;
   str = $sformatf("\n Read_Address_phase_print \n arid = %d ,araddr = %h, arlen =%d, arsize =%d, arburst= %d ",obj.arid,obj.araddr,obj.arlen,obj.arsize,obj.arburst);
  `uvm_info("print_read_addr",str,UVM_MEDIUM);
endfunction

function void axi_base_seq_item :: print_read_txn (axi_base_seq_item obj);// print read arrdess and data phases
   `uvm_info("print_read_txn","Printing Read Transaction",UVM_MEDIUM);
   // call phase prints
   print_read_addr(obj);
   print_read_data(obj);
endfunction

function void axi_base_seq_item :: print_write_txn (axi_base_seq_item obj);// print write arrdess data and response phases
   `uvm_info("print_write_txn","Printing Write Transaction",UVM_MEDIUM);
   // call phase prints
   print_write_addr(obj);
   print_write_data(obj);
   print_write_resp(obj);
endfunction

//AXI Protocol checks
function void axi_base_seq_item ::axi_protocol_check(axi_base_seq_item pkt);
    if(pkt.operation==WRITE) begin
      assert(pkt.awid==pkt.bid) else `uvm_error("Axi_base :: AXI_Protocol_Check","awid != bid");
      assert((pkt.awlen +1) == pkt.wdata.size()) else `uvm_error("Axi_base :: AXI_Protocol_Check","number of beats != pkt.awlen");
      assert((pkt.awlen +1) == pkt.wstrobe.size()) else `uvm_error("Axi_base :: AXI_Protocol_Check","number of strobes != pkt.awlen");
      assert(pkt.awaddr>=32'h44A0_0000 && pkt.awaddr<=32'h44A3_ffff) else `uvm_error("Axi_base :: AXI_Protocol_Check","Write_Address_out_of_range"); //valid range that a master can address
      foreach(pkt.wstrobe[i])
      assert((2**pkt.awsize)>=$countones(pkt.wstrobe[i])) else `uvm_error("Axi_base :: AXI_Protocol_Check","Invalid_strobe. Strobe high for more bytes than required");
      assert(pkt.bresp ==OKAY) else `uvm_error("Axi_base :: AXI_Protocol_Check","Bresponse not OKAY");
    end else begin
      assert(pkt.arid==pkt.rid) else `uvm_error("Axi_base :: AXI_Protocol_Check","arid != rid");
      assert((pkt.arlen +1) == pkt.rdata.size()) else `uvm_error("Axi_base :: AXI_Protocol_Check","number of beats != pkt.arlen");
      assert((pkt.arlen +1) == pkt.rresp.size()) else `uvm_error("Axi_base :: AXI_Protocol_Check","number of read_responses != pkt.arlen");
      assert(pkt.araddr>=32'h44A0_0000 && pkt.araddr<=32'h44A3_ffff) else `uvm_error("Axi_base :: AXI_Protocol_Check","Read_Address_out_of_range");
      //assert(pkt.araddr %(2**pkt.arsize) ==0) else `uvm_error("Axi_base :: AXI_Protocol_Check","Unaligned Read_address is not allowed");//read address must be aligned
      foreach(pkt.rresp[i])
      assert(pkt.rresp[i]==OKAY) else `uvm_error("Axi_base :: AXI_Protocol_Check","Read_response not OKAY");
    end
endfunction
