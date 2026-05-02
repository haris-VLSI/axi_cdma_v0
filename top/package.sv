package axi_package;
 `include "uvm_macros.svh"
  import  uvm_pkg :: *;
  import  reg_block_pkg :: *;
// COMMON
 `include "../common/config_obj.sv"
 `include "../common/axi_parameters.sv"
 `include "../common/axi_base_sequence_item.sv"
 `include "../axi_lite/master_seq_item.sv"
 `include "../cdma_reg_ral/reg_seq_item.sv"
  `include "../cdma_reg_ral/cdma_reg_adapter.sv"
  `include "../cdma_reg_ral/cdma_reg_predictor.sv"
 `include "../axi_lite/master_sequencer.sv"
 `include "../axi_lite/master_sequence1.sv"
 //`include "../axi_lite/master_sequence.sv"
 `include "../axi_slave/slave_seq_item.sv"
 `include "../axi_slave/slave_sequencer.sv"
 `include "../axi_slave/slave_sequence.sv"
 //`include "../axi_lite/master_driver.sv"
 //`include "../axi_lite/master_monitor.sv"
 `include "../axi_lite/master_driver_1.sv"
 `include "../axi_lite/master_monitor_1.sv"
 `include "../axi_lite/master_agent.sv"
 `include "../axi_slave/slave_driver.sv"
 //`include "../axi_slave/slave_monitor.sv"
 //`include "../axi_slave/slave_driver_2.sv"
 `include "../axi_slave/slave_monitor_2.sv"
 `include "../axi_slave/slave_agent.sv"
 `include "../common/virtual_sequencer.sv"
 `include "../common/virtual_sequence.sv"

 `include "../common/cov_cdma.sv"
// `include "../common/sbd.sv"
 `include "../common/sbd_cdma.sv"
// `include "../common/chk_cdma.sv"
 `include "../common/cdma_checker.sv"
 //`include "../common/cdma_sbd.sv"
 //`include "../common/cdma_4k_sbd.sv"
// TOP
 `include "cdma_env.sv"
 `include "ral_seq.sv"
 `include "cdma_base_test.sv"

endpackage
