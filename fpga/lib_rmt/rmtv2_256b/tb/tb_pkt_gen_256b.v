`timescale 1ns / 1ps

module tb_pkt_gen #(
	parameter C_S_AXIS_DATA_WIDTH = 256,
	parameter C_S_AXIS_TUSER_WIDTH = 128
)();

localparam CYCLE = 4;

reg								clk;
reg								aresetn;
reg								start;
reg [15:0]						pkt_len;

reg [C_S_AXIS_DATA_WIDTH-1:0]		s_axis_tdata;
reg [((C_S_AXIS_DATA_WIDTH/8))-1:0]	s_axis_tkeep;
reg [C_S_AXIS_TUSER_WIDTH-1:0]		s_axis_tuser;
reg									s_axis_tvalid;
wire								s_axis_tready;
reg									s_axis_tlast;

wire [C_S_AXIS_DATA_WIDTH-1:0]		    m_axis_tdata;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]    m_axis_tkeep;
wire [C_S_AXIS_TUSER_WIDTH-1:0]		    m_axis_tuser;
wire								    m_axis_tvalid;
reg										m_axis_tready;
wire									m_axis_tlast;


always begin
	#(CYCLE/2) clk = ~clk;
end

initial begin
	clk = 0;
	aresetn = 1;
	start = 0;
	pkt_len = 2;
	m_axis_tready = 1;

	#100;
	aresetn = 0; // reset all the values
	#100;
	aresetn = 1;
	start = 1;
end

rmt_wrapper #(
	.C_S_AXI_DATA_WIDTH(),
	.C_S_AXI_ADDR_WIDTH(),
	.C_BASEADDR(),
	.C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.C_S_AXIS_TUSER_WIDTH(),
	.C_M_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.PHV_ADDR_WIDTH()
)rmt_wrapper_ins
(
	.clk(clk),		// axis clk
	.aresetn(aresetn),	

	// input Slave AXI Stream
	.s_axis_tdata(s_axis_tdata),
	.s_axis_tkeep(s_axis_tkeep),
	.s_axis_tuser(s_axis_tuser),
	.s_axis_tvalid(s_axis_tvalid),
	.s_axis_tready(s_axis_tready),
	.s_axis_tlast(s_axis_tlast),

	// output Master AXI Stream
	.m_axis_tdata(m_axis_tdata),
	.m_axis_tkeep(m_axis_tkeep),
	.m_axis_tuser(m_axis_tuser),
	.m_axis_tvalid(m_axis_tvalid),
	.m_axis_tready(1),
	.m_axis_tlast(m_axis_tlast)
	
);


reg [63:0] counter;
reg [63:0] c_counter;
reg [63:0] cycle_counter;
reg [63:0] byte_counter;


always @(*) begin
	s_axis_tvalid = 0;
	s_axis_tlast = 0;
	if (start && s_axis_tready) begin
		s_axis_tvalid = 1;
		if (c_counter == 0) begin
			s_axis_tvalid = 1;
			s_axis_tdata = 256'h6f6fd79b1140000001002e000045000801000081a401bdfefd3c050000000000;
			s_axis_tuser = 128'h00000000000000000000000000000040;
			s_axis_tkeep = {32{1'b1}};
		end
		else begin
			s_axis_tdata = c_counter + counter;
			// s_axis_tkeep = 1;
			s_axis_tkeep = {32{1'b1}};
		end
		
		if (c_counter == pkt_len-1) begin
			s_axis_tkeep = {32{1'b1}};
			// s_axis_tkeep = 1;
			s_axis_tlast = 1;
		end
	end
end

always @(posedge clk) begin
	if (~aresetn) begin
		counter <= 1;
		c_counter <= 0;
		cycle_counter <= 0;
	end
	else begin
		if (start) begin
			cycle_counter <= cycle_counter+1;
		end
		if (start && s_axis_tready && s_axis_tvalid) begin
			c_counter <= c_counter+1;
			if (c_counter == pkt_len-1) begin
				c_counter <= 0;
				counter <= counter + 1;
			end
		end
	end
end

// check
reg [63:0] check_seq_counter;
reg [63:0] check_counter;
reg [2:0] pk_start;
always@(posedge clk) begin
	if(~aresetn) begin
		check_counter <= 0;
		check_seq_counter <= 1;
		pk_start <= 1;
		byte_counter <= 0;
	end
	if(m_axis_tvalid) begin
		check_counter <= check_counter +1;
		byte_counter <= byte_counter + 512/8;
		if(pk_start == 1) begin
			pk_start <= 2;
		end
		else if (pk_start == 2) begin
			check_seq_counter = m_axis_tdata - check_counter;
			pk_start <= 0;
		end
		else if(!m_axis_tlast) begin
			if(m_axis_tkeep != {32{1'b1}}) begin
				$display("ERROR in compare %x with %x", m_axis_tdata, check_counter + check_seq_counter);
			end
		end
		else if(m_axis_tlast) begin
			if(m_axis_tkeep != {32{1'b1}}) begin
				$display("ERROR in compare %x with %x", m_axis_tdata, check_counter + check_seq_counter);
			end
			$display("DEBUG, received: %d", m_axis_tdata);
			pk_start <= 1;
			check_counter <= 0;
			check_seq_counter <= check_seq_counter + 1; 
		end
	end
end

always @(*) begin
	if (byte_counter >= 16000 * 64 || counter > 10000) begin
		aresetn = 0;
		start = 0;

		$finish;
	end
end

endmodule
