`timescale 1ns / 1ps


module parser_wait_segs #(
	parameter C_AXIS_DATA_WIDTH = 256,
	parameter C_AXIS_TUSER_WIDTH = 128,
	parameter C_NUM_SEGS = 4
)
(
	input											axis_clk,
	input											aresetn,
	
	//
	input [C_AXIS_DATA_WIDTH-1:0]					s_axis_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]					s_axis_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]					s_axis_tkeep,
	input											s_axis_tvalid,
	input											s_axis_tlast,
	
	//
	input											segs_fifo_ready,
	
	//
	output reg[C_NUM_SEGS*C_AXIS_DATA_WIDTH-1:0]	tdata_segs,
	output reg[C_AXIS_TUSER_WIDTH-1:0]				tuser_1st,
	output reg[11:0]								vlan,
	output reg										segs_valid,
	output reg										vlan_valid
);

localparam	WAIT_1ST_SEG=0,
			WAIT_2ND_SEG=1,
			WAIT_3RD_SEG=2,
			WAIT_4TH_SEG=3,
			OUTPUT_SEGS=4;

reg [2:0]	state, state_next;
reg [C_NUM_SEGS*C_AXIS_DATA_WIDTH-1:0] tdata_segs_next;
reg [C_AXIS_TUSER_WIDTH-1:0] tuser_1st_next;
reg	segs_valid_next, vlan_valid_next;

always @(*) begin

	state_next = state;

	tdata_segs_next = tdata_segs;
	tuser_1st_next = tuser_1st;

	segs_valid_next = 0;
	vlan_valid_next = 0;


	case (state)
		// at least 2 segs
		WAIT_1ST_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[0*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;
				tuser_1st_next = s_axis_tuser;

				vlan = s_axis_tdata[116+:12];
				vlan_valid_next = 1;
			
				//
				state_next = WAIT_2ND_SEG;
			end
		end
		WAIT_2ND_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[1*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;

				if (s_axis_tlast) begin
					if (segs_fifo_ready) begin
						segs_valid_next = 1;
						state_next = WAIT_1ST_SEG;
					end
					else begin
						state_next = OUTPUT_SEGS;
					end
				end
				else begin
					state_next = WAIT_3RD_SEG;
				end
			end
		end
		WAIT_3RD_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[2*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;

				if (s_axis_tlast) begin
					if (segs_fifo_ready) begin
						segs_valid_next = 1;
						state_next = WAIT_1ST_SEG;
					end
					else begin
						state_next = OUTPUT_SEGS;
					end
				end
				else begin
					state_next = WAIT_4TH_SEG;
				end
			end
		end
		WAIT_4TH_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[3*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;

				if (segs_fifo_ready) begin
					segs_valid_next = 1;
					state_next = WAIT_1ST_SEG;
				end
				else begin
					state_next = OUTPUT_SEGS;
				end
			end
		end
		OUTPUT_SEGS: begin
			if (segs_fifo_ready) begin
				segs_valid_next = 1;
				state_next = WAIT_1ST_SEG;
			end
		end
	endcase
end


always @(posedge axis_clk) begin
	if (~aresetn) begin

		state <= WAIT_1ST_SEG;

		tdata_segs <= {C_NUM_SEGS*C_AXIS_DATA_WIDTH{1'b0}};
		tuser_1st <= {C_AXIS_TUSER_WIDTH{1'b0}};
		segs_valid <= 0;
		vlan_valid <= 0;
	end
	else begin
		state <= state_next;

		tdata_segs <= tdata_segs_next;
		tuser_1st <= tuser_1st_next;

		segs_valid <= segs_valid_next;
		vlan_valid <= vlan_valid_next;
	end
end

endmodule
