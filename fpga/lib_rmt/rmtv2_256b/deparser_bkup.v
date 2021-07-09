`timescale 1ns / 1ps

`define SUB_DEPARSE_1P(idx) \
	if(parse_action[idx][0]) begin \
		case(sub_depar_val_out_type_r[idx]) \
			2'b01: pkts_tdata_stored_r_1p[parse_action_ind_10b[idx]<<3 +: 16] = sub_depar_val_out_swapped[idx][32+:16]; \
			2'b10: pkts_tdata_stored_r_1p[parse_action_ind_10b[idx]<<3 +: 32] = sub_depar_val_out_swapped[idx][16+:32]; \
			2'b11: pkts_tdata_stored_r_1p[parse_action_ind_10b[idx]<<3 +: 48] = sub_depar_val_out_swapped[idx][0+:48]; \
		endcase \
	end \

`define SUB_DEPARSE_2P(idx) \
	if(parse_action[idx][0]) begin \
		case(sub_depar_val_out_type_r[idx]) \
			2'b01: pkts_tdata_stored_r_2p[parse_action_ind_10b[idx]<<3 +: 16] = sub_depar_val_out_swapped[idx][32+:16]; \
			2'b10: pkts_tdata_stored_r_2p[parse_action_ind_10b[idx]<<3 +: 32] = sub_depar_val_out_swapped[idx][16+:32]; \
			2'b11: pkts_tdata_stored_r_2p[parse_action_ind_10b[idx]<<3 +: 48] = sub_depar_val_out_swapped[idx][0+:48]; \
		endcase \
	end \

`define SWAP_BYTE_ORDER(idx) \
	assign sub_depar_val_out_swapped[idx] = {	sub_depar_val_out_r[idx][0+:8], \
												sub_depar_val_out_r[idx][8+:8], \
												sub_depar_val_out_r[idx][16+:8], \
												sub_depar_val_out_r[idx][24+:8], \
												sub_depar_val_out_r[idx][32+:8], \
												sub_depar_val_out_r[idx][40+:8]}; \

module deparser #(
	//in corundum with 100g ports, data width is 512b
	parameter	C_AXIS_DATA_WIDTH = 256,
	parameter	C_AXIS_TUSER_WIDTH = 128,
	parameter	C_PKT_VEC_WIDTH = (6+4+2)*8*8+256,
	parameter	DEPARSER_MOD_ID = 3'b101
)
(
	input									clk,
	input									aresetn,

	input [C_AXIS_DATA_WIDTH-1:0]			pkt_fifo_tdata,
	input [C_AXIS_DATA_WIDTH/8-1:0]			pkt_fifo_tkeep,
	input [C_AXIS_TUSER_WIDTH-1:0]			pkt_fifo_tuser,
	// input									pkt_fifo_tvalid,
	input									pkt_fifo_tlast,
	input									pkt_fifo_empty,
	//TODO might want to change it back
	output reg							    pkt_fifo_rd_en,

	input [C_PKT_VEC_WIDTH-1:0]				phv_fifo_out,
	input									phv_fifo_empty,
	output reg								phv_fifo_rd_en,

	output reg [C_AXIS_DATA_WIDTH-1:0]		depar_out_tdata,
	output reg [C_AXIS_DATA_WIDTH/8-1:0]	depar_out_tkeep,
	output reg [C_AXIS_TUSER_WIDTH-1:0]		depar_out_tuser,
	output reg								depar_out_tvalid,
	output reg								depar_out_tlast,
	input									depar_out_tready,

	// control path
	input [C_AXIS_DATA_WIDTH-1:0]			ctrl_s_axis_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]			ctrl_s_axis_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]			ctrl_s_axis_tkeep,
	input									ctrl_s_axis_tvalid,
	input									ctrl_s_axis_tlast
);


//=====================================deparser part
localparam WAIT_TILL_PARSE_DONE = 0; 
localparam WAIT_PKT_1 = 1;
localparam WAIT_PKT_2 = 2;
localparam WAIT_PKT_3 = 3;
localparam BEGIN_SUB_DEPARSER = 4;
localparam EMPTY_FINISH = 5;
localparam FINISH_SUB_DEPARSER_0 = 6;
localparam FINISH_SUB_DEPARSER_1 = 7;
localparam FINISH_SUB_DEPARSER_2 = 8;

