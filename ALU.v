`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/19 18:57:12
// Design Name: 
// Module Name: ALU
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


module ALU(
    input clk,
    input rstn,
    input [15:0]  sw_i,
    input [31:0] A,
    input [31:0] B,
    input [4:0] aluop,
    output reg [7:0] zero,
    output reg [31:0] C
    );

    //ALUOp(customized)
    localparam ALU_ADD  = 5'b00000;  // ADD, ADDI, 地址计算
    localparam ALU_SUB  = 5'b00001;  // SUB
    localparam ALU_SLT  = 5'b00010;  // SLT, SLTI  （有符号比较）
    localparam ALU_SLTU = 5'b00011;  // SLTU, SLTIU（无符号比较）
    localparam ALU_AND  = 5'b00100;  // AND, ANDI
    localparam ALU_OR   = 5'b00101;  // OR,  ORI
    localparam ALU_XOR  = 5'b00110;  // XOR, XORI
    localparam ALU_SLL  = 5'b00111;  // SLL, SLLI
    localparam ALU_SRL  = 5'b01000;  // SRL, SRLI
    localparam ALU_SRA  = 5'b01001;  // SRA, SRAI

    wire [4:0] shamt;
    assign shamt = B[4:0];

    always @(*) begin
        if(!rstn) begin
            C <= 32'd0;
            zero <= 8'd0;
        end else begin
            case (aluop)
                ALU_ADD:  C = A + B;
                ALU_SUB:  C = A - B;

                ALU_SLT:  C = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
                ALU_SLTU: C = (A < B) ? 32'd1 : 32'd0;

                ALU_AND:  C = A & B;
                ALU_OR:   C = A | B;
                ALU_XOR:  C = A ^ B;

                ALU_SLL:  C = A << shamt;
                ALU_SRL:  C = A >> shamt;
                ALU_SRA:  C = $signed(A) >>> shamt;

                default:  C = 32'd0; 
            endcase
        end
        zero <= (C == 32'd0) ? 8'b00000001 : 8'b00000000;
    end

endmodule
