`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/21 08:16:19
// Design Name: 
// Module Name: DM
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


`define dm_word             3'b000
`define dm_halfword         3'b001
`define dm_halfword_unsigned 3'b010
`define dm_byte             3'b011
`define dm_byte_unsigned    3'b100

module DM(
    input        sw_i,
    input        clk,
    input        rstn,
    input        DMWr,
    input [4:0]  addr,    
    input [31:0] din,
    input [2:0]  DMType,
    output reg [31:0] dout
);
    reg [7:0] dmem[0:31];
    integer i;

    // 写：同步到时钟（包含复位）
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1)
                dmem[i] <= i[7:0];   // 按实验要求初始化
        end else if (DMWr) begin
            case (DMType)
                `dm_byte,
                `dm_byte_unsigned: begin
                    dmem[addr] <= din[7:0];
                end
                `dm_halfword,
                `dm_halfword_unsigned: begin
                    dmem[addr]   <= din[7:0];
                    dmem[addr+1] <= din[15:8];
                end
                `dm_word: begin
                    dmem[addr]   <= din[7:0];
                    dmem[addr+1] <= din[15:8];
                    dmem[addr+2] <= din[23:16];
                    dmem[addr+3] <= din[31:24];
                end
            endcase
        end
    end

    // 读：纯组合逻辑，随 addr / DMType 变化立即更新
    always @(*) begin
        case (DMType)
            `dm_byte: begin
                dout = {{24{dmem[addr][7]}}, dmem[addr]};
            end
            `dm_byte_unsigned: begin
                dout = {24'd0, dmem[addr]};
            end
            `dm_halfword: begin
                dout = {{16{dmem[addr+1][7]}}, dmem[addr+1], dmem[addr]};
            end
            `dm_halfword_unsigned: begin
                dout = {16'd0, dmem[addr+1], dmem[addr]};
            end
            `dm_word: begin
                dout = {dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr]};
            end
            default: begin
                dout = 32'd0;
            end
        endcase
    end
endmodule


