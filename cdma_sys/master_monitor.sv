/* RAITON_COPYRIGHT_BEGIN                                                 */
/* This is an automatically generated prolog.                             */
/*                                                                        */
/* AXI_INTERCONNECT_DESIGN/AXI_TB/master_monitor.sv                       */
/*                                                                        */
/* RAITON CONFIDENTIAL                                                    */
/*                                                                        */
/* COPYRIGHT RAITON SEMICONDUCTOR PVT LTD 2018,2022                       */
/*                                                                        */
/* All Rights Reserved                                                    */
/*                                                                        */
/* NOTICE: All information contained herein is, and remains the           */
/* property of Raiton semiconductor PVT. LTD. and its suppliers           */
/* ,if any.  The intellectual and  technical concepts contained           */
/* herein  are proprietary to  Raiton  semiconductor  PVT. LTD.           */
/* they are protected  by trade secrets and / or copyright law.           */
/* Dissemination of this  information  or reproduction of  this           */
/* material or code is strictly forbidden unless  prior written           */
/* permission is obtained from Raiton semiconductor PVT. LTD.             */
/*                                                                        */
/* RAITON_COPYRIGHT_END                                                   */
class master_monitor extends uvm_monitor;

   `uvm_component_utils (master_monitor)
   uvm_analysis_port #(master_seq_item)   mon_ap;
   virtual master_intf.MON_MOD_master     master_mon_intf;
   mailbox #(master_seq_item) read_data_array[id_t];

   function new (string name = "master_monitor" , uvm_component parent);
      super.new(name,parent);
   endfunction

   extern task main_phase (uvm_phase phase);
   extern function void build_phase (uvm_phase phase);
   extern task  capture_reset();
   extern task  capture_read_data();

endclass :master_monitor

   function void master_monitor :: build_phase (uvm_phase phase);
     super.build_phase (phase);
     mon_ap = new ("mon_ap",this);
     `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
   endfunction : build_phase

task master_monitor :: main_phase (uvm_phase phase);
 `uvm_info (get_full_name() , phase.get_name() , UVM_MEDIUM)
 fork
  capture_reset();
  capture_read_data();
 join
endtask

task  master_monitor ::  capture_read_data();
 master_seq_item     pkt, pkt2sb;
 int i,no_of_beats;
 forever begin
    `uvm_info("master_monitor :: capture_read_data","Triggred",UVM_LOW);
    i = 0;
    do begin
      pkt = master_seq_item :: type_id :: create("pkt");
      pkt.cdma_introut =new [1];
      wait( master_mon_intf.mas_mon_cb.rready==1 && master_mon_intf.mas_mon_cb.rvalid==1 && master_mon_intf.areset_n==1);
      pkt.cdma_introut[0]  = master_mon_intf.mas_mon_cb.cdma_introut;
      @(master_mon_intf.mas_mon_cb); //wait till next clk posedge
      pkt2sb = master_seq_item :: type_id :: create("pkt2sb");
      pkt2sb.cdma_introut = new[no_of_beats];
   end
    `uvm_info("master_monitor :: capture_read_data","Sending pkt to SB",UVM_LOW);
    mon_ap.write(pkt2sb); //write pkt to sb
 end
endtask

task master_monitor :: capture_reset();
 master_seq_item     rst_pkt;
 `uvm_info("master_monitor :: capture_reset","Triggred",UVM_LOW);
 fork
  forever begin //reset deasserted
    @(posedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_DEASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_deasserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
  forever begin //reset asserted
    @(negedge master_mon_intf.areset_n) ;
    rst_pkt = master_seq_item :: type_id :: create("rst_pkt");
    rst_pkt.reset_op = RESET_ASSERTED;
    rst_pkt.reset_deasserted = $realtime();
    `uvm_info("master_monitor :: capture_reset","reset_asserted_pkt to SB",UVM_LOW);
    mon_ap.write(rst_pkt);
  end
join
endtask

