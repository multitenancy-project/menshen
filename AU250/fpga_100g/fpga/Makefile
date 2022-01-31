
# FPGA settings
FPGA_PART = xcu250-figd2104-2-e
FPGA_TOP = fpga
FPGA_ARCH = virtexuplus

# Files for synthesis
SYN_FILES = rtl/fpga.v

#replace rtl/fpga_core.v
#SYN_FILES += rtl/fpga_core.v
SYN_FILES += rtl/one_in_one_out/fpga_core.v

SYN_FILES += rtl/debounce_switch.v
SYN_FILES += rtl/sync_signal.v

#replace rtl/common/interface.v
#SYN_FILES += rtl/common/interface.v
SYN_FILES += rtl/one_in_one_out/interface.v

#replace rtl/common/port.v with 
#SYN_FILES += rtl/common/port.v
SYN_FILES += rtl/one_in_one_out/port.v

SYN_FILES += rtl/common/cpl_write.v
SYN_FILES += rtl/common/cpl_op_mux.v
SYN_FILES += rtl/common/desc_fetch.v
SYN_FILES += rtl/common/desc_op_mux.v
SYN_FILES += rtl/common/queue_manager.v
SYN_FILES += rtl/common/cpl_queue_manager.v
SYN_FILES += rtl/common/event_mux.v
SYN_FILES += rtl/common/tx_scheduler_rr.v
SYN_FILES += rtl/common/tdma_scheduler.v
SYN_FILES += rtl/common/tx_engine.v
SYN_FILES += rtl/common/rx_engine.v
SYN_FILES += rtl/common/tx_checksum.v
SYN_FILES += rtl/common/rx_hash.v
SYN_FILES += rtl/common/rx_checksum.v
SYN_FILES += rtl/common/cmac_pad.v
SYN_FILES += lib/eth/rtl/ptp_clock.v
SYN_FILES += lib/eth/rtl/ptp_clock_cdc.v
SYN_FILES += lib/eth/rtl/ptp_ts_extract.v
SYN_FILES += lib/axi/rtl/axil_interconnect.v
SYN_FILES += lib/axi/rtl/arbiter.v
SYN_FILES += lib/axi/rtl/priority_encoder.v
SYN_FILES += lib/axis/rtl/axis_adapter.v
SYN_FILES += lib/axis/rtl/axis_async_fifo.v
SYN_FILES += lib/axis/rtl/axis_fifo.v
SYN_FILES += lib/axis/rtl/axis_register.v
SYN_FILES += lib/axis/rtl/sync_reset.v
SYN_FILES += lib/pcie/rtl/pcie_us_axil_master.v
SYN_FILES += lib/pcie/rtl/dma_if_pcie_us.v
SYN_FILES += lib/pcie/rtl/dma_if_pcie_us_rd.v
SYN_FILES += lib/pcie/rtl/dma_if_pcie_us_wr.v
SYN_FILES += lib/pcie/rtl/dma_if_mux.v
SYN_FILES += lib/pcie/rtl/dma_if_mux_rd.v
SYN_FILES += lib/pcie/rtl/dma_if_mux_wr.v
SYN_FILES += lib/pcie/rtl/dma_psdpram.v
SYN_FILES += lib/pcie/rtl/dma_client_axis_sink.v
SYN_FILES += lib/pcie/rtl/dma_client_axis_source.v
SYN_FILES += lib/pcie/rtl/pcie_us_cfg.v
SYN_FILES += lib/pcie/rtl/pcie_us_msi.v
SYN_FILES += lib/pcie/rtl/pcie_tag_manager.v
SYN_FILES += lib/pcie/rtl/pulse_merge.v

# RMT-related rtl files
SYN_FILES += lib_rmt/rmtv2/deparser.v
SYN_FILES += lib_rmt/rmtv2/sub_deparser.v
SYN_FILES += lib_rmt/rmtv2/parser.v
SYN_FILES += lib_rmt/rmtv2/sub_parser.v
SYN_FILES += lib_rmt/rmtv2/rmt_wrapper.v
SYN_FILES += lib_rmt/rmtv2/stage.v
SYN_FILES += lib_rmt/rmtv2/extract/key_extract_2.v
SYN_FILES += lib_rmt/rmtv2/lookup/lookup_engine.v
SYN_FILES += lib_rmt/rmtv2/action/action_engine.v
SYN_FILES += lib_rmt/rmtv2/action/alu_1.v
SYN_FILES += lib_rmt/rmtv2/action/alu_2.v
SYN_FILES += lib_rmt/rmtv2/action/alu_3.v
SYN_FILES += lib_rmt/rmtv2/action/crossbar.v
SYN_FILES += lib_rmt/rmtv2/pkt_filter.v


