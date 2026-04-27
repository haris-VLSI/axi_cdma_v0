class cdma_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(cdma_reg_adapter)

  function new(string name = "cdma_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 1;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    master_seq_item bus_item = master_seq_item::type_id::create("bus_item");
    `uvm_info("ADAPTER", $sformatf("reg2bus IN  addr=0x%0h data=0x%0h kind=%s", rw.addr, rw.data, rw.kind.name()), UVM_LOW)

    bus_item.wdata   = new[1];
    bus_item.rdata   = new[1];
    bus_item.rresp   = new[1];

    if (rw.kind == UVM_WRITE) begin
      bus_item.operation = WRITE;
      bus_item.awaddr    = rw.addr;
      bus_item.wdata[0]  = rw.data;

      `uvm_info("adapter_write",$sformatf("reg2bus WRITE addr=0x%0h data=0x%0h", rw.addr, rw.data), UVM_LOW);

    end else begin
      bus_item.operation = READ;
      bus_item.araddr    = rw.addr;

      `uvm_info("adapter_read",$sformatf("reg2bus READ addr=0x%0h", rw.addr), UVM_LOW);
    end
    `uvm_info("ADAPTER", $sformatf("reg2bus OUT awaddr=0x%0h araddr=0x%0h wdata=0x%0h",bus_item.awaddr, bus_item.araddr, bus_item.wdata[0]), UVM_LOW)
    return bus_item;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
    master_seq_item bus_pkt;
    if (!$cast(bus_pkt, bus_item))begin
        `uvm_fatal(get_type_name(), "Failed to cast bus_item transaction")
        return;
    end
    if (bus_pkt.operation == READ) begin
        rw.kind = UVM_READ;
        rw.addr = bus_pkt.araddr;
        rw.data = bus_pkt.rdata[0];
        `uvm_info("adapter_read",$sformatf("bus2reg READ addr=0x%0h data=0x%0h", rw.addr, rw.data), UVM_LOW);
    `uvm_info("ADAPTER", $sformatf("bus2reg IN READ addr=0x%0h data=0x%0h kind=%s", bus_pkt.araddr, bus_pkt.rdata[0], bus_pkt.operation.name()), UVM_LOW)
    end
    else begin
        rw.kind = UVM_WRITE;
        rw.addr = bus_pkt.awaddr;
        rw.data = bus_pkt.wdata[0];
        `uvm_info("adapter_write",$sformatf("bus2reg WRITE addr=0x%0h data=0x%0h", rw.addr, rw.data), UVM_LOW);
    `uvm_info("ADAPTER", $sformatf("bus2reg IN WRITE addr=0x%0h data=0x%0h kind=%s", bus_pkt.awaddr, bus_pkt.wdata[0], bus_pkt.operation.name()), UVM_LOW)
    end
// add status
    `uvm_info("ADAPTER", $sformatf("bus2reg OUT addr=0x%0h data=0x%0h",rw.addr, rw.data), UVM_LOW)
  endfunction
endclass
