class mem_module extends uvm_component;
    `uvm_component_utils(mem_module)

    virtual slave_intf.DRV_MOD_slave        slave_drv_intf;

    function new (string name = "mem_module", uvm_component parent);
       super.new(name,parent);
    endfunction

    bit[7:0] mem[*];

    function void start_of_simulation();
        for(int i=0;i<3000;i++)begin
            mem[32'h0000_0000+i]  =   $random;
        end
    endfunction

    task run();
        forever begin
            @(slave_drv_intf.slv_drv_cb);
            if(slave_drv_intf.slv_drv_cb.wstrobe && slave_drv_intf.slv_drv_cb.wvalid) begin
                slave_drv_intf.slv_drv_cb.awvalid  <=  1;
                if(slave_drv_intf.slv_drv_cb.awvalid)begin
                    mem[slave_drv_intf.slv_drv_cb.awaddr]     =   slave_drv_intf.slv_drv_cb.wdata[7:0];
                    mem[slave_drv_intf.slv_drv_cb.awaddr+1]   =   slave_drv_intf.slv_drv_cb.wdata[15:8];
                    mem[slave_drv_intf.slv_drv_cb.awaddr+2]   =   slave_drv_intf.slv_drv_cb.wdata[23:16];
                    mem[slave_drv_intf.slv_drv_cb.awaddr+3]   =   slave_drv_intf.slv_drv_cb.wdata[31:24];
                end
                if(slave_drv_intf.slv_drv_cb.arvalid)begin
                slave_drv_intf.slv_drv_cb.arready  <=   1;
                    slave_drv_intf.slv_drv_cb.rdata[7:0]     <=   mem[slave_drv_intf.slv_drv_cb.araddr];
                    slave_drv_intf.slv_drv_cb.rdata[15:8]    <=   mem[slave_drv_intf.slv_drv_cb.araddr+1];
                    slave_drv_intf.slv_drv_cb.rdata[23:16]   <=   mem[slave_drv_intf.slv_drv_cb.araddr+2];
                    slave_drv_intf.slv_drv_cb.rdata[31:24]   <=   mem[slave_drv_intf.slv_drv_cb.araddr+3];
                @(slave_drv_intf.slv_drv_cb);
                slave_drv_intf.slv_drv_cb.arready  <=   0;
                end
            end
            else begin
                slave_drv_intf.slv_drv_cb.awvalid  <=   0;
            end
        end
    endtask
endclass
