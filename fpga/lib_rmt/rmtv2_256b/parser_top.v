`timescale 1ns / 1ps


module parser_top #(
	parameter C_S_AXIS_DATA_WIDTH = 256,
	parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter PKT_HDR_LEN = (6+4+2)*8*8+256, // check with the doc
	parameter PARSER_MOD_ID = 3'b0,
	parameter C_NUM_SEGS = 4,
	parameter C_VLANID_WIDTH = 12
)
(
	input									axis_clk,
	input									aresetn,

	// input slvae axi stream
	input [C_S_AXIS_DATA_WIDTH-1:0]			s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		s_axis_tkeep,
	input									s_axis_tvalid,
	input									s_axis_tlast,

	// output
	output									parser_valid,
	output [PKT_HDR_LEN-1:0]				pkt_hdr_vec,

	// back-pressure signals
	output									s_axis_tready,
	input									stg_ready_in,

	// ctrl path
	input [C_S_AXIS_DATA_WIDTH-1:0]			ctrl_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		ctrl_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		ctrl_s_axis_tkeep,
	input									ctrl_s_axis_tvalid,
	input									ctrl_s_axis_tlast,

	output [C_S_AXIS_DATA_WIDTH-1:0]		ctrl_m_axis_tdata,
	output [C_S_AXIS_TUSER_WIDTH-1:0]		ctrl_m_axis_tuser,
	output [C_S_AXIS_DATA_WIDTH/8-1:0]		ctrl_m_axis_tkeep,
	output									ctrl_m_axis_tvalid,
	output									ctrl_m_axis_tlast
);

wire [C_NUM_SEGS*C_S_AXIS_DATA_WIDTH-1:0]	tdata_segs_in, tdata_segs_fifo_out;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				tuser_1st_in, tuser_1st_fifo_out;
wire										segs_fifo_full, segs_fifo_empty;
wire										vlan_fifo_full, vlan_fifo_empty;
wire										segs_valid_in, vlan_valid_in;

wire [C_VLANID_WIDTH-1:0]					vlan_in, vlan_fifo_out;
wire										segs_fifo_rd, vlan_fifo_rd;

assign s_axis_tready = ~segs_fifo_full & ~vlan_fifo_full;

fallthrough_small_fifo #(
	.WIDTH(C_NUM_SEGS*C_S_AXIS_DATA_WIDTH+C_S_AXIS_TUSER_WIDTH),
	.MAX_DEPTH_BITS(5)
)
segs_fifo (
	.din					({tdata_segs_in, tuser_1st_in}),
	.wr_en					(segs_valid_in),
	//
	.rd_en					(segs_fifo_rd),
	.dout					({tdata_segs_fifo_out, tuser_1st_fifo_out}),
	//
	.full					(),
	.prog_full				(),
	.nearly_full			(segs_fifo_full),
	.empty					(segs_fifo_empty),
	.reset					(~aresetn),
	.clk					(axis_clk)
);

fallthrough_small_fifo #(
	.WIDTH(C_VLANID_WIDTH),
	.MAX_DEPTH_BITS(5)
)
vlan_fifo (
	.din					(vlan_in),
	.wr_en					(vlan_valid_in),
	//
	.rd_en					(vlan_fifo_rd),
	.dout					(vlan_fifo_out),
	//
	.full					(),
	.prog_full				(),
	.nearly_full			(vlan_fifo_full),
	.empty					(vlan_fifo_empty),
	.reset					(~aresetn),
	.clk					(axis_clk)
);

parser_wait_segs #(
)
get_segs
(
	.axis_clk				(axis_clk),
	.aresetn				(aresetn),

	.s_axis_tdata			(s_axis_tdata),
	.s_axis_tuser			(s_axis_tuser),
	.s_axis_tkeep			(s_axis_tkeep),
	.s_axis_tvalid			(s_axis_tvalid),
	.s_axis_tlast			(s_axis_tlast),

	.segs_fifo_ready		(!segs_fifo_full),
	// output
	.tdata_segs				(tdata_segs_in),
	.tuser_1st				(tuser_1st_in),
	.vlan					(vlan_in),
	.segs_valid				(segs_valid_in),
	.vlan_valid				(vlan_valid_in)
);

parser_do_parsing #(
)
do_parsing
(
	.axis_clk				(axis_clk),
	.aresetn				(aresetn),

	.tdata_segs				(tdata_segs_fifo_out),
	.tuser_1st				(tuser_1st_fifo_out),
	.vlan_id				(vlan_fifo_out),
	.segs_fifo_empty		(segs_fifo_empty),
	.vlan_fifo_empty		(vlan_fifo_empty),
	.stg_ready_in			(stg_ready_in),

	.segs_fifo_rd			(segs_fifo_rd),
	.vlan_fifo_rd			(vlan_fifo_rd),
	
	.parser_valid			(parser_valid),
	.pkt_hdr_vec			(pkt_hdr_vec),

	.ctrl_s_axis_tdata		(ctrl_s_axis_tdata),
	.ctrl_s_axis_tuser		(ctrl_s_axis_tuser),
	.ctrl_s_axis_tkeep		(ctrl_s_axis_tkeep),
	.ctrl_s_axis_tvalid		(ctrl_s_axis_tvalid),
	.ctrl_s_axis_tlast		(ctrl_s_axis_tlast),

	.ctrl_m_axis_tdata		(ctrl_m_axis_tdata),
	.ctrl_m_axis_tuser		(ctrl_m_axis_tuser),
	.ctrl_m_axis_tkeep		(ctrl_m_axis_tkeep),
	.ctrl_m_axis_tvalid		(ctrl_m_axis_tvalid),
	.ctrl_m_axis_tlast		(ctrl_m_axis_tlast)
);

endmodule
