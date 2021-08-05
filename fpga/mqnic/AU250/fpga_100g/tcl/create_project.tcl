##############################

set design TProj
set top fpga
set device xcu250-figd2104-2-e
set proj_dir ./project_synth

#############################
# Source files
set SYN_FILES [list rtl/fpga.v]
lappend SYN_FILES rtl/one_in_one_out/fpga_core.v
#
lappend SYN_FILES rtl/debounce_switch.v
lappend SYN_FILES rtl/sync_signal.v
lappend SYN_FILES rtl/one_in_one_out/interface.v
lappend SYN_FILES rtl/one_in_one_out/port.v
#
lappend SYN_FILES rtl/common/cpl_write.v
lappend SYN_FILES rtl/common/cpl_op_mux.v
lappend SYN_FILES rtl/common/desc_fetch.v
lappend SYN_FILES rtl/common/desc_op_mux.v
lappend SYN_FILES rtl/common/queue_manager.v
lappend SYN_FILES rtl/common/cpl_queue_manager.v
lappend SYN_FILES rtl/common/event_mux.v
lappend SYN_FILES rtl/common/tx_scheduler_rr.v
lappend SYN_FILES rtl/common/tdma_scheduler.v
lappend SYN_FILES rtl/common/tx_engine.v
lappend SYN_FILES rtl/common/rx_engine.v
lappend SYN_FILES rtl/common/tx_checksum.v
lappend SYN_FILES rtl/common/rx_hash.v
lappend SYN_FILES rtl/common/rx_checksum.v
lappend SYN_FILES rtl/common/cmac_pad.v
lappend SYN_FILES lib/eth/rtl/ptp_clock.v
lappend SYN_FILES lib/eth/rtl/ptp_clock_cdc.v
lappend SYN_FILES lib/eth/rtl/ptp_ts_extract.v
lappend SYN_FILES lib/axi/rtl/axil_interconnect.v
lappend SYN_FILES lib/axi/rtl/arbiter.v
lappend SYN_FILES lib/axi/rtl/priority_encoder.v
lappend SYN_FILES lib/axis/rtl/axis_adapter.v
lappend SYN_FILES lib/axis/rtl/axis_async_fifo.v
lappend SYN_FILES lib/axis/rtl/axis_fifo.v
lappend SYN_FILES lib/axis/rtl/axis_register.v
lappend SYN_FILES lib/axis/rtl/sync_reset.v
lappend SYN_FILES lib/pcie/rtl/pcie_us_axil_master.v
lappend SYN_FILES lib/pcie/rtl/dma_if_pcie_us.v
lappend SYN_FILES lib/pcie/rtl/dma_if_pcie_us_rd.v
lappend SYN_FILES lib/pcie/rtl/dma_if_pcie_us_wr.v
lappend SYN_FILES lib/pcie/rtl/dma_if_mux.v
lappend SYN_FILES lib/pcie/rtl/dma_if_mux_rd.v
lappend SYN_FILES lib/pcie/rtl/dma_if_mux_wr.v
lappend SYN_FILES lib/pcie/rtl/dma_psdpram.v
lappend SYN_FILES lib/pcie/rtl/dma_client_axis_sink.v
lappend SYN_FILES lib/pcie/rtl/dma_client_axis_source.v
lappend SYN_FILES lib/pcie/rtl/pcie_us_cfg.v
lappend SYN_FILES lib/pcie/rtl/pcie_us_msi.v
lappend SYN_FILES lib/pcie/rtl/pcie_tag_manager.v
lappend SYN_FILES lib/pcie/rtl/pulse_merge.v
# RMT-related 
lappend SYN_FILES lib_rmt/rmtv2/rmt_wrapper.v
lappend SYN_FILES lib_rmt/rmtv2/pkt_filter.v
lappend SYN_FILES lib_rmt/rmtv2/cookie.v
lappend SYN_FILES lib_rmt/rmtv2/parser_top.v
lappend SYN_FILES lib_rmt/rmtv2/parser_do_parsing_top.v
lappend SYN_FILES lib_rmt/rmtv2/parser_do_parsing.v
lappend SYN_FILES lib_rmt/rmtv2/parser_wait_segs.v
lappend SYN_FILES lib_rmt/rmtv2/sub_parser.v
lappend SYN_FILES lib_rmt/rmtv2/deparser_top.v
lappend SYN_FILES lib_rmt/rmtv2/depar_wait_segs.v
lappend SYN_FILES lib_rmt/rmtv2/depar_do_deparsing.v
lappend SYN_FILES lib_rmt/rmtv2/sub_deparser.v
lappend SYN_FILES lib_rmt/rmtv2/stage.v
lappend SYN_FILES lib_rmt/rmtv2/last_stage.v
lappend SYN_FILES lib_rmt/rmtv2/output_arbiter.v
lappend SYN_FILES lib_rmt/rmtv2/action/action_engine.v
lappend SYN_FILES lib_rmt/rmtv2/action/alu_1.v
lappend SYN_FILES lib_rmt/rmtv2/action/alu_2.v
lappend SYN_FILES lib_rmt/rmtv2/action/alu_3.v
lappend SYN_FILES lib_rmt/rmtv2/action/crossbar.v
lappend SYN_FILES lib_rmt/rmtv2/extract/key_extract.v
lappend SYN_FILES lib_rmt/rmtv2/extract/key_extract_top.v
lappend SYN_FILES lib_rmt/rmtv2/lookup/lookup_engine_top.v
lappend SYN_FILES lib_rmt/rmtv2/lookup/lke_cam_part.v
lappend SYN_FILES lib_rmt/rmtv2/lookup/lke_ram_part.v

