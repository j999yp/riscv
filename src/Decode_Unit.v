`timescale 1ns / 1ps
`include "macros.hv"

module Decode_Unit (
    // clock and reset
    input clk,
    input rstn,

    // Fetch Unit
    input [`ILEN-1:0] i_fu_inst,
    input [`XLEN-1:0] i_fu_addr,
    input i_fu_branch_taken,
    output reg o_fu_stall,

    // Register File
    output reg [4:0] o_reg_rs1,
    output reg [4:0] o_reg_rs2,

    // Execute Unit
    input i_exec_stall,
    input i_exec_flush,
    output reg o_exec_branch_taken,
    output reg [4:0] o_exec_rs1,
    output reg [4:0] o_exec_rs2,
    output reg [4:0] o_exec_rd,
    // output reg [1:0] o_exec_src1_type,
    output reg [1:0] o_exec_src2_type,
    // output reg [1:0] o_exec_src3_type,
    output reg [4:0] o_exec_opcode,
    output reg [`XLEN-1:0] o_exec_pc,
    output reg [`XLEN-1:0] o_exec_imm,
    output reg o_exec_is_load

);
  parameter src_imm = 0, src_reg = 1, src_pc = 2, src_zero = 3;
  parameter op_add = 0, op_sub = 1,  // math
  op_and = 2, op_or = 3, op_xor = 4,  // logical
  op_slt = 5, op_sltu = 6,  // comparison
  op_sll = 7, op_srl = 8, op_sra = 9,  // shift
  op_jal = 10, op_jalr = 11,  // jump
  op_beq = 12, op_bne = 13, op_blt = 14, op_bge = 15, op_bltu = 16, op_bgeu = 17,  // branch
  op_lui = 18, op_auipc = 19,  // U-type
  op_lb = 20, op_lh = 21, op_lw = 22, op_lbu = 23, op_lhu = 24,  // load
  op_sb = 25, op_sh = 26, op_sw = 27,  // store
  op_nop = 31;

  // data buffer
  reg [`ILEN-1:0] inst_buf;
  reg [`XLEN-1:0] addr_buf;

  // obtain data from Fetch Unit
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      inst_buf <= `nop;
      addr_buf <= `invalid_pc;
    end else begin
      if (i_exec_flush) begin
        inst_buf <= `nop;
        addr_buf <= `invalid_pc;
      end else if (i_exec_stall) begin
        inst_buf <= inst_buf;
        addr_buf <= addr_buf;
      end else begin
        inst_buf <= i_fu_inst;
        addr_buf <= i_fu_addr;
      end
    end
  end

  // info extraction
  wire [6:0] funct7;
  wire [4:0] rs2;
  wire [4:0] rs1;
  wire [2:0] funct3;
  wire [4:0] rd;
  wire [6:0] opcode;

  assign funct7 = inst_buf[31:25];
  assign rs2 = inst_buf[24:20];
  assign rs1 = inst_buf[19:15];
  assign funct3 = inst_buf[14:12];
  assign rd = inst_buf[11:7];
  assign opcode = inst_buf[6:0];


  // create imm
  reg [31:0] imm_I, imm_S, imm_B, imm_U, imm_J;
  always @(*) begin
    imm_I = {{21{inst_buf[31]}}, inst_buf[30:20]};
    imm_S = {{21{inst_buf[31]}}, inst_buf[30:25], inst_buf[11:7]};
    imm_B = {{20{inst_buf[31]}}, inst_buf[7], inst_buf[30:25], inst_buf[11:8], 1'b0};
    imm_U = {inst_buf[31:12], 12'b0};
    imm_J = {{12{inst_buf[31]}}, inst_buf[19:12], inst_buf[20], inst_buf[30:21], 1'b0};
  end

  // function type
  reg is_R_type, is_I_type, is_S_type, is_B_type, is_U_type, is_J_type;
  always @(*) begin
    is_R_type = opcode == `OP;
    is_I_type = opcode == `OP_IMM | opcode == `JALR | opcode == `LOAD;
    is_S_type = opcode == `STORE;
    is_B_type = opcode == `BRANCH;
    is_U_type = opcode == `LUI | opcode == `AUIPC;
    is_J_type = opcode == `JAL;
  end

  // output mapping
  always @(*) begin
    o_fu_stall = i_exec_stall;
    o_reg_rs1 = rs1;
    o_reg_rs2 = rs2;

    o_exec_branch_taken = i_fu_branch_taken;
    o_exec_rs1 = rs1;
    o_exec_rs2 = rs2;
    o_exec_rd = (is_B_type | is_S_type) ? 0 : rd;

    o_exec_pc = addr_buf;
    o_exec_imm = is_I_type ? imm_I : is_S_type ? imm_S : is_B_type ? imm_B : is_U_type ? imm_U : is_J_type ? imm_J : 32'b0;
    o_exec_is_load = opcode == `LOAD;
  end

  // data type
  always @(*) begin
    if (is_R_type) begin
      //   o_exec_src1_type = src_reg;
      o_exec_src2_type = src_reg;
      //   o_exec_src3_type = src_zero;
    end else if (is_I_type) begin
      //   o_exec_src1_type = src_reg;
      o_exec_src2_type = src_imm;
      //   o_exec_src3_type = src_zero;
    end else if (is_S_type) begin
      //   o_exec_src1_type = src_reg;
      o_exec_src2_type = src_reg;
      //   o_exec_src3_type = src_imm;
    end else if (is_B_type) begin
      //   o_exec_src1_type = src_reg;
      o_exec_src2_type = src_reg;
      //   o_exec_src3_type = src_imm;
    end else if (is_U_type) begin
      //   o_exec_src1_type = src_pc;
      o_exec_src2_type = src_imm;
      //   o_exec_src3_type = src_zero;
    end else if (is_J_type) begin
      //   o_exec_src1_type = src_pc;
      o_exec_src2_type = src_imm;
      //   o_exec_src3_type = src_zero;
    end else begin  //? system fence etc. as nop
      //   o_exec_src1_type = src_reg;
      o_exec_src2_type = src_imm;
      //   o_exec_src3_type = src_zero;
    end
  end

  // actual decode
  always @(*) begin
    if (opcode == `LUI) begin  // LUI
      o_exec_opcode = op_lui;
    end else if (opcode == `AUIPC) begin  // AUIPC
      o_exec_opcode = op_auipc;
    end else if (opcode == `JAL) begin  // JAL
      o_exec_opcode = op_jal;
    end else if (opcode == `JALR) begin  // JALR
      o_exec_opcode = op_jalr;
    end else if (opcode == `BRANCH) begin  // BRANCH
      case (funct3)
        3'b000:  o_exec_opcode = op_beq;
        3'b001:  o_exec_opcode = op_bne;
        3'b100:  o_exec_opcode = op_blt;
        3'b101:  o_exec_opcode = op_bge;
        3'b110:  o_exec_opcode = op_bltu;
        3'b111:  o_exec_opcode = op_bgeu;
        default: o_exec_opcode = op_nop;
      endcase
    end else if (opcode == `LOAD) begin  // LOAD
      case (funct3)
        3'b000:  o_exec_opcode = op_lb;
        3'b001:  o_exec_opcode = op_lh;
        3'b010:  o_exec_opcode = op_lw;
        3'b100:  o_exec_opcode = op_lbu;
        3'b101:  o_exec_opcode = op_lhu;
        default: o_exec_opcode = op_nop;
      endcase
    end else if (opcode == `STORE) begin  // STORE
      case (funct3)
        3'b000:  o_exec_opcode = op_sb;
        3'b001:  o_exec_opcode = op_sh;
        3'b010:  o_exec_opcode = op_sw;
        default: o_exec_opcode = op_nop;
      endcase
    end else if (opcode == `OP_IMM | opcode == `OP) begin  // OP-IMM and OP
      case (funct3)
        3'b000:
        if (opcode == `OP & funct7[5] == 1) o_exec_opcode = op_sub;
        else o_exec_opcode = op_add;
        3'b010: o_exec_opcode = op_slt;
        3'b011: o_exec_opcode = op_sltu;
        3'b100: o_exec_opcode = op_xor;
        3'b110: o_exec_opcode = op_or;
        3'b111: o_exec_opcode = op_and;
        3'b001: o_exec_opcode = op_sll;
        3'b101:
        case (funct7[5])
          0: o_exec_opcode = op_srl;
          1: o_exec_opcode = op_sra;
        endcase
      endcase
    end else begin
      o_exec_opcode = op_nop;
    end
  end

endmodule
