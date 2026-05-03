class base_slave_sequence extends uvm_sequence #(slave_seq_item);
    `uvm_object_utils (base_slave_sequence)
    `uvm_declare_p_sequencer(slave_sequencer)
    slave_seq_item pkt,resp_pkt;

    function new (string name = "base_slave_sequence");
       super.new (name);
    endfunction

    virtual task body ();
        `uvm_info("slave_sequence :: body task","Triggred",UVM_MEDIUM);
        forever begin
            `uvm_info("slave_sequence :: body task","Waiting_for_resp_pkt",UVM_MEDIUM);
            p_sequencer.resp_af.get(resp_pkt);
            `uvm_info("slave_sequence :: body task","got_resp_pkt",UVM_MEDIUM);

            if(resp_pkt.operation == WRITE) begin
            pkt = slave_seq_item :: type_id :: create ("pkt");
            start_item(pkt);
            assert (pkt.randomize() with {  operation == WRITE;
                                            awid == resp_pkt.awid;
	                                        awaddr == resp_pkt.awaddr;
	                                        awlock == resp_pkt.awlock;
	                                        awprot == resp_pkt.awprot;
	                                        awqos == resp_pkt.awqos;
	                                        awregion == resp_pkt.awregion;
	                                        awcache == resp_pkt.awcache;
	                                        awlen == resp_pkt.awlen;
	                                        awsize == resp_pkt.awsize;
	                                        awburst == resp_pkt.awburst;
	                                        bid == awid;
	                                        bresp == OKAY;
	                                    })
            else  `uvm_error (get_full_name() ,"Packet Randomization Fail")
            finish_item(pkt);
            get_response(pkt);
            end

            if(resp_pkt.operation==READ)begin
                pkt = slave_seq_item :: type_id :: create ("pkt");
                start_item(pkt);
                assert (pkt.randomize() with {  operation == READ;
                                                arid ==resp_pkt.arid;
	                                            araddr==resp_pkt.araddr;
	                                            arlock==resp_pkt.arlock;
	                                            arprot ==resp_pkt.arprot;
	                                            arqos ==resp_pkt.arqos ;
	                                            arregion==resp_pkt.arregion;
	                                            arcache==resp_pkt.arcache;
	                                            arlen ==resp_pkt.arlen;
	                                            arsize==resp_pkt.arsize;
	                                            arburst==resp_pkt.arburst;
	                                            rid==resp_pkt.arid;
	                                        })
                else `uvm_error (get_full_name() ,"Packet Randomization Fail")
                //pkt.rdata = new[pkt.arlen + 1];
                //pkt.rresp = new[pkt.arlen + 1];
                //foreach(pkt.rresp[i])begin
                    //pkt.rdata[i] = {4{$urandom()}};
                    //pkt.rresp[i] = OKAY;
                //end
                finish_item(pkt);
                get_response(pkt);
            end
        end
    endtask : body
endclass : base_slave_sequence


class base_slave_error_sequence extends uvm_sequence #(slave_seq_item);
    `uvm_object_utils (base_slave_error_sequence)
    `uvm_declare_p_sequencer(slave_sequencer)
    slave_seq_item pkt,resp_pkt;

    function new (string name = "base_slave_error_sequence");
       super.new (name);
    endfunction

    virtual task body ();
        `uvm_info("slave_sequence :: body task","Triggred",UVM_MEDIUM);
        forever begin
            `uvm_info("slave_sequence :: body task","Waiting_for_resp_pkt",UVM_MEDIUM);
            p_sequencer.resp_af.get(resp_pkt);
            `uvm_info("slave_sequence :: body task","got_resp_pkt",UVM_MEDIUM);

            if(resp_pkt.operation == WRITE) begin
            pkt = slave_seq_item :: type_id :: create ("pkt");
            start_item(pkt);
            assert (pkt.randomize() with {  operation == WRITE;
                                            awid == resp_pkt.awid;
	                                        awaddr == resp_pkt.awaddr;
	                                        awlock == resp_pkt.awlock;
	                                        awprot == resp_pkt.awprot;
	                                        awqos == resp_pkt.awqos;
	                                        awregion == resp_pkt.awregion;
	                                        awcache == resp_pkt.awcache;
	                                        awlen == resp_pkt.awlen;
	                                        awsize == resp_pkt.awsize;
	                                        awburst == resp_pkt.awburst;
	                                        bid == awid;
	                                        bresp == SLVERR;
	                                        //bresp == OKAY;
	                                    })
            else  `uvm_error (get_full_name() ,"Packet Randomization Fail")
            finish_item(pkt);
            get_response(pkt);
            end

            if(resp_pkt.operation==READ)begin
                pkt = slave_seq_item :: type_id :: create ("pkt");
                start_item(pkt);
                assert (pkt.randomize() with {  operation == READ;
                                                arid ==resp_pkt.arid;
	                                            araddr==resp_pkt.araddr;
	                                            arlock==resp_pkt.arlock;
	                                            arprot ==resp_pkt.arprot;
	                                            arqos ==resp_pkt.arqos ;
	                                            arregion==resp_pkt.arregion;
	                                            arcache==resp_pkt.arcache;
	                                            arlen ==resp_pkt.arlen;
	                                            arsize==resp_pkt.arsize;
	                                            arburst==resp_pkt.arburst;
	                                            rid==resp_pkt.arid;
	                                        })
                else `uvm_error (get_full_name() ,"Packet Randomization Fail")
                foreach(pkt.rresp[i])begin
                    pkt.rresp[i] = SLVERR;
                end
                finish_item(pkt);
                get_response(pkt);
            end
        end
    endtask : body
endclass : base_slave_error_sequence


class base_decode_error_sequence extends uvm_sequence #(slave_seq_item);
    `uvm_object_utils (base_decode_error_sequence)
    `uvm_declare_p_sequencer(slave_sequencer)
    slave_seq_item pkt,resp_pkt;

    function new (string name = "base_decode_error_sequence");
       super.new (name);
    endfunction

    virtual task body ();
        `uvm_info("slave_sequence :: body task","Triggred",UVM_MEDIUM);
        forever begin
            `uvm_info("slave_sequence :: body task","Waiting_for_resp_pkt",UVM_MEDIUM);
            p_sequencer.resp_af.get(resp_pkt);
            `uvm_info("slave_sequence :: body task","got_resp_pkt",UVM_MEDIUM);

            if(resp_pkt.operation == WRITE) begin
            pkt = slave_seq_item :: type_id :: create ("pkt");
            start_item(pkt);
            assert (pkt.randomize() with {  operation == WRITE;
                                            awid == resp_pkt.awid;
	                                        awaddr == resp_pkt.awaddr;
	                                        awlock == resp_pkt.awlock;
	                                        awprot == resp_pkt.awprot;
	                                        awqos == resp_pkt.awqos;
	                                        awregion == resp_pkt.awregion;
	                                        awcache == resp_pkt.awcache;
	                                        awlen == resp_pkt.awlen;
	                                        awsize == resp_pkt.awsize;
	                                        awburst == resp_pkt.awburst;
	                                        bid == awid;
	                                        bresp == OKAY;
	                                    })
            else  `uvm_error (get_full_name() ,"Packet Randomization Fail")
            finish_item(pkt);
            get_response(pkt);
            end

            if(resp_pkt.operation==READ)begin
                pkt = slave_seq_item :: type_id :: create ("pkt");
                start_item(pkt);
                assert (pkt.randomize() with {  operation == READ;
                                                arid ==resp_pkt.arid;
	                                            araddr==resp_pkt.araddr;
	                                            arlock==resp_pkt.arlock;
	                                            arprot ==resp_pkt.arprot;
	                                            arqos ==resp_pkt.arqos ;
	                                            arregion==resp_pkt.arregion;
	                                            arcache==resp_pkt.arcache;
	                                            arlen ==resp_pkt.arlen;
	                                            arsize==resp_pkt.arsize;
	                                            arburst==resp_pkt.arburst;
	                                            rid==resp_pkt.arid;
	                                        })
                else `uvm_error (get_full_name() ,"Packet Randomization Fail")
                foreach(pkt.rresp[i])begin
                    pkt.rresp[i] = DECERR;
                end
                finish_item(pkt);
                get_response(pkt);
            end
        end
    endtask : body
endclass : base_decode_error_sequence


class cdma_capture_seq extends base_slave_sequence;
  `uvm_object_utils(cdma_capture_seq)

  function new (string name = "cdma_capture_seq");
     super.new (name);
  endfunction

  task body();
    master_seq_item pkt, rsp;
    for (int addr = 'h2000; addr < 'h2000+10; addr+=4) begin
        pkt = master_seq_item::type_id::create("read_pkt");
        start_item(pkt);
        if(!pkt.randomize() with {
            pkt.operation == READ;
            pkt.araddr    == addr;
            pkt.rdata.size() == 1;

            pkt.awaddr    == 'h0;
            pkt.wdata.size() == 1;
            pkt.wdata[0]  == 'h0;
            pkt.bresp     == 'h0;
        })begin
            `uvm_error (get_full_name(), "randomization_failed")
        end
        finish_item(pkt);
        //get_response(pkt);
        `uvm_info(get_full_name(),
          $sformatf("Captured read: addr=0x%0h data=0x%0h",
                  pkt.araddr, pkt.rdata[0]), UVM_MEDIUM);
    end
  endtask
endclass


class cdma_data_seq extends base_slave_sequence;
  `uvm_object_utils(cdma_data_seq)
  `uvm_declare_p_sequencer(slave_sequencer)
  slave_seq_item pkt;

  bit [31:0] s_mem [0:3000];

  function new(string name="cdma_data_seq");
    super.new(name);
    foreach (s_mem[i]) s_mem[i] = i;
  endfunction

  task body();
    foreach (s_mem[i]) begin
    pkt = slave_seq_item::type_id::create($sformatf("read_pkt_%0d",i));
    //start_item(pkt);
    //if(!pkt.randomize() with {
      pkt.operation     = READ;
      //pkt.rdata.size()  = 1;
      pkt.rdata = new[1];
      //pkt.rdata[0]      = s_mem[pkt.araddr];
      //pkt.rresp.size()  = 1;
      pkt.rresp = new[1];
      pkt.rresp[0]      = OKAY;
    //})begin
    //    `uvm_error (get_full_name(), "randomization_failed")
    //end
    //finish_item(pkt);
    end
  endtask
endclass


class slave_memory_seq extends base_slave_sequence;
    `uvm_declare_p_sequencer(slave_sequencer)
    `uvm_object_utils(slave_memory_seq)

    logic [31:0] mem_m[*]; 

    function new(string name="slave_memory_seq");
        super.new(name);
    endfunction

    task body();
        slave_seq_item pkt;
        `uvm_info("SLV_SEQ", "Starting Slave Memory Sequence...", UVM_MEDIUM)
        wait(p_sequencer.vif.areset_n == 1'b1);
        `uvm_info("SLV_SEQ", "Reset released. Slave is awake and waiting for transactions.", UVM_MEDIUM)

        forever begin
            pkt = slave_seq_item::type_id::create("pkt");
            pkt.operation = READ; 
            pkt.rdata = new[1];
            pkt.wdata = new[1];
            pkt.wstrobe = new[1];
            pkt.rresp = new[1];
            start_item(pkt);
            pkt.rdata[0] = 32'hDEADBEEF;
            pkt.rresp[0] = OKAY;
            finish_item(pkt);
            if (pkt.operation == WRITE) begin
                mem_m[pkt.awaddr] = pkt.wdata[0];
                `uvm_info("SLAVE_MEM", $sformatf("Captured Write: Addr=0x%0h Data=0x%0h", pkt.awaddr, pkt.wdata[0]), UVM_MEDIUM)
            end
            @(p_sequencer.vif.slv_drv_cb);
        end    
    endtask
endclass
