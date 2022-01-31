# Vivado Launch Script
#### Change design settings here #######
set design TProj
set top top
set device xc7vx690t-3-ffg1761
set proj_dir ./project_synth
set public_repo_dir $::env(SUME_FOLDER)/lib/hw/
set xilinx_repo_dir $::env(XILINX_PATH)/data/ip/xilinx/
set bit_settings ./TProj.src/generic_bit.xdc 
set project_constraints ./TProj.src/nf_sume_general.xdc
set nf_10g_constraints ./TProj.src/nf_sume_10g.xdc

#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "${proj_dir}" -part ${device}
set_property source_mgmt_mode DisplayOnly [current_project]
set_property top ${top} [current_fileset]
puts "Creating User Datapath reference project"


#####################################
# Constraints
#####################################
#
create_fileset -constrset -quiet constraints
set_property ip_repo_paths ${public_repo_dir} [current_fileset]
add_files -fileset constraints -norecurse ${bit_settings}
add_files -fileset constraints -norecurse ${project_constraints}
add_files -fileset constraints -norecurse ${nf_10g_constraints}
set_property is_enabled true [get_files ${project_constraints}]
set_property is_enabled true [get_files ${bit_settings}]
set_property is_enabled true [get_files ${nf_10g_constraints}]
set_property constrset constraints [get_runs synth_1]
set_property constrset constraints [get_runs impl_1]

#####################################
# Project
#####################################
update_ip_catalog

# input arbiter
create_ip -name input_arbiter -vendor NetFPGA -library NetFPGA -module_name input_arbiter_ip
set_property generate_synth_checkpoint false [get_files input_arbiter_ip.xci]
reset_target all [get_ips input_arbiter_ip]
generate_target all [get_ips input_arbiter_ip]

# output queues
create_ip -name output_queues -vendor NetFPGA -library NetFPGA -module_name output_queues_ip
set_property generate_synth_checkpoint false [get_files output_queues_ip.xci]
reset_target all [get_ips output_queues_ip]
generate_target all [get_ips output_queues_ip]

source tcl/control_sub.tcl
source tcl/nf_10ge_interface.tcl

create_ip -name nf_10ge_interface -vendor NetFPGA -library NetFPGA -module_name nf_10g_interface_ip
set_property generate_synth_checkpoint false [get_files nf_10g_interface_ip.xci]
reset_target all [get_ips nf_10g_interface_ip]
generate_target all [get_ips nf_10g_interface_ip]

source tcl/nf_10ge_interface_shared.tcl
create_ip -name nf_10ge_interface_shared -vendor NetFPGA -library NetFPGA -module_name nf_10g_interface_shared_ip
set_property generate_synth_checkpoint false [get_files nf_10g_interface_shared_ip.xci]
reset_target all [get_ips nf_10g_interface_shared_ip]
generate_target all [get_ips nf_10g_interface_shared_ip]

#Add a clock wizard
# create_ip -name clk_wiz -vendor xilinx.com -library ip -version 5.3 -module_name clk_wiz_ip
# create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_ip
# # set_property -dict [list   CONFIG.NUM_OUT_CLKS {3} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT3_USED {true} CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {156.250} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100.000} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.RESET_PORT {resetn} ] [get_ips clk_wiz_ip]
# # set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_JITTER {98.146} CONFIG.CLKOUT1_PHASE_ERROR {89.971}] [get_ips clk_wiz_ip]
# set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {156.250} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.RESET_PORT {resetn} ] [get_ips clk_wiz_ip]
# set_property generate_synth_checkpoint false [get_files clk_wiz_ip.xci]
# reset_target all [get_ips clk_wiz_ip]
# generate_target all [get_ips clk_wiz_ip]
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_ip
# set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.RESET_PORT {resetn} ] [get_ips clk_wiz_ip]
set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {160.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.RESET_PORT {resetn} ] [get_ips clk_wiz_ip]
# set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_JITTER {98.146} CONFIG.CLKOUT1_PHASE_ERROR {89.971}] [get_ips clk_wiz_ip]
set_property generate_synth_checkpoint false [get_files clk_wiz_ip.xci]
reset_target all [get_ips clk_wiz_ip]
generate_target all [get_ips clk_wiz_ip]

