 `timescale 1ns / 1ps
// verilog规则：对同一个变量的赋值操作，只能在同一个always块里


module sccomp(clk, rstn, sw_i, disp_seg_o, disp_an_o);
    input clk;
    input rstn;
    input [15:0] sw_i;
    output [7:0] disp_an_o, disp_seg_o;

    reg [31:0] clkdiv;
    wire Clk_CPU;


    always @(posedge clk or negedge rstn) begin
        if (!rstn) clkdiv <= 0;
        else clkdiv <= clkdiv + 1'b1;
    end

   // 仿真可assign Clk_CPU = clk;
    assign Clk_CPU = (sw_i[15]) ? clkdiv[27] : clkdiv[25];
    // assign Clk_CPU = clk;

    wire [31:0] instr;
    reg[31:0] reg_data;
    reg[31:0] alu_disp_data;
    reg [31:0] dmem_data;
    reg [63:0] display_data; 
    reg [5:0] led_data_addr;
    reg [63:0] led_disp_data;
    reg [4:0] rom_addr;
    reg [4:0] reg_addr;
    reg [2:0] alu_addr;
    reg [4:0] dm_addr;

    //control - to ctrl
    wire RegWrite;
    wire MemWrite;
    wire [5:0] EXTOp;     // 立即数扩展控制
    wire [4:0] ALUOp;     // 给 ALU
    wire       ALUSrc;    // 选择 ALU B 的来源
    wire [2:0] DMType;    // DM 读写类型
    wire [1:0] WDSel;     // 寄存器写回数据来源
    wire [6:0] Op;        // Opcode [6:0]
    wire [6:0] Funct7;    // [31:25]-to ctrl
    wire [2:0] Funct3;    // [14:12]-to branch and ctrl
    //imm gen - to ext
    wire [11:0] iimm;
    wire [11:0] simm;       
    wire [4:0]  iimm_shamt;
    wire [11:0] bimm;
    wire [19:0] uimm;
    wire [19:0] jimm;   
    wire [31:0] imm_ext;
    //ALU input 
    wire [4:0]  rs1, rs2; 
    wire [31:0] RD1, RD2;
    wire [4:0]  rd;      
    //ALU output      
    reg [31:0] WD;  
    wire [31:0] A,B,C;
    wire zero;
    //DM
    parameter DM_DATA_NUM = 32;
    wire [31:0] dm_din;
    wire [31:0] dm_dout;
    wire [4:0] write_addr;


    assign Funct7 = instr[31:25];
    assign Funct3 = instr[14:12];
    assign Op = instr[6:0];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];
    assign iimm       = instr[31:20];
    assign simm       = {instr[31:25], instr[11:7]};
    assign iimm_shamt = instr[24:20];
    assign bimm       = {instr[31], instr[7], instr[30:25], instr[11:8]};
    assign uimm       = instr[31:12];
    assign jimm       = {instr[31], instr[19:12], instr[20], instr[30:21]};

    // 写回 reg 的两种可能性
    wire [31:0] WD_from_alu = C;
    wire [31:0] WD_from_mem = dm_dout;

    //当前PC
    wire [31:0] pc_cur = {rom_addr, 2'b00};
    // PC+4
    wire [31:0] pc_plus4 = pc_cur + 32'd4;
    // lui 和 auipc单独判断
    wire is_lui, is_auipc;
    assign is_lui   = (Op == 7'b0110111);
    assign is_auipc = (Op == 7'b0010111);


    always @(*) begin
        if (is_lui) begin
        // LUI: 直接把 U-type 立即数写进 rd
            WD = imm_ext;  // imm_ext = {uimm, 12'b0}
        end
        else if (is_auipc) begin
            // AUIPC: PC + U-type 立即数
            WD = pc_cur + imm_ext;
        end
        else begin
            case (WDSel)
                2'b00: WD = WD_from_alu;   // 普通 R/I 指令
                2'b01: WD = WD_from_mem;   // load
                2'b10: WD = pc_plus4;      // JAL / JALR
                default: WD = WD_from_alu;
            endcase
        end
    end
    
    parameter LED_DATA_NUM = 19;

    assign A = RD1;
    assign B = ALUSrc ? imm_ext : RD2;
    assign write_addr = C[4:0]; // DM：32*8
    assign dm_din = RD2;

    wire Branch; //分支信号
    wire br_taken; //跳转类型
    // jal, jalr单独判断
    wire jal;   // rom_addr <= rom_addr + imm_ext[6:2];
    wire jalr;  // rom_addr <= ( (RD1 + imm_ext) >> 2 ) & 5'h1F;

    // test
    reg [63:0] LED_DATA[18:0];
    initial begin
        LED_DATA[0] = 64'hC6F6F6F0C6F6F6F0;
        LED_DATA[1] = 64'hF9F6F6CFF9F6F6CF;
        LED_DATA[2] = 64'hFFC6F0FFFFC6F0FF;
        LED_DATA[3] = 64'hFFC0FFFFFFC0FFFF;
        LED_DATA[4] = 64'hFFA3FFFFFFA3FFFF;
        LED_DATA[5] = 64'hFFFFA3FFFFFFA3FF;
        LED_DATA[6] = 64'hFFFF9CFFFFFF9CFF;
        LED_DATA[7] = 64'hFF9EBCFFFF9EBCFF;
        LED_DATA[8] = 64'hFF9CFFFFFF9CFFFF;
        LED_DATA[9] = 64'hFFC0FFFFFFC0FFFF;
        LED_DATA[10] = 64'hFFA3FFFFFFA3FFFF;
        LED_DATA[11] = 64'hFFA7B3FFFFA7B3FF;
        LED_DATA[12] = 64'hFFC6F0FFFFC6F0FF;
        LED_DATA[13] = 64'hF9F6F6CFF9F6F6CF;
        LED_DATA[14] = 64'h9EBEBEBC9EBEBEBC;
        LED_DATA[15] = 64'h2737373327373733;
        LED_DATA[16] = 64'h505454EC505454EC;
        LED_DATA[17] = 64'h744454F8744454F8;
        LED_DATA[18] = 64'h0062080000620800;
    end

    //例化
    dist_mem_gen_0 dmg(
        .a(rom_addr),
        .spo(instr)
    );

    RF U_RF(.clk(Clk_CPU),.rstn(rstn),
            .RFWr(RegWrite),
            .sw_i(sw_i),
            .A1(rs1),
            .A2(rs2),
            .A3(rd),
            .WD(WD),
            .RD1(RD1),
            .RD2(RD2)   
        );

    ALU U_ALU(
            .clk(Clk_CPU),.rstn(rstn),
            .sw_i(sw_i),
            .A(A),
            .B(B),
            .aluop(ALUOp),
            .C(C),
            .zero(zero)
            );
    DM U_DM(
            .sw_i(sw_i),
            .clk(Clk_CPU),
            .rstn(rstn),
            .DMWr(MemWrite),
            .addr(write_addr),
            .din(dm_din),
            .DMType(DMType[2:0]),
            .dout(dm_dout)
            );
    ctrl U_CTRL(
        .Op     (Op),
        .Funct7 (Funct7),
        .Funct3 (Funct3),
        .zero   (zero),
        .RegWrite (RegWrite),
        .MemWrite (MemWrite),
        .EXTOp    (EXTOp),
        .ALUOp    (ALUOp),
        .ALUSrc   (ALUSrc),
        .DMType   (DMType),
        .WDSel    (WDSel),
        .Branch   (Branch),
        .jal      (jal),
        .jalr     (jalr)
    );

    EXT U_EXT(
        .iimm_shamt (iimm_shamt),
        .iimm       (iimm),
        .simm       (simm),
        .bimm       (bimm),
        .uimm       (uimm),
        .jimm       (jimm),
        .EXTOp      (EXTOp),
        .immout     (imm_ext)
    );

    branch U_BRANCH(
        .rs1 (RD1),
        .rs2 (RD2),
        .funct3 (Funct3),
        .br_taken (br_taken)
    );

    // PC
    // imm_ext是EXT输出的32位地址偏移（B-type情况下已经处理为<<1）
    // ROM按32位指令寻址，将byte offset>>2得到word offset
    wire [4:0] pc_seq;
    wire [4:0] pc_br_off; //imm_ext[6:2]
    wire [4:0] pc_branch;

    assign pc_seq = rom_addr + 5'd1; //非跳转的下一条指令地址
    assign pc_br_off = imm_ext[6:2]; //计算偏移地址
    assign pc_branch = rom_addr + pc_br_off; //跳转的下一条指令地址

    //always块之后不能再对变量赋值
    always @(*) begin
        if (sw_i[0] == 0) begin
            case (sw_i[14:11])
                4'b1000: display_data = instr; 
                4'b0100: display_data = reg_data;
                4'b0010: display_data = alu_disp_data; 
                4'b0001: display_data = dmem_data;
                default: display_data = instr;
            endcase
        end else begin
            display_data = led_disp_data;
        end
    end

    always @(posedge Clk_CPU or negedge rstn) begin
        if (!rstn) begin
            rom_addr <= 5'd0;              
        end else begin
            if (Branch && br_taken) begin
                rom_addr <= pc_branch;
            end
            else if(jal)
                rom_addr <= rom_addr + imm_ext[6:2];
            else if(jalr)
                rom_addr <= ( (RD1 + imm_ext) >> 2 ) & 5'h1F;
            else
                rom_addr <= pc_seq;
        end
    end

    // wasted (test if you complete this project step by step)
    always @(posedge Clk_CPU or negedge rstn) begin
        if (!rstn) begin
            led_data_addr = 6'd0;
            led_disp_data = 64'b1;
            reg_addr = 1'b0;
            alu_addr = 1'b0;
            dm_addr = 1'b0;
        end else if (led_data_addr == LED_DATA_NUM) begin
            led_data_addr = 6'd0;
            led_disp_data = 64'b1;
        end else begin
            led_disp_data = LED_DATA[led_data_addr];
            led_data_addr = led_data_addr + 1'b1;

            if (sw_i[13]) begin     
                reg_addr = reg_addr + 1'b1; 
                reg_data = U_RF.rf[reg_addr];
            end
            if (sw_i[12]) begin
                alu_addr = alu_addr + 1'b1;
                case (alu_addr)
                    3'b001:alu_disp_data=A;
                    3'b010:alu_disp_data=B;
                    3'b011:alu_disp_data=C;
                    3'b100:alu_disp_data=zero;
                    default: alu_disp_data=32'hFFFFFFFF;
                endcase
            end
            if(sw_i[11]) begin
                dm_addr = dm_addr + 1'b1;
                dmem_data = {24'd0, U_DM.dmem[dm_addr]}; 
                if(dm_addr==DM_DATA_NUM-1) begin
                    dm_addr=5'd0;
                    dmem_data=32'hFFFFFFFF;
                end
            end
        end
    end

    seg7x16 u_seg7x16(
        .clk(clk),
        .rstn(rstn),
        .i_data(display_data),
        .disp_mode(sw_i[0]),
        .o_seg(disp_seg_o),
        .o_sel(disp_an_o)
    );

endmodule

// 语法规则：
// 4'b/o/d/h 几位几进制（默认32位位宽）
// 变量：寄存器/线网/参数
// reg类型数据只能在always和initial语句中赋值
// 时序逻辑（always中有时钟信号）：寄存器变量对应为触发器
// 组合逻辑（always中无时钟信号）：寄存器变量对应为硬连线
// assign给线网赋值（连线操作）
// 

// 移位运算：左移位宽增加，右移位宽不变
// 拼接运算符：{}
//
//always @(posedge Clk_CPU or negedge rstn) begin
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