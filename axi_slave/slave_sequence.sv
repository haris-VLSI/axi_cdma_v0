class base_slave_sequence extends uvm_sequence #(slave_seq_item);
    `uvm_object_utils (base_slave_sequence)
    `uvm_declare_p_sequencer(slave_sequencer)
    slave_seq_item pkt, resp_pkt, sg_resp_pkt;

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
	                                        bresp == DECERR;
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

/******************** SG-MODE *********************/

class sg_base_slave_sequence extends base_slave_sequence;
    `uvm_object_utils(sg_base_slave_sequence)
    `uvm_declare_p_sequencer(slave_sequencer)

    slave_seq_item pkt, resp_pkt;
    desc_mem mem_i;
    longint index;

    function new (string name = "sg_base_slave_sequence");
       super.new (name);
    endfunction

    virtual task body();
        if(!uvm_config_db #(desc_mem)::get(null,"","descriptor_mem",mem_i))
            `uvm_fatal("SG_SLAVE", "Descriptor memory handle not found!")

        forever begin
            p_sequencer.resp_af.get(resp_pkt);
            `uvm_info("RESP_GET", $sformatf("Packet Details:\n%s", resp_pkt.sprint()), UVM_LOW)

            if(resp_pkt.operation == READ) begin
                pkt = slave_seq_item::type_id::create("pkt");
                start_item(pkt);
                index = resp_pkt.araddr/4;

                assert(pkt.randomize() with { 
                    operation == READ; 
                    rid == resp_pkt.arid; 
                    arlen == resp_pkt.arlen;
                });

                foreach(pkt.rdata[i]) begin
                    if (mem_i.mem_m.exists(index+i))
                        pkt.rdata[i] = mem_i.mem_m[index+i];
                    else
                        pkt.rdata[i] = $urandom();
                end
                
                foreach(pkt.rresp[i])begin
                    pkt.rresp[i] = OKAY;
                end
                finish_item(pkt);
            end

            if(resp_pkt.operation == WRITE) begin
                pkt = slave_seq_item::type_id::create("pkt");
                start_item(pkt);

                assert(pkt.randomize() with { 
                    bid == resp_pkt.awid; 
                    bresp == OKAY; 
                });
                finish_item(pkt);
            end
        end
    endtask
endclass: sg_base_slave_sequence