localparam FLUSH_PKT_0 = 44;
localparam FLUSH_PKT_1 = 45;
localparam FLUSH_PKT_2 = 46;
localparam FLUSH_PKT_3 = 47;
localparam FLUSH_PKT = 48;
localparam DROP_PKT = 49;

reg [2*C_AXIS_DATA_WIDTH-1:0]		pkts_tdata_stored_r_1p, pkts_tdata_stored_r_2p;
reg [2*C_AXIS_DATA_WIDTH-1:0]		pkts_tdata_stored_1p, pkts_tdata_stored_2p;
reg [2*C_AXIS_TUSER_WIDTH-1:0]		pkts_tuser_stored_r_1p, pkts_tuser_stored_r_2p;
reg [2*C_AXIS_TUSER_WIDTH-1:0]		pkts_tuser_stored_1p, pkts_tuser_stored_2p;
reg [2*(C_AXIS_DATA_WIDTH/8)-1:0]	pkts_tkeep_stored_r_1p, pkts_tkeep_stored_r_2p;
reg [2*(C_AXIS_DATA_WIDTH/8)-1:0]	pkts_tkeep_stored_1p, pkts_tkeep_stored_2p;
reg [2:0]							pkts_tlast_stored_r_1p, pkts_tlast_stored_r_2p;
reg [2:0]							pkts_tlast_stored_1p, pkts_tlast_stored_2p;

reg [7:0] state, state_next;

wire [11:0] vlan_id; // vlan id
assign vlan_id = phv_fifo_out[129+:12];
wire [159:0] bram_out;
wire [6:0] parse_action_ind [0:9];
wire [9:0] parse_action_ind_10b [0:9];
wire discard_signal;

assign discard_signal = phv_fifo_out[128];

wire [15:0] parse_action [0:9];		// we have 10 parse action

assign parse_action[9] = bram_out[0+:16];
assign parse_action[8] = bram_out[16+:16];
assign parse_action[7] = bram_out[32+:16];
assign parse_action[6] = bram_out[48+:16];
assign parse_action[5] = bram_out[64+:16];
assign parse_action[4] = bram_out[80+:16];
assign parse_action[3] = bram_out[96+:16];
assign parse_action[2] = bram_out[112+:16];
assign parse_action[1] = bram_out[128+:16];
assign parse_action[0] = bram_out[144+:16];

assign parse_action_ind[0] = parse_action[0][12:6];
assign parse_action_ind[1] = parse_action[1][12:6];
assign parse_action_ind[2] = parse_action[2][12:6];
assign parse_action_ind[3] = parse_action[3][12:6];
assign parse_action_ind[4] = parse_action[4][12:6];
assign parse_action_ind[5] = parse_action[5][12:6];
assign parse_action_ind[6] = parse_action[6][12:6];
assign parse_action_ind[7] = parse_action[7][12:6];
assign parse_action_ind[8] = parse_action[8][12:6];
assign parse_action_ind[9] = parse_action[9][12:6];

assign parse_action_ind_10b[0] = parse_action_ind[0];
assign parse_action_ind_10b[1] = parse_action_ind[1];
assign parse_action_ind_10b[2] = parse_action_ind[2];
assign parse_action_ind_10b[3] = parse_action_ind[3];
assign parse_action_ind_10b[4] = parse_action_ind[4];
assign parse_action_ind_10b[5] = parse_action_ind[5];
assign parse_action_ind_10b[6] = parse_action_ind[6];
assign parse_action_ind_10b[7] = parse_action_ind[7];
assign parse_action_ind_10b[8] = parse_action_ind[8];
assign parse_action_ind_10b[9] = parse_action_ind[9];


reg	[9:0]					sub_depar_act_valid;

wire [47:0]					sub_depar_val_out [0:9];
reg [47:0]					sub_depar_val_out_r [0:9];
wire [47:0]					sub_depar_val_out_swapped [0:9];
wire [1:0]					sub_depar_val_out_type [0:9];
reg [1:0]					sub_depar_val_out_type_r [0:9];
wire [9:0]					sub_depar_val_out_valid;


