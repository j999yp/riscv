`timescale 1ns / 1ps
`include "macros.hv"

module Fetch_Unit (
    // clock and reset
    input clk,
    input rstn,
    // mem
    output reg [`XLEN-1:0] o_mem_pc,
    input [`ILEN-1:0] i_mem_inst,
    input [`XLEN-1:0] i_mem_addr,
    // Decode Unit
    output reg [`ILEN-1:0] o_du_inst,
    output reg [`XLEN-1:0] o_du_addr,
    output reg o_du_branch_taken,
    input i_du_stall,
    // Execute Unit
    input i_exec_flush,
    input [`XLEN-1:0] i_exec_pc,
    output reg o_exec_sig_align_error
);

  // pc declaration
  reg [`XLEN-1:0] pc = `init_pc;
  reg [`XLEN-1:0] pc_add_4;
  reg [`XLEN-1:0] branch_pc;

  // instruction buffer declaration
  reg [`ILEN-1:0] inst_buf[1:0];
  initial begin
    inst_buf[0] = `nop;
    inst_buf[1] = `nop;
  end

  // addr buffer declaration
  reg [`XLEN-1:0] addr_buf[1:0];
  initial begin
    addr_buf[0] = `invalid_pc;
    addr_buf[1] = `invalid_pc;
  end

  // branch status buffer
  reg branch_taken_buf[1:0];
  initial begin
    branch_taken_buf[0] = 0;
    branch_taken_buf[1] = 0;
  end

  // assign to output
  always @(*) begin
    o_mem_pc = pc;
    o_du_inst = inst_buf[1];
    o_du_addr = addr_buf[1];
    pc_add_4 = pc + `XLEN'd4;
    o_du_branch_taken = branch_taken_buf[1];
  end

  // branch prediction
  reg [`XLEN-1:0] imm_JAL;
  reg is_JAL;
  reg [`XLEN-1:0] imm_B;
  reg is_Branch;
  reg [6:0] opcode;
  reg branch_taken;
  always @(*) begin
    opcode = inst_buf[0][6:0];

    imm_JAL = {
      {(`XLEN - 20) {inst_buf[0][31]}},
      inst_buf[0][19:12],
      inst_buf[0][20],
      inst_buf[0][30:21],
      1'b0
    };
    is_JAL = opcode == 7'b1101111;

    imm_B = {
      {(`XLEN - 12) {inst_buf[0][31]}}, inst_buf[0][7], inst_buf[0][30:25], inst_buf[0][11:8], 1'b0
    };
    is_Branch = opcode == 7'b1100011;

    branch_taken = is_JAL | (is_Branch & imm_B[31]);
    branch_pc = is_JAL ? addr_buf[0] + imm_JAL : is_Branch ? addr_buf[0] + imm_B : 0;
  end

  // pc logic
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      pc <= `init_pc;
      addr_buf[0] <= `invalid_pc;
      addr_buf[1] <= `invalid_pc;
      o_exec_sig_align_error <= 0;
    end else begin
      if (i_exec_flush) begin
        addr_buf[0] <= `invalid_pc;
        addr_buf[1] <= `invalid_pc;

        if (i_exec_pc[1:0] != 2'b0) begin
          pc <= `trap;
          o_exec_sig_align_error <= 1;
        end else begin
          pc <= i_exec_pc;
          o_exec_sig_align_error <= 0;
        end
      end else if (branch_taken) begin
        pc <= branch_pc;
        addr_buf[1] <= addr_buf[0];
        addr_buf[0] <= `invalid_pc;
      end else if (i_du_stall) begin
        pc <= pc;
        addr_buf[0] <= addr_buf[0];
        addr_buf[1] <= addr_buf[1];
      end else begin
        pc <= pc_add_4;
        addr_buf[1] <= addr_buf[0];
        addr_buf[0] <= i_mem_addr;
      end
    end
  end

  // instruction buffer logic
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      inst_buf[0] <= `nop;
      inst_buf[1] <= `nop;
    end else begin
      if (i_exec_flush) begin
        inst_buf[0] <= `nop;
        inst_buf[1] <= `nop;
      end else if (branch_taken) begin
        inst_buf[1] <= inst_buf[0];
        inst_buf[0] <= `nop;
      end else if (i_du_stall) begin
        inst_buf[0] <= inst_buf[0];
        inst_buf[1] <= inst_buf[1];
      end else begin
        inst_buf[1] <= inst_buf[0];
        inst_buf[0] <= i_mem_inst;
      end
    end
  end

  // branch buffer logic
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      branch_taken_buf[0] <= 0;
      branch_taken_buf[1] <= 0;
    end else begin
      if (i_exec_flush) begin
        branch_taken_buf[0] <= 0;
        branch_taken_buf[1] <= 0;
      end else if (i_du_stall) begin
        branch_taken_buf[0] <= branch_taken_buf[0];
        branch_taken_buf[1] <= branch_taken_buf[1];
      end else begin
        branch_taken_buf[1] <= branch_taken_buf[0];
        branch_taken_buf[0] <= branch_taken;
      end
    end
  end

endmodule
