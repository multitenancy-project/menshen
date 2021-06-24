`timescale 1ns / 1ps

module rmt_wrapper #(
	// Slave AXI parameters
	// AXI Stream parameters
	// Slave
	parameter C_S_AXIS_DATA_WIDTH = 256,
	parameter C_S_AXIS_TUSER_WIDTH = 128
	// Master
	// self-defined
)
(
	input									clk,		// axis clk
	input									aresetn,	

	// input Slave AXI Stream
	input [C_S_AXIS_DATA_WIDTH-1:0]				s_axis_tdata,
	input [((C_S_AXIS_DATA_WIDTH/8))-1:0]		s_axis_tkeep,
	input [C_S_AXIS_TUSER_WIDTH-1:0]			s_axis_tuser,
	input										s_axis_tvalid,
	output										s_axis_tready,
	input										s_axis_tlast,

	// output Master AXI Stream
	output     [C_S_AXIS_DATA_WIDTH-1:0]		m_axis_tdata,
	output     [((C_S_AXIS_DATA_WIDTH/8))-1:0]	m_axis_tkeep,
	output     [C_S_AXIS_TUSER_WIDTH-1:0]		m_axis_tuser,
	output    									m_axis_tvalid,
	input										m_axis_tready,
	output  									m_axis_tlast
	
);

/*=================================================*/
localparam PKT_VEC_WIDTH = (6+4+2)*8*8+256;
// pkt fifo
wire								pkt_fifo_rd_en;
wire								pkt_fifo_nearly_full;
wire								pkt_fifo_empty;
wire [C_S_AXIS_DATA_WIDTH-1:0]		tdata_fifo;
wire [C_S_AXIS_TUSER_WIDTH-1:0]		tuser_fifo;
wire [C_S_AXIS_DATA_WIDTH/8-1:0]	tkeep_fifo;
wire								tlast_fifo;
// phv fifo
wire								phv_fifo_rd_en;
wire								phv_fifo_nearly_full;
wire								phv_fifo_empty;
wire [PKT_VEC_WIDTH-1:0]			phv_fifo_out_w;
wire								phv_valid;
// 
wire								stg0_phv_in_valid;
wire								stg0_phv_in_valid_w;
reg									stg0_phv_in_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg0_phv_in;
// stage-related
wire [PKT_VEC_WIDTH-1:0]			stg0_phv_out;
wire								stg0_phv_out_valid;
wire								stg0_phv_out_valid_w;
reg									stg0_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg1_phv_out;
wire								stg1_phv_out_valid;
wire								stg1_phv_out_valid_w;
reg									stg1_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg2_phv_out;
wire								stg2_phv_out_valid;
wire								stg2_phv_out_valid_w;
reg									stg2_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg3_phv_out;
wire								stg3_phv_out_valid;
wire								stg3_phv_out_valid_w;
reg									stg3_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg4_phv_out;
wire								stg4_phv_out_valid;
wire								stg4_phv_out_valid_w;
reg									stg4_phv_out_valid_r;

// back pressure signals
wire s_axis_tready_p;
wire stg0_ready;
wire stg1_ready;
wire stg2_ready;
wire stg3_ready;
wire stg4_ready;


//NOTE: to filter out packets other than UDP/IP.
wire [C_S_AXIS_DATA_WIDTH-1:0]				s_axis_tdata_f;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		s_axis_tkeep_f;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				s_axis_tuser_f;
wire										s_axis_tvalid_f;
wire										s_axis_tready_f;
wire										s_axis_tlast_f;

//NOTE: filter control packets from data packets.
wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_1;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_1;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_1;
wire										ctrl_s_axis_tvalid_1;
wire										ctrl_s_axis_tlast_1;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_2;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_2;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_2;
wire 										ctrl_s_axis_tvalid_2;
wire 										ctrl_s_axis_tlast_2;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_3;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_3;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_3;
wire 										ctrl_s_axis_tvalid_3;
wire 										ctrl_s_axis_tlast_3;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_4;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_4;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_4;
wire 										ctrl_s_axis_tvalid_4;
wire 										ctrl_s_axis_tlast_4;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_5;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_5;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_5;
wire 										ctrl_s_axis_tvalid_5;
wire 										ctrl_s_axis_tlast_5;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_6;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_6;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_6;
wire 										ctrl_s_axis_tvalid_6;
wire 										ctrl_s_axis_tlast_6;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_7;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_7;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_7;
wire 										ctrl_s_axis_tvalid_7;
wire 										ctrl_s_axis_tlast_7;

assign s_axis_tready_f = !pkt_fifo_nearly_full;

pkt_filter #(
	.C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH)
)pkt_filter
(
	.clk(clk),
	.aresetn(aresetn),

	// input Slave AXI Stream
	.s_axis_tdata(s_axis_tdata),
	.s_axis_tkeep(s_axis_tkeep),
	.s_axis_tuser(s_axis_tuser),
	.s_axis_tvalid(s_axis_tvalid),
	.s_axis_tready(s_axis_tready),
	.s_axis_tlast(s_axis_tlast),

	// output Master AXI Stream
	.m_axis_tdata(s_axis_tdata_f),
	.m_axis_tkeep(s_axis_tkeep_f),
	.m_axis_tuser(s_axis_tuser_f),
	.m_axis_tvalid(s_axis_tvalid_f),
	.m_axis_tready(s_axis_tready_f && s_axis_tready_p),
	.m_axis_tlast(s_axis_tlast_f),

	.ctrl_m_axis_tdata (ctrl_s_axis_tdata_1),
	.ctrl_m_axis_tuser (ctrl_s_axis_tuser_1),
	.ctrl_m_axis_tkeep (ctrl_s_axis_tkeep_1),
	.ctrl_m_axis_tlast (ctrl_s_axis_tlast_1),
	.ctrl_m_axis_tvalid (ctrl_s_axis_tvalid_1)
);

fallthrough_small_fifo #(
	.WIDTH(C_S_AXIS_DATA_WIDTH + C_S_AXIS_TUSER_WIDTH + C_S_AXIS_DATA_WIDTH/8 + 1),
	.MAX_DEPTH_BITS(8)
)
pkt_fifo
(
	.din									({s_axis_tdata_f, s_axis_tuser_f, s_axis_tkeep_f, s_axis_tlast_f}),
	.wr_en									(s_axis_tvalid_f & ~pkt_fifo_nearly_full),
	.rd_en									(pkt_fifo_rd_en),
	.dout									({tdata_fifo, tuser_fifo, tkeep_fifo, tlast_fifo}),
	.full									(),
	.prog_full								(),
	.nearly_full							(pkt_fifo_nearly_full),
	.empty									(pkt_fifo_empty),
	.reset									(~aresetn),
	.clk									(clk)
);

fallthrough_small_fifo #(
	.WIDTH(PKT_VEC_WIDTH),
	.MAX_DEPTH_BITS(8)
)
phv_fifo
(
	.din			(stg4_phv_out),
	.wr_en			(stg4_phv_out_valid_w),
	// .din			(stg1_phv_out),
	// .wr_en			(stg1_phv_out_valid_w),

	.rd_en			(phv_fifo_rd_en),
	.dout			(phv_fifo_out_w),

	.full			(),
	.prog_full		(),
	.nearly_full	(phv_fifo_nearly_full),
	.empty			(phv_fifo_empty),
	.reset			(~aresetn),
	.clk			(clk)
);

parser_top #(
    .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH), //for 100g mac exclusively
	.C_S_AXIS_TUSER_WIDTH(),
	.PKT_HDR_LEN()
)
phv_parser
(
	.axis_clk		(clk),
	.aresetn		(aresetn),
	// input slvae axi stream
	.s_axis_tdata	(s_axis_tdata_f),
	.s_axis_tuser	(s_axis_tuser_f),
	.s_axis_tkeep	(s_axis_tkeep_f),
	.s_axis_tvalid	(s_axis_tvalid_f & s_axis_tready_f),
	.s_axis_tlast	(s_axis_tlast_f),
	.s_axis_tready	(s_axis_tready_p),

	// output
	.parser_valid	(stg0_phv_in_valid),
	.pkt_hdr_vec	(stg0_phv_in),
	// 
	.stg_ready_in	(stg0_ready),

	// control path
    .ctrl_s_axis_tdata(ctrl_s_axis_tdata_1),
	.ctrl_s_axis_tuser(ctrl_s_axis_tuser_1),
	.ctrl_s_axis_tkeep(ctrl_s_axis_tkeep_1),
	.ctrl_s_axis_tlast(ctrl_s_axis_tlast_1),
	.ctrl_s_axis_tvalid(ctrl_s_axis_tvalid_1),

    .ctrl_m_axis_tdata(ctrl_s_axis_tdata_2),
	.ctrl_m_axis_tuser(ctrl_s_axis_tuser_2),
	.ctrl_m_axis_tkeep(ctrl_s_axis_tkeep_2),
	.ctrl_m_axis_tlast(ctrl_s_axis_tlast_2),
	.ctrl_m_axis_tvalid(ctrl_s_axis_tvalid_2)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(0)
)
stage0
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg0_phv_in),
    .phv_in_valid			(stg0_phv_in_valid_w),
	// output
    .phv_out				(stg0_phv_out),
    .phv_out_valid			(stg0_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg0_ready),
	.stage_ready_in			(stg1_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_2),
	.c_s_axis_tuser(ctrl_s_axis_tuser_2),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_2),
	.c_s_axis_tlast(ctrl_s_axis_tlast_2),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_2),

    .c_m_axis_tdata(ctrl_s_axis_tdata_3),
	.c_m_axis_tuser(ctrl_s_axis_tuser_3),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_3),
	.c_m_axis_tlast(ctrl_s_axis_tlast_3),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_3)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(1)
)
stage1
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg0_phv_out),
    .phv_in_valid			(stg0_phv_out_valid_w),
	// output
    .phv_out				(stg1_phv_out),
    .phv_out_valid			(stg1_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg1_ready),
	.stage_ready_in			(stg2_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_3),
	.c_s_axis_tuser(ctrl_s_axis_tuser_3),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_3),
	.c_s_axis_tlast(ctrl_s_axis_tlast_3),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_3),

    .c_m_axis_tdata(ctrl_s_axis_tdata_4),
	.c_m_axis_tuser(ctrl_s_axis_tuser_4),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_4),
	.c_m_axis_tlast(ctrl_s_axis_tlast_4),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_4)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(2)
)
stage2
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg1_phv_out),
    .phv_in_valid			(stg1_phv_out_valid_w),
	// output
    .phv_out				(stg2_phv_out),
    .phv_out_valid			(stg2_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg2_ready),
	.stage_ready_in			(stg3_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_4),
	.c_s_axis_tuser(ctrl_s_axis_tuser_4),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_4),
	.c_s_axis_tlast(ctrl_s_axis_tlast_4),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_4),

    .c_m_axis_tdata(ctrl_s_axis_tdata_5),
	.c_m_axis_tuser(ctrl_s_axis_tuser_5),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_5),
	.c_m_axis_tlast(ctrl_s_axis_tlast_5),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_5)
);

stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(3)
)
stage3
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg2_phv_out),
    .phv_in_valid			(stg2_phv_out_valid_w),
	// output
    .phv_out				(stg3_phv_out),
    .phv_out_valid			(stg3_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg3_ready),
	.stage_ready_in			(stg4_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_5),
	.c_s_axis_tuser(ctrl_s_axis_tuser_5),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_5),
	.c_s_axis_tlast(ctrl_s_axis_tlast_5),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_5),

    .c_m_axis_tdata(ctrl_s_axis_tdata_6),
	.c_m_axis_tuser(ctrl_s_axis_tuser_6),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_6),
	.c_m_axis_tlast(ctrl_s_axis_tlast_6),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_6)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(4)
)
stage4
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg3_phv_out),
    .phv_in_valid			(stg3_phv_out_valid_w),
	// output
    .phv_out				(stg4_phv_out),
    .phv_out_valid			(stg4_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg4_ready),
	.stage_ready_in			(!phv_fifo_nearly_full),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_6),
	.c_s_axis_tuser(ctrl_s_axis_tuser_6),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_6),
	.c_s_axis_tlast(ctrl_s_axis_tlast_6),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_6),

    .c_m_axis_tdata(ctrl_s_axis_tdata_7),
	.c_m_axis_tuser(ctrl_s_axis_tuser_7),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_7),
	.c_m_axis_tlast(ctrl_s_axis_tlast_7),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_7)
);


deparser #(
	.C_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.C_AXIS_TUSER_WIDTH(),
	.C_PKT_VEC_WIDTH()
)
phv_deparser (
	.clk					(clk),
	.aresetn				(aresetn),

	.pkt_fifo_tdata			(tdata_fifo),
	.pkt_fifo_tkeep			(tkeep_fifo),
	.pkt_fifo_tuser			(tuser_fifo),
	.pkt_fifo_tlast			(tlast_fifo),
	.pkt_fifo_empty			(pkt_fifo_empty),
	// output from STAGE
	.pkt_fifo_rd_en			(pkt_fifo_rd_en),

	.phv_fifo_out			(phv_fifo_out_w),
	.phv_fifo_empty			(phv_fifo_empty),
	.phv_fifo_rd_en			(phv_fifo_rd_en),
	// output
	.depar_out_tdata		(m_axis_tdata),
	.depar_out_tkeep		(m_axis_tkeep),
	.depar_out_tuser		(m_axis_tuser),
	.depar_out_tvalid		(m_axis_tvalid),
	.depar_out_tlast		(m_axis_tlast),
	// input
	.depar_out_tready		(m_axis_tready),

	// control path
	.ctrl_s_axis_tdata(ctrl_s_axis_tdata_7),
	.ctrl_s_axis_tuser(ctrl_s_axis_tuser_7),
	.ctrl_s_axis_tkeep(ctrl_s_axis_tkeep_7),
	.ctrl_s_axis_tlast(ctrl_s_axis_tlast_7),
	.ctrl_s_axis_tvalid(ctrl_s_axis_tvalid_7)
);


always @(posedge clk) begin
	if (~aresetn) begin
		stg0_phv_in_valid_r <= 0;
		stg0_phv_out_valid_r <= 0;
		stg1_phv_out_valid_r <= 0;
		stg2_phv_out_valid_r <= 0;
		stg3_phv_out_valid_r <= 0;
		stg4_phv_out_valid_r <= 0;
	end
	else begin
		stg0_phv_in_valid_r <= stg0_phv_in_valid;
		stg0_phv_out_valid_r <= stg0_phv_out_valid;
		stg1_phv_out_valid_r <= stg1_phv_out_valid;
		stg2_phv_out_valid_r <= stg2_phv_out_valid;
		stg3_phv_out_valid_r <= stg3_phv_out_valid;
		stg4_phv_out_valid_r <= stg4_phv_out_valid;
	end
end

assign stg0_phv_in_valid_w = stg0_phv_in_valid ;//& ~stg0_phv_in_valid_r;
assign stg0_phv_out_valid_w = stg0_phv_out_valid ;//& ~stg0_phv_out_valid_r;
assign stg1_phv_out_valid_w = stg1_phv_out_valid ;//& ~stg1_phv_out_valid_r;
assign stg2_phv_out_valid_w = stg2_phv_out_valid ;//& ~stg2_phv_out_valid_r;
assign stg3_phv_out_valid_w = stg3_phv_out_valid ;//& ~stg3_phv_out_valid_r;
assign stg4_phv_out_valid_w = stg4_phv_out_valid ;//& ~stg4_phv_out_valid_r;


endmodule
