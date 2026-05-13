class desc_mem extends uvm_object;
    
    logic [31:0] mem_m [*];

    rand bit [31:0] CD;
    rand bit [31:0] ND;
    rand bit [31:0] ND_MSB;
    rand bit [31:0] SA;
    rand bit [31:0] SA_MSB;
    rand bit [31:0] DA;
    rand bit [31:0] DA_MSB;
    rand bit [25:0] BTT;
    rand bit [31:0] STATUS;

    `uvm_object_utils_begin(desc_mem)
        `uvm_field_int(CD, UVM_ALL_ON)
        `uvm_field_int(ND, UVM_ALL_ON)
        `uvm_field_int(ND_MSB, UVM_ALL_ON)
        `uvm_field_int(SA, UVM_ALL_ON)
        `uvm_field_int(SA_MSB, UVM_ALL_ON)
        `uvm_field_int(DA, UVM_ALL_ON)
        `uvm_field_int(DA_MSB, UVM_ALL_ON)
        `uvm_field_int(BTT, UVM_ALL_ON)
        `uvm_field_int(STATUS, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="desc_mem");
        super.new(name);
    endfunction

    constraint c_desc_align {
        //CD[5:0] == 0; 
        //ND[6:0] == 0; 
    }
    constraint c_msb_init {
        //ND_MSB == 0;
        //SA_MSB == 0;
        //DA_MSB == 0;
    }
    constraint c_btt {
        //soft BTT inside {[1:1000]};
    }
    constraint c_data_align {
        //soft SA % 16 == 0;
        //soft DA % 16 == 0;
    }
    constraint c_overlap {
        //(SA > DA) ? (SA - DA >= BTT) : (DA - SA >= BTT);
        //soft ((DA + BTT) < SA) || ((SA + BTT) < DA);
    }
    constraint c_status{
        STATUS == 0;
    }

    function void load_desc(bit [31:0] start_addr);
        mem_m[start_addr]         = ND;
        mem_m[start_addr + 'h4]   = ND_MSB;
        mem_m[start_addr + 'h8]   = SA;
        mem_m[start_addr + 'hC]   = SA_MSB;
        mem_m[start_addr + 'h10]  = DA;
        mem_m[start_addr + 'h14]  = DA_MSB;
        mem_m[start_addr + 'h18]  = BTT;
        mem_m[start_addr + 'h1C]  = STATUS;
    endfunction
endclass: desc_mem
