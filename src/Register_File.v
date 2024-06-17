`timescale 1ns / 1ps
`include "macros.hv"

module Register_File (
    // clock and reset
    input clk,
    input rstn,
    // async read
    input [4:0] i_du_rs1,
    input [4:0] i_du_rs2,
    output [`XLEN-1:0] o_exec_data1,
    output [`XLEN-1:0] o_exec_data2,
    // sync write
    input i_wb_write_en,
    input [4:0] i_wb_rd,
    input [`XLEN-1:0] i_wb_data
);
  integer i;
  reg [`XLEN-1:0] GPRs[31:0];

  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      GPRs[i] = 32'b0;
    end
  end

  assign o_exec_data1 = GPRs[i_du_rs1];
  assign o_exec_data2 = GPRs[i_du_rs2];

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      for (i = 1; i < 32; i = i + 1) begin
        GPRs[i] <= 32'b0;
      end
    end else begin
      if (i_wb_write_en) begin
        GPRs[i_wb_rd] <= i_wb_data;
      end
    end
  end
endmodule
