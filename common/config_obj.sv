class config_obj extends uvm_object();
`uvm_object_utils(config_obj)

   //static reg                   reset_n;

//config members
   int no_of_masters, no_of_slaves;
   virtual master_intf mas_if[];
   virtual slave_intf  slv_if[];
   int total_trans;
   uvm_active_passive_enum mas_is_active[] ,slv_is_active[];
   //int slave_width [4], master_width[4];

  function new (string name = "config_obj");
     super.new (name);
  endfunction
endclass :config_obj
