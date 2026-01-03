`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 21:23:46
// Design Name: 
// Module Name: ctrl
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
`define EXT_CTRL_ITYPE_SHAMT  6'b000001
`define EXT_CTRL_ITYPE        6'b000010
`define EXT_CTRL_STYPE        6'b000011
`define EXT_CTRL_BTYPE        6'b000100
`define EXT_CTRL_UTYPE        6'b000101
`define EXT_CTRL_JTYPE        6'b000110

module ctrl(
    input  [6:0] Op,
    input  [6:0] Funct7,
    input  [2:0] Funct3,
    input        zero,      // 目前没用，可以保留接口
    output       RegWrite,
    output       MemWrite,
    output [5:0] EXTOp,
    output [4:0] ALUOp,
    output [2:0] NPCOp,     // 先全部 000，不用
    output       ALUSrc,
    output [2:0] DMType,
    output [1:0] WDSel,
    output       Branch,
    output       jal,
    output       jalr
);
    //============================================================
    // 1. 指令大类判别
    //============================================================
    wire rtype      = (Op == 7'b0110011); // R-type
    wire itype_alu  = (Op == 7'b0010011); // I-type 算术/逻辑
    wire itype_load = (Op == 7'b0000011); // load
    wire stype      = (Op == 7'b0100011); // store
    wire btype      = (Op == 7'b1100011); // branch
    wire lui        = (Op == 7'b0110111); // lui
    wire auipc      = (Op == 7'b0010111); // auipc
    assign jal        = (Op == 7'b1101111); // jal
    assign jalr       = (Op == 7'b1100111); // jalr

    //============================================================
    // 2. R-type 具体指令（Funct7 + Funct3）
    //============================================================
    wire r_add  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b000);
    wire r_sub  = rtype & (Funct7 == 7'b0100000) & (Funct3 == 3'b000);
    wire r_sll  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b001);
    wire r_slt  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b010);
    wire r_sltu = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b011);
    wire r_xor  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b100);
    wire r_srl  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b101);
    wire r_sra  = rtype & (Funct7 == 7'b0100000) & (Funct3 == 3'b101);
    wire r_or   = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b110);
    wire r_and  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b111);

    //============================================================
    // 3. I-type 算术/逻辑指令
    //============================================================
    wire i_addi  = itype_alu & (Funct3 == 3'b000);
    wire i_slti  = itype_alu & (Funct3 == 3'b010);
    wire i_sltiu = itype_alu & (Funct3 == 3'b011);
    wire i_xori  = itype_alu & (Funct3 == 3'b100);
    wire i_ori   = itype_alu & (Funct3 == 3'b110);
    wire i_andi  = itype_alu & (Funct3 == 3'b111);

    // 移位立即数（shamt）：
    wire i_slli  = itype_alu & (Funct3 == 3'b001) & (Funct7 == 7'b0000000);
    wire i_srli  = itype_alu & (Funct3 == 3'b101) & (Funct7 == 7'b0000000);
    wire i_srai  = itype_alu & (Funct3 == 3'b101) & (Funct7 == 7'b0100000);

    //============================================================
    // 4. I-type load
    //============================================================
    wire i_lb  = itype_load & (Funct3 == 3'b000);
    wire i_lh  = itype_load & (Funct3 == 3'b001);
    wire i_lw  = itype_load & (Funct3 == 3'b010);
    wire i_lbu = itype_load & (Funct3 == 3'b100);
    wire i_lhu = itype_load & (Funct3 == 3'b101);

    //============================================================
    // 5. S-type store
    //============================================================
    wire i_sb  = stype & (Funct3 == 3'b000);
    wire i_sh  = stype & (Funct3 == 3'b001);
    wire i_sw  = stype & (Funct3 == 3'b010);

    //============================================================
    // 6. B-type branch
    //============================================================
    wire i_beq  = btype & (Funct3 == 3'b000);
    wire i_bne  = btype & (Funct3 == 3'b001);
    wire i_blt  = btype & (Funct3 == 3'b100);
    wire i_bge  = btype & (Funct3 == 3'b101);
    wire i_bltu = btype & (Funct3 == 3'b110);
    wire i_bgeu = btype & (Funct3 == 3'b111);

    //============================================================
    // 7. 寄存器/存储器 总体控制信号
    //============================================================

    // 寄存器写：R/I 算术 + load
    assign RegWrite = rtype | itype_alu | itype_load | lui | auipc | jal | jalr;

    // 存储器写：store
    assign MemWrite = stype;

    // ALU 第二操作数选立即数：I 算术 / load / store
    assign ALUSrc = itype_alu | itype_load | stype | jalr | auipc;

    // 写回数据选择：00->ALU，01->MEM
    assign WDSel = (itype_load)? 2'b01 :   // load
               (jal | jalr)? 2'b10 :  // PC+4
               2'b00;                // ALU result
    
    // 分支标记：是 B-type 指令
    assign Branch = btype;

    // NPCOp 暂时不用，统一输出 000
    assign NPCOp = 3'b000;

    //============================================================
    // 8. EXTOp：立即数扩展类型
    //============================================================
    reg [5:0] extop_r;
    always @(*) begin
        extop_r = 6'b000000;

        // I-type 普通立即数（算术/逻辑、load）
        if (itype_load || i_addi || i_slti || i_sltiu || i_xori || i_ori || i_andi || jalr)
            extop_r = `EXT_CTRL_ITYPE;
        // I-type 移位：用 shamt，不符号扩展
        else if (i_slli || i_srli || i_srai)
            extop_r = `EXT_CTRL_ITYPE_SHAMT;
        // S-type store
        else if (stype)
            extop_r = `EXT_CTRL_STYPE;
        // B-type branch 偏移
        else if (btype)
            extop_r = `EXT_CTRL_BTYPE;
        else if (lui || auipc)
            extop_r = `EXT_CTRL_UTYPE;
        else if (jal)
            extop_r = `EXT_CTRL_JTYPE;
    end

    assign EXTOp = extop_r;

    //============================================================
    // 9. DMType：数据存储器读写宽度/符号
    //============================================================
    assign DMType[2] = i_lbu;                     // 100: byte unsigned
    assign DMType[1] = i_lb | i_sb | i_lhu;       // 区分 half/byte
    assign DMType[0] = i_lh | i_sh | i_lb | i_sb;

    //============================================================
    // 10. ALUOp：告诉 ALU 干啥
    //============================================================
    localparam ALU_ADD  = 5'b00000;
    localparam ALU_SUB  = 5'b00001;
    localparam ALU_SLT  = 5'b00010;
    localparam ALU_SLTU = 5'b00011;
    localparam ALU_AND  = 5'b00100;
    localparam ALU_OR   = 5'b00101;
    localparam ALU_XOR  = 5'b00110;
    localparam ALU_SLL  = 5'b00111;
    localparam ALU_SRL  = 5'b01000;
    localparam ALU_SRA  = 5'b01001;

    reg [4:0] aluop_r;
    always @(*) begin
        // 默认用 ADD（地址计算/默认）
        aluop_r = ALU_ADD;

        // R / I 加法相关 + load/store 地址
        if (r_add | i_addi | itype_load | stype)
            aluop_r = ALU_ADD;
        else if (r_sub)
            aluop_r = ALU_SUB;

        // set-less-than（有符号 / 无符号）
        else if (r_slt | i_slti)
            aluop_r = ALU_SLT;
        else if (r_sltu | i_sltiu)
            aluop_r = ALU_SLTU;

        // 逻辑
        else if (r_and | i_andi)
            aluop_r = ALU_AND;
        else if (r_or  | i_ori)
            aluop_r = ALU_OR;
        else if (r_xor | i_xori)
            aluop_r = ALU_XOR;

        // 移位
        else if (r_sll | i_slli)
            aluop_r = ALU_SLL;
        else if (r_srl | i_srli)
            aluop_r = ALU_SRL;
        else if (r_sra | i_srai)
            aluop_r = ALU_SRA;

        // 分支指令也要给 ALU 一个操作：
        // - beq/bne 用 SUB，再看 zero
        // - blt/bge 用 SLT
        // - bltu/bgeu 用 SLTU
        else if (i_beq | i_bne)
            aluop_r = ALU_SUB;
        else if (i_blt | i_bge)
            aluop_r = ALU_SLT;
        else if (i_bltu | i_bgeu)
            aluop_r = ALU_SLTU;

        //auipc
        else if (auipc)
            aluop_r = ALU_ADD;
    end

    assign ALUOp = aluop_r;

endmodule

