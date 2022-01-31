`timescale 1ns / 1ps

module parser #(
    //for 100g MAC, the AXIS width is 512b
	parameter C_S_AXIS_DATA_WIDTH = 512,
	parameter C_S_AXIS_TUSER_WIDTH = 128,
	//parameter PKT_HDR_LEN = (6+4+2)*8*8+20*5+256, // check with the doc
	parameter PKT_HDR_LEN = (6+4+2)*8*8+256, // check with the doc
    parameter PARSE_ACT_RAM_WIDTH = 167,
    parameter PARSER_ID = 0
    )(
    input									axis_clk,
	input									aresetn,

	// input slave axi stream
	input [C_S_AXIS_DATA_WIDTH-1:0]			s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		s_axis_tkeep,
	input									s_axis_tvalid,
	input									s_axis_tlast,
    output  reg                             s_axis_tready,

	// output
	output   								phv_valid_out,
	output      [PKT_HDR_LEN-1:0]			phv_out,
    input                                   m_axis_tready,

    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]			c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		c_s_axis_tkeep,
	input									c_s_axis_tvalid,
	input									c_s_axis_tlast,

    output reg [C_S_AXIS_DATA_WIDTH-1:0]	c_m_axis_tdata,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]	c_m_axis_tuser,
	output reg [C_S_AXIS_DATA_WIDTH/8-1:0]	c_m_axis_tkeep,
	output reg								c_m_axis_tvalid,
	output reg								c_m_axis_tlast
);

// intermediate variables declared here

//phv_out signals before putting out.
reg phv_valid_out_reg;

assign phv_valid_out = phv_valid_out_reg;

wire [11:0] vlan_id_w;
reg  [11:0] vlan_id;

//Parse Action RAM
wire [159:0] bram_out;

wire [15:0]  parse_action [0:9];
//reg  [19:0]  condi_action [0:4];
//reg  [19:0]  condi_action_d[0:4];

reg [47:0] val_6B [0:7];
reg [31:0] val_4B [0:7];
reg [15:0] val_2B [0:7];

wire [47:0] val_6B_BE [0:7];
wire [31:0] val_4B_BE [0:7];
wire [15:0] val_2B_BE [0:7];

//BE LE switching
assign val_2B_BE[0] = {val_2B[0][7:0], val_2B[0][15:8]};
assign val_2B_BE[1] = {val_2B[1][7:0], val_2B[1][15:8]};
assign val_2B_BE[2] = {val_2B[2][7:0], val_2B[2][15:8]};
assign val_2B_BE[3] = {val_2B[3][7:0], val_2B[3][15:8]};
assign val_2B_BE[4] = {val_2B[4][7:0], val_2B[4][15:8]};
assign val_2B_BE[5] = {val_2B[5][7:0], val_2B[5][15:8]};
assign val_2B_BE[6] = {val_2B[6][7:0], val_2B[6][15:8]};
assign val_2B_BE[7] = {val_2B[7][7:0], val_2B[7][15:8]};

assign val_4B_BE[0] = {val_4B[0][7:0], val_4B[0][15:8], val_4B[0][23:16], val_4B[0][31:24]};
assign val_4B_BE[1] = {val_4B[1][7:0], val_4B[1][15:8], val_4B[1][23:16], val_4B[1][31:24]};
assign val_4B_BE[2] = {val_4B[2][7:0], val_4B[2][15:8], val_4B[2][23:16], val_4B[2][31:24]};
assign val_4B_BE[3] = {val_4B[3][7:0], val_4B[3][15:8], val_4B[3][23:16], val_4B[3][31:24]};
assign val_4B_BE[4] = {val_4B[4][7:0], val_4B[4][15:8], val_4B[4][23:16], val_4B[4][31:24]};
assign val_4B_BE[5] = {val_4B[5][7:0], val_4B[5][15:8], val_4B[5][23:16], val_4B[5][31:24]};
assign val_4B_BE[6] = {val_4B[6][7:0], val_4B[6][15:8], val_4B[6][23:16], val_4B[6][31:24]};
assign val_4B_BE[7] = {val_4B[7][7:0], val_4B[7][15:8], val_4B[7][23:16], val_4B[7][31:24]};

assign val_6B_BE[0] = {val_6B[0][7:0], val_6B[0][15:8], val_6B[0][23:16], val_6B[0][31:24], val_6B[0][39:32], val_6B[0][47:40]};
assign val_6B_BE[1] = {val_6B[1][7:0], val_6B[1][15:8], val_6B[1][23:16], val_6B[1][31:24], val_6B[1][39:32], val_6B[1][47:40]};
assign val_6B_BE[2] = {val_6B[2][7:0], val_6B[2][15:8], val_6B[2][23:16], val_6B[2][31:24], val_6B[2][39:32], val_6B[2][47:40]};
assign val_6B_BE[3] = {val_6B[3][7:0], val_6B[3][15:8], val_6B[3][23:16], val_6B[3][31:24], val_6B[3][39:32], val_6B[3][47:40]};
assign val_6B_BE[4] = {val_6B[4][7:0], val_6B[4][15:8], val_6B[4][23:16], val_6B[4][31:24], val_6B[4][39:32], val_6B[4][47:40]};
assign val_6B_BE[5] = {val_6B[5][7:0], val_6B[5][15:8], val_6B[5][23:16], val_6B[5][31:24], val_6B[5][39:32], val_6B[5][47:40]};
assign val_6B_BE[6] = {val_6B[6][7:0], val_6B[6][15:8], val_6B[6][23:16], val_6B[6][31:24], val_6B[6][39:32], val_6B[6][47:40]};
assign val_6B_BE[7] = {val_6B[7][7:0], val_6B[7][15:8], val_6B[7][23:16], val_6B[7][31:24], val_6B[7][39:32], val_6B[7][47:40]};

integer idx;
localparam SEG_NUM = 1024/C_S_AXIS_DATA_WIDTH;
//reg [C_S_AXIS_DATA_WIDTH-1:0]  pkt_seg [0:(1024/C_S_AXIS_DATA_WIDTH-1)];

// reg [SEG_NUM-1:0] pkt_seg_cnt;
reg [3:0]    pkt_seg_cnt; //cnt is 4'd6 if its invalid
reg          s_axis_tvalid_before;
reg          phv_ready;

reg [1023:0] pkt_hdr_field;


/**
divide and conquar (below)
*/

genvar gen_i;

localparam C_PARSE_ACTION_LEN = 13;

reg [9:0]                    pkt_hdr_field_valid;
reg [9:0]                    parse_action_valid_in;

wire [47:0]                  val_out[0:9];
wire [1:0]                   val_out_select[0:9];
wire [2:0]                   val_seq_select[0:9];
wire [9:0]                   val_valid_out;




assign parse_action[9] = bram_out[0 +:16];
assign parse_action[8] = bram_out[16+:16];
assign parse_action[7] = bram_out[32+:16];
assign parse_action[6] = bram_out[48+:16];
assign parse_action[5] = bram_out[64+:16];
assign parse_action[4] = bram_out[80+:16];
assign parse_action[3] = bram_out[96+:16];
assign parse_action[2] = bram_out[112+:16];
assign parse_action[1] = bram_out[128+:16];
assign parse_action[0] = bram_out[144+:16];


// always @(posedge axis_clk or negedge aresetn) begin
//     if(~aresetn) begin
//         condi_action_d[0] <= 0;
//         condi_action_d[1] <= 0;
//         condi_action_d[2] <= 0;
//         condi_action_d[3] <= 0;
//         condi_action_d[4] <= 0;
//         condi_action[0] <= 0;
//         condi_action[1] <= 0;
//         condi_action[2] <= 0;
//         condi_action[3] <= 0;
//         condi_action[4] <= 0;
//     end
//     else begin
//         condi_action_d[0] <= bram_out[0+:20];
//         condi_action_d[1] <= bram_out[20+:20];
//         condi_action_d[2] <= bram_out[40+:20];
//         condi_action_d[3] <= bram_out[60+:20];
//         condi_action_d[4] <= bram_out[80+:20];
//         condi_action[0] <= condi_action_d[0];
//         condi_action[1] <= condi_action_d[1];
//         condi_action[2] <= condi_action_d[2];
//         condi_action[3] <= condi_action_d[3];
//         condi_action[4] <= condi_action_d[4];
//     end
// end


/**** here we parse everything (8 containers & 5 conditions) ****/

always @(posedge axis_clk) begin
    s_axis_tvalid_before <= s_axis_tvalid;
end

//a counter to determine if this value needs to be recorded
always @(posedge axis_clk) begin
    //1st segment
    if(s_axis_tvalid && ~s_axis_tvalid_before) begin
        pkt_seg_cnt <= 4'd0;
    end
    //left but not 1st segment (within SEG_NUM)
    else if(s_axis_tvalid) begin
        pkt_seg_cnt <= pkt_seg_cnt + 4'b1;
    end
    else begin
        pkt_seg_cnt <= pkt_seg_cnt;
    end
end

assign vlan_id_w = s_axis_tdata[116 +: 12];

always @(posedge axis_clk or negedge aresetn) begin
    if(~aresetn) begin
        vlan_id <= 12'b0;
    end
    else begin
        if(s_axis_tvalid && ~s_axis_tvalid_before) begin
            vlan_id <= s_axis_tdata[116 +: 12];
        end
    end
end

//record the pkts into pkt_hdr_field
always @(posedge axis_clk or negedge aresetn) begin
    if(~aresetn) begin
        pkt_hdr_field <= 1024'b0;
    end
    else begin
        //the 1st segment of the packet
        if(s_axis_tvalid && ~s_axis_tvalid_before) begin
            phv_ready <= 1'b0;
            //pkt_hdr_field <= s_axis_tdata<<(1024-C_S_AXIS_DATA_WIDTH);    
            pkt_hdr_field[511:0] <= s_axis_tdata;
            if(s_axis_tlast) begin
                pkt_hdr_field[1023:512] <= 512'b0;
            end
        end
        else if(pkt_seg_cnt < SEG_NUM-1 && s_axis_tvalid) begin
            pkt_hdr_field[1024-1 -: C_S_AXIS_DATA_WIDTH] <= s_axis_tdata;   
            //here we can start extract values from PHV
            if(pkt_seg_cnt == SEG_NUM-2 || s_axis_tlast) begin
                phv_ready <= 1'b1;
            end
        end
        else begin
            pkt_hdr_field <= pkt_hdr_field;
        end
    end
end


//here we extract the 1024b from packet (depend on data_width)
reg [2:0] parse_state;

localparam IDLE_S   = 3'd0,
           WAIT1_S  = 3'd1,
           WAIT2_S  = 3'd2,
           PHVGEN_S = 3'd3,
           HALT_S = 3'd4;

//fire up the FSM
always @(posedge axis_clk or negedge aresetn) begin
    if(~aresetn) begin
        phv_valid_out_reg <= 1'b0;
        //phv_out <= 1024'b0;
        for(idx=0; idx<10; idx = idx+1) begin
            parse_action_valid_in[idx] <= 1'b0;
            pkt_hdr_field_valid[idx] <= 1'b0;
        end
        parse_state <= IDLE_S;
        s_axis_tready <= 1'b1;
    end
    else begin
        case(parse_state)
            IDLE_S: begin
                if(s_axis_tvalid && ~s_axis_tvalid_before) begin
                    parse_state <= WAIT1_S;
                    s_axis_tready <= 1'b0;
                end
                else begin
                    s_axis_tready <= 1'b1;
                end
                phv_valid_out_reg <= 1'b0;
                //phv_out<=1024'b0;
                for(idx = 0; idx < 8; idx = idx+1) begin
                    val_2B[idx] <= 16'b0;
                    val_4B[idx] <= 32'b0;
                    val_6B[idx] <= 48'b0;
                end
                for(idx=0; idx<10; idx = idx+1) begin
                    parse_action_valid_in[idx] <= 1'b0;
                    pkt_hdr_field_valid[idx] <= 1'b0;
                end
            end

            WAIT1_S: begin
                parse_state <= WAIT2_S;
                for(idx=0; idx<10; idx = idx+1) begin
                    parse_action_valid_in[idx] <= 1'b1;
                    pkt_hdr_field_valid[idx] <= 1'b1;
                end
            end 

            WAIT2_S: begin
                for(idx=0; idx<10; idx = idx+1) begin
                    parse_action_valid_in[idx] <= 1'b0;
                    pkt_hdr_field_valid[idx] <= 1'b0;
                end
                parse_state <= PHVGEN_S;
            end

            PHVGEN_S: begin
                case(val_out_select[0])
                    2'b01: val_2B[val_seq_select[0]] <= val_out[0][15:0];
                    2'b10: val_4B[val_seq_select[0]] <= val_out[0][31:0];
                    2'b11: val_6B[val_seq_select[0]] <= val_out[0][47:0];
                endcase
                case(val_out_select[1])
                    2'b01: val_2B[val_seq_select[1]] <= val_out[1][15:0];
                    2'b10: val_4B[val_seq_select[1]] <= val_out[1][31:0];
                    2'b11: val_6B[val_seq_select[1]] <= val_out[1][47:0];
                endcase
                case(val_out_select[2])
                    2'b01: val_2B[val_seq_select[2]] <= val_out[2][15:0];
                    2'b10: val_4B[val_seq_select[2]] <= val_out[2][31:0];
                    2'b11: val_6B[val_seq_select[2]] <= val_out[2][47:0];
                endcase
                case(val_out_select[3])
                    2'b01: val_2B[val_seq_select[3]] <= val_out[3][15:0];
                    2'b10: val_4B[val_seq_select[3]] <= val_out[3][31:0];
                    2'b11: val_6B[val_seq_select[3]] <= val_out[3][47:0];
                endcase
                case(val_out_select[4])
                    2'b01: val_2B[val_seq_select[4]] <= val_out[4][15:0];
                    2'b10: val_4B[val_seq_select[4]] <= val_out[4][31:0];
                    2'b11: val_6B[val_seq_select[4]] <= val_out[4][47:0];
                endcase
                case(val_out_select[5])
                    2'b01: val_2B[val_seq_select[5]] <= val_out[5][15:0];
                    2'b10: val_4B[val_seq_select[5]] <= val_out[5][31:0];
                    2'b11: val_6B[val_seq_select[5]] <= val_out[5][47:0];
                endcase
                case(val_out_select[6])
                    2'b01: val_2B[val_seq_select[6]] <= val_out[6][15:0];
                    2'b10: val_4B[val_seq_select[6]] <= val_out[6][31:0];
                    2'b11: val_6B[val_seq_select[6]] <= val_out[6][47:0];
                endcase
                case(val_out_select[7])
                    2'b01: val_2B[val_seq_select[7]] <= val_out[7][15:0];
                    2'b10: val_4B[val_seq_select[7]] <= val_out[7][31:0];
                    2'b11: val_6B[val_seq_select[7]] <= val_out[7][47:0];
                endcase
                case(val_out_select[8])
                    2'b01: val_2B[val_seq_select[8]] <= val_out[8][15:0];
                    2'b10: val_4B[val_seq_select[8]] <= val_out[8][31:0];
                    2'b11: val_6B[val_seq_select[8]] <= val_out[8][47:0];
                endcase
                case(val_out_select[9])
                    2'b01: val_2B[val_seq_select[9]] <= val_out[9][15:0];
                    2'b10: val_4B[val_seq_select[9]] <= val_out[9][31:0];
                    2'b11: val_6B[val_seq_select[9]] <= val_out[9][47:0];
                endcase
                if(m_axis_tready) begin
                    phv_valid_out_reg <= 1'b1;
                    s_axis_tready <= 1'b1;
                    parse_state <= IDLE_S;
                end
                else begin
                    phv_valid_out_reg <= 1'b0;
                    parse_state <= HALT_S;
                end
            end
            HALT_S: begin
                if(m_axis_tready) begin
                    phv_valid_out_reg <= 1'b1;
                    s_axis_tready <= 1'b1;
                    parse_state <= IDLE_S;
                end
                else begin
                    phv_valid_out_reg <= 1'b0;
                    parse_state <= HALT_S;
                end
            end
        endcase
    end
end

//big endian for simpler processing
assign phv_out = {val_6B_BE[7], val_6B_BE[6], val_6B_BE[5], val_6B_BE[4], val_6B_BE[3], val_6B_BE[2], val_6B_BE[1], val_6B_BE[0],
				 val_4B_BE[7], val_4B_BE[6], val_4B_BE[5], val_4B_BE[4], val_4B_BE[3], val_4B_BE[2], val_4B_BE[1], val_4B_BE[0],
				 val_2B_BE[7], val_2B_BE[6], val_2B_BE[5], val_2B_BE[4], val_2B_BE[3], val_2B_BE[2], val_2B_BE[1], val_2B_BE[0],
				 {115{1'b0}}, vlan_id, 1'b0, {128{1'b0}}};



generate
    for(gen_i = 0; gen_i < 10; gen_i = gen_i + 1)
        begin: sub_op
            sub_parser #(
                //for 100g MAC, the AXIS width is 512b
	            .PARSE_ACT_RAM_WIDTH(),
                .C_PARSE_ACTION_LEN(),
                .HDR_FIELD_LEN(),
                .VAL_LEN()
            )sub_parser(
                .axis_clk(axis_clk),
	            .aresetn(aresetn),

	            .pkt_hdr_field(pkt_hdr_field),
                .pkt_hdr_field_valid(pkt_hdr_field_valid[gen_i]),

                .parse_action(parse_action[gen_i][12:0]),
                .parse_action_valid_in(parse_action_valid_in[gen_i]),

	            .val_valid_out(val_valid_out[gen_i]),
	            .val_out(val_out[gen_i]),
                .val_out_select(val_out_select[gen_i]),
                .val_seq_select(val_seq_select[gen_i])
            );
        end

endgenerate



/****control path for 512b*****/
wire [7:0]          mod_id; //module ID
wire [15:0]         control_flag; //dst udp port num
reg  [7:0]          c_index; //table index(addr)
reg                 c_wr_en; //enable table write(wen)
reg  [159:0]        entry_reg;

reg  [2:0]          c_state;

localparam IDLE_C = 1,
           WRITE_C  =2,
           SU_WRITE_C = 3;

assign mod_id = c_s_axis_tdata[368+:8];
assign control_flag = c_s_axis_tdata[335:320];

//LE to BE switching
wire[C_S_AXIS_DATA_WIDTH-1:0] c_s_axis_tdata_swapped;
assign c_s_axis_tdata_swapped = {	c_s_axis_tdata[0+:8],
									c_s_axis_tdata[8+:8],
									c_s_axis_tdata[16+:8],
									c_s_axis_tdata[24+:8],
									c_s_axis_tdata[32+:8],
									c_s_axis_tdata[40+:8],
									c_s_axis_tdata[48+:8],
									c_s_axis_tdata[56+:8],
									c_s_axis_tdata[64+:8],
									c_s_axis_tdata[72+:8],
									c_s_axis_tdata[80+:8],
									c_s_axis_tdata[88+:8],
									c_s_axis_tdata[96+:8],
									c_s_axis_tdata[104+:8],
									c_s_axis_tdata[112+:8],
									c_s_axis_tdata[120+:8],
									c_s_axis_tdata[128+:8],
									c_s_axis_tdata[136+:8],
									c_s_axis_tdata[144+:8],
									c_s_axis_tdata[152+:8],
									c_s_axis_tdata[160+:8],
									c_s_axis_tdata[168+:8],
									c_s_axis_tdata[176+:8],
									c_s_axis_tdata[184+:8],
									c_s_axis_tdata[192+:8],
									c_s_axis_tdata[200+:8],
									c_s_axis_tdata[208+:8],
									c_s_axis_tdata[216+:8],
									c_s_axis_tdata[224+:8],
									c_s_axis_tdata[232+:8],
									c_s_axis_tdata[240+:8],
									c_s_axis_tdata[248+:8],
                                    c_s_axis_tdata[256+:8],
                                    c_s_axis_tdata[264+:8],
                                    c_s_axis_tdata[272+:8],
                                    c_s_axis_tdata[280+:8],
                                    c_s_axis_tdata[288+:8],
                                    c_s_axis_tdata[296+:8],
                                    c_s_axis_tdata[304+:8],
                                    c_s_axis_tdata[312+:8],
                                    c_s_axis_tdata[320+:8],
                                    c_s_axis_tdata[328+:8],
                                    c_s_axis_tdata[336+:8],
                                    c_s_axis_tdata[344+:8],
                                    c_s_axis_tdata[352+:8],
                                    c_s_axis_tdata[360+:8],
                                    c_s_axis_tdata[368+:8],
                                    c_s_axis_tdata[376+:8],
                                    c_s_axis_tdata[384+:8],
                                    c_s_axis_tdata[392+:8],
                                    c_s_axis_tdata[400+:8],
                                    c_s_axis_tdata[408+:8],
                                    c_s_axis_tdata[416+:8],
                                    c_s_axis_tdata[424+:8],
                                    c_s_axis_tdata[432+:8],
                                    c_s_axis_tdata[440+:8],
                                    c_s_axis_tdata[448+:8],
                                    c_s_axis_tdata[456+:8],
                                    c_s_axis_tdata[464+:8],
                                    c_s_axis_tdata[472+:8],
                                    c_s_axis_tdata[480+:8],
                                    c_s_axis_tdata[488+:8],
                                    c_s_axis_tdata[496+:8],
                                    c_s_axis_tdata[504+:8]
                                };

always @(posedge axis_clk or negedge aresetn) begin
    if(~aresetn) begin
        c_wr_en <= 1'b0;
        c_index <= 4'b0;

        c_m_axis_tdata <= 0;
        c_m_axis_tuser <= 0;
        c_m_axis_tkeep <= 0;
        c_m_axis_tvalid <= 0;
        c_m_axis_tlast <= 0;
        entry_reg <= 0;

        c_state <= IDLE_C;
    end
    else begin
        case(c_state)
            IDLE_C: begin
                if(c_s_axis_tvalid && mod_id[2:0] == PARSER_ID && control_flag == 16'hf2f1)begin
                    c_wr_en <= 1'b0;
                    c_index <= c_s_axis_tdata[384+:8];

                    c_m_axis_tdata <= 0;
                    c_m_axis_tuser <= 0;
                    c_m_axis_tkeep <= 0;
                    c_m_axis_tvalid <= 0;
                    c_m_axis_tlast <= 0;

                    c_state <= WRITE_C;

                end
                else begin
                    c_wr_en <= 1'b0;
                    c_index <= 4'b0; 
                    entry_reg <= 0;

                    c_m_axis_tdata <= c_s_axis_tdata;
                    c_m_axis_tuser <= c_s_axis_tuser;
                    c_m_axis_tkeep <= c_s_axis_tkeep;
                    c_m_axis_tvalid <= c_s_axis_tvalid;
                    c_m_axis_tlast <= c_s_axis_tlast;

                    c_state <= IDLE_C;
                end
            end
            //support full table flush
            WRITE_C: begin
                if(c_s_axis_tvalid) begin
                    c_wr_en <= 1'b1;
                    entry_reg <= c_s_axis_tdata_swapped[511 -: 160];
                    if(c_s_axis_tlast) begin
                        c_state <= IDLE_C;
                    end
                    else begin
                        c_state <= SU_WRITE_C;
                    end
                end
                else begin
                    c_wr_en <= 1'b0;
                end
            end

            SU_WRITE_C: begin
                if(c_s_axis_tvalid) begin
                    entry_reg <= c_s_axis_tdata_swapped[511 -: 160];
                    c_wr_en <= 1'b1;
                    c_index <= c_index + 1'b1;
                    if(c_s_axis_tlast) begin
                        c_state <= IDLE_C;
                    end
                    else begin
                        c_state <= SU_WRITE_C;
                    end
                end
                else begin
                    c_wr_en <= 1'b0;
                end
            end
        endcase

    end
end


// =============================================================== //
// parse_act_ram_ip #(
// 	.C_INIT_FILE_NAME	("./parse_act_ram_init_file.mif"),
// 	.C_LOAD_INIT_FILE	(1)
// )
parse_act_ram_ip
parse_act_ram
(
	// write port
	.clka		(axis_clk),
	.addra		(c_index[4:0]),
	.dina		(entry_reg),
	.ena		(1'b1),
	.wea		(c_wr_en),

	//
	.clkb		(axis_clk),
	.addrb		(vlan_id_w[8:4]), // TODO: note that we may change due to little or big endian
	.doutb		(bram_out),
	.enb		(1'b1) // always set to 1
);


endmodule


