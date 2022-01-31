set design TProj
set sim_top tb/tb_pkt_gen_256b.v
set device xc7vx690t-3-ffg1761
set proj_dir ./project_pktgen
set public_repo_dir $::env(SUME_FOLDER)/lib/hw/

create_project -name ${design} -force -dir "${proj_dir}" -part ${device}
set_property source_mgmt_mode DisplayOnly [current_project]
puts "Creating RMT 512b datawidth simulation"

create_fileset -constrset -quiet constrants
set_property ip_repo_paths ${public_repo_dir} [current_fileset]
update_ip_catalog

# dummy
create_ip -name input_arbiter -vendor NetFPGA -library NetFPGA -module_name input_arbiter_ip
set_property generate_synth_checkpoint false [get_files input_arbiter_ip.xci]
reset_target all [get_ips input_arbiter_ip]
generate_target all [get_ips input_arbiter_ip]

#Add Parser Action RAM IP
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name parse_act_ram_ip
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../lib_rmtv2/memory_init_files/parse_act_ram_init_file.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {160} CONFIG.Read_Width_A {160} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {160} CONFIG.Read_Width_B {160} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips parse_act_ram_ip]
set_property generate_synth_checkpoint false [get_files parse_act_ram_ip.xci]
reset_target all [get_ips parse_act_ram_ip]
generate_target all [get_ips parse_act_ram_ip]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../lib_rmtv2/memory_init_files/alu_2.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {32} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_0]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_0.xci]
reset_target all [get_ips blk_mem_gen_0]
generate_target all [get_ips blk_mem_gen_0]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_1
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../lib_rmtv2/memory_init_files/lkup.coe} CONFIG.Write_Depth_A {16} CONFIG.Write_Width_A {625} CONFIG.Read_Width_A {625} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {625} CONFIG.Read_Width_B {625} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_1]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_1.xci]
reset_target all [get_ips blk_mem_gen_1]
generate_target all [get_ips blk_mem_gen_1]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_2
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../lib_rmtv2/memory_init_files/key_extract.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {38} CONFIG.Read_Width_A {38} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {38} CONFIG.Read_Width_B {38} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_2]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_2.xci]
reset_target all [get_ips blk_mem_gen_2]
generate_target all [get_ips blk_mem_gen_2]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_3
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../lib_rmtv2/memory_init_files/key_mask.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {193} CONFIG.Read_Width_A {193} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {193} CONFIG.Read_Width_B {193} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_3]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_3.xci]
reset_target all [get_ips blk_mem_gen_3]
generate_target all [get_ips blk_mem_gen_3]


create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name page_tbl_16w_32d

set_property -dict [list \
	CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
	CONFIG.Load_Init_File {true} \
	CONFIG.Coe_File {/../../../../../../lib_rmtv2/memory_init_files/page_tlb.coe} \
	CONFIG.Write_Depth_A {32} \
	CONFIG.Write_Width_A {16} \
	CONFIG.Read_Width_A {16} \
	CONFIG.Operating_Mode_A {NO_CHANGE} \
	CONFIG.Write_Width_B {16} \
	CONFIG.Read_Width_B {16} \
	CONFIG.Enable_B {Use_ENB_Pin} \
	CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
	CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
	CONFIG.Port_B_Clock {100} \
	CONFIG.Port_B_Enable_Rate {100} \
] [get_ips page_tbl_16w_32d]

set_property generate_synth_checkpoint false [get_files page_tbl_16w_32d.xci]
reset_target all [get_ips page_tbl_16w_32d]
generate_target all [get_ips page_tbl_16w_32d]
####################

update_ip_catalog

###
add_files "./lib_rmtv2/memory_init_files/cam_init_file.mif"

###
read_vhdl -library cam  ../xilinx_cam/dmem.vhd
read_vhdl -library cam  [glob ../xilinx_cam/cam*.vhd]

# rmt-related
read_verilog "./sub_deparser.v"
read_verilog "./deparser_top.v"
read_verilog "./depar_wait_segs.v"
read_verilog "./depar_do_deparsing.v"
read_verilog "./parser_do_parsing.v"
read_verilog "./parser_wait_segs.v"
read_verilog "./sub_parser.v"
read_verilog "./parser_top.v"
# read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/orig_pkt_filter.v"
read_verilog "./pkt_filter.v"
read_verilog "./rmt_wrapper.v"
read_verilog "./lib_rmtv2/stage.v"
read_verilog "./lib_rmtv2/last_stage.v"
read_verilog "./lib_rmtv2/output_arbiter.v"
read_verilog "./lib_rmtv2/action/action_engine.v"
read_verilog "./lib_rmtv2/action/alu_1.v"
read_verilog "./lib_rmtv2/action/alu_2.v"
read_verilog "./lib_rmtv2/action/alu_3.v"
read_verilog "./lib_rmtv2/action/crossbar.v"
read_verilog "./lib_rmtv2/extract/key_extract.v"
read_verilog "./lib_rmtv2/extract/key_extract_top.v"
read_verilog "./lib_rmtv2/lookup/lookup_engine_top.v"
read_verilog "./lib_rmtv2/lookup/lke_cam_part.v"
read_verilog "./lib_rmtv2/lookup/lke_ram_part.v"
###
read_verilog "./tb/tb_pkt_gen_256b.v"

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property top ${sim_top} [get_filesets sim_1]
set_property include_dirs ${proj_dir} [get_filesets sim_1]
set_property simulator_language Mixed [current_project]
set_property verilog_define { {SIMULATION=1} } [get_filesets sim_1]
set_property -name xsim.more_options -value {-testplusarg TESTNAME=basic_test} -objects [get_filesets sim_1]
set_property runtime {} [get_filesets sim_1]
set_property target_simulator xsim [current_project]
set_property compxlib.compiled_library_dir {} [current_project]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# workaround to avoid invoking default python2 in vivado
# unset env(PYTHONHOME)
# set output [exec python3 $::env(NF_DESIGN_DIR)/test/${test_name}/run.py]
# puts $output

set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1
set_property -name {xsim.simulate.runtime} -value {10000ns} -objects [get_filesets sim_1]

launch_simulation -simset sim_1 -mode behavioral
run 10us

exit
