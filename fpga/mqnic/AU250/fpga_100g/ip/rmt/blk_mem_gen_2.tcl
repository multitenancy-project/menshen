create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_2

set_property -dict [list \
	CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
	CONFIG.Load_Init_File {true} \
	CONFIG.Coe_File {/../../../../../../lib_rmt/rmtv2/memory_init_files/key_extract.coe} \
	CONFIG.Write_Depth_A {32} \
	CONFIG.Write_Width_A {38} \
	CONFIG.Read_Width_A {38} \
	CONFIG.Operating_Mode_A {NO_CHANGE} \
	CONFIG.Write_Width_B {38} \
	CONFIG.Read_Width_B {38} \
	CONFIG.Enable_B {Use_ENB_Pin} \
	CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
	CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
	CONFIG.Port_B_Clock {100} \
	CONFIG.Port_B_Enable_Rate {100} \
] [get_ips blk_mem_gen_2]

set_property generate_synth_checkpoint false [get_files blk_mem_gen_2.xci]
reset_target all [get_ips blk_mem_gen_2]
generate_target all [get_ips blk_mem_gen_2]
