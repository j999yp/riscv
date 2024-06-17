`timescale 1ns / 1ps
`include "macros.hv"

module Execute_Unit (
    // clock and rstn
    input clk,
    input rstn,
    // Decode Unit
    input [4:0] i_du_rs1,  // rs1 idx
    input [4:0] i_du_rs2,  // rs2 idx
    input [4:0] i_du_rd,  // rd idx
    // input [1:0] i_du_src1_type,
    input [1:0] i_du_src2_type,
    // input [1:0] i_du_src3_type,
    input [4:0] i_du_opcode,
    input [`XLEN-1:0] i_du_pc,
    input [`XLEN-1:0] i_du_imm,
    input i_du_branch_taken,
    output o_du_stall,
    output o_du_flush,
    input i_du_is_load,

    // Register File
    input [`XLEN-1:0] i_reg_data1,
    input [`XLEN-1:0] i_reg_data2,

    // Fetch Unit
    output o_fu_flush,
    output reg [`XLEN-1:0] o_fu_pc,
    input i_fu_sig_align_error,

    // Memory Access Unit
    output reg [`XLEN-1:0] o_mau_addr_r,
    output reg [1:0] o_mau_len_r,
    output reg o_mau_is_signed,
    output o_mau_read_en,

    output reg [`XLEN-1:0] o_mau_addr_w,
    output reg [`XLEN-1:0] o_mau_data_w,
    output reg [1:0] o_mau_len_w,
    output o_mau_write_en,

    output [4:0] o_mau_rd,
    output [`XLEN-1:0] o_mau_res,

    input [4:0] i_mau_bypass_reg_0,
    input [4:0] i_mau_bypass_reg_1,
    input [`XLEN-1:0] i_mau_bypass_data_0,
    input [`XLEN-1:0] i_mau_bypass_data_1,
    input [4:0] i_mau_reg_not_ready,
    input i_mau_sig_load_x0,

    // Write Back Unit
    input [4:0] i_wb_bypass_reg,
    input [`XLEN-1:0] i_wb_bypass_data
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

  reg [`XLEN-1:0] rs1_data_buffer, rs2_data_buffer, pc_buffer, imm_buffer;  // oprand
  reg [4:0] rd_buffer, rs1_buffer, rs2_buffer, opcode_buffer;
  reg [1:0] src2_type;
  reg branch_taken, should_branch, flush_flag, load_flag;
  reg [`XLEN-1:0] res;
  // read variables
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      rs1_buffer <= 0;
      rs1_data_buffer <= 0;
      rs2_buffer <= 0;
      rs2_data_buffer <= 0;
      pc_buffer <= 0;
      imm_buffer <= 0;
      rd_buffer <= 0;
      branch_taken <= 0;
      load_flag <= 0;
      src2_type <= src_zero;
      opcode_buffer <= op_nop;
      // flush_flag <= 0;
    end else begin
      if (flush_flag) begin  // insert a nop
        rs1_buffer <= 0;
        rs1_data_buffer <= 0;
        rs2_buffer <= 0;
        rs2_data_buffer <= 0;
        pc_buffer <= 0;
        imm_buffer <= 0;
        rd_buffer <= 0;
        branch_taken <= 0;
        load_flag <= 0;
        src2_type <= src_zero;
        opcode_buffer <= op_nop;
        // flush_flag <= 0;
      end else begin
        rs1_data_buffer <= (i_du_rs1 == 0 | o_du_stall) ? 0 : (i_du_rs1 == rd_buffer) ? res : (i_du_rs1 == i_mau_bypass_reg_0) ? i_mau_bypass_data_0 : (i_du_rs1 == i_mau_bypass_reg_1) ? i_mau_bypass_data_1 : (i_du_rs1 == i_wb_bypass_reg) ? i_wb_bypass_data : i_reg_data1;
        rs2_data_buffer <= (i_du_rs2 == 0 | o_du_stall) ? 0 : (i_du_rs2 == rd_buffer) ? res : (i_du_rs2 == i_mau_bypass_reg_0) ? i_mau_bypass_data_0 : (i_du_rs2 == i_mau_bypass_reg_1) ? i_mau_bypass_data_1 : (i_du_rs2 == i_wb_bypass_reg) ? i_wb_bypass_data : i_reg_data2;

        rs1_buffer <= o_du_stall ? 0 : i_du_rs1;
        rs2_buffer <= o_du_stall ? 0 : i_du_rs2;
        pc_buffer <= o_du_stall ? 0 : i_du_pc;
        imm_buffer <= o_du_stall ? 0 : i_du_imm;
        rd_buffer <= o_du_stall ? 0 : i_du_rd;
        opcode_buffer <= o_du_stall ? op_nop : i_du_opcode;
        src2_type <= o_du_stall ? src_zero : i_du_src2_type;
        branch_taken <= o_du_stall ? 0 : i_du_branch_taken;
        load_flag <= o_du_stall ? 0 : i_du_is_load;
      end
    end
  end

  // excute
  always @(*) begin
    case (opcode_buffer)
      op_add:
      if (src2_type == src_reg) res = rs1_data_buffer + rs2_data_buffer;
      else res = rs1_data_buffer + imm_buffer;
      op_sub: res = rs1_data_buffer - rs2_data_buffer;
      op_and:
      if (src2_type == src_reg) res = rs1_data_buffer & rs2_data_buffer;
      else res = rs1_data_buffer & imm_buffer;
      op_or:
      if (src2_type == src_reg) res = rs1_data_buffer | rs2_data_buffer;
      else res = rs1_data_buffer | imm_buffer;
      op_xor:
      if (src2_type == src_reg) res = rs1_data_buffer ^ rs2_data_buffer;
      else res = rs1_data_buffer ^ imm_buffer;
      op_slt:
      if (src2_type == src_reg)
        res = $signed(rs1_data_buffer) < $signed(rs2_data_buffer) ? 32'b1 : 32'b0;
      else res = $signed(rs1_data_buffer) < $signed(imm_buffer) ? 32'b1 : 32'b0;
      op_sltu:
      if (src2_type == src_reg) res = rs1_data_buffer < rs2_data_buffer ? 32'b1 : 32'b0;
      else res = rs1_data_buffer < imm_buffer ? 32'b1 : 32'b0;
      op_sll:
      if (src2_type == src_reg) res = rs1_data_buffer << (rs2_data_buffer & 32'b11111);
      else res = rs1_data_buffer << (imm_buffer & 32'b11111);
      op_srl:
      if (src2_type == src_reg) res = rs1_data_buffer >> (rs2_data_buffer & 32'b11111);
      else res = rs1_data_buffer >> (imm_buffer & 32'b11111);
      op_sra:
      if (src2_type == src_reg) res = $signed(rs1_data_buffer) >>> (rs2_data_buffer & 32'b11111);
      else res = $signed(rs1_data_buffer) >>> (imm_buffer & 32'b11111);
      op_jal: res = pc_buffer + 4;  // return addr
      op_jalr: begin
        o_fu_pc = (rs1_data_buffer + imm_buffer) & (~32'b1);
        flush_flag = 1;
        res = pc_buffer + 4;
      end
      op_beq, op_bne, op_blt, op_bge, op_bltu, op_bgeu: begin
        case (opcode_buffer)
          op_beq:  should_branch = rs1_data_buffer == rs2_data_buffer;
          op_bne:  should_branch = rs1_data_buffer != rs2_data_buffer;
          op_blt:  should_branch = $signed(rs1_data_buffer) < $signed(rs2_data_buffer);
          op_bge:  should_branch = $signed(rs1_data_buffer) >= $signed(rs2_data_buffer);
          op_bltu: should_branch = rs1_data_buffer < rs2_data_buffer;
          op_bgeu: should_branch = rs1_data_buffer >= rs2_data_buffer;
        endcase
        if (should_branch & !branch_taken) begin
          o_fu_pc = pc_buffer + imm_buffer;
          flush_flag = 1;
        end else if (!should_branch & branch_taken) begin
          o_fu_pc = pc_buffer + 4;
          flush_flag = 1;
        end
      end
      op_lui: res = imm_buffer;
      op_auipc: res = pc_buffer + imm_buffer;
      op_lb, op_lh, op_lw, op_lbu, op_lhu: begin
        o_mau_addr_r = rs1_data_buffer + imm_buffer;
        o_mau_len_r = (opcode_buffer == op_lb | opcode_buffer == op_lbu) ? 0 : (opcode_buffer == op_lh | opcode_buffer == op_lhu)? 1 : 2;
        o_mau_is_signed = (opcode_buffer == op_lb | opcode_buffer == op_lh | opcode_buffer == op_lw) ? 1 : 0;
      end
      op_sb, op_sh, op_sw: begin
        o_mau_addr_w = rs1_data_buffer + imm_buffer;
        o_mau_data_w = rs2_data_buffer;
        o_mau_len_w  = opcode_buffer == op_sb ? 0 : opcode_buffer == op_sh ? 1 : 2;
      end
      default: begin
        res = 0;
        flush_flag = 0;
      end
    endcase
  end

  assign o_fu_flush = flush_flag;
  assign o_du_flush = flush_flag;
  assign o_mau_read_en = opcode_buffer == op_lb | opcode_buffer == op_lh | opcode_buffer == op_lw | opcode_buffer == op_lbu | opcode_buffer == op_lhu;
  assign o_mau_write_en = opcode_buffer == op_sb | opcode_buffer == op_sh | opcode_buffer == op_sw;
  assign o_mau_rd = rd_buffer;
  assign o_mau_res = res;
  assign o_du_stall = (i_mau_reg_not_ready == i_du_rs1 & i_mau_reg_not_ready != 0) | (i_mau_reg_not_ready == i_du_rs2 & i_mau_reg_not_ready != 0) |
   i_fu_sig_align_error | i_mau_sig_load_x0 | (load_flag & (rd_buffer == i_du_rs1 | rd_buffer == i_du_rs2));

endmodule
