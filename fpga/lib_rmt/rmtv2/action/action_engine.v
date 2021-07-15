`timescale 1ns / 1ps
module action_engine #(
    parameter STAGE_ID = 0,
    parameter PHV_LEN = 48*8+32*8+16*8+256,
    parameter ACT_LEN = 25,
    parameter ACT_ID = 3,
    parameter C_S_AXIS_DATA_WIDTH = 512,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter C_VLANID_WIDTH = 12
)(
    input clk,
    input rst_n,

    //signals from lookup to ALUs
    input [PHV_LEN-1:0]           phv_in,
    input                         phv_valid_in,
    input [ACT_LEN*25-1:0]        action_in,
    input                         action_valid_in,
    output                        ready_out,

    //signals output from ALUs
    output reg [PHV_LEN-1:0]      phv_out,
    output reg                    phv_valid_out,
    input                         ready_in,
	// vlan
	output reg [C_VLANID_WIDTH-1:0]		vlan_out,
	output reg							vlan_out_valid,
	input								vlan_out_ready,

    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]			c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		c_s_axis_tkeep,
	input									c_s_axis_tvalid,
	input									c_s_axis_tlast,

    output [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output [C_S_AXIS_DATA_WIDTH/8-1:0]		c_m_axis_tkeep,
	output 								    c_m_axis_tvalid,
	output 								    c_m_axis_tlast
);

/********intermediate variables declared here********/
integer i;

localparam width_2B = 16;
localparam width_4B = 32;
localparam width_6B = 48;

wire                        alu_in_valid;
wire [width_6B*8-1:0]       alu_in_6B_1;
wire [width_6B*8-1:0]       alu_in_6B_2;
wire [width_4B*8-1:0]       alu_in_4B_1;
wire [width_4B*8-1:0]       alu_in_4B_2;
wire [width_4B*8-1:0]       alu_in_4B_3;
wire [11:0]                 vlan_id;
wire [width_2B*8-1:0]       alu_in_2B_1;
wire [width_2B*8-1:0]       alu_in_2B_2;
wire [255:0]                alu_in_phv_remain_data;

wire		                phv_valid_bit;

wire [ACT_LEN*25-1:0]       alu_in_action;
wire                        alu_in_action_valid;

wire                        alu_ready_out;

/********intermediate variables declared here********/

/********IPs instancilzed here*********/

wire [width_6B-1:0]			output_6B[0:7];
wire [width_4B-1:0]			output_4B[0:7];
wire [width_2B-1:0]			output_2B[0:7];
wire [255:0]				output_md;

//crossbar
crossbar #(
    .STAGE_ID(STAGE_ID),
    .PHV_LEN(),
    .ACT_LEN(),
    .width_2B(),
    .width_4B(),
    .width_6B()
)cross_bar(
    .clk(clk),
    .rst_n(rst_n),
    //input from PHV
    .phv_in(phv_in),
    .phv_in_valid(phv_valid_in),
    //input from action
    .action_in(action_in),
    .action_in_valid(action_valid_in),
    .ready_out(ready_out),
    .vlan_id(vlan_id),
    //output to the ALU
    .alu_in_valid(alu_in_valid),
    .alu_in_6B_1(alu_in_6B_1),
    .alu_in_6B_2(alu_in_6B_2),
    .alu_in_4B_1(alu_in_4B_1),
    .alu_in_4B_2(alu_in_4B_2),
    .alu_in_4B_3(alu_in_4B_3),
    .alu_in_2B_1(alu_in_2B_1),
    .alu_in_2B_2(alu_in_2B_2),
    .phv_remain_data(alu_in_phv_remain_data),
    .action_out(alu_in_action),
    .action_valid_out(alu_in_action_valid),
    .ready_in(alu_ready_out)
);



//ALU_1
genvar gen_i;
generate
    //initialize 8 6B containers 
    for(gen_i = 7; gen_i >= 0; gen_i = gen_i - 1) begin
        alu_1 #(
            .STAGE_ID(STAGE_ID),
            .ACTION_LEN(),
            .DATA_WIDTH(width_6B)
        )alu_1_6B(
            .clk(clk),
            .rst_n(rst_n),
            .action_in(alu_in_action[(gen_i+8+8+1+1)*ACT_LEN-1 -: ACT_LEN]),
            .action_valid(alu_in_action_valid),
            .operand_1_in(alu_in_6B_1[(gen_i+1) * width_6B -1 -: width_6B]),
            .operand_2_in(alu_in_6B_2[(gen_i+1) * width_6B -1 -: width_6B]),
            // .container_out(phv_out[width_4B*8+width_2B*8+356+width_6B*(gen_i+1)-1 -: width_6B]),
            .container_out(output_6B[gen_i]),
            .container_out_valid()
        );

        alu_1 #(
            .STAGE_ID(STAGE_ID),
            .ACTION_LEN(),
            .DATA_WIDTH(width_2B)
        )alu_1_2B(
            .clk(clk),
            .rst_n(rst_n),
            .action_in(alu_in_action[(gen_i+1+1)*ACT_LEN-1 -: ACT_LEN]),
            .action_valid(alu_in_action_valid),
            .operand_1_in(alu_in_2B_1[(gen_i+1) * width_2B -1 -: width_2B]),
            .operand_2_in(alu_in_2B_2[(gen_i+1) * width_2B -1 -: width_2B]),
            // .container_out(phv_out[356+width_2B*(gen_i+1) -1 -: width_2B]),
            .container_out(output_2B[gen_i]),
            .container_out_valid()
        );
	end
endgenerate

alu_2 #(
    .STAGE_ID(STAGE_ID),
    .ACTION_LEN(),
    .DATA_WIDTH(width_4B),  //data width of the ALU
    .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
    .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH)
)alu_2_0(
    .clk(clk),
    .rst_n(rst_n),
    //input from sub_action
    .action_in(alu_in_action[(7+8+1+1)*ACT_LEN-1 -: ACT_LEN]),
    .action_valid(alu_in_action_valid),
    .operand_1_in(alu_in_4B_1[(7+1) * width_4B -1 -: width_4B]),
    .operand_2_in(alu_in_4B_2[(7+1) * width_4B -1 -: width_4B]),
    .operand_3_in(alu_in_4B_3[(7+1) * width_4B -1 -: width_4B]),
    .ready_out(alu_ready_out),
    .vlan_id(vlan_id),
    //output to form PHV
    .container_out(output_4B[7]),
    .container_out_valid(),
    .ready_in(ready_in),
    
    .c_s_axis_tdata(c_s_axis_tdata),
    .c_s_axis_tuser(c_s_axis_tuser),
    .c_s_axis_tkeep(c_s_axis_tkeep),
    .c_s_axis_tvalid(c_s_axis_tvalid),
    .c_s_axis_tlast(c_s_axis_tlast),

    .c_m_axis_tdata(c_m_axis_tdata),
    .c_m_axis_tuser(c_m_axis_tuser),
    .c_m_axis_tkeep(c_m_axis_tkeep),
    .c_m_axis_tvalid(c_m_axis_tvalid),
    .c_m_axis_tlast(c_m_axis_tlast)
);

generate
    for(gen_i = 6; gen_i >= 0; gen_i = gen_i - 1) begin
		alu_1 #(
		    .STAGE_ID(STAGE_ID),
		    .ACTION_LEN(),
		    .DATA_WIDTH(width_4B)
		)alu_1_4B(
		    .clk(clk),
		    .rst_n(rst_n),
		    .action_in(alu_in_action[(gen_i+8+1+1)*ACT_LEN-1 -: ACT_LEN]),
		    .action_valid(alu_in_action_valid),
		    .operand_1_in(alu_in_4B_1[(gen_i+1) * width_4B -1 -: width_4B]),
		    .operand_2_in(alu_in_4B_2[(gen_i+1) * width_4B -1 -: width_4B]),
		    // .container_out(phv_out[width_2B*8+356+width_4B*(gen_i+1) -1 -: width_4B]),
		    .container_out(output_4B[gen_i]),
		    .container_out_valid()
		);
    end
endgenerate


//initialize ALU_3 for matedata

alu_3 #(
    .STAGE_ID(STAGE_ID),
    .ACTION_LEN(),
    .META_LEN()
)alu_3_0(
    .clk(clk),
    .rst_n(rst_n),
    //input data shall be metadata & com_ins
    .comp_meta_data_in(alu_in_phv_remain_data),
    .comp_meta_data_valid_in(alu_in_valid),
    .action_in(alu_in_action[24:0]),
    .action_valid_in(alu_in_action_valid),

    //output is the modified metadata plus comp_ins
    // .comp_meta_data_out(phv_out[355:0]),
    .comp_meta_data_out(output_md),
    .comp_meta_data_valid_out(phv_valid_bit)
);

reg [PHV_LEN-1:0]	phv_out_r;
reg					phv_valid_out_r;

always @(*) begin

	phv_out_r = phv_out;
	phv_valid_out_r = 0;

	if (phv_valid_bit) begin
		phv_valid_out_r = 1;
		phv_out_r = {output_6B[7], output_6B[6], output_6B[5], output_6B[4], output_6B[3], output_6B[2], output_6B[1], output_6B[0],
				output_4B[7], output_4B[6], output_4B[5], output_4B[4], output_4B[3], output_4B[2], output_4B[1], output_4B[0],
				output_2B[7], output_2B[6], output_2B[5], output_2B[4], output_2B[3], output_2B[2], output_2B[1], output_2B[0], output_md};
	end
end

always @(posedge clk) begin
	if (~rst_n) begin
		phv_out <= 0;
		phv_valid_out <= 0;
	end
	else begin
		phv_out <= phv_out_r;
		phv_valid_out <= phv_valid_out_r;
	end
end

//================================================================
// vlan out logic
localparam		IDLE=0,
				FLUSH_VLAN=1;

reg [C_VLANID_WIDTH-1:0]	vlan_out_next;
reg							vlan_out_valid_next;
reg							state, state_next;


always @(*) begin

	state_next = state;
	vlan_out_next = vlan_out;
	vlan_out_valid_next = 0;

	case (state)
		IDLE: begin
			if (phv_valid_in) begin
				vlan_out_next = phv_in[140:129];

				if (vlan_out_ready) begin
					vlan_out_valid_next = 1;
				end
				else begin
					state_next = FLUSH_VLAN;
				end
			end
		end
		FLUSH_VLAN: begin
			if (vlan_out_ready) begin
				vlan_out_valid_next = 1;
				state_next = IDLE;
			end
		end
	endcase
end

always @(posedge clk) begin
	if (~rst_n) begin
		state <= IDLE;
		vlan_out <= 0;
		vlan_out_valid <= 0;
	end
	else begin
		state <= state_next;
		vlan_out <= vlan_out_next;
		vlan_out_valid <= vlan_out_valid_next;
	end
end

endmodule
