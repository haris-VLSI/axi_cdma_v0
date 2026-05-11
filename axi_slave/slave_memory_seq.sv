class slave_memory_seq extends uvm_sequence #(slave_seq_item);
    `uvm_declare_p_sequencer(slave_sequencer)
    `uvm_object_utils(slave_memory_seq)
    
    function new(string name="slave_memory_seq");
        super.new(name);
    endfunction

    slave_seq_item pkt;

    logic [31:0]mem_m[*]; 

    task body();
        forever begin
            pkt = slave_seq_item::type_id::create("pkt");
            
            rdata = new[1];
            wdata = new[1];
            wstrobe = new[1];
            rresp = new[1];
    
            start_item(pkt);
            rdata[0] = 32'hDEADBEEF;
            rresp[0] = OKAY; 
            finish_item(pkt);
            if (operation == WRITE) begin
                mem_m[awaddr] = wdata[0];
                `uvm_info("SLAVE_MEM", $sformatf("Captured Write: Addr=0x%0h Data=0x%0h", awaddr, wdata[0]), UVM_LOW)
            end
        end    
    endtask
endclass
