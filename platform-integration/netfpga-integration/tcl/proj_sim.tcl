#
# Copyright (c) 2015 Georgina Kalogeridou
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

# Set variables.
set design proj_sim
set top top_sim
set sim_top top_tb
set device  xc7vx690t-3-ffg1761
set proj_dir ./project_sim
set public_repo_dir $::env(SUME_FOLDER)/lib/hw/
set xilinx_repo_dir $::env(XILINX_PATH)/data/ip/xilinx/
set axi_files_dir $::env(ONNETFPGA_PATH)/TProj.src/input_files
set bit_settings ./TProj.src/generic_bit.xdc 
set project_constraints ./TProj.src/nf_sume_general.xdc
set nf_10g_constraints ./TProj.src/nf_sume_10g.xdc


#####################################
# Read IP Addresses and export registers
#####################################

# Build project.
create_project -name ${design} -force -dir "${proj_dir}" -part ${device}
set_property source_mgmt_mode DisplayOnly [current_project]  
set_property top ${top} [current_fileset]
puts "Creating User Datapath reference project"

create_fileset -constrset -quiet constraints
set_property ip_repo_paths ${public_repo_dir} [current_fileset]
add_files -fileset constraints -norecurse ${bit_settings}
add_files -fileset constraints -norecurse ${project_constraints}
add_files -fileset constraints -norecurse ${nf_10g_constraints}
set_property is_enabled true [get_files ${project_constraints}]
set_property is_enabled true [get_files ${bit_settings}]
set_property is_enabled true [get_files ${project_constraints}]

update_ip_catalog
create_ip -name input_arbiter -vendor NetFPGA -library NetFPGA -module_name input_arbiter_ip
set_property generate_synth_checkpoint false [get_files input_arbiter_ip.xci]
reset_target all [get_ips input_arbiter_ip]
generate_target all [get_ips input_arbiter_ip]

create_ip -name output_queues -vendor NetFPGA -library NetFPGA -module_name output_queues_ip
set_property generate_synth_checkpoint false [get_files output_queues_ip.xci]
reset_target all [get_ips output_queues_ip]
generate_target all [get_ips output_queues_ip]

#Add ID block
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name identifier_ip
set_property -dict [list CONFIG.Interface_Type {AXI4} CONFIG.AXI_Type {AXI4_Lite} CONFIG.AXI_Slave_Type {Memory_Slave} CONFIG.Use_AXI_ID {false} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../TProj.src/id_rom16x32.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Remaining_Memory_Locations {DEADDEAD} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {1024} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC} CONFIG.Port_A_Write_Rate {50} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips identifier_ip]
set_property generate_synth_checkpoint false [get_files identifier_ip.xci]
reset_target all [get_ips identifier_ip]
generate_target all [get_ips identifier_ip]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_ip
set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_JITTER {98.146} CONFIG.CLKOUT1_PHASE_ERROR {89.971}] [get_ips clk_wiz_ip]
set_property generate_synth_checkpoint false [get_files clk_wiz_ip.xci]
reset_target all [get_ips clk_wiz_ip]
generate_target all [get_ips clk_wiz_ip]


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
# 
# set_property generate_synth_checkpoint false [get_files key_offset_ram_9w_16d.xci]
# reset_target all [get_ips key_offset_ram_9w_16d]
# generate_target all [get_ips key_offset_ram_9w_16d]

##################

create_ip -name barrier -vendor NetFPGA -library NetFPGA -module_name barrier_ip
reset_target all [get_ips barrier_ip]
generate_target all [get_ips barrier_ip]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip0
set_property -dict [list CONFIG.OUTPUT_FILE ${axi_files_dir}/record0.axi] [get_ips axis_sim_record_ip0]
reset_target all [get_ips axis_sim_record_ip0]
generate_target all [get_ips axis_sim_record_ip0]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip1
set_property -dict [list CONFIG.OUTPUT_FILE ${axi_files_dir}/record1.axi] [get_ips axis_sim_record_ip1]
reset_target all [get_ips axis_sim_record_ip1]
generate_target all [get_ips axis_sim_record_ip1]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip2
set_property -dict [list CONFIG.OUTPUT_FILE ${axi_files_dir}/record2.axi] [get_ips axis_sim_record_ip2]
reset_target all [get_ips axis_sim_record_ip2]
generate_target all [get_ips axis_sim_record_ip2]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip3
set_property -dict [list CONFIG.OUTPUT_FILE ${axi_files_dir}/record3.axi] [get_ips axis_sim_record_ip3]
reset_target all [get_ips axis_sim_record_ip3]
generate_target all [get_ips axis_sim_record_ip3]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip4
set_property -dict [list CONFIG.OUTPUT_FILE ${axi_files_dir}/record4.axi] [get_ips axis_sim_record_ip4]
reset_target all [get_ips axis_sim_record_ip4]
generate_target all [get_ips axis_sim_record_ip4]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip0
set_property -dict [list CONFIG.input_file ${axi_files_dir}/test0.axi] [get_ips axis_sim_stim_ip0]
generate_target all [get_ips axis_sim_stim_ip0]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip1
set_property -dict [list CONFIG.input_file ${axi_files_dir}/test1.axi] [get_ips axis_sim_stim_ip1]
generate_target all [get_ips axis_sim_stim_ip1]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip2
set_property -dict [list CONFIG.input_file ${axi_files_dir}/test2.axi] [get_ips axis_sim_stim_ip2]
generate_target all [get_ips axis_sim_stim_ip2]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip3
set_property -dict [list CONFIG.input_file ${axi_files_dir}/test3.axi] [get_ips axis_sim_stim_ip3]
generate_target all [get_ips axis_sim_stim_ip3]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip4
set_property -dict [list CONFIG.input_file ${axi_files_dir}/test4.axi] [get_ips axis_sim_stim_ip4]
generate_target all [get_ips axis_sim_stim_ip4]

create_ip -name axi_sim_transactor -vendor NetFPGA -library NetFPGA -module_name axi_sim_transactor_ip
set_property -dict [list CONFIG.STIM_FILE ${axi_files_dir}/reg_stim.axi CONFIG.EXPECT_FILE ${axi_files_dir}/reg_exp.axi CONFIG.LOG_FILE ${axi_files_dir}/reg_stim.log] [get_ips axi_sim_transactor_ip]
reset_target all [get_ips axi_sim_transactor_ip]
generate_target all [get_ips axi_sim_transactor_ip]

update_ip_catalog

source ./tcl/control_sub_sim.tcl

add_files "./TProj.src/lib_rmt_256b/rmtv2/memory_init_files/cam_init_file.mif"

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
read_verilog "./TProj.src/rmt_cpu_regs_defines.v"
read_verilog "./TProj.src/axi_clocking.v"
read_verilog "./TProj.src/nf_datapath.v"
read_verilog "./TProj.src/top_sim.v"
read_verilog "./TProj.src/top_tb.v"

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
run 15us