`SWAP_BYTE_ORDER(0)
`SWAP_BYTE_ORDER(1)
`SWAP_BYTE_ORDER(2)
`SWAP_BYTE_ORDER(3)
`SWAP_BYTE_ORDER(4)
`SWAP_BYTE_ORDER(5)
`SWAP_BYTE_ORDER(6)
`SWAP_BYTE_ORDER(7)
`SWAP_BYTE_ORDER(8)
`SWAP_BYTE_ORDER(9)

always @(*) begin

	// remember to set depar_out_tdata, tuser, tkeep, tlast, tvalid
	depar_out_tdata = pkt_fifo_tdata;
	depar_out_tuser = pkt_fifo_tuser;
	depar_out_tkeep = pkt_fifo_tkeep;
	depar_out_tlast = pkt_fifo_tlast;
	depar_out_tvalid = 0;
	// fifo rd signals
	pkt_fifo_rd_en = 0;
	phv_fifo_rd_en = 0;

	pkts_tdata_stored_r_1p = pkts_tdata_stored_1p;
	pkts_tuser_stored_r_1p = pkts_tuser_stored_1p;
	pkts_tkeep_stored_r_1p = pkts_tkeep_stored_1p;
	pkts_tlast_stored_r_1p = pkts_tlast_stored_1p;
	pkts_tdata_stored_r_2p = pkts_tdata_stored_2p;
	pkts_tuser_stored_r_2p = pkts_tuser_stored_2p;
	pkts_tkeep_stored_r_2p = pkts_tkeep_stored_2p;
	pkts_tlast_stored_r_2p = pkts_tlast_stored_2p;

	sub_depar_act_valid = 10'b0;

	state_next = state;
	//
	case (state)
		WAIT_TILL_PARSE_DONE: begin // later will be modifed to PROCESSING done
			if (!pkt_fifo_empty && !phv_fifo_empty) begin // both pkt and phv fifo are not empty
				pkts_tdata_stored_r_1p[0+:C_AXIS_DATA_WIDTH] = pkt_fifo_tdata;
				pkts_tuser_stored_r_1p[0+:C_AXIS_TUSER_WIDTH] = phv_fifo_out[0+:128]; // first 128b of PHV
				pkts_tkeep_stored_r_1p[0+:(C_AXIS_DATA_WIDTH/8)] = pkt_fifo_tkeep;
				pkts_tlast_stored_r_1p[0] = pkt_fifo_tlast;
				
				pkt_fifo_rd_en = 1;


				if (discard_signal == 1) begin
					phv_fifo_rd_en = 1;
					state_next = DROP_PKT;
				end
				else begin
					state_next = WAIT_PKT_1;
				end
			end
		end
		WAIT_PKT_1: begin
			pkts_tdata_stored_r_1p[(C_AXIS_DATA_WIDTH*1)+:C_AXIS_DATA_WIDTH] = pkt_fifo_tdata;
			pkts_tuser_stored_r_1p[(C_AXIS_TUSER_WIDTH*1)+:C_AXIS_TUSER_WIDTH] = pkt_fifo_tuser;
			pkts_tkeep_stored_r_1p[(C_AXIS_DATA_WIDTH/8*1)+:(C_AXIS_DATA_WIDTH/8)] = pkt_fifo_tkeep;
			pkts_tlast_stored_r_1p[1] = pkt_fifo_tlast;

			pkt_fifo_rd_en = 1;

			if (pkt_fifo_tlast) begin
				state_next = BEGIN_SUB_DEPARSER;
			end
			else begin
				state_next = WAIT_PKT_2;
			end

		end
		WAIT_PKT_2: begin
			pkts_tdata_stored_r_2p[0+:C_AXIS_DATA_WIDTH] = pkt_fifo_tdata;
			pkts_tuser_stored_r_2p[0+:C_AXIS_TUSER_WIDTH] = pkt_fifo_tuser;
			pkts_tkeep_stored_r_2p[0+:(C_AXIS_DATA_WIDTH/8)] = pkt_fifo_tkeep;
			pkts_tlast_stored_r_2p[0] = pkt_fifo_tlast;

			pkt_fifo_rd_en = 1;
			if (pkt_fifo_tlast) begin
				state_next = BEGIN_SUB_DEPARSER;
			end
			else begin
				state_next = WAIT_PKT_3;
			end
		end
		WAIT_PKT_3: begin
			pkts_tdata_stored_r_2p[(C_AXIS_DATA_WIDTH*1)+:C_AXIS_DATA_WIDTH] = pkt_fifo_tdata;
			pkts_tuser_stored_r_2p[(C_AXIS_TUSER_WIDTH*1)+:C_AXIS_TUSER_WIDTH] = pkt_fifo_tuser;
			pkts_tkeep_stored_r_2p[(C_AXIS_DATA_WIDTH/8*1)+:(C_AXIS_DATA_WIDTH/8)] = pkt_fifo_tkeep;
			pkts_tlast_stored_r_2p[1] = pkt_fifo_tlast;

			pkt_fifo_rd_en = 1;
			state_next = BEGIN_SUB_DEPARSER;
		end

		BEGIN_SUB_DEPARSER: begin
			sub_depar_act_valid = 10'b1111111111;

			state_next = EMPTY_FINISH;
		end

		EMPTY_FINISH: begin
			state_next = FINISH_SUB_DEPARSER_0;
		end

		FINISH_SUB_DEPARSER_0: begin
			`SUB_DEPARSE_1P(0)
			`SUB_DEPARSE_1P(1)
			`SUB_DEPARSE_2P(5)

			state_next = FINISH_SUB_DEPARSER_1;
		end

		FINISH_SUB_DEPARSER_1: begin
			`SUB_DEPARSE_1P(2)
			`SUB_DEPARSE_2P(6)
			`SUB_DEPARSE_2P(7)

			state_next = FINISH_SUB_DEPARSER_2;
		end

		FINISH_SUB_DEPARSER_2: begin
			`SUB_DEPARSE_1P(3)
			`SUB_DEPARSE_1P(4)
			`SUB_DEPARSE_2P(8)
			`SUB_DEPARSE_2P(9)

			state_next = FLUSH_PKT_0;
		end

		FLUSH_PKT_0: begin
			phv_fifo_rd_en = 1;
			depar_out_tdata = pkts_tdata_stored_1p[(C_AXIS_DATA_WIDTH*0)+:C_AXIS_DATA_WIDTH];
			depar_out_tuser = pkts_tuser_stored_1p[(C_AXIS_TUSER_WIDTH*0)+:C_AXIS_TUSER_WIDTH];
			depar_out_tkeep = pkts_tkeep_stored_1p[(C_AXIS_DATA_WIDTH/8*0)+:(C_AXIS_DATA_WIDTH/8)];
			depar_out_tlast = pkts_tlast_stored_1p[0];
			depar_out_tvalid = 1;


			if (depar_out_tready) begin
				if (pkts_tlast_stored_1p[0]) begin
					state_next = WAIT_TILL_PARSE_DONE;
				end
				else begin
					state_next = FLUSH_PKT_1;
				end
			end
		end

		FLUSH_PKT_1: begin
			depar_out_tdata = pkts_tdata_stored_1p[(C_AXIS_DATA_WIDTH*1)+:C_AXIS_DATA_WIDTH];
			depar_out_tuser = pkts_tuser_stored_1p[(C_AXIS_TUSER_WIDTH*1)+:C_AXIS_TUSER_WIDTH];
			depar_out_tkeep = pkts_tkeep_stored_1p[(C_AXIS_DATA_WIDTH/8*1)+:(C_AXIS_DATA_WIDTH/8)];
			depar_out_tlast = pkts_tlast_stored_1p[1];
			depar_out_tvalid = 1;

			if (depar_out_tready) begin
				if (pkts_tlast_stored_1p[1]) begin
					state_next = WAIT_TILL_PARSE_DONE;
				end
				else begin
					state_next = FLUSH_PKT_2;
				end
			end
		end
		FLUSH_PKT_2: begin
			depar_out_tdata = pkts_tdata_stored_2p[(C_AXIS_DATA_WIDTH*0)+:C_AXIS_DATA_WIDTH];
			depar_out_tuser = pkts_tuser_stored_2p[(C_AXIS_TUSER_WIDTH*0)+:C_AXIS_TUSER_WIDTH];
			depar_out_tkeep = pkts_tkeep_stored_2p[(C_AXIS_DATA_WIDTH/8*0)+:(C_AXIS_DATA_WIDTH/8)];
			depar_out_tlast = pkts_tlast_stored_2p[0];
			depar_out_tvalid = 1;

			if (depar_out_tready) begin
				if (pkts_tlast_stored_2p[0]) begin
					state_next = WAIT_TILL_PARSE_DONE;
				end
				else begin
					state_next = FLUSH_PKT_3;
				end
			end
		end
		FLUSH_PKT_3: begin
			depar_out_tdata = pkts_tdata_stored_2p[(C_AXIS_DATA_WIDTH*1)+:C_AXIS_DATA_WIDTH];
			depar_out_tuser = pkts_tuser_stored_2p[(C_AXIS_TUSER_WIDTH*1)+:C_AXIS_TUSER_WIDTH];
			depar_out_tkeep = pkts_tkeep_stored_2p[(C_AXIS_DATA_WIDTH/8*1)+:(C_AXIS_DATA_WIDTH/8)];
			depar_out_tlast = pkts_tlast_stored_2p[1];
			depar_out_tvalid = 1;

			if (depar_out_tready) begin
				if (pkts_tlast_stored_2p[1]) begin
					state_next = WAIT_TILL_PARSE_DONE;
				end
				else begin
					state_next = FLUSH_PKT;
				end
			end
		end
		FLUSH_PKT: begin
			if (!pkt_fifo_empty) begin
				depar_out_tdata = pkt_fifo_tdata;
				depar_out_tuser =  pkt_fifo_tuser;
				depar_out_tkeep =  pkt_fifo_tkeep;
				depar_out_tlast =  pkt_fifo_tlast;
				depar_out_tvalid = 1;
				if(depar_out_tready) begin
					pkt_fifo_rd_en = 1;
					if (pkt_fifo_tlast) begin
						state_next = WAIT_TILL_PARSE_DONE;
					end
					else begin
						state_next = FLUSH_PKT;
					end
				end
			end
		end
		DROP_PKT: begin
			pkt_fifo_rd_en = 1;
			if (pkt_fifo_tlast) begin
				state_next = WAIT_TILL_PARSE_DONE;
			end
		end
	endcase
