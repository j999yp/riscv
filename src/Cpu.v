`timescale 1ps / 1ps
`include "macros.hv"

module Cpu (
    input clk,
    input rstn,
    output [`XLEN-1:0] pc,
    input [`ILEN-1:0] inst,
    input [`XLEN-1:0] pc_copy,
    output read_en,
    output [`XLEN-1:0] read_addr,
    input [`XLEN-1:0] read_data,
    output write_en,
    output [`XLEN-1:0] write_addr,
    output [`XLEN-1:0] write_data,
    output [1:0] write_len
);

  wire [31:0] fu_du_inst, fu_du_addr, exec_fu_pc, du_exec_pc, du_exec_imm, reg_exec_data1, reg_exec_data2, exec_mau_addr_r, exec_mau_addr_w, exec_mau_data_w, exec_mau_res, mau_exec_bypass_data, wb_exec_res, mau_wb_res, wb_reg_data;

  wire [4:0] du_reg_rs1, du_reg_rs2, du_exec_rs1, du_exec_rs2, du_exec_rd, du_exec_opcode, exec_mau_rd, mau_exec_bypass_reg, wb_exec_bypass_reg, mau_wb_rd, wb_reg_rd;

  wire [1:0] du_exec_src2_type, exec_mau_len_r, exec_mau_len_w;

  wire fu_du_branch_taken,du_fu_stall,exec_fu_flush,fu_exec_align_error,exec_du_stall,exec_du_flush,du_exec_branch_taken,du_exec_is_load,exec_mau_is_signed,exec_mau_read_en,exec_mau_write_en,mau_exec_sig_load_x0,wb_reg_write_en;

  Fetch_Unit fetch_unit_inst (
      .clk(clk),
      .rstn(rstn),
      .o_mem_pc(pc),
      .i_mem_inst(inst),
      .i_mem_addr(pc_copy),
      .o_du_inst(fu_du_inst),
      .o_du_addr(fu_du_addr),
      .o_du_branch_taken(fu_du_branch_taken),
      .i_du_stall(du_fu_stall),
      .i_exec_flush(exec_fu_flush),
      .i_exec_pc(exec_fu_pc),
      .o_exec_sig_align_error(fu_exec_align_error)
  );

  Decode_Unit decode_unit_inst (
      .clk(clk),
      .rstn(rstn),
      .i_fu_inst(fu_du_inst),
      .i_fu_addr(fu_du_addr),
      .i_fu_branch_taken(fu_du_branch_taken),
      .o_fu_stall(du_fu_stall),
      .o_reg_rs1(du_reg_rs1),
      .o_reg_rs2(du_reg_rs2),
      .i_exec_stall(exec_du_stall),
      .i_exec_flush(exec_du_flush),
      .o_exec_branch_taken(du_exec_branch_taken),
      .o_exec_rs1(du_exec_rs1),
      .o_exec_rs2(du_exec_rs2),
      .o_exec_rd(du_exec_rd),
      .o_exec_src2_type(du_exec_src2_type),
      .o_exec_opcode(du_exec_opcode),
      .o_exec_pc(du_exec_pc),
      .o_exec_imm(du_exec_imm),
      .o_exec_is_load(du_exec_is_load)
  );

  Execute_Unit execute_unit_inst (
      .clk(clk),
      .rstn(rstn),
      .i_du_rs1(du_exec_rs1),
      .i_du_rs2(du_exec_rs2),
      .i_du_rd(du_exec_rd),
      .i_du_src2_type(du_exec_src2_type),
      .i_du_opcode(du_exec_opcode),
      .i_du_pc(du_exec_pc),
      .i_du_imm(du_exec_imm),
      .i_du_branch_taken(du_exec_branch_taken),
      .o_du_stall(exec_du_stall),
      .o_du_flush(exec_du_flush),
      .i_reg_data1(reg_exec_data1),
      .i_reg_data2(reg_exec_data2),
      .o_fu_flush(exec_fu_flush),
      .o_fu_pc(exec_fu_pc),
      .i_fu_sig_align_error(fu_exec_align_error),
      .o_mau_addr_r(exec_mau_addr_r),
      .o_mau_len_r(exec_mau_len_r),
      .o_mau_is_signed(exec_mau_is_signed),
      .o_mau_read_en(exec_mau_read_en),
      .o_mau_addr_w(exec_mau_addr_w),
      .o_mau_data_w(exec_mau_data_w),
      .o_mau_len_w(exec_mau_len_w),
      .o_mau_write_en(exec_mau_write_en),
      .o_mau_rd(exec_mau_rd),
      .o_mau_res(exec_mau_res),
      .i_mau_bypass_reg(mau_exec_bypass_reg),
      .i_mau_bypass_data(mau_exec_bypass_data),
      .i_mau_sig_load_x0(mau_exec_sig_load_x0),
      .i_wb_bypass_reg(wb_exec_bypass_reg),
      .i_wb_bypass_data(wb_exec_res),
      .i_du_is_load(du_exec_is_load)
  );

  Mem_Access_Unit mem_access_unit_inst (
      .clk(clk),
      .rstn(rstn),
      .i_exec_addr_r(exec_mau_addr_r),
      .i_exec_len_r(exec_mau_len_r),
      .i_exec_is_signed(exec_mau_is_signed),
      .i_exec_read_en(exec_mau_read_en),
      .i_exec_addr_w(exec_mau_addr_w),
      .i_exec_data_w(exec_mau_data_w),
      .i_exec_len_w(exec_mau_len_w),
      .i_exec_write_en(exec_mau_write_en),
      .i_exec_rd(exec_mau_rd),
      .i_exec_res(exec_mau_res),
      .o_exec_bypass_reg(mau_exec_bypass_reg),
      .o_exec_bypass_data(mau_exec_bypass_data),
      .o_exec_sig_load_x0(mau_exec_sig_load_x0),
      .o_mem_addr_r(read_addr),
      .i_mem_data_r(read_data),
      .o_mem_addr_w(write_addr),
      .o_mem_data_w(write_data),
      .o_mem_len_w(write_len),
      .o_mem_write_en(write_en),
      .o_wb_rd(mau_wb_rd),
      .o_wb_res(mau_wb_res),
      .o_mem_read_en(read_en)
  );

  Write_Back_Unit write_back_unit_inst (
      .clk(clk),
      .rstn(rstn),
      .i_mau_rd(mau_wb_rd),
      .i_mau_res(mau_wb_res),
      .o_reg_write_en(wb_reg_write_en),
      .o_reg_addr(wb_reg_rd),
      .o_reg_data(wb_reg_data),
      .o_exec_bypass_data(wb_exec_res),
      .o_exec_bypass_reg(wb_exec_bypass_reg)
  );

  Register_File register_file_inst (
      .clk(clk),
      .rstn(rstn),
      .i_du_rs1(du_reg_rs1),
      .i_du_rs2(du_reg_rs2),
      .o_exec_data1(reg_exec_data1),
      .o_exec_data2(reg_exec_data2),
      .i_wb_write_en(wb_reg_write_en),
      .i_wb_rd(wb_reg_rd),
      .i_wb_data(wb_reg_data)
  );

endmodule