# XDC files
XDC_FILES = fpga.xdc
XDC_FILES += boot.xdc
XDC_FILES += lib/axis/syn/axis_async_fifo.tcl
XDC_FILES += lib/axis/syn/sync_reset.tcl
XDC_FILES += lib/eth/syn/ptp_clock_cdc.tcl
XDC_FILES += ../../../common/syn/tdma_ber_ch.tcl

# IP
IP_TCL_FILES = ip/pcie4_uscale_plus_0.tcl
IP_TCL_FILES += ip/cmac_usplus_0.tcl
IP_TCL_FILES += ip/cmac_usplus_1.tcl
IP_TCL_FILES += ip/clk_wiz_0.tcl

# IPs for RMT pipeline
IP_TCL_FILES += ip/rmt/blk_mem_gen_0.tcl
IP_TCL_FILES += ip/rmt/blk_mem_gen_1.tcl
IP_TCL_FILES += ip/rmt/blk_mem_gen_2.tcl
IP_TCL_FILES += ip/rmt/blk_mem_gen_3.tcl
IP_TCL_FILES += ip/rmt/fifo_generator_512b.tcl
IP_TCL_FILES += ip/rmt/fifo_generator_612b.tcl
IP_TCL_FILES += ip/rmt/fifo_generator_705b.tcl
IP_TCL_FILES += ip/rmt/parse_act_ram_ip.tcl
IP_TCL_FILES += ip/rmt/tcam_generator.tcl


include ../common/vivado.mk

program: $(FPGA_TOP).bit
	echo "open_hw" > program.tcl
	echo "connect_hw_server" >> program.tcl
	echo "open_hw_target" >> program.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> program.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> program.tcl
	echo "set_property PROGRAM.FILE {$(FPGA_TOP).bit} [current_hw_device]" >> program.tcl
	echo "program_hw_devices [current_hw_device]" >> program.tcl
	echo "exit" >> program.tcl
	vivado -nojournal -nolog -mode batch -source program.tcl

%.mcs %.prm: %.bit
	echo "write_cfgmem -force -format mcs -size 128 -interface SPIx4 -loadbit {up 0x01002000 $*.bit} -checksum -file $*.mcs" > generate_mcs.tcl
	echo "exit" >> generate_mcs.tcl
	vivado -nojournal -nolog -mode batch -source generate_mcs.tcl
	mkdir -p rev
	COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.bit ]; \
	do COUNT=$$((COUNT+1)); done; \
	COUNT=$$((COUNT-1)); \
	for x in .mcs .prm; \
	do cp $*$$x rev/$*_rev$$COUNT$$x; \
	echo "Output: rev/$*_rev$$COUNT$$x"; done;

flash: $(FPGA_TOP).mcs $(FPGA_TOP).prm
	echo "open_hw" > flash.tcl
	echo "connect_hw_server" >> flash.tcl
	echo "open_hw_target" >> flash.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> flash.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> flash.tcl
	echo "create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {mt25qu01g-spi-x1_x2_x4}] 0]" >> flash.tcl
	echo "current_hw_cfgmem -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM [current_hw_device]]" >> flash.tcl
	echo "set_property PROGRAM.FILES [list \"$(FPGA_TOP).mcs\"] [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.PRM_FILES [list \"$(FPGA_TOP).prm\"] [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.ERASE 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]" >> flash.tcl
	echo "create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]" >> flash.tcl
	echo "program_hw_devices [current_hw_device]" >> flash.tcl
	echo "refresh_hw_device [current_hw_device]" >> flash.tcl
	echo "program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]" >> flash.tcl
	echo "boot_hw_device [current_hw_device]" >> flash.tcl
	echo "exit" >> flash.tcl
	vivado -nojournal -nolog -mode batch -source flash.tcl