end

always @(posedge clk) begin
	if (~aresetn) begin
		state <= WAIT_TILL_PARSE_DONE;

		pkts_tdata_stored_1p <= 0;
		pkts_tuser_stored_1p <= 0;
		pkts_tkeep_stored_1p <= 0;
		pkts_tlast_stored_1p <= 0;
		pkts_tdata_stored_2p <= 0;
		pkts_tuser_stored_2p <= 0;
		pkts_tkeep_stored_2p <= 0;
		pkts_tlast_stored_2p <= 0;

	end
	else begin
		state <= state_next;

		pkts_tdata_stored_1p <= pkts_tdata_stored_r_1p;
		pkts_tuser_stored_1p <= pkts_tuser_stored_r_1p;
		pkts_tkeep_stored_1p <= pkts_tkeep_stored_r_1p;
		pkts_tlast_stored_1p <= pkts_tlast_stored_r_1p;

		pkts_tdata_stored_2p <= pkts_tdata_stored_r_2p;
		pkts_tuser_stored_2p <= pkts_tuser_stored_r_2p;
		pkts_tkeep_stored_2p <= pkts_tkeep_stored_r_2p;
		pkts_tlast_stored_2p <= pkts_tlast_stored_r_2p;
	end
end

always @(posedge clk) begin
	if (~aresetn) begin
		sub_depar_val_out_r[0] <= 0;
		sub_depar_val_out_r[1] <= 0;
		sub_depar_val_out_r[2] <= 0;
		sub_depar_val_out_r[3] <= 0;
		sub_depar_val_out_r[4] <= 0;
		sub_depar_val_out_r[5] <= 0;
		sub_depar_val_out_r[6] <= 0;
		sub_depar_val_out_r[7] <= 0;
		sub_depar_val_out_r[8] <= 0;
		sub_depar_val_out_r[9] <= 0;

		sub_depar_val_out_type_r[0] <= 0;
		sub_depar_val_out_type_r[1] <= 0;
		sub_depar_val_out_type_r[2] <= 0;
		sub_depar_val_out_type_r[3] <= 0;
		sub_depar_val_out_type_r[4] <= 0;
		sub_depar_val_out_type_r[5] <= 0;
		sub_depar_val_out_type_r[6] <= 0;
		sub_depar_val_out_type_r[7] <= 0;
		sub_depar_val_out_type_r[8] <= 0;
		sub_depar_val_out_type_r[9] <= 0;
	end
	else begin
		if (sub_depar_val_out_valid[0]) begin
			sub_depar_val_out_r[0] <= sub_depar_val_out[0];
			sub_depar_val_out_r[1] <= sub_depar_val_out[1];
			sub_depar_val_out_r[2] <= sub_depar_val_out[2];
			sub_depar_val_out_r[3] <= sub_depar_val_out[3];
			sub_depar_val_out_r[4] <= sub_depar_val_out[4];
			sub_depar_val_out_r[5] <= sub_depar_val_out[5];
			sub_depar_val_out_r[6] <= sub_depar_val_out[6];
			sub_depar_val_out_r[7] <= sub_depar_val_out[7];
			sub_depar_val_out_r[8] <= sub_depar_val_out[8];
			sub_depar_val_out_r[9] <= sub_depar_val_out[9];

			sub_depar_val_out_type_r[0] <= sub_depar_val_out_type[0];
			sub_depar_val_out_type_r[1] <= sub_depar_val_out_type[1];
			sub_depar_val_out_type_r[2] <= sub_depar_val_out_type[2];
			sub_depar_val_out_type_r[3] <= sub_depar_val_out_type[3];
			sub_depar_val_out_type_r[4] <= sub_depar_val_out_type[4];
			sub_depar_val_out_type_r[5] <= sub_depar_val_out_type[5];
			sub_depar_val_out_type_r[6] <= sub_depar_val_out_type[6];
			sub_depar_val_out_type_r[7] <= sub_depar_val_out_type[7];
			sub_depar_val_out_type_r[8] <= sub_depar_val_out_type[8];
			sub_depar_val_out_type_r[9] <= sub_depar_val_out_type[9];
		end
	end
