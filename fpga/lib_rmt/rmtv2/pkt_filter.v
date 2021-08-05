`timescale 1ns / 1ps

`define ETH_TYPE_IPV4	16'h0008
`define IPPROT_UDP		8'h11
`define CONTROL_PORT    16'hf2f1

module pkt_filter #(
	parameter C_S_AXIS_DATA_WIDTH = 512,
	parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter C_VLANID_WIDTH = 12
)
(
	input				clk,
	input				aresetn,

	input      [95:0]	time_stamp,
	input      [31:0]	vlan_drop_flags,
	output     [31:0]	cookie_val,
	output     [31:0]	ctrl_token,

	// input Slave AXI Stream
	input [C_S_AXIS_DATA_WIDTH-1:0]			s_axis_tdata,
	input [((C_S_AXIS_DATA_WIDTH/8))-1:0]	s_axis_tkeep,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		s_axis_tuser,
	input									s_axis_tvalid,
	output	reg 							s_axis_tready,
	input									s_axis_tlast,

	// output Master AXI Stream
	output reg [C_S_AXIS_DATA_WIDTH-1:0]		m_axis_tdata,
	output reg [((C_S_AXIS_DATA_WIDTH/8))-1:0]	m_axis_tkeep,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]		m_axis_tuser,
	output reg									m_axis_tvalid,
	input										m_axis_tready,
	output reg									m_axis_tlast,

	output reg [C_VLANID_WIDTH-1:0]				vlan_id,
	output reg									vlan_id_valid,

	//TODO a back-pressure is needed?
	output reg [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output reg [((C_S_AXIS_DATA_WIDTH/8))-1:0]	c_m_axis_tkeep,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output reg									c_m_axis_tvalid,
	output reg									c_m_axis_tlast

);


localparam WAIT_FIRST_PKT=0, 
		   DROP_PKT=1, 
		   FLUSH_DATA=2,
		   FLUSH_CTL = 3;


reg [C_S_AXIS_DATA_WIDTH-1:0]		r_tdata;
reg [((C_S_AXIS_DATA_WIDTH/8))-1:0]	r_tkeep;
reg [C_S_AXIS_TUSER_WIDTH-1:0]		r_tuser;
reg									r_tvalid;
reg									r_tlast;

reg									r_s_tready;

reg [1:0] state, state_next;
//1 for control, 0 for data;
reg 								c_switch;
wire								w_c_switch;

// vlan 
reg									vlan_id_valid_next;

//for security and reliability 
wire [31:0]							cookie_w;
wire [31:0]							token_w;

reg  [31:0]							ctrl_token_r, ctrl_token_next;

//checkme: for dropping packets during reconf
wire [11:0]							vlan_id_w;
wire [31:0]							vlan_id_one_hot_w;

assign w_c_switch = c_switch;
assign ctrl_token = ctrl_token_r;
assign cookie_w = {s_axis_tdata[399:392],s_axis_tdata[407:400],s_axis_tdata[415:408],s_axis_tdata[423:416]};
assign token_w = {s_axis_tdata[431:424], s_axis_tdata[439:432], s_axis_tdata[447:440], s_axis_tdata[455:448]};

