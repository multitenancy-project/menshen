module test_cam (
  parameter HH=0
)
(
input clk
);


cam_top #(
.C_DEPTH (4),
.C_WIDTH (16),
.C_MEM_INIT (0)
)
cam_0
(
.CLK	(clk),
.CMP_DIN	(),
.CMP_DATA_MASK	(),
.BUSY		(),
.MATCH		(),
.MATCH_ADDR	(),

.WE		(),
.WR_ADDR	(),
.DATA_MASK	(),
.DIN		(),
.EN		(1'b1)
);





endmodule
