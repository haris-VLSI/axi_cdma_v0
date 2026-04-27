class cdma_cov extends uvm_subscriber #(master_seq_item);
    `uvm_component_utils(cdma_cov)

    virtual reset_intf rst;
    //uvm_analysis_imp #(master_seq_item,cdma_cov) analysis_export;

    master_seq_item cov;

    function new(string name = "cdma_cov",uvm_component parent);
        super.new(name,parent);
        axi_cdma = new();
    endfunction
    
    function void build();
        //analysis_export = new("analysis_export",this);
        if(!uvm_config_db #(virtual reset_intf)::get(null,"","reset_if", rst))
            `uvm_fatal (get_full_name(), "reset_intf_not_accessable");
    endfunction

    covergroup axi_cdma;
    OP_MODE:coverpoint cov.wdata[0][3] iff(cov.operation == WRITE && cov.awaddr == 'h00){
                bins Simple_DMA = {0};
                bins SG_DMA = {1};
                }
    //BURST:  coverpoint cov.wdata[0][5:4] iff(cov.operation == WRITE && cov.awaddr == 'h00){
    //           bins  rd_wr_inc      = {2'b00}; 
    //           bins  rd_fix_wr_inc  = {2'b01};
    //           bins  rd_inc_wr_fix  = {2'b10};
    //           bins  rd_fix_wr_fix  = {2'b11};
    //           }
    IOC_EN: coverpoint cov.wdata[0][12] iff(cov.operation == WRITE && cov.awaddr == 'h00){
                bins IOC_IrqEn      = {1'b1};
                bins IOC_IrqDis     = {1'b0};
                }
    ERR_EN: coverpoint cov.wdata[0][14] iff(cov.operation == WRITE && cov.awaddr == 'h00){
                bins ERR_IrqEn      = {1'b1};
                bins ERR_IrqDis     = {1'b0};
                }
    RESET:  coverpoint cov.wdata[0][2] iff(cov.operation == WRITE && cov.awaddr == 'h00){
                bins Reset_High     = {1'b1};
                bins Reset_Low      = {1'b0};
                }
    INT_ERR:coverpoint cov.rdata[4] iff(cov.operation == READ && cov.araddr == 'h04){
                bins IntErr_High        = {1};
                bins IntErr_Low         = {0};
                }
    SLV_ERR:coverpoint cov.rdata[5] iff(cov.operation == READ && cov.araddr == 'h04){
                bins SlvErr_High        = {1};
                bins SlvErr_Low         = {0};
                }
    DEC_ERR:coverpoint cov.rdata[6] iff(cov.operation == READ && cov.araddr == 'h04){
                bins DecErr_High        = {1};
                bins DecErr_Low         = {0};
                }
    endgroup

    virtual function void write(master_seq_item t);
        //cov = t;
        //$cast(cov,t);
        cov = new t;
        `uvm_info("COV",$sformatf("data pkt in COV: %s",cov.sprint()),UVM_LOW)
        axi_cdma.sample();
    endfunction
endclass
