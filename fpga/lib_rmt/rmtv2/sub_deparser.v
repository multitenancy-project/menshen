`timescale 1ns / 1ps

module sub_deparser #(
	//in corundum with 100g ports, data width is 512b
	parameter	C_S_AXIS_DATA_WIDTH = 256,
	parameter	C_S_AXIS_TUSER_WIDTH = 128,
	parameter	C_PKT_VEC_WIDTH = (6+4+2)*8*8+20*5+256,
    parameter   C_PARSE_ACTION_LEN = 6  //parse_action[5:0]
)
(
	input									clk,
	input									aresetn,

    input  [C_PKT_VEC_WIDTH-100-256-1:0]    deparse_phv_reg_in,
    input                                   deparse_phv_reg_valid_in,
    input  [C_PARSE_ACTION_LEN-1:0]         parse_action,
    input                                   parse_action_valid_in,

    output reg [47:0]                       deparse_phv_reg_out,
    //2'b01 for 2B, 2'b10 for 4B and 2'b11 for 6B
    output reg [1:0]                        deparse_phv_select,
    output reg                              valid_out
);

/**
    in this module, we generate the data about how the deparse_tdata_stored should be changed 
    based on bram_out and deparse_phv_reg. For example:

    in the REFORM_HDR state, this module should be given with:
    1) deparse_phv_reg;
    2) bram_out;
    3) a valid signal (when we need an output in the next cycle)

    **in one cycle later**, this module should output:
    1) a valid signal (the output is valid, optional);
    2) a deparse_phv_stored_r indicating how the deparse_tdata shall be modified
    3) a selector to indicate whether its 2B, 4B or 6B
*/

localparam PHV_2B_START_POS = 0;
localparam PHV_4B_START_POS = 16*8;
localparam PHV_6B_START_POS = 16*8+32*8;

reg [C_PKT_VEC_WIDTH-100-256-1:0] deparse_phv_reg;

always @(posedge clk or negedge aresetn) begin
    if(~aresetn) begin
        deparse_phv_reg_out <= 48'b0;
        deparse_phv_select <= 2'b0;
        valid_out <= 1'b0;
    end

    else begin
        case(deparse_phv_reg_valid_in)
            1'b1:    deparse_phv_reg <= deparse_phv_reg_in;
            default: deparse_phv_reg <= deparse_phv_reg;
        endcase
        
        case(parse_action_valid_in)
            1'b1: begin
                //case(parse_action[0])
                valid_out <= 1'b1;
                case({parse_action[5:4], parse_action[0]})
                    //2B
                    3'b011:begin
                        deparse_phv_select <= 2'b01;
                        case(parse_action[3:1])
                            3'd0:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*0+:16];
                            3'd1:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*1+:16];
                            3'd2:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*2+:16];
                            3'd3:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*3+:16];
                            3'd4:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*4+:16];
                            3'd5:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*5+:16];
                            3'd6:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*6+:16];
                            3'd7:  deparse_phv_reg_out[15:0] <= deparse_phv_reg[PHV_2B_START_POS+16*7+:16];
                        endcase
                    end
                    //4B
                    3'b101:begin
                        deparse_phv_select <= 2'b10;
                        case(parse_action[3:1])
                            3'd0:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*0+:32];
                            3'd1:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*1+:32];
                            3'd2:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*2+:32];
                            3'd3:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*3+:32];
                            3'd4:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*4+:32];
                            3'd5:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*5+:32];
                            3'd6:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*6+:32];
                            3'd7:  deparse_phv_reg_out[31:0] <= deparse_phv_reg[PHV_4B_START_POS+32*7+:32];
                        endcase
                    end
                    //6B
                    3'b111:begin
                        deparse_phv_select <= 2'b11;
                        case(parse_action[3:1])
                            3'd0:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*0+:48];
                            3'd1:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*1+:48];
                            3'd2:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*2+:48];
                            3'd3:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*3+:48];
                            3'd4:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*4+:48];
                            3'd5:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*5+:48];
                            3'd6:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*6+:48];
                            3'd7:  deparse_phv_reg_out[47:0] <= deparse_phv_reg[PHV_6B_START_POS+48*7+:48];
                        endcase
                    end

                    default: deparse_phv_select <= 2'b0;
                endcase

            end
            default: begin
                //NOTE: if nothing comes in, do nothing.
                valid_out <= 1'b0;
            end
        endcase
        

    end
end

endmodule