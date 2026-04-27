//class slave_memory_seq extends uvm_sequence #(slave_seq_item);
//    `uvm_declare_p_sequencer(slave_sequencer)
//    `uvm_object_utils(slave_memory_seq)
//    
//    function new(string name="slave_memory_seq");
//        super.new(name);
//    endfunction
//
//    slave_seq_item pkt;
//
//    logic [31:0]mem_m[*]; 
//
//    task body();
//        wait(p_sequencer.vif.areset_n == 1'b1);
//        forever begin
//            pkt = slave_seq_item::type_id::create("pkt");
//            
//            pkt.rdata = new[1];
//            pkt.wdata = new[1];
//            pkt.wstrobe = new[1];
//            pkt.rresp = new[1];
//    
//            start_item(pkt);
//            pkt.rdata[0] = 32'hDEADBEEF;
//            pkt.rresp[0] = OKAY; 
//            finish_item(pkt);
//            if (pkt.operation == WRITE) begin
//                mem_m[pkt.awaddr] = pkt.wdata[0];
//                `uvm_info("SLAVE_MEM", $sformatf("Captured Write: Addr=0x%0h Data=0x%0h", pkt.awaddr, pkt.wdata[0]), UVM_LOW)
//            end
//            @(p_sequencer.vif.slv_drv_cb);
//        end    
//    endtask
//endclass
