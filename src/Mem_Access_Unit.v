`timescale 1ns / 1ps
`include "macros.hv"
module Mem_Access_Unit (
    // clock and rstn
    input clk,
    input rstn,

    // Execute Unit
    input [`XLEN-1:0] i_exec_addr_r,
    input [1:0] i_exec_len_r,
    input i_exec_is_signed,
    input i_exec_read_en,

    input [`XLEN-1:0] i_exec_addr_w,
    input [`XLEN-1:0] i_exec_data_w,
    input [1:0] i_exec_len_w,
    input i_exec_write_en,

    input [4:0] i_exec_rd,
    input [`XLEN-1:0] i_exec_res,

    output [4:0] o_exec_bypass_reg_0,
    output [4:0] o_exec_bypass_reg_1,
    output [`XLEN-1:0] o_exec_bypass_data_0,
    output [`XLEN-1:0] o_exec_bypass_data_1,
    output [4:0] o_exec_reg_not_ready,
    output o_exec_sig_load_x0,

    // mem
    output [`XLEN-1:0] o_mem_addr_r,
    input  [`XLEN-1:0] i_mem_data_r,

    output [`XLEN-1:0] o_mem_addr_w,
    output [`XLEN-1:0] o_mem_data_w,
    output [1:0] o_mem_len_w,
    output o_mem_write_en,

    // Write Back Unit
    output reg [4:0] o_wb_rd,
    output reg [`XLEN-1:0] o_wb_res
);
  reg [4:0] rd_buffer[1:0];
  reg [`XLEN-1:0] res_buffer[1:0];
  reg [1:0] len_r_buffer[1:0];
  reg is_signed_buffer[1:0];
  reg read_en_buffer[1:0];
  reg write_en_buffer[1:0];

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      rd_buffer[0] <= 0;
      rd_buffer[1] <= 0;
      res_buffer[0] <= 0;
      res_buffer[1] <= 0;
      len_r_buffer[0] <= 0;
      len_r_buffer[1] <= 0;
      is_signed_buffer[0] <= 0;
      is_signed_buffer[1] <= 0;
      read_en_buffer[0] <= 0;
      read_en_buffer[1] <= 0;
      write_en_buffer[0] <= 0;
      write_en_buffer[1] <= 0;
    end else begin
      rd_buffer[0] <= i_exec_rd;
      rd_buffer[1] <= rd_buffer[0];
      res_buffer[0] <= i_exec_res;
      res_buffer[1] <= res_buffer[0];
      len_r_buffer[0] <= i_exec_len_r;
      len_r_buffer[1] <= len_r_buffer[0];
      is_signed_buffer[0] <= i_exec_is_signed;
      is_signed_buffer[1] <= is_signed_buffer[0];
      read_en_buffer[0] <= i_exec_read_en;
      read_en_buffer[1] <= read_en_buffer[0];
      write_en_buffer[0] <= i_exec_write_en;
      write_en_buffer[1] <= write_en_buffer[0];
    end
  end

  assign o_mem_addr_r = i_exec_addr_r;
  assign o_mem_addr_w = i_exec_addr_w;
  assign o_mem_data_w = i_exec_data_w;
  assign o_mem_len_w = i_exec_len_w;
  assign o_mem_write_en = i_exec_write_en;
  assign o_exec_bypass_reg_0 = rd_buffer[0];
  assign o_exec_bypass_reg_1 = o_wb_rd;
  assign o_exec_bypass_data_0 = res_buffer[0];
  assign o_exec_bypass_data_1 = o_wb_res;
  assign o_exec_sig_load_x0 = i_exec_read_en & i_exec_rd == 0;
  assign o_exec_reg_not_ready = rd_buffer[0] & {5{read_en_buffer[0]}};

  always @(*) begin
    if (read_en_buffer[1]) begin
      o_wb_rd = rd_buffer[1];
      case (len_r_buffer[1])
        0:  // byte
        case (is_signed_buffer[1])
          1: o_wb_res = {{24{i_mem_data_r[7]}}, i_mem_data_r[7:0]};
          0: o_wb_res = {24'b0, i_mem_data_r[7:0]};
        endcase
        1:  // half word
        case (is_signed_buffer[1])
          1: o_wb_res = {{16{i_mem_data_r[15]}}, i_mem_data_r[15:0]};
          0: o_wb_res = {16'b0, i_mem_data_r[15:0]};
        endcase
        2:  // word
        o_wb_res = i_mem_data_r;
      endcase
    end else if (write_en_buffer[1]) begin
      o_wb_rd  = 0;
      o_wb_res = 0;
    end else begin
      o_wb_rd  = rd_buffer[1];
      o_wb_res = res_buffer[1];
    end
  end

endmodule
