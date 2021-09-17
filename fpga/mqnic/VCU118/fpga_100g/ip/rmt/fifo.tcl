set public_repo_dir /home/wtao/workspace/hc20-verilog/corundum/fpga/lib_rmt/netfpga_fifo_vcu118/

set_property ip_repo_paths ${public_repo_dir} [current_fileset]
update_ip_catalog

# dummy ip to include NetFPGA fallthrough_small_fifo
create_ip -name input_arbiter -vendor NetFPGA -library NetFPGA -module_name input_arbiter_ip
set_property generate_synth_checkpoint false [get_files input_arbiter_ip.xci]
reset_target all [get_ips input_arbiter_ip]
generate_target all [get_ips input_arbiter_ip]

update_ip_catalog

create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {4} CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_ADV_TRIGGER {true} CONFIG.C_PROBE3_MU_CNT {2} CONFIG.C_PROBE2_MU_CNT {2} CONFIG.C_PROBE1_MU_CNT {2} CONFIG.C_PROBE0_MU_CNT {2} CONFIG.ALL_PROBE_SAME_MU_CNT {2}] [get_ips ila_0]
reset_target all [get_ips ila_0]
generate_target all [get_ips ila_0]
update_ip_catalog
