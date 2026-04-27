class master_seq_item extends axi_base_seq_item;

    `uvm_object_utils_begin(master_seq_item)
        `uvm_field_int(awaddr,UVM_ALL_ON)
        `uvm_field_array_int(wdata,  UVM_ALL_ON)
        `uvm_field_array_int(wstrobe,UVM_ALL_ON)  // always 4'hF
        `uvm_field_enum(response_t, bresp, UVM_ALL_ON)
        `uvm_field_int(araddr,UVM_ALL_ON)
        `uvm_field_array_int(rdata, UVM_ALL_ON)
        `uvm_field_array_enum(response_t, rresp, UVM_ALL_ON)
        `uvm_field_enum(slave_type,slave,UVM_ALL_ON)
        `uvm_field_enum(master_type,master,UVM_ALL_ON)
    `uvm_object_utils_end

    rand delay_t add_valid_dly;
    rand delay_t resp_ready_dly;
    rand delay_t read_ready2ready_dly;
    rand delay_t write_valid2valid_dly;

    function new(string name = "master_seq_item");
      super.new(name);
    endfunction

    // Constraints
    constraint awaddr_align_c{
        awaddr % 4 == 0;
        }
    constraint araddr_align_c{
        araddr % 4 == 0;
        }
    //constraint wstrobe_c{
    //    wstrobe[0] == 4'hf;
    //    }


    constraint wdata_c {
        wdata.size() == awlen+1;
        }
    constraint awlen_c{
        awlen == 0;
        }

    constraint resp_ready_dly_c{
        soft resp_ready_dly inside {[0:1]};
        }
    constraint add_valid_dly_c{
        soft add_valid_dly inside {[0:1]};
        }
    constraint write_valid2valid_dly_c{
        soft write_valid2valid_dly inside {[0:1]};
        }
    constraint read_ready2ready_dly_c{
        soft read_ready2ready_dly inside {[0:1]};
        }

    //constraint awsize_c{awsize inside {[0:5]};} //max 256 bit or 32 byte port
    constraint awsize_c{solve master before awsize;
      	              master == m0 -> awsize == 2;    //modified
      	              //master == m0 -> awsize inside {[0:3]};
      	              //master == m1 -> awsize inside {[0:4]};
                        //master == m2 -> awsize inside {[0:5]};
                        //master == m3 -> awsize inside {[0:2]};
                        }
    //constraint arsize_c{arsize inside {[0:5]};} //max 256 bit or 32 byte port
    constraint arsize_c{solve master before arsize;
      	              master == m0 -> arsize == 2;    //modified
      	              //master == m0 -> arsize inside {[0:3]};
      	              //master == m1 -> arsize inside {[0:4]};
                        //master == m2 -> arsize inside {[0:5]};
                        //master == m3 -> arsize inside {[0:2]};
                        }
endclass : master_seq_item
