`timescale 1ns / 1ps
`include "macros.hv"

module Write_Back_Unit (
    // clock and rstn
    input clk,
    input rstn,

    // Mem Access Unit
    input [4:0] i_mau_rd,
    input [`XLEN-1:0] i_mau_res,

    // Register File
    output o_reg_write_en,
    output [4:0] o_reg_addr,
    output [`XLEN-1:0] o_reg_data,

    // Execute Unit
    output [`XLEN-1:0] o_exec_bypass_data,
    output [4:0] o_exec_bypass_reg
);

  reg [4:0] addr_buffer;
  reg [`XLEN-1:0] data_buffer;

  always @(posedge clk) begin
    if (!rstn) begin
      addr_buffer <= 0;
      data_buffer <= 0;
    end else begin
      addr_buffer <= i_mau_rd;
      data_buffer <= i_mau_res;
    end
  end

  assign o_reg_write_en = addr_buffer != 0;
  assign o_reg_addr = addr_buffer;
  assign o_reg_data = data_buffer;
  assign o_exec_bypass_reg = addr_buffer;
  assign o_exec_bypass_data = data_buffer;

endmodule
