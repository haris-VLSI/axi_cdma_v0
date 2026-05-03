interface introut_intf (input aclk, areset_n);
    logic            cdma_introut;    //added

    clocking mas_mon_cb @(posedge aclk);
        default input #1 output #0;
        input     cdma_introut;     //added
    endclocking:mas_mon_cb

    modport MON_MOD_introut (clocking mas_mon_cb,input areset_n);

endinterface : master_intf
