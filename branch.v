`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/04 15:42:40
// Design Name: 
// Module Name: branch
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module branch(
    input [31:0] rs1,
    input [31:0] rs2,
    input [2:0]  funct3,
    output reg   br_taken
    );

    always @(*) begin
        case (funct3)
            3'b000: br_taken = (rs1 == rs2);                         // BEQ
            3'b001: br_taken = (rs1 != rs2);                         // BNE
            3'b100: br_taken = ($signed(rs1) <  $signed(rs2));       // BLT
            3'b101: br_taken = ($signed(rs1) >= $signed(rs2));       // BGE
            3'b110: br_taken = (rs1 < rs2);                          // BLTU
            3'b111: br_taken = (rs1 >= rs2);                         // BGEU 
            default: br_taken = 1'b0;
        endcase
    end
endmodule
