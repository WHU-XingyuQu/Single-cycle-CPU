`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 19:30:42
// Design Name: 
// Module Name: RF
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


module RF(
    input              clk,
    input              rstn,       
    input              RFWr,
    input      [15:0]  sw_i,      
    input      [4:0]   A1,A2,A3,
    input      [31:0]  WD,
    output reg [31:0]  RD1,
    output reg [31:0]  RD2
);
    reg [31:0] rf [31:0];
    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 复位时初始化寄存器
            for(i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'b0;
            end
        end else begin
            // 写操作（x0寄存器不能写）
            if (RFWr && (A3 != 5'd0)) begin
                rf[A3] <= WD;
            end
        end
    end

    always @(*) begin
        RD1 = rf[A1];
        RD2 = rf[A2];
    end
endmodule
