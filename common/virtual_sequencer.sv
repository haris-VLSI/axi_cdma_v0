class virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils (virtual_sequencer)
   master_sequencer m_seqr[]; //master sequencers
   slave_sequencer  s_seqr[]; //slave sequencers
   uvm_component    sqr_q[$];
   cdma_reg_block   reg_block;
   config_obj       obj;

   function new (string name = "virtual_sequencer" , uvm_component parent);
        super.new(name,parent);
   endfunction
  
   extern function void build_phase		(uvm_phase phase);
   extern function void connect_phase	(uvm_phase phase);

endclass: virtual_sequencer


function void virtual_sequencer:: build_phase 	(uvm_phase phase);
  super.build_phase (phase);
  if (!uvm_config_db #(config_obj) :: get(this,"","config_obj",obj))
  `uvm_fatal(get_full_name(),"Config_obj get Failure");
  m_seqr = new[obj.no_of_masters];						//4 master sequencer
  s_seqr = new[obj.no_of_slaves];						//4 slaves sequencer

  //creating 4 master sequencer
  for (int i = 0 ; i < obj.no_of_masters ; i++)
    m_seqr[i]= master_sequencer :: type_id :: create ($sformatf("m_sqr_h[%0d]",i), this);

      //creating 4 slave sequencer
  for (int i = 0 ; i < obj.no_of_slaves ; i++)
    s_seqr[i]= slave_sequencer :: type_id :: create ($sformatf("s_sqr_h[%0d]",i), this);
endfunction : build_phase


function void virtual_sequencer:: connect_phase 	(uvm_phase phase);
     super.connect_phase (phase);
     for (int i = 0 ; i < obj.no_of_masters ; i++) begin
       sqr_q.delete();								//reseting the queue
       uvm_top.find_all ($sformatf ("*.m_agt[%0d].sqr",i),sqr_q);
       if (sqr_q.size() > 1)
         `uvm_fatal (get_full_name , "Multiple sqr match")
       else if (sqr_q.size() == 0)
           `uvm_fatal (get_full_name , "No sqr match")
       else
            $cast(m_seqr[i],sqr_q[0]);
     end

     for (int i = 0 ; i < obj.no_of_slaves ; i++) begin
        sqr_q.delete();
        uvm_top.find_all ($sformatf ("*.s_agt[%0d].sqr",i),sqr_q);
        if (sqr_q.size() > 1)
           `uvm_fatal (get_full_name , "Multiple sqr match")
        else if (sqr_q.size() == 0)
           `uvm_fatal (get_full_name , "No sqr match")
        else
            $cast(s_seqr[i],sqr_q[0]);
     end
endfunction : connect_phase
