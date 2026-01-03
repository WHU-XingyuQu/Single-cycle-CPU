`timescale 1ns / 1ps


`define EXT_CTRL_ITYPE_SHAMT  6'b000001
`define EXT_CTRL_ITYPE        6'b000010
`define EXT_CTRL_STYPE        6'b000011
`define EXT_CTRL_BTYPE        6'b000100
`define EXT_CTRL_UTYPE        6'b000101
`define EXT_CTRL_JTYPE        6'b000110


module EXT(
    input [4:0] iimm_shamt,
    input [11:0] iimm,
    input [11:0] simm,
    input [11:0] bimm,
    input [19:0] uimm,
    input [19:0] jimm,
    input [5:0] EXTOp,
    output reg [31:0] immout
    );
 always @(*) begin
        case (EXTOp)
            // I-type, shift amount（不需要符号扩展）
            `EXT_CTRL_ITYPE_SHAMT: begin
                immout = {27'b0, iimm_shamt[4:0]};
            end

            // I-type，普通立即数，12 位符号扩展
            `EXT_CTRL_ITYPE: begin
                immout = {{20{iimm[11]}}, iimm[11:0]};
            end

            // S-type，12 位符号扩展
            `EXT_CTRL_STYPE: begin
                immout = {{20{simm[11]}}, simm[11:0]};
            end

            // B-type，符号扩展后左移 1（分支偏移以 2 字节对齐）
            `EXT_CTRL_BTYPE: begin
                immout = {{19{bimm[11]}}, bimm[11:0], 1'b0};
            end

            // U-type，高 20 位直接放到 imm[31:12]，低 12 位补 0
            `EXT_CTRL_UTYPE: begin
                immout = {uimm[19:0], 12'b0};
            end

            // J-type，20 位符号扩展后左移 1（跳转偏移以 2 字节对齐）
            `EXT_CTRL_JTYPE: begin
                immout = {{11{jimm[19]}}, jimm[19:0], 1'b0};
            end

            default: begin
                immout = 32'b0;
            end
        endcase
    end

endmodule

// always @(posedge Clk_CPU or negedge rstn) begin
//         if (!rstn) begin
//             rom_addr <= 5'd0;              
//         end else begin
//             if (Branch && br_taken) begin
//                 rom_addr <= pc_branch;
//             end
//             else if(jal)
//                 rom_addr <= rom_addr + imm_ext[6:2];
//             else if(jalr)
//                 rom_addr <= ( (RD1 + imm_ext) >> 2 ) & 5'h1F;
//             else
//                 rom_addr <= pc_seq;
//         end
//     end