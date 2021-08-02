set public_repo_dir /home/wtao/workspace/hc20-verilog/corundum/fpga/lib_rmt/netfpga_fifo_vcu118/

set_property ip_repo_paths ${public_repo_dir} [current_fileset]
update_ip_catalog

# dummy ip to include NetFPGA fallthrough_small_fifo
create_ip -name input_arbiter -vendor NetFPGA -library NetFPGA -module_name input_arbiter_ip
set_property generate_synth_checkpoint false [get_files input_arbiter_ip.xci]
reset_target all [get_ips input_arbiter_ip]
generate_target all [get_ips input_arbiter_ip]

update_ip_catalog
