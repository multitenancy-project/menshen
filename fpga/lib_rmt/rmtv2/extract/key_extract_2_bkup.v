/****************************************************/
//	Module name: key_extract.v
//	Authority @ yangxiangrui (yangxiangrui11@nudt.edu.cn)
//	Last edited time: 2020/10/01
//	Function outline: extract 256b+5b key out of PHV
//  Note: Used only for multi-tenants scenario
/****************************************************/

`timescale 1ns / 1ps
module key_extract_2 #(
    parameter C_S_AXIS_DATA_WIDTH = 512,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
    parameter STAGE_ID = 0,
    parameter PHV_LEN = 48*8+32*8+16*8+5*20+256,
    parameter KEY_LEN = 48*2+32*2+16*2+5,
    // format of KEY_OFF entry: |--3(6B)--|--3(6B)--|--3(4B)--|--3(4B)--|--3(2B)--|--3(2B)--|
    parameter KEY_OFF = (3+3)*3,
    parameter AXIL_WIDTH = 32,
    parameter KEY_OFF_ADDR_WIDTH = 4,
    parameter KEY_EX_ID = 1
    )(
    input                               clk,
    input                               rst_n,
    input [PHV_LEN-1:0]                 phv_in,
    input                               phv_valid_in,

    output reg [PHV_LEN-1:0]            phv_out,
    output reg                          phv_valid_out,
    output reg [KEY_LEN-1:0]            key_out,
    output reg                          key_valid_out,
    output reg [KEY_LEN-1:0]            key_mask_out,

    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]			c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		c_s_axis_tkeep,
	input									c_s_axis_tvalid,
	input									c_s_axis_tlast,

    output reg [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output reg [C_S_AXIS_DATA_WIDTH/8-1:0]		c_m_axis_tkeep,
	output reg								    c_m_axis_tvalid,
	output reg								    c_m_axis_tlast
);


/********intermediate variables declared here********/
// (*mark_debug = "true"*) wire         phv_in_valid_dbg;
// (*mark_debug = "true"*) wire [15:0]  phv_in_2B_dbg;
// (*mark_debug = "true"*) wire [3:0]   vlan_id_in_dbg;
// (*mark_debug = "true"*) wire         phv_out_valid_dbg;
// (*mark_debug = "true"*) wire [15:0]  phv_out_2B_dbg;
// (*mark_debug = "true"*) wire [3:0]   vlan_id_out_dbg;

// assign phv_in_valid_dbg = phv_valid_in;
// assign phv_in_2B_dbg = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-7*width_2B -: width_2B];
// assign vlan_id_in_dbg = phv_in[136:133];

// assign phv_out_valid_dbg = phv_valid_out;
// assign phv_out_2B_dbg = phv_out[PHV_LEN-1-8*width_6B-8*width_4B-7*width_2B -: width_2B];
// assign vlan_id_out_dbg = phv_out[136:133];


integer i;

localparam width_2B = 16;
localparam width_4B = 32;
localparam width_6B = 48;

//24 fields to be retrived from the pkt header
reg [width_2B-1:0]    cont_2B [0:7];
reg [width_4B-1:0]    cont_4B [0:7];
reg [width_6B-1:0]    cont_6B [0:7];

reg [PHV_LEN-1:0]     phv_out_delay[0:2];
reg                   phv_valid_out_delay[0:2];

reg  [19:0]            com_op[0:4];
reg  [7:0]             com_op_1;
reg  [7:0]             com_op_2;

//vlan_id extracted from metadata
wire  [11:0]             vlan_id; 

wire [KEY_OFF-1:0]      key_offset;
reg  [KEY_OFF-1:0]      key_offset_r;
wire [196:0]        key_mask_out_w;

/********intermediate variables declared here********/

// assign cont_6B[7] = phv_in[PHV_LEN-1            -: width_6B];
// assign cont_6B[6] = phv_in[PHV_LEN-1-  width_6B -: width_6B];
// assign cont_6B[5] = phv_in[PHV_LEN-1-2*width_6B -: width_6B];
// assign cont_6B[4] = phv_in[PHV_LEN-1-3*width_6B -: width_6B];
// assign cont_6B[3] = phv_in[PHV_LEN-1-4*width_6B -: width_6B];
// assign cont_6B[2] = phv_in[PHV_LEN-1-5*width_6B -: width_6B];
// assign cont_6B[1] = phv_in[PHV_LEN-1-6*width_6B -: width_6B];
// assign cont_6B[0] = phv_in[PHV_LEN-1-7*width_6B -: width_6B];

// assign cont_4B[7] = phv_in[PHV_LEN-1-8*width_6B           -: width_4B];
// assign cont_4B[6] = phv_in[PHV_LEN-1-8*width_6B-  width_4B -: width_4B];
// assign cont_4B[5] = phv_in[PHV_LEN-1-8*width_6B-2*width_4B -: width_4B];
// assign cont_4B[4] = phv_in[PHV_LEN-1-8*width_6B-3*width_4B -: width_4B];
// assign cont_4B[3] = phv_in[PHV_LEN-1-8*width_6B-4*width_4B -: width_4B];
// assign cont_4B[2] = phv_in[PHV_LEN-1-8*width_6B-5*width_4B -: width_4B];
// assign cont_4B[1] = phv_in[PHV_LEN-1-8*width_6B-6*width_4B -: width_4B];
// assign cont_4B[0] = phv_in[PHV_LEN-1-8*width_6B-7*width_4B -: width_4B];


// assign cont_2B[7] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B            -: width_2B];
// assign cont_2B[6] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-  width_2B -: width_2B];
// assign cont_2B[5] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-2*width_2B -: width_2B];
// assign cont_2B[4] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-3*width_2B -: width_2B];
// assign cont_2B[3] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-4*width_2B -: width_2B];
// assign cont_2B[2] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-5*width_2B -: width_2B];
// assign cont_2B[1] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-6*width_2B -: width_2B];
// assign cont_2B[0] = phv_in[PHV_LEN-1-8*width_6B-8*width_4B-7*width_2B -: width_2B];

//retrive the operators here using wire
// assign com_op[0] = phv_in[255+100 -: 20];
// assign com_op[1] = phv_in[255+80  -: 20];
// assign com_op[2] = phv_in[255+60  -: 20];
// assign com_op[3] = phv_in[255+40  -: 20];
// assign com_op[4] = phv_in[255+20  -: 20];

assign vlan_id = phv_in[140:129];

//locate those containers
always @(posedge clk) begin
    cont_6B[7] <= phv_out_delay[1][PHV_LEN-1            -: width_6B];
    cont_6B[6] <= phv_out_delay[1][PHV_LEN-1-  width_6B -: width_6B];
    cont_6B[5] <= phv_out_delay[1][PHV_LEN-1-2*width_6B -: width_6B];
    cont_6B[4] <= phv_out_delay[1][PHV_LEN-1-3*width_6B -: width_6B];
    cont_6B[3] <= phv_out_delay[1][PHV_LEN-1-4*width_6B -: width_6B];
    cont_6B[2] <= phv_out_delay[1][PHV_LEN-1-5*width_6B -: width_6B];
    cont_6B[1] <= phv_out_delay[1][PHV_LEN-1-6*width_6B -: width_6B];
    cont_6B[0] <= phv_out_delay[1][PHV_LEN-1-7*width_6B -: width_6B];
    cont_4B[7] <= phv_out_delay[1][PHV_LEN-1-8*width_6B           -: width_4B];
    cont_4B[6] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-  width_4B -: width_4B];
    cont_4B[5] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-2*width_4B -: width_4B];
    cont_4B[4] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-3*width_4B -: width_4B];
    cont_4B[3] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-4*width_4B -: width_4B];
    cont_4B[2] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-5*width_4B -: width_4B];
    cont_4B[1] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-6*width_4B -: width_4B];
    cont_4B[0] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-7*width_4B -: width_4B];
    cont_2B[7] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B            -: width_2B];
    cont_2B[6] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-  width_2B -: width_2B];
    cont_2B[5] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-2*width_2B -: width_2B];
    cont_2B[4] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-3*width_2B -: width_2B];
    cont_2B[3] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-4*width_2B -: width_2B];
    cont_2B[2] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-5*width_2B -: width_2B];
    cont_2B[1] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-6*width_2B -: width_2B];
    cont_2B[0] <= phv_out_delay[1][PHV_LEN-1-8*width_6B-8*width_4B-7*width_2B -: width_2B];
    com_op[0]  <= phv_out_delay[1][255+100 -: 20];
    com_op[1]  <= phv_out_delay[1][255+80  -: 20];
    com_op[2]  <= phv_out_delay[1][255+60  -: 20];
    com_op[3]  <= phv_out_delay[1][255+40  -: 20];
    com_op[4]  <= phv_out_delay[1][255+20  -: 20];
    key_mask_out <= key_mask_out_w;
end



//have to extract comparators within 1 cycle
always @(*) begin
    if(com_op[STAGE_ID][17] == 1'b1) begin
        com_op_1 = com_op[STAGE_ID][16:9];
    end
    else begin
        case(com_op[STAGE_ID][13:12])
            2'b10: begin
                com_op_1 = cont_6B[com_op[STAGE_ID][11:9]][7:0];
            end
            2'b01: begin
                com_op_1 = cont_4B[com_op[STAGE_ID][11:9]][7:0];
            end
            2'b00: begin
                com_op_1 = cont_2B[com_op[STAGE_ID][11:9]][7:0];
            end
        endcase
    end
    if(com_op[STAGE_ID][8] == 1'b1) begin
        com_op_2 = com_op[STAGE_ID][7:0];
    end
    else begin
        case(com_op[STAGE_ID][4:3])
            2'b10: begin
                com_op_2 = cont_6B[com_op[STAGE_ID][2:0]][7:0];
            end
            2'b01: begin
                com_op_2 = cont_4B[com_op[STAGE_ID][2:0]][7:0];
            end
            2'b00: begin
                com_op_2 = cont_2B[com_op[STAGE_ID][2:0]][7:0];
            end
        endcase
    end

end

//extract keys from PHV
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        key_out <= 0;
        key_valid_out <= 1'b0;
        phv_out <= 0;
        phv_valid_out <= 1'b0;
        phv_out_delay[0] <= 0;
        phv_out_delay[1] <= 0;
        phv_out_delay[2] <= 0;
        phv_valid_out_delay[0] <= 1'b0;
        phv_valid_out_delay[1] <= 1'b0;
        phv_valid_out_delay[2] <= 1'b0;
    end
    else begin
        //output PHV
        phv_out_delay[0] <= phv_in;
        phv_out_delay[1] <= phv_out_delay[0];
        phv_out_delay[2] <= phv_out_delay[1];
        phv_out <= phv_out_delay[2];
        phv_valid_out_delay[0] <= phv_valid_in;
        phv_valid_out_delay[1] <= phv_valid_out_delay[0];
        phv_valid_out_delay[2] <= phv_valid_out_delay[1];
        phv_valid_out <= phv_valid_out_delay[2];

        key_offset_r <= key_offset;

        //extract keys according to key_off
        if(phv_valid_out_delay[2]) begin
            //optimize for `if`
            key_valid_out <= 1'b1; 

            key_out[KEY_LEN-1                                     -: width_6B] <= cont_6B[key_offset_r[KEY_OFF-1     -: 3]];
            key_out[KEY_LEN-1- 1*width_6B                         -: width_6B] <= cont_6B[key_offset_r[KEY_OFF-1-1*3 -: 3]];
            key_out[KEY_LEN-1- 2*width_6B                         -: width_4B] <= cont_4B[key_offset_r[KEY_OFF-1-2*3 -: 3]];
            key_out[KEY_LEN-1- 2*width_6B - 1*width_4B            -: width_4B] <= cont_4B[key_offset_r[KEY_OFF-1-3*3 -: 3]];
            key_out[KEY_LEN-1- 2*width_6B - 2*width_4B            -: width_2B] <= cont_2B[key_offset_r[KEY_OFF-1-4*3 -: 3]];
            key_out[KEY_LEN-1- 2*width_6B - 2*width_4B - width_2B -: width_2B] <= cont_2B[key_offset_r[KEY_OFF-1-5*3 -: 3]];
            //deal with comparators
            case(com_op[STAGE_ID][19:18])
                2'b00: begin
                    key_out[4-STAGE_ID] <= (com_op_1>com_op_2)?1'b1:1'b0;
                end
                2'b01: begin
                    key_out[4-STAGE_ID] <= (com_op_1>=com_op_2)?1'b1:1'b0;
                end
                2'b10: begin
                    key_out[4-STAGE_ID] <= (com_op_1==com_op_2)?1'b1:1'b0;
                end
                default: begin
                    key_out[4-STAGE_ID] <= 1'b1;
                end
            endcase

        end
        
               
        else begin
            key_out <= 0;
            key_valid_out <= 1'b0;
        end
    end
end


/****control path for 512b*****/
wire [7:0]          mod_id; //module ID
wire [3:0]          resv;
wire [15:0]         control_flag; //dst udp port num
reg  [7:0]          c_index; //table index(addr)
reg                 c_wr_en_off; //enable table write(wena)
reg                 c_wr_en_mask;


reg [2:0]           c_state;

/****for 256b exclusively*****/
reg [C_S_AXIS_DATA_WIDTH-1:0]       c_m_axis_tdata_r;
reg [C_S_AXIS_TUSER_WIDTH-1:0]      c_m_axis_tuser_r;
reg [C_S_AXIS_DATA_WIDTH/8-1:0]     c_m_axis_tkeep_r;
reg                                 c_m_axis_tvalid_r;
reg                                 c_m_axis_tlast_r;



localparam IDLE_C = 0,
           PARSE_C = 1,
           WRITE_OFF_C = 2,
           SU_WRITE_OFF_C = 3,
           WRITE_MASK_C = 4,
           SU_WRITE_MASK_C = 5,
		   FLUSH_PKT_C = 6;

generate 
    if(C_S_AXIS_DATA_WIDTH == 512) begin
        assign mod_id = c_s_axis_tdata[368+:8];
        //4'b0 for key offset
        //4'b1 for key mask
        assign resv = c_s_axis_tdata[376+:4];
        assign control_flag = c_s_axis_tdata[335:320];

        reg [17:0]                    key_off_entry_reg;
        reg [196:0]                   key_mask_entry_reg;
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
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                c_wr_en_off <= 1'b0;
                c_wr_en_mask <= 1'b0;
                c_index <= 8'b0;
        
                c_m_axis_tdata <= 0;
                c_m_axis_tuser <= 0;
                c_m_axis_tkeep <= 0;
                c_m_axis_tvalid <= 0;
                c_m_axis_tlast <= 0;

                key_off_entry_reg <= 0;
                key_mask_entry_reg <= 0;
        
                c_state <= IDLE_C;
        
            end
            else begin
                case(c_state)
                    IDLE_C: begin
                        if(c_s_axis_tvalid && mod_id[7:3] == STAGE_ID && mod_id[2:0] == KEY_EX_ID &&
                         control_flag == 16'hf2f1)begin
                            //c_wr_en <= 1'b1;
                            c_index <= c_s_axis_tdata[384+:8];
        
                            c_m_axis_tdata <= 0;
                            c_m_axis_tuser <= 0;
                            c_m_axis_tkeep <= 0;
                            c_m_axis_tvalid <= 0;
                            c_m_axis_tlast <= 0;
        
                            //c_state <= WRITE_C;
                            if(resv == 4'b0) begin
                                c_wr_en_off <= 1'b0;
                                c_state <= WRITE_OFF_C;
                            end
                            else begin
                                c_wr_en_mask <= 1'b0;
                                c_state <= WRITE_MASK_C;
                            end
                        end
                        else begin
                            c_wr_en_off <= 1'b0;
                            c_wr_en_mask <= 1'b0;
                            c_index <= 8'b0; 
        
                            c_m_axis_tdata <= c_s_axis_tdata;
                            c_m_axis_tuser <= c_s_axis_tuser;
                            c_m_axis_tkeep <= c_s_axis_tkeep;
                            c_m_axis_tvalid <= c_s_axis_tvalid;
                            c_m_axis_tlast <= c_s_axis_tlast;
        
                            c_state <= IDLE_C;
                        end
                    end
                    //support full table flush
                    WRITE_OFF_C: begin
                        if(c_s_axis_tvalid) begin
                            key_off_entry_reg <= c_s_axis_tdata_swapped[511 -: 18];
                            c_wr_en_mask <= 1'b1;
                            if(c_s_axis_tlast) begin
                                c_state <= IDLE_C;
                            end
                            else begin
                                c_state <= SU_WRITE_OFF_C;
                            end
                        end
                        else begin
                            c_wr_en_off <= 0;
                        end
                    end

                    SU_WRITE_OFF_C: begin
                        if(c_s_axis_tvalid) begin
                            key_off_entry_reg <= c_s_axis_tdata_swapped[511 -: 18];
                            c_wr_en_off <= 1'b1;
                            c_index <= c_index + 1'b1;
                            if(c_s_axis_tlast) begin
                                c_state <= IDLE_C;
                            end
                            else begin
                                c_state <= SU_WRITE_OFF_C;
                            end
                        end
                        else begin
                            c_wr_en_off <= 1'b0;
                        end
                    end

                    WRITE_MASK_C: begin
                        if(c_s_axis_tvalid) begin
                            key_mask_entry_reg <= c_s_axis_tdata_swapped[511 -: 197];
                            c_wr_en_mask <= 1'b1;
                            if(c_s_axis_tlast) begin
                                c_state <= IDLE_C;
                            end
                            else begin
                                c_state <= SU_WRITE_MASK_C;
                            end
                        end
                        else begin
                            c_wr_en_mask <= 0;
                        end
                    end

                    SU_WRITE_MASK_C: begin
                        if(c_s_axis_tvalid) begin
                            key_mask_entry_reg <= c_s_axis_tdata_swapped[511 -: 197];
                            c_wr_en_mask <= 1'b1;
                            c_index <= c_index + 1'b1;
                            if(c_s_axis_tlast) begin
                                c_state <= IDLE_C;
                            end
                            else begin
                                c_state <= SU_WRITE_MASK_C;
                            end
                        end
                        else begin
                            c_wr_en_mask <= 1'b0;
                        end
                    end

                    default: begin
                        c_wr_en_off <= 1'b0;
                        c_wr_en_mask <= 1'b0;
                        c_index <= 8'b0; 
                        c_m_axis_tdata <= c_s_axis_tdata;
                        c_m_axis_tuser <= c_s_axis_tuser;
                        c_m_axis_tkeep <= c_s_axis_tkeep;
                        c_m_axis_tvalid <= c_s_axis_tvalid;
                        c_m_axis_tlast <= c_s_axis_tlast;
                    end
                endcase
        
            end
        end
        //ram for key extract
        //blk_mem_gen_2 act_ram_18w_16d
        // blk_mem_gen_2 #(
        // 	.C_INIT_FILE_NAME	("./key_extract.mif"),
        // 	.C_LOAD_INIT_FILE	(1)
        // )
        blk_mem_gen_2
        key_ram_18w_16d
        (
            .addra(c_index[3:0]),
            .clka(clk),
            .dina(key_off_entry_reg),
            .ena(1'b1),
            .wea(c_wr_en_off),

            //only [3:0] is needed for addressing
            .addrb(vlan_id[7:4]), // TODO: we may need to change this logic due to big/little endian
            .clkb(clk),
            .doutb(key_offset),
            .enb(1'b1)
        );

        blk_mem_gen_3
        mask_ram_197w_16d
        (
            .addra(c_index[3:0]),
            .clka(clk),
            .dina(key_mask_entry_reg),
            .ena(1'b1),
            .wea(c_wr_en_mask),

            //only [3:0] is needed for addressing
            .addrb(vlan_id[7:4]), // TODO: we may need to change this logic due to big/little endian
            .clkb(clk),
            .doutb(key_mask_out_w),
            .enb(1'b1)
        );
    end

    else if(C_S_AXIS_DATA_WIDTH == 256) begin
        assign mod_id = c_s_axis_tdata[112+:8];
        //4'b0 for key offset
        //4'b1 for key mask
        assign resv = c_s_axis_tdata[120+:4];
        assign control_flag = c_s_axis_tdata[64:16];
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
											c_s_axis_tdata[248+:8]};

        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                c_wr_en_off <= 1'b0;
                c_wr_en_mask <= 1'b0;
                c_index <= 8'b0;

                c_m_axis_tdata <= 0;
                c_m_axis_tuser <= 0;
                c_m_axis_tkeep <= 0;
                c_m_axis_tvalid <= 0;
                c_m_axis_tlast <= 0;

                c_m_axis_tdata_r  <= 0;
                c_m_axis_tuser_r  <= 0;
                c_m_axis_tkeep_r  <= 0;
                c_m_axis_tvalid_r <= 0;
                c_m_axis_tlast_r  <= 0;

                c_state <= IDLE_C;

            end

            else begin
                case(c_state)
                    IDLE_C: begin
                        c_m_axis_tdata <= c_m_axis_tdata_r;
                        c_m_axis_tuser <= c_m_axis_tuser_r;
                        c_m_axis_tkeep <= c_m_axis_tkeep_r;
                        c_m_axis_tvalid <= c_m_axis_tvalid_r;
                        c_m_axis_tlast <= c_m_axis_tlast_r;

                        if(c_s_axis_tvalid) begin

                            c_m_axis_tdata_r <= c_s_axis_tdata;
                            c_m_axis_tuser_r <= c_s_axis_tuser;
                            c_m_axis_tkeep_r <= c_s_axis_tkeep;
                            c_m_axis_tvalid_r <= c_s_axis_tvalid;
                            c_m_axis_tlast_r <= c_s_axis_tlast;

                            c_state <= PARSE_C;
                        end
                        
                        else begin
                            c_wr_en_off <= 1'b0;
                            c_wr_en_mask <= 1'b0;
                            c_index <= 8'b0; 
                            c_m_axis_tvalid_r <= 1'b0;
                            c_m_axis_tlast_r <= 1'b0;

                            c_state <= IDLE_C;
                        end
                    end

                    PARSE_C: begin
                        // if(mod_id[7:3] == STAGE_ID && mod_id[2:0] == KEY_EX_ID && 
                        //    control_flag == 16'hf2f1 && c_s_axis_tvalid) begin
                        if(mod_id[7:3] == STAGE_ID && mod_id[2:0] == KEY_EX_ID && c_s_axis_tvalid) begin
                            c_m_axis_tdata <= 0;
                            c_m_axis_tuser <= 0;
                            c_m_axis_tkeep <= 0;
                            c_m_axis_tvalid <= 0;
                            c_m_axis_tlast <= 0;

                            c_index <= c_s_axis_tdata[128+:8];

                            if(resv == 4'b0) begin
                                c_wr_en_off <= 1'b1;
                                c_state <= WRITE_OFF_C;
                            end
                            else begin
                                c_wr_en_mask <= 1'b1;
                                c_state <= WRITE_MASK_C;
                            end
                        end
                        //if I don't know if I should send it, then I should hold it.
                        else if(!c_s_axis_tvalid) begin
                            c_m_axis_tdata <= c_m_axis_tdata;
                            c_m_axis_tuser <= c_m_axis_tuser;
                            c_m_axis_tkeep <= c_m_axis_tkeep;
                            c_m_axis_tvalid <= 0;
                            c_m_axis_tlast <= 0;

                            c_m_axis_tdata_r <= c_m_axis_tdata_r;
                            c_m_axis_tuser_r <= c_m_axis_tuser_r;
                            c_m_axis_tkeep_r <= c_m_axis_tkeep_r;
                            c_m_axis_tvalid_r <= c_m_axis_tvalid_r;
                            c_m_axis_tlast_r <= c_m_axis_tlast_r;
                        end

                        else begin
                            c_m_axis_tdata <= c_m_axis_tdata_r;
                            c_m_axis_tuser <= c_m_axis_tuser_r;
                            c_m_axis_tkeep <= c_m_axis_tkeep_r;
                            c_m_axis_tvalid <= c_m_axis_tvalid_r;
                            c_m_axis_tlast <= c_m_axis_tlast_r;

                            c_m_axis_tdata_r <= c_s_axis_tdata;
                            c_m_axis_tuser_r <= c_s_axis_tuser;
                            c_m_axis_tkeep_r <= c_s_axis_tkeep;
                            c_m_axis_tvalid_r <= c_s_axis_tvalid;
                            c_m_axis_tlast_r <= c_s_axis_tlast;
                            
                            if(c_s_axis_tvalid && c_s_axis_tlast) 
								c_state <= IDLE_C;
							else
								c_state <= FLUSH_PKT_C;
                        end

                    end

                    WRITE_OFF_C: begin
                        c_m_axis_tvalid_r <= 1'b0;
                        if(c_s_axis_tvalid && c_s_axis_tlast) begin
                            c_wr_en_off <= 1'b0;
                            c_index <= 8'b0;
                            c_state <= IDLE_C;
                        end
                        else if(c_s_axis_tvalid) begin
                            c_wr_en_off <= 1'b1;
                            c_index <= c_index + 8'b1;
                            c_state <= WRITE_OFF_C;
                        end
                        else begin
                            c_wr_en_off <= c_wr_en_off;
                            c_index <= c_index;
                            c_state <= c_state;
                        end
                    end

                    WRITE_MASK_C: begin
                        c_m_axis_tvalid_r <= 1'b0;
                        if(c_s_axis_tvalid && c_s_axis_tlast) begin
                            c_wr_en_mask <= 1'b0;
                            c_index <= 8'b0;
                            c_state <= IDLE_C;
                        end
                        else if (c_s_axis_tvalid) begin
                            c_wr_en_mask <= 1'b1;
                            c_index <= c_index + 8'b1;
                            c_state <= WRITE_MASK_C;
                        end
                        else begin
                            c_wr_en_mask <= c_wr_en_mask;
                            c_index <= c_index;
                            c_state <= c_state;
                        end
                    end

					FLUSH_PKT_C: begin
                        c_m_axis_tdata <= c_m_axis_tdata_r;
                        c_m_axis_tuser <= c_m_axis_tuser_r;
                        c_m_axis_tkeep <= c_m_axis_tkeep_r;
                        c_m_axis_tvalid <= c_m_axis_tvalid_r;
                        c_m_axis_tlast <= c_m_axis_tlast_r;

                        c_m_axis_tdata_r <= c_s_axis_tdata;
                        c_m_axis_tuser_r <= c_s_axis_tuser;
                        c_m_axis_tkeep_r <= c_s_axis_tkeep;
                        c_m_axis_tvalid_r <= c_s_axis_tvalid;
                        c_m_axis_tlast_r <= c_s_axis_tlast;
                            
                        if(c_s_axis_tvalid && c_s_axis_tlast) 
							c_state <= IDLE_C;
					end

                endcase
            end
        end

        //ram for key extract
        //blk_mem_gen_2 act_ram_18w_16d
        // blk_mem_gen_2 #(
        // 	.C_INIT_FILE_NAME	("./key_extract.mif"),
        // 	.C_LOAD_INIT_FILE	(1)
        // )
        blk_mem_gen_2
        key_ram_18w_16d
        (
            .addra(c_index[3:0]),
            .clka(clk),
            .dina(c_s_axis_tdata_swapped[238+:18]),
            .ena(1'b1),
            .wea(c_wr_en_off),

            //only [3:0] is needed for addressing
            .addrb(vlan_id[7:4]), // TODO: we may need to change this logic due to big/little endian
            .clkb(clk),
            .doutb(key_offset),
            .enb(1'b1)
        );

        blk_mem_gen_3
        mask_ram_197w_16d
        (
            .addra(c_index[3:0]),
            .clka(clk),
            .dina(c_s_axis_tdata_swapped[59+:197]),
            .ena(1'b1),
            .wea(c_wr_en_mask),

            //only [3:0] is needed for addressing
            .addrb(vlan_id[7:4]), // TODO: we may need to change this logic due to big/little endian
            .clkb(clk),
            .doutb(key_mask_out_w),
            .enb(1'b1)
        );
    end
endgenerate

endmodule