create_ip -name proc_sys_reset -vendor xilinx.com -library ip -version 5.0 -module_name proc_sys_reset_ip
set_property -dict [list CONFIG.C_EXT_RESET_HIGH {0} CONFIG.C_AUX_RESET_HIGH {0}] [get_ips proc_sys_reset_ip]
set_property -dict [list CONFIG.C_NUM_PERP_RST {1} CONFIG.C_NUM_PERP_ARESETN {1}] [get_ips proc_sys_reset_ip]
set_property generate_synth_checkpoint false [get_files proc_sys_reset_ip.xci]
reset_target all [get_ips proc_sys_reset_ip]
generate_target all [get_ips proc_sys_reset_ip]

#Add ID block
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name identifier_ip
set_property -dict [list CONFIG.Interface_Type {AXI4} CONFIG.AXI_Type {AXI4_Lite} CONFIG.AXI_Slave_Type {Memory_Slave} CONFIG.Use_AXI_ID {false} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/id_rom16x32.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Remaining_Memory_Locations {DEADDEAD} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC} CONFIG.Port_A_Write_Rate {50} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips identifier_ip]
set_property generate_synth_checkpoint false [get_files identifier_ip.xci]
reset_target all [get_ips identifier_ip]
generate_target all [get_ips identifier_ip]

#Add Parser Action RAM IP
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name parse_act_ram_ip
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/lib_rmt_256b/rmtv2/memory_init_files/parse_act_ram_init_file.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {160} CONFIG.Read_Width_A {160} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {160} CONFIG.Read_Width_B {160} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips parse_act_ram_ip]
set_property generate_synth_checkpoint false [get_files parse_act_ram_ip.xci]
reset_target all [get_ips parse_act_ram_ip]
generate_target all [get_ips parse_act_ram_ip]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/lib_rmt_256b/rmtv2/memory_init_files/alu_2.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {32} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_0]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_0.xci]
reset_target all [get_ips blk_mem_gen_0]
generate_target all [get_ips blk_mem_gen_0]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_1
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/lib_rmt_256b/rmtv2/memory_init_files/lkup.coe} CONFIG.Write_Depth_A {16} CONFIG.Write_Width_A {625} CONFIG.Read_Width_A {625} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {625} CONFIG.Read_Width_B {625} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_1]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_1.xci]
reset_target all [get_ips blk_mem_gen_1]
generate_target all [get_ips blk_mem_gen_1]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_2
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/lib_rmt_256b/rmtv2/memory_init_files/key_extract.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {38} CONFIG.Read_Width_A {38} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {38} CONFIG.Read_Width_B {38} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_2]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_2.xci]
reset_target all [get_ips blk_mem_gen_2]
generate_target all [get_ips blk_mem_gen_2]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_3
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/lib_rmt_256b/rmtv2/memory_init_files/key_mask.coe} CONFIG.Write_Depth_A {32} CONFIG.Write_Width_A {193} CONFIG.Read_Width_A {193} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {193} CONFIG.Read_Width_B {193} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_3]
set_property generate_synth_checkpoint false [get_files blk_mem_gen_3.xci]
reset_target all [get_ips blk_mem_gen_3]
generate_target all [get_ips blk_mem_gen_3]


create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name page_tbl_16w_32d

set_property -dict [list \
	CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
	CONFIG.Load_Init_File {true} \
	CONFIG.Coe_File {/../../../../../../TProj.src/lib_rmt_256b/rmtv2/memory_init_files/page_tlb.coe} \
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

###

# create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name key_mask_ram_101w_16d
# 
# set_property -dict [list \
# 	CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
# 	CONFIG.Load_Init_File {false} \
# 	CONFIG.Write_Depth_A {16} \
# 	CONFIG.Write_Width_A {101} \
# 	CONFIG.Read_Width_A {101} \
# 	CONFIG.Operating_Mode_A {NO_CHANGE} \
# 	CONFIG.Write_Width_B {101} \
# 	CONFIG.Read_Width_B {101} \
# 	CONFIG.Enable_B {Use_ENB_Pin} \
# 	CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
# 	CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
# 	CONFIG.Port_B_Clock {100} \
# 	CONFIG.Port_B_Enable_Rate {100} \
# 	] [get_ips key_mask_ram_101w_16d]
# 
# set_property generate_synth_checkpoint false [get_files key_mask_ram_101w_16d.xci]
# reset_target all [get_ips key_mask_ram_101w_16d]
# generate_target all [get_ips key_mask_ram_101w_16d]
# 
# 
# create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name key_offset_ram_9w_16d
# 
# set_property -dict [list \
# 	CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
# 	CONFIG.Load_Init_File {false} \
# 	CONFIG.Write_Depth_A {16} \
# 	CONFIG.Write_Width_A {9} \
# 	CONFIG.Read_Width_A {9} \
# 	CONFIG.Operating_Mode_A {NO_CHANGE} \
# 	CONFIG.Write_Width_B {9} \
# 	CONFIG.Read_Width_B {9} \
# 	CONFIG.Enable_B {Use_ENB_Pin} \
# 	CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
# 	CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
# 	CONFIG.Port_B_Clock {100} \
# 	CONFIG.Port_B_Enable_Rate {100} \
# 	] [get_ips key_offset_ram_9w_16d]

# set_property generate_synth_checkpoint false [get_files key_offset_ram_9w_16d.xci]
# reset_target all [get_ips key_offset_ram_9w_16d]
# generate_target all [get_ips key_offset_ram_9w_16d]

#########

read_vhdl -library cam  TProj.src/lib_rmt_256b/xilinx_cam/dmem.vhd
read_vhdl -library cam  [glob TProj.src/lib_rmt_256b/xilinx_cam/cam*.vhd]

# rmt-related
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/sub_deparser.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/deparser_top.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/depar_wait_segs.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/depar_do_deparsing.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/parser_do_parsing.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/parser_wait_segs.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/sub_parser.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/parser_top.v"
# read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/orig_pkt_filter.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/pkt_filter.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2_256b/rmt_wrapper.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/stage.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/last_stage.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/output_arbiter.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/action/action_engine.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/action/alu_1.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/action/alu_2.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/action/alu_3.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/action/crossbar.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/extract/key_extract.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/extract/key_extract_top.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/lookup/lookup_engine_top.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/lookup/lke_cam_part.v"
read_verilog "./TProj.src/lib_rmt_256b/rmtv2/lookup/lke_ram_part.v"
#
read_verilog "./TProj.src/rmt_cpu_regs.v"
read_verilog "./TProj.src/axi_clocking.v"
read_verilog "./TProj.src/nf_datapath.v"
read_verilog "./TProj.src/top.v"
# read_verilog "./TProj.src/.v"

# add_files [glob TProj.src/*.v]
# add_files [glob TProj.src/*.v]
# add_files [glob TProj.src/rmtv2/*.v]
# add_files [glob TProj.src/rmtv2/action/*.v]
# add_files [glob TProj.src/rmtv2/extract/*.v]
# add_files [glob TProj.src/rmtv2/lookup/*.v]
# add_files [glob TProj.src/*.vhd]
add_files [glob TProj.src/lib_rmt_256b/rmtv2/memory_init_files/*.coe]
add_files [glob TProj.src/lib_rmt_256b/rmtv2/memory_init_files/*.mif]
# add_files [glob TProj.src/input_files/*.axi]
# read_verilog TProj.src/action_engine/action_engine.v
# read_verilog TProj.src/key_extract/key_extract.v
# read_verilog TProj.src/lookup/lookup_engine.v

# generic_bit.xdc, nf_sume_general.xdc, nf_sume_10g.xdc
# add_files -fileset constrs_1 [glob TProj.src/*.xdc]


exit
