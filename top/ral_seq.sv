class ral_reset_seq_s extends uvm_sequence;
  `uvm_object_utils(ral_reset_seq_s)

  uvm_reg_block model;

  function new(string name = "ral_reset_seq_s");
    super.new(name);
  endfunction

  task body();
    uvm_reg_hw_reset_seq reset_seq;
    uvm_status_e status;

    `uvm_info(get_full_name(), "Starting RAL reset wrapper sequence", UVM_LOW)
    if (model == null) begin
      `uvm_error(get_full_name(),"ral_reset_seq_s.model is null. Set model before start().")
      return;
    end

    reset_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
    reset_seq.model = model;
    reset_seq.start(null);
    model.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    model.print();
    `uvm_info(get_full_name(), $sformatf("RAL reset wrapper finished, mirror status=%0d", status), UVM_LOW)
  endtask : body
endclass : ral_reset_seq_s

class ral_read_all_seq extends uvm_sequence;
  `uvm_object_utils(ral_read_all_seq)

  uvm_reg_block model;
  int i;
  uvm_status_e status;
  uvm_reg_data_t data;
  uvm_reg regs[$];

  function new(string name = "ral_read_all_seq");
      super.new(name);
  endfunction

  task body();
    model.get_registers(regs);
    foreach (regs[i]) begin
        `uvm_info("READ_SEQ", $sformatf("Attempting read of %s", regs[i].get_full_name()), UVM_LOW)
        regs[i].read(status, data, UVM_FRONTDOOR);

        `uvm_info("READ_SEQ", $sformatf("Read %s = 0x%0h", regs[i].get_full_name(), data), UVM_LOW)
    end
      endtask : body
endclass : ral_read_all_seq

/*
class ral_write_all_seq extends uvm_sequence #(uvm_reg_item);
  `uvm_object_utils(ral_write_all_seq)

  uvm_reg_block model;   // handle to your reg block

  function new(string name = "ral_write_all_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e   status;
    uvm_reg_data_t data;
    uvm_reg        regs[$];

    // Collect all registers from the block
    model.get_registers(regs);

    foreach (regs[i]) begin
      // Example write pattern
      data = 'hA5A50000 + i;

      `uvm_info("RAL_WRITE_ALL",
                $sformatf("Writing 0x%0h to %s",
                          data, regs[i].get_full_name()),
                UVM_LOW)

      // Frontdoor write
      regs[i].write(status, data, UVM_FRONTDOOR);

      // Frontdoor read
      regs[i].read(status, data, UVM_FRONTDOOR);

      `uvm_info("RAL_WRITE_ALL",
                $sformatf("Read back %s = 0x%0h (mirror=0x%0h)",
                          regs[i].get_full_name(),
                          data,
                          regs[i].get_mirrored_value()),
                UVM_LOW)
    end
  endtask
endclass
*/

class ral_write_all_seq extends uvm_sequence #(uvm_reg_item);
  `uvm_object_utils(ral_write_all_seq)
  uvm_reg_block model;
  cdma_reg_block blk;
  uvm_status_e status;
  uvm_reg_data_t data;
  uvm_reg regs[$];

  function new(string name = "ral_write_all_seq");
    super.new(name);
  endfunction

  task body();
    model.get_registers(regs);
    foreach(regs[i])begin
      data = 'hA5A50000 + i;
      `uvm_info("RAL_WRITE_ALL",$sformatf("Writing 0x%0h to %s",data, regs[i].get_full_name()),UVM_LOW)
      regs[i].write(status, data, UVM_FRONTDOOR);
    end

    foreach(regs[i])begin
      regs[i].read(status, data, UVM_FRONTDOOR);
      `uvm_info("RAL_WRITE_ALL",$sformatf("Read back %s = 0x%0h (mirror=0x%0h)",regs[i].get_full_name(),data,regs[i].get_mirrored_value()),UVM_LOW)
    end
  endtask
endclass : ral_write_all_seq
