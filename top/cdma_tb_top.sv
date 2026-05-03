`timescale 1ns/1ps
`include "reset_intf.sv"
`include "../axi_lite/master_intf.sv"
`include "../axi_slave/slave_intf.sv"
`include "../cdma_reg_ral/reg_block_pkg.sv"
`include "package.sv"
`include "uvm_macros.svh"

module top;
    import  uvm_pkg :: *;
    import  reg_block_pkg :: *;
    import  axi_package :: *;

    reg     aclk;
    reg     s_clk,m_clk;
    reg     reset_n;

    parameter int FREQ = 200;

    real    half_clk = 1000.00/(2*FREQ);

   // Instantiate AXI Design
   design_1_wrapper  dut (
                       .m_axi_aclk_0(m_clk),
                       .s_axi_lite_aclk_0(m_clk),
                       .s_axi_lite_aresetn_0(reset_n),
                        //Data Signals
                           .M_AXI_0_araddr(s_axi_if.araddr),
                           .M_AXI_0_arburst(s_axi_if.arburst[1:0]),
                           .M_AXI_0_arcache(s_axi_if.arcache[3:0]),
                           .M_AXI_0_arlen(s_axi_if.arlen[7:0]),
                           .M_AXI_0_arprot(s_axi_if.arprot[2:0]),
                           .M_AXI_0_arready(s_axi_if.arready),
                           .M_AXI_0_arsize(s_axi_if.arsize[2:0]),
                           .M_AXI_0_arvalid(s_axi_if.arvalid),
                           .M_AXI_0_awaddr(s_axi_if.awaddr),
                           .M_AXI_0_awburst(s_axi_if.awburst[1:0]),
                           .M_AXI_0_awcache(s_axi_if.awcache[3:0]),
                           .M_AXI_0_awlen(s_axi_if.awlen[7:0]),
                           .M_AXI_0_awprot(s_axi_if.awprot[2:0]),
                           .M_AXI_0_awready(s_axi_if.awready),
                           .M_AXI_0_awsize(s_axi_if.awsize[2:0]),
                           .M_AXI_0_awvalid(s_axi_if.awvalid),
                           .M_AXI_0_bready(s_axi_if.bready),
                           .M_AXI_0_bresp(s_axi_if.bresp[1:0]),
                           .M_AXI_0_bvalid(s_axi_if.bvalid),
                           .M_AXI_0_rdata(s_axi_if.rdata[127:0]),
                           .M_AXI_0_rlast(s_axi_if.rlast),
                           .M_AXI_0_rready(s_axi_if.rready),
                           .M_AXI_0_rresp(s_axi_if.rresp[1:0]),
                           .M_AXI_0_rvalid(s_axi_if.rvalid),
                           .M_AXI_0_wdata(s_axi_if.wdata[127:0]),
                           .M_AXI_0_wlast(s_axi_if.wlast),
                           .M_AXI_0_wready(s_axi_if.wready),
                           .M_AXI_0_wstrb(s_axi_if.wstrobe[15:0]),
                           .M_AXI_0_wvalid(s_axi_if.wvalid),
                            //SG Descriptor Signals
                               .M_AXI_SG_0_araddr(s_axi_sg_if.araddr),
                               .M_AXI_SG_0_arburst(s_axi_sg_if.arburst[1:0]),
                               .M_AXI_SG_0_arcache(s_axi_sg_if.arcache[3:0]),
                               .M_AXI_SG_0_arlen(s_axi_sg_if.arlen[7:0]),
                               .M_AXI_SG_0_arprot(s_axi_sg_if.arprot[2:0]),
                               .M_AXI_SG_0_arready(s_axi_sg_if.arready),
                               .M_AXI_SG_0_arsize(s_axi_sg_if.arsize[2:0]),
                               .M_AXI_SG_0_arvalid(s_axi_sg_if.arvalid),
                               .M_AXI_SG_0_awaddr(s_axi_sg_if.awaddr),
                               .M_AXI_SG_0_awburst(s_axi_sg_if.awburst[1:0]),
                               .M_AXI_SG_0_awcache(s_axi_sg_if.awcache[3:0]),
                               .M_AXI_SG_0_awlen(s_axi_sg_if.awlen[7:0]),
                               .M_AXI_SG_0_awprot(s_axi_sg_if.awprot[2:0]),
                               .M_AXI_SG_0_awready(s_axi_sg_if.awready),
                               .M_AXI_SG_0_awsize(s_axi_sg_if.awsize[2:0]),
                               .M_AXI_SG_0_awvalid(s_axi_sg_if.awvalid),
                               .M_AXI_SG_0_bready(s_axi_sg_if.bready),
                               .M_AXI_SG_0_bresp(s_axi_sg_if.bresp[1:0]),
                               .M_AXI_SG_0_bvalid(s_axi_sg_if.bvalid),
                               .M_AXI_SG_0_rdata(s_axi_sg_if.rdata[31:0]),
                               .M_AXI_SG_0_rlast(s_axi_sg_if.rlast),
                               .M_AXI_SG_0_rready(s_axi_sg_if.rready),
                               .M_AXI_SG_0_rresp(s_axi_sg_if.rresp[1:0]),
                               .M_AXI_SG_0_rvalid(s_axi_sg_if.rvalid),
                               .M_AXI_SG_0_wdata(s_axi_sg_if.wdata[31:0]),
                               .M_AXI_SG_0_wlast(s_axi_sg_if.wlast),
                               .M_AXI_SG_0_wready(s_axi_sg_if.wready),
                               .M_AXI_SG_0_wstrb(s_axi_sg_if.wstrobe[3:0]),
                               .M_AXI_SG_0_wvalid(s_axi_sg_if.wvalid),
                               //Lite Master Signals
                                   .S_AXI_LITE_0_araddr(m_axi_lite_if.araddr[5:0]),
                                   .S_AXI_LITE_0_arready(m_axi_lite_if.arready),
                                   .S_AXI_LITE_0_arvalid(m_axi_lite_if.arvalid),
                                   .S_AXI_LITE_0_awaddr(m_axi_lite_if.awaddr[5:0]),
                                   .S_AXI_LITE_0_awready(m_axi_lite_if.awready),
                                   .S_AXI_LITE_0_awvalid(m_axi_lite_if.awvalid),
                                   .S_AXI_LITE_0_bready(m_axi_lite_if.bready),
                                   .S_AXI_LITE_0_bresp(m_axi_lite_if.bresp[1:0]),
                                   .S_AXI_LITE_0_bvalid(m_axi_lite_if.bvalid),
                                   .S_AXI_LITE_0_rdata(m_axi_lite_if.rdata[31:0]),
                                   .S_AXI_LITE_0_rready(m_axi_lite_if.rready),
                                   .S_AXI_LITE_0_rresp(m_axi_lite_if.rresp[1:0]),
                                   .S_AXI_LITE_0_rvalid(m_axi_lite_if.rvalid),
                                   .S_AXI_LITE_0_wdata(m_axi_lite_if.wdata[31:0]),
                                   .S_AXI_LITE_0_wready(m_axi_lite_if.wready),
                                   .S_AXI_LITE_0_wvalid(m_axi_lite_if.wvalid),
                                   //Interuppet Out From CDMA
                                   .cdma_introut_0(m_axi_lite_if.cdma_introut)    //added
                            );

//------------- CLOCK GENERATION --------------//
   initial begin
      aclk = 0;
      forever #half_clk aclk = ~aclk;
   end
   initial begin
      m_clk = 0;
      forever #half_clk m_clk = ~m_clk;
   end
   initial begin
      s_clk = 0;
      forever #half_clk s_clk = ~s_clk;
   end

//RESET CONDITION
    initial begin
        reset_if.reset_n = 0;
        repeat(16)@(posedge m_clk);
        reset_if.reset_n = 1;
    end

// Interface
    reset_intf   reset_if();    //SG Desc
    assign top.reset_n = reset_if.reset_n; // Drive the actual signal

    master_intf  m_axi_lite_if   (.aclk(m_clk), .areset_n(reset_n));    //Lite
    slave_intf   s_axi_if        (.aclk(m_clk), .areset_n(reset_n));    //Data
    slave_intf   s_axi_sg_if     (.aclk(m_clk), .areset_n(reset_n));    //SG Desc
//   cdma_system_if sys_if();

    initial begin
        uvm_config_db #(virtual reset_intf)::set(null,"*","reset_if", reset_if);
        //uvm_config_db #(int)::set(null, "*", "AXI_DATA_WIDTH", 16);
    end

    config_obj   obj;
    initial begin
        obj = config_obj :: type_id :: create ("obj");
        obj.mas_if         = new[1];
        obj.slv_if         = new[2];
        obj.mas_if[0]      = m_axi_lite_if;
        obj.slv_if[0]      = s_axi_if;
        obj.slv_if[1]      = s_axi_sg_if;
        obj.no_of_masters  = 1;
        obj.no_of_slaves   = 2;
        obj.mas_is_active  = new[1];
        obj.mas_is_active[0]  = UVM_ACTIVE;
        //obj.mas_is_active  = '{1{UVM_ACTIVE}};//set agent active/passive
        obj.slv_is_active  = new[2];
        obj.slv_is_active[0]  = UVM_ACTIVE;
        obj.slv_is_active[1]  = UVM_ACTIVE;
        //obj.slv_is_active  = '{2{UVM_ACTIVE}};//set agent active/passive
        uvm_config_db #(config_obj) :: set (null , "*" , "config_obj" , obj);
    end

    initial begin
        //run_test ("simple_mode_64mb_btt_test");           //19 to run
        //run_test ("simple_mode_b2b_ioc_test");            //18 working
        //run_test ("simple_mode_b2b_test");                //17 working SBD failed for b2b tx
        run_test ("simple_mode_4k_check_test");           //16 working
        //run_test ("simple_mode_btt_check_test");          //15 working
        //run_test ("simple_mode_alignment_test");          //14 working
        //run_test ("simple_dma_4k_boundary_test");         //13 working
        //run_test ("simple_dma_int_error_test");           //12 working
        //run_test ("simple_dma_decode_error_test");        //11 working
        //run_test ("simple_dma_slave_error_test");         //10 working
        //run_test ("simple_mode_fixed_transfer_test");     //9 working
        //run_test ("simple_mode_incr_transfer_test");      //8 working
        //run_test ("simple_mode_wr_rd_test");              //7 working
        //run_test ("ral_access_test");                     //6 working
        //run_test ("ral_bit_bash_test");                   //5 working
        //run_test ("ral_intermediate_hard_reset_test");    //4 working
        //run_test ("ral_intermediate_soft_reset_test");    //3 working
        //run_test ("ral_reset_test");                      //2 working
        //
        //run_test ("cdma_base_test");                      //1
        //run_test ();
    end
    
    initial begin
        #156;
        $display("AT 156ns: m_clk is %b, interface aclk is %b", m_clk, m_axi_lite_if.aclk);
        #157;
        $display("AT 157ns: m_clk is %b, interface aclk is %b", m_clk, m_axi_lite_if.aclk);
    end
//    initial begin
//        #100000;  //safety finish to avoid infinite
//        $finish();
//    end

//Master - AXI4 to AXI4-Lite convertion
always@(posedge aclk)begin
     m_axi_lite_if.awid      <=  0;
     m_axi_lite_if.awaddr[63:6]    <=  'h0;
     m_axi_lite_if.awlen     <=  0;
     m_axi_lite_if.awburst   <=  0;
     m_axi_lite_if.awsize    <=  'h2;
     m_axi_lite_if.mas_drv_cb.awlock    <=  0;
     m_axi_lite_if.awprot    <=  0;
     m_axi_lite_if.awqos     <=  0;

     m_axi_lite_if.awregion  <=  0;
     m_axi_lite_if.awcache   <=  0;

     m_axi_lite_if.wdata[127:32]  <=  'h0;
     m_axi_lite_if.wstrobe[15:4]  <=  'h0;
     m_axi_lite_if.wstrobe[3:0]   <=  'hf;
     m_axi_lite_if.mas_drv_cb.wlast     <=  0;
     m_axi_lite_if.arid      <=  0;
     m_axi_lite_if.araddr[63:6]    <=  'h0;
     m_axi_lite_if.arlen     <=  0;
     m_axi_lite_if.arburst   <=  0;
     m_axi_lite_if.arsize    <=  0;
     m_axi_lite_if.mas_drv_cb.arlock    <=  0;
     m_axi_lite_if.mas_drv_cb.rdata[127:32] <=   'h0;
end
    assign m_axi_lite_if.bid       =  0;
    assign m_axi_lite_if.rid       =  0;
    assign m_axi_lite_if.rlast     =  0;
    //assign m_axi_lite_if.rdata[127:32]  =  'h0;

//SG - AXI4
//Write Address signals
    assign s_axi_sg_if.awid        =  0;
    //assign s_axi_sg_if.awaddr[63:32]=  0;
    assign s_axi_sg_if.awlock      =  0;
    assign s_axi_sg_if.awqos       =  0;
    assign s_axi_sg_if.awregion    =  0;
    assign s_axi_sg_if.wdata[127:32]  =  'h0;
//Read Address signals
    assign s_axi_sg_if.arid        =  0;
    //assign s_axi_sg_if.araddr[63:32]=  0;
    assign s_axi_sg_if.arlock      =  0;
    assign s_axi_sg_if.arqos       =  0;
    assign s_axi_sg_if.arregion    =  0;
//Write Response signals
    //assign s_axi_sg_if.bid         =  0;
//Read Data signals
    //assign s_axi_sg_if.rid         =  0;
    //assign s_axi_sg_if.rdata[127:32]  =  0;

//Data - AXI4
//Write Address signals
    assign s_axi_if.awid           =  0;
    assign s_axi_if.awlock         =  0;
    assign s_axi_if.awqos          =  0;
    assign s_axi_if.awregion       =  0;
//Read Address signals
    assign s_axi_if.arid           =  0;
    assign s_axi_if.arlock         =  0;
    assign s_axi_if.arqos          =  0;
    assign s_axi_if.arregion       =  0;

//Master - AXI4 to AXI4-Lite convertion
//Write Address signals
    //assign m_axi_lite_if.awid      =  0;
    //assign m_axi_lite_if.awlen     =  0;
    //assign m_axi_lite_if.awburst   =  0;
    //assign m_axi_lite_if.awsize    =  32'h2;
    //assign m_axi_lite_if.awlock    =  0;
    //assign m_axi_lite_if.awprot    =  0;
    //assign m_axi_lite_if.awqos     =  0;

    //assign m_axi_lite_if.awregion  =  0;
    //assign m_axi_lite_if.awcache   =  0;

    //assign m_axi_lite_if.wdata[127:32]  =  0;
    //assign m_axi_lite_if.wstrobe   =  'hffff;

    //assign m_axi_lite_if.arid      =  0;
    //assign m_axi_lite_if.arlen     =  0;
    //assign m_axi_lite_if.arburst   =  0;
    //assign m_axi_lite_if.arsize    =  0;
    //assign m_axi_lite_if.arlock    =  0;

    //assign s_axi_if.bid            =  0;
    //assign s_axi_if.rid            =  0;
    //assign s_axi_if.rdata[127:128] =  0;
    initial begin
        s_axi_if.bid            =  'h0;
        s_axi_if.rid            =  'h0;
        s_axi_sg_if.rdata[127:32]   =   'h0;
        s_axi_sg_if.bid         =  'h0;
        s_axi_sg_if.rid         =  'h0;
    end
endmodule:top
