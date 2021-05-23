read_file -library cam -format vhdl -autoread "${source_path}xilinx_cam/cam_init_file_pack_xst.vhd ${source_path}xilinx_cam/cam_rtl.vhd ${source_path}xilinx_cam/cam_control.vhd ${source_path}xilinx_cam/cam_decoder.vhd ${source_path}xilinx_cam/cam_input_ternary_ternenc.vhd ${source_path}xilinx_cam/cam_input_ternary.vhd ${source_path}xilinx_cam/cam_input.vhd ${source_path}xilinx_cam/cam_match_enc.vhd ${source_path}xilinx_cam/cam_mem_srl16_block.vhd ${source_path}xilinx_cam/cam_mem_srl16_block_word.vhd ${source_path}xilinx_cam/cam_mem_srl16_ternwrcomp.vhd ${source_path}xilinx_cam/cam_mem_srl16.vhd ${source_path}xilinx_cam/cam_mem_srl16_wrcomp.vhd ${source_path}xilinx_cam/cam_mem.vhd ${source_path}xilinx_cam/cam_regouts.vhd ${source_path}xilinx_cam/dmem.vhd ${source_path}xilinx_cam/cam_pkg.vhd ${source_path}xilinx_cam/cam_top.vhd" -top cam_top


read_file ${source_path} -autoread -recursive -format verilog -top rmt_wrapper
# read_file ${source_path} -autoread -recursive -format verilog -top stage 

# test simple file
# read_file "${source_path}/test_cam.v"

#
# read_file {./src/ftfifo/fallthrough_small_fifo.v ./src/ftfifo/small_fifo.v} -format verilog 
#