assign vlan_id_w = s_axis_tdata[116 +: 12];
assign vlan_id_one_hot_w = (1'b1 << vlan_id_w[8:4]); 

always @(*) begin

	r_tdata = s_axis_tdata;
	r_tkeep = s_axis_tkeep;
	r_tuser = s_axis_tuser;
	r_tlast = s_axis_tlast;

	r_tvalid = s_axis_tvalid;
	r_s_tready = m_axis_tready;

	c_switch = 1'b0;
	vlan_id_valid_next = 0;

	state_next = state;

	case (state) 
		WAIT_FIRST_PKT: begin
			if (m_axis_tready && s_axis_tvalid) begin
				if ((s_axis_tdata[143:128]==`ETH_TYPE_IPV4) && 
					(s_axis_tdata[223:216]==`IPPROT_UDP)) begin
					//checkme: we put the security check here
					// if(s_axis_tdata[335:320] == `CONTROL_PORT && cookie_w == cookie_val) begin
					if(s_axis_tdata[335:320] == `CONTROL_PORT) begin
						state_next = FLUSH_CTL;
						c_switch = 1'b1;
						//modify token once its true
						ctrl_token_next = ctrl_token_r + 1'b1;
					end
					else if (!s_axis_tlast) begin
						//checkme: if this vlan is not configed, send it
						// TODO: for validity check
						//if((vlan_id_one_hot_w & vlan_drop_flags)==0) begin
						if (1) begin
							state_next = FLUSH_DATA;
							c_switch = 1'b0;
							vlan_id_valid_next = 1;
						end
						else begin
							state_next = DROP_PKT;
							r_tvalid = 0;
						end
					end

					else if (s_axis_tlast) begin
						state_next = WAIT_FIRST_PKT;
						c_switch = 1'b0;
						vlan_id_valid_next = 1;
						//checkme: if this vlan is configed, drop it
						if((vlan_id_one_hot_w & vlan_drop_flags)!=0) begin
							r_tvalid = 0;
						end
					end
				end
				else begin
					
					r_tvalid = 0;
					state_next = DROP_PKT;
				end

				if (s_axis_tlast) begin
					state_next = WAIT_FIRST_PKT;
				end
			end

			else begin
				ctrl_token_next = ctrl_token_r;
				c_switch = 1'b0;
			end

		end
		FLUSH_DATA: begin
			if (s_axis_tvalid && s_axis_tlast) begin
				state_next = WAIT_FIRST_PKT;
			end
		end
		FLUSH_CTL: begin
			c_switch = 1'b1;
			if (s_axis_tvalid && s_axis_tlast) begin
				state_next = WAIT_FIRST_PKT;
			end
		end
		DROP_PKT: begin
			r_tvalid = 0;
			if (s_axis_tvalid && s_axis_tlast) begin
				state_next = WAIT_FIRST_PKT;
			end
		end
	endcase
end

always @(posedge clk or negedge aresetn) begin
	if (~aresetn) begin
		state <= WAIT_FIRST_PKT;

		m_axis_tdata <= 0;
		m_axis_tkeep <= 0;
		m_axis_tuser <= 0;
		m_axis_tlast <= 0;

		m_axis_tvalid <= 0;

		c_m_axis_tdata <= 0;
		c_m_axis_tkeep <= 0;
		c_m_axis_tuser <= 0;
		c_m_axis_tlast <= 0;

		c_m_axis_tvalid <= 0;
		s_axis_tready <= 0;

		//ctrl_token_r <= time_stamp[31:0];
		ctrl_token_r <= 32'b0;
		//
		vlan_id <= 0;
		vlan_id_valid <= 0;
	end

	else begin
		state <= state_next;
		ctrl_token_r <= ctrl_token_next;

		if(!w_c_switch) begin // data pkt
			m_axis_tdata <= r_tdata;
			m_axis_tkeep <= r_tkeep;
			m_axis_tuser <= r_tuser;
			m_axis_tlast <= r_tlast;
			m_axis_tvalid <= r_tvalid;

			s_axis_tready <= r_s_tready;
			//reset control path output 
			c_m_axis_tdata <= 0;
			c_m_axis_tkeep <= 0;
			c_m_axis_tuser <= 0;
			c_m_axis_tlast <= 0;
			c_m_axis_tvalid <= 0;

			vlan_id <= vlan_id_w;
			vlan_id_valid <= vlan_id_valid_next;
		end
		else begin // ctrl pkt
			m_axis_tdata <= 0;
			m_axis_tkeep <= 0;
			m_axis_tuser <= 0;
			m_axis_tlast <= 0;
			m_axis_tvalid <= 0;
			// 
			c_m_axis_tdata <= r_tdata;
			c_m_axis_tkeep <= r_tkeep;
			c_m_axis_tuser <= r_tuser;
			c_m_axis_tlast <= r_tlast;

			c_m_axis_tvalid <= r_tvalid;
		end
		
	end
end

cookie #(
	.COOKIE_LEN()
)cookie(
	.clk(clk),
	.rst_n(aresetn),
	.time_stamp(time_stamp),
	.cookie_val(cookie_val)
);

endmodule