end

generate
	genvar index;
	for (index=0; index<10; index=index+1) 
	begin: sub_op
		sub_deparser #(
			.C_PKT_VEC_WIDTH(),
			.C_PARSE_ACT_LEN()
		)
		sub_deparser (
			.clk				(clk),
			.aresetn			(aresetn),
			.parse_act_valid	(sub_depar_act_valid[index]),
			.parse_act			(parse_action[index][5:0]),
			.phv_in				(phv_fifo_out),
			.val_out_valid		(sub_depar_val_out_valid[index]),
			.val_out			(sub_depar_val_out[index]),
			.val_out_type		(sub_depar_val_out_type[index])
		);
	end
endgenerate

/*================Control Path====================*/
wire [C_AXIS_DATA_WIDTH-1:0] ctrl_s_axis_tdata_swapped;

assign ctrl_s_axis_tdata_swapped = {	ctrl_s_axis_tdata[0+:8],
										ctrl_s_axis_tdata[8+:8],
										ctrl_s_axis_tdata[16+:8],
										ctrl_s_axis_tdata[24+:8],
										ctrl_s_axis_tdata[32+:8],
										ctrl_s_axis_tdata[40+:8],
										ctrl_s_axis_tdata[48+:8],
										ctrl_s_axis_tdata[56+:8],
										ctrl_s_axis_tdata[64+:8],
										ctrl_s_axis_tdata[72+:8],
										ctrl_s_axis_tdata[80+:8],
										ctrl_s_axis_tdata[88+:8],
										ctrl_s_axis_tdata[96+:8],
										ctrl_s_axis_tdata[104+:8],
										ctrl_s_axis_tdata[112+:8],
										ctrl_s_axis_tdata[120+:8],
										ctrl_s_axis_tdata[128+:8],
										ctrl_s_axis_tdata[136+:8],
										ctrl_s_axis_tdata[144+:8],
										ctrl_s_axis_tdata[152+:8],
										ctrl_s_axis_tdata[160+:8],
										ctrl_s_axis_tdata[168+:8],
										ctrl_s_axis_tdata[176+:8],
										ctrl_s_axis_tdata[184+:8],
										ctrl_s_axis_tdata[192+:8],
										ctrl_s_axis_tdata[200+:8],
										ctrl_s_axis_tdata[208+:8],
										ctrl_s_axis_tdata[216+:8],
										ctrl_s_axis_tdata[224+:8],
										ctrl_s_axis_tdata[232+:8],
										ctrl_s_axis_tdata[240+:8],
										ctrl_s_axis_tdata[248+:8]};