# XDC files
set XDC_FILES [list fpga.xdc]
lappend XDC_FILES boot.xdc
lappend XDC_FILES lib/axis/syn/axis_async_fifo.tcl
lappend XDC_FILES lib/axis/syn/sync_reset.tcl
lappend XDC_FILES lib/eth/syn/ptp_clock_cdc.tcl
lappend XDC_FILES ../../../common/syn/tdma_ber_ch.tcl

# IP files
set IP_TCL_FILES [list ip/pcie4_uscale_plus_0.tcl]
lappend IP_TCL_FILES ip/cmac_usplus_0.tcl
lappend IP_TCL_FILES ip/cmac_usplus_1.tcl

# IPs for RMT pipeline
lappend IP_TCL_FILES ip/rmt/blk_mem_gen_0.tcl
lappend IP_TCL_FILES ip/rmt/blk_mem_gen_1.tcl
lappend IP_TCL_FILES ip/rmt/blk_mem_gen_2.tcl
lappend IP_TCL_FILES ip/rmt/blk_mem_gen_3.tcl
lappend IP_TCL_FILES ip/rmt/fifo_generator_512b.tcl
lappend IP_TCL_FILES ip/rmt/fifo_generator_705b.tcl
lappend IP_TCL_FILES ip/rmt/parse_act_ram_ip.tcl
lappend IP_TCL_FILES ip/rmt/page_tbl_16w_32d.tcl
lappend IP_TCL_FILES ip/rmt/fifo.tcl


#############################

create_project -name ${design} -force -dir "${proj_dir}" -part ${device}

read_vhdl -library cam  lib_rmt/xilinx_cam/dmem.vhd
read_vhdl -library cam  [glob lib_rmt/xilinx_cam/cam*.vhd]

foreach syn $SYN_FILES {
	add_files -fileset sources_1 $syn
}

foreach xdc $XDC_FILES {
	add_files -fileset constrs_1 $xdc
}

foreach ip_tcl $IP_TCL_FILES {
	source $ip_tcl
}

##
#
#add_files [glob lib_rmt/rmtv2/*.coe]
#add_files [glob lib_rmt/rmtv2/*.mif]

# for better simulation
#config_ip_cache -disable_cache
#update_ip_catalog

exit
