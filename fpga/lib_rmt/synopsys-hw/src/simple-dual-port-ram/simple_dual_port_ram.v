module simple_dual_port_ram #(
	parameter DATA_WIDTH=8,
	parameter ADDR_WIDTH=4
)
(
	// write input
	input						clka,
	input [ADDR_WIDTH-1:0]		addra,
	input [DATA_WIDTH-1:0]		dina,
	input						wea,
	input						ena,
	// read output
	input						clkb,
	input [ADDR_WIDTH-1:0]		addrb,
	output reg [DATA_WIDTH-1:0]	doutb,
	input						enb
);

reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

// write
always @(posedge clka) begin // write
	if (wea) begin
		ram[addra] <= dina;
	end
end

// read
always @(posedge clkb) begin
	doutb <= ram[addrb];
end


endmodule