reg	[7:0]						ctrl_wr_ram_addr, ctrl_wr_ram_addr_next;
reg	[159:0]						ctrl_wr_ram_data, ctrl_wr_ram_data_next;
reg								ctrl_wr_ram_en, ctrl_wr_ram_en_next;
wire [7:0]						ctrl_mod_id;

assign ctrl_mod_id = ctrl_s_axis_tdata[112+:8];

localparam	WAIT_FIRST_PKT = 0,
			WAIT_SECOND_PKT = 1,
			WAIT_THIRD_PKT = 2,
			WRITE_RAM = 3,
			FLUSH_REST_C = 4;

reg [2:0] ctrl_state, ctrl_state_next;

always @(*) begin
	ctrl_state_next = ctrl_state;
	ctrl_wr_ram_addr_next = ctrl_wr_ram_addr;
	ctrl_wr_ram_data_next = ctrl_wr_ram_data;
	ctrl_wr_ram_en_next = 0;

	case (ctrl_state)
		WAIT_FIRST_PKT: begin
			// 1st ctrl packet
			if (ctrl_s_axis_tvalid && ~ctrl_s_axis_tlast) begin
				ctrl_state_next = WAIT_SECOND_PKT;
			end
		end
		WAIT_SECOND_PKT: begin
			// 2nd ctrl packet, we can check module ID
			if (ctrl_s_axis_tvalid) begin
				if (ctrl_mod_id[2:0]==DEPARSER_MOD_ID) begin
					ctrl_state_next = WAIT_THIRD_PKT;

					ctrl_wr_ram_addr_next = ctrl_s_axis_tdata[128+:8];
				end
				else begin
					ctrl_state_next = FLUSH_REST_C;
				end
			end
		end
		WAIT_THIRD_PKT: begin // first half of ctrl_wr_ram_data
			if (ctrl_s_axis_tvalid) begin
				ctrl_state_next = WRITE_RAM;
				ctrl_wr_ram_data_next = ctrl_s_axis_tdata_swapped[255-:160];
			end
		end
		WRITE_RAM: begin // second half of ctrl_wr_ram_data
			if (ctrl_s_axis_tvalid) begin
				if (ctrl_s_axis_tlast)
					ctrl_state_next = WAIT_FIRST_PKT;
				else
					ctrl_state_next = FLUSH_REST_C;
				ctrl_wr_ram_en_next = 1;
			end
		end
		FLUSH_REST_C: begin
			if (ctrl_s_axis_tvalid && ctrl_s_axis_tlast)
				ctrl_state_next = WAIT_FIRST_PKT;
		end
	endcase
end

always @(posedge clk) begin
	if (~aresetn) begin
		ctrl_state <= WAIT_FIRST_PKT;

		ctrl_wr_ram_addr <= 0;
		ctrl_wr_ram_data <= 0;
		ctrl_wr_ram_en <= 0;
	end
	else begin
		ctrl_state <= ctrl_state_next;

		ctrl_wr_ram_addr <= ctrl_wr_ram_addr_next;
		ctrl_wr_ram_data <= ctrl_wr_ram_data_next;
		ctrl_wr_ram_en <= ctrl_wr_ram_en_next;
	end
end

// =============================================================== //
// parse_act_ram_ip #(
// 	.C_INIT_FILE_NAME	("./alu_2.mif"),
// 	.C_LOAD_INIT_FILE	(1)
// )
parse_act_ram_ip
parse_act_ram
(
	// write port
	.clka		(clk),
	.addra		(ctrl_wr_ram_addr[4:0]),
	.dina		(ctrl_wr_ram_data),
	.ena		(1'b1),
	.wea		(ctrl_wr_ram_en),

	//
	.clkb		(clk),
	.addrb		(vlan_id[8:4]),
	.doutb		(bram_out),
	.enb		(1'b1) // always set to 1
);

endmodule
