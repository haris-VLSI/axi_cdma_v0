class cdma_cov extends uvm_subscriber #(master_seq_item);
    `uvm_component_utils(cdma_cov)

    virtual reset_intf rst;
    //uvm_analysis_imp #(master_seq_item,cdma_cov) analysis_export;

    master_seq_item cov;

    bit op_mode, reset;

    function new(string name = "cdma_cov",uvm_component parent);
        super.new(name,parent);
        axi_cdma = new();
    endfunction
    
    function void build_phase(uvm_phase phase);
        //analysis_export = new("analysis_export",this);
        if(!uvm_config_db #(virtual reset_intf)::get(null,"","reset_if", rst))
            `uvm_fatal(get_full_name(), "reset_intf_not_accessable")
    endfunction

    covergroup axi_cdma;
        RD_REG: coverpoint cov.araddr {
            bins CDMACR         = {'h00};
            bins CDMASR         = {'h04};
            bins SA             = {'h18};
            bins DA             = {'h20};
            bins BTT            = {'h28};
        }
        WR_REG: coverpoint cov.awaddr {
            bins CDMACR         = {'h00}; 
            bins CDMASR         = {'h04}; 
            bins SA             = {'h18}; 
            bins DA             = {'h20}; 
            bins BTT            = {'h28}; 
        }
    // CDMACR
        OP_MODE: coverpoint op_mode;
        RESET: coverpoint reset;
        //OP_MODE: coverpoint cov.wdata[0][3] iff(cov.operation == WRITE && cov.awaddr == 'h00){
        //    bins Simple_DMA     = {0};
        //    bins SG_DMA         = {1};
        //}
        //RESET: coverpoint cov.wdata[0][2] iff(cov.operation == WRITE && cov.awaddr == 'h00){
        //    bins Reset_High     = {1'b1};
        //    bins Reset_Low      = {1'b0};
        //}
        READ_BURST: coverpoint cov.wdata[0][4] iff(cov.operation == WRITE && cov.awaddr == 'h00){
            bins RD_Inc         = {0};
            bins RD_Fix         = {1};
        }
        WRITE_BURST: coverpoint cov.wdata[0][5] iff(cov.operation == WRITE && cov.awaddr == 'h00){
            bins WR_Inc         = {0};
            bins WR_Fix         = {1};
        }
        IOC_EN: coverpoint cov.wdata[0][12] iff(cov.operation == WRITE && cov.awaddr == 'h00){
            bins IOC_IrqEn      = {1'b1};
            bins IOC_IrqDis     = {1'b0};
        }
        ERR_EN: coverpoint cov.wdata[0][14] iff(cov.operation == WRITE && cov.awaddr == 'h00){
            bins ERR_IrqEn      = {1'b1};
            bins ERR_IrqDis     = {1'b0};
        }
        CR_RSVD: coverpoint {cov.wdata[0][15], cov.wdata[0][11:7], cov.wdata[0][0]} iff(cov.operation == WRITE && cov.awaddr == 'h00) {
            bins Rsvd_Low       = {0};
            illegal_bins CR_Rsvd= { [1:$] }; 
        }
    // CDMASR
        INT_ERR: coverpoint cov.rdata[0][4] iff(cov.operation == READ && cov.araddr == 'h04){
            bins IntErr_High    = {1};
            bins IntErr_Low     = {0};
        }
        SLV_ERR: coverpoint cov.rdata[0][5] iff(cov.operation == READ && cov.araddr == 'h04){
            bins SlvErr_High    = {1};
            bins SlvErr_Low     = {0};
        }
        DEC_ERR: coverpoint cov.rdata[0][6] iff(cov.operation == READ && cov.araddr == 'h04){
            bins DecErr_High    = {1};
            bins DecErr_Low     = {0};
        }
        IDLE: coverpoint cov.rdata[0][1] iff(cov.operation == READ && cov.araddr == 'h04){
            bins Idle_High      = {1};
            bins Idle_Low       = {0};
        }
        IOC: coverpoint cov.rdata[0][12] iff(cov.operation == READ && cov.araddr == 'h04){
            bins IOC_Asserted   = {1};
            bins IOC_Cleared    = {0};
        }
        IOC_W: coverpoint cov.wdata[0][12] iff(cov.operation == WRITE && cov.awaddr == 'h04){
            bins W1C_Clear      = {1};
            bins W1C_NoEffect   = {0};
        }
        ERR: coverpoint cov.rdata[0][14] iff(cov.operation == READ && cov.araddr == 'h04){
            bins ERR_Asserted   = {1};
            bins ERR_Cleared    = {0};
        }
        SR_RSVD: coverpoint {cov.rdata[0][15], cov.rdata[0][11], cov.rdata[0][7], cov.rdata[0][2], cov.rdata[0][0]} iff(cov.operation == READ && cov.araddr == 'h04) {
            bins Rsvd_Low       = {0};
            illegal_bins SR_Rsvd= { [1:$] };
        }
    // SA
        SRC_ADDR: coverpoint cov.wdata[0] iff(cov.operation == WRITE && cov.awaddr == 'h18) {
            wildcard bins word_aligned = {32'b????_????_????_????_????_????_????_??00};
            wildcard bins unaligned    = {32'b????_????_????_????_????_????_????_??01,
                                          32'b????_????_????_????_????_????_????_??10,
                                          32'b????_????_????_????_????_????_????_??11};
        }
    // DA
        DES_ADDR: coverpoint cov.wdata[0] iff(cov.operation == WRITE && cov.awaddr == 'h20) {
            wildcard bins word_aligned = {32'b????_????_????_????_????_????_????_??00};
            wildcard bins unaligned    = {32'b????_????_????_????_????_????_????_??01,
                                          32'b????_????_????_????_????_????_????_??10,
                                          32'b????_????_????_????_????_????_????_??11};
        }

    // Cross Coverage
        BURST_CROSS : cross READ_BURST, WRITE_BURST;
        IDLE_ERR    : cross IDLE, ERR;
        IOC_ERR     : cross IOC, ERR;        

        IDLE_OP_MODE: cross IDLE, OP_MODE;
        IOC_OP_MODE : cross IOC, OP_MODE;
        ERR_OP_MODE : cross ERR, OP_MODE;
        SLV_MODE    : cross SLV_ERR, OP_MODE;
        DEC_MODE    : cross DEC_ERR, OP_MODE;
        INT_MODE    : cross INT_ERR, OP_MODE;

        SLV_RST     : cross SLV_ERR, RESET;
        DEC_RST     : cross DEC_ERR, RESET;
        INT_RST     : cross INT_ERR, RESET;
    endgroup

    virtual function void write(master_seq_item t);
        //cov = t;
        //$cast(cov,t);
        cov = new t;
        if (cov.operation == WRITE && cov.awaddr == 'h00) begin
            op_mode = cov.wdata[0][3];
            reset   = cov.wdata[0][2];
        end
        `uvm_info("COV",$sformatf("data pkt in COV: %s",cov.sprint()),UVM_LOW)
        axi_cdma.sample();
    endfunction
endclass
