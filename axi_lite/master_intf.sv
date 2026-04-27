`include "uvm_macros.svh"
//required macros
  //`define DATA_WIDTH     128
  `define DATA_WIDTH     32
  `define ADDR_WIDTH     64
  `define STRB_WIDTH     16
  `define ID_WIDTH       0
  `define LEN_WIDTH      8
  `define SIZE_WIDTH     3
  `define BURST_WIDTH    2
  `define RESPONSE_WIDTH 2
 interface master_intf (input aclk, areset_n);
   import  uvm_pkg :: *;
    //Write_interface signals
   logic [`ID_WIDTH-1 : 0]       awid;
   logic [`ADDR_WIDTH-1 : 0]     awaddr;
   logic [`LEN_WIDTH-1 : 0]      awlen;
   logic [`BURST_WIDTH-1 : 0]    awburst;
   logic [`SIZE_WIDTH-1 : 0]     awsize;
   logic                         awvalid;
   logic                         awready;
   logic [`ID_WIDTH-1 : 0]       bid;
   logic [`RESPONSE_WIDTH-1 : 0] bresp;
   logic                         bvalid;
   logic                         bready;
   logic [`DATA_WIDTH-1 : 0]     wdata;
   logic [`STRB_WIDTH-1 : 0]     wstrobe;
   logic                         wlast;
   logic                         wvalid;
   logic                         wready;
   logic                         awlock;
   logic [2 : 0]                 awprot;
   logic [3 : 0]                 awqos;
   logic [3 : 0]                 awregion;
   logic [3 : 0]                 awcache;
   //Read interface signals
   logic [4 : 0]                 arid;
   logic [`ADDR_WIDTH-1 : 0]     araddr;
   logic [`LEN_WIDTH-1 : 0]      arlen;
   logic [`BURST_WIDTH-1 : 0]    arburst;
   logic [`SIZE_WIDTH-1 : 0]     arsize;
   logic                         arvalid;
   logic                         arready;
   logic [4 : 0]                 rid;
   logic [`RESPONSE_WIDTH-1:0]   rresp;
   logic [`DATA_WIDTH-1 : 0]     rdata;
   logic                         rlast;
   logic                         rvalid;
   logic                         rready;
   logic                         arlock;
   logic [2:0]                   arprot;
   logic [3:0]                   arqos;
   logic [3:0]                   arregion;
   logic [3:0]                   arcache;
   logic                         cdma_introut;    //added

   clocking mas_drv_cb @(posedge aclk);
     default input #1 output #0;
      output   awaddr;
      output   awburst;
      output   awcache;
      output   awid;
      output   awlen;
      output   awlock;
      output   awprot;
      output   awqos;
      input    awready;
      output   awregion;
      output   awsize;
      output   awvalid;
      input    bid;
      output   bready;
      input    bresp;
      input    bvalid;
      input    rdata;
      input    rid;
      input    rlast;
      output   rready;
      input    rresp;
      input    rvalid;
      output   wdata;
      output   wlast;
      input    wready;
      output   wstrobe;
      output   wvalid;
      output   araddr;
      output   arburst;
      output   arcache;
      output   arid;
      output   arlen;
      output   arlock;
      output   arprot;
      output   arqos;
      input    arready;
      output   arregion;
      output   arsize;
      output   arvalid;
      input    cdma_introut;     //added
   endclocking:mas_drv_cb

   clocking mas_mon_cb @(posedge aclk);
      default input #1 output #0;
      input      awid;
      input      awaddr;
      input      awlen;
      input      awburst;
      input      awsize;
      input      awvalid;
      input      awready;
      input      bid;
      input      bresp;
      input      bvalid;
      input      bready;
      input      wdata;
      input      wstrobe;
      input      wlast;
      input      wvalid;
      input      wready;
      input      awlock;
      input      awprot;
      input      awqos;
      input      awregion;
      input      awcache;
      input     arid;
      input     araddr;
      input     arlen;
      input     arburst;
      input     arsize;
      input     arvalid;
      input     arready;
      input     rid;
      input     rresp;
      input     rdata;
      input     rlast;
      input     rvalid;
      input     rready;
      input     arlock;
      input     arprot;
      input     arqos;
      input     arregion;
      input     arcache;
      input     cdma_introut;     //added
  endclocking:mas_mon_cb

     modport  DRV_MOD_master (clocking mas_drv_cb,input areset_n);
     modport  MON_MOD_master (clocking mas_mon_cb,input areset_n);

    always @(posedge aclk) begin
        // Print exactly ONCE at 160ns to prove the clock made it inside
        if ($time == 160000) begin 
            $display("SUCCESS: Clock edge reached inside master_intf at 160ns!");
        end
    end
endinterface : master_intf


















 //Importing properties from package
//  import axi_package :: valid_handshake;
//  import axi_package :: signal_stable;
/*
  //assert valid handshake on all 5 channels
  assert property (valid_handshake(aclk,areset_n,awvalid,awready)) else `uvm_error("AXI_Protocol_check","Invalid awvalid-ready_handshake")
  assert property (valid_handshake(aclk,areset_n,wvalid,wready))   else `uvm_error("AXI_Protocol_check","Invalid wvalid-ready_handshake");
  assert property (valid_handshake(aclk,areset_n,bvalid,bready))   else `uvm_error("AXI_Protocol_check","Invalid bvalid-ready_handshake");
  assert property (valid_handshake(aclk,areset_n,arvalid,arready)) else `uvm_error("AXI_Protocol_check","Invalid arvalid-ready_handshake");
  assert property (valid_handshake(aclk,areset_n,rvalid,rready))   else `uvm_error("AXI_Protocol_check","Invalid rvalid-ready_handshake");
  //assert data stable for read/write data channels
  assert property (signal_stable(aclk,areset_n,rvalid,rready,rdata))    else `uvm_error("AXI_Protocol_check","rdata must be stable till Handshake");
  assert property (signal_stable(aclk,areset_n,wvalid,wready,wdata))    else `uvm_error("AXI_Protocol_check","wdata must be stable till Handshake");
  assert property (signal_stable(aclk,areset_n,awvalid,awready,awaddr)) else `uvm_error("AXI_Protocol_check","awaddr must be stable till Handshake");
  assert property (signal_stable(aclk,areset_n,arvalid,arready,araddr)) else `uvm_error("AXI_Protocol_check","araddr must be stable till Handshake");
  assert property (signal_stable(aclk,areset_n,bvalid,bready,bresp))    else `uvm_error("AXI_Protocol_check","bresp must be stable till Handshake"); 
*/
