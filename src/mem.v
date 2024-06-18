`timescale 1ps / 1ps
`include "macros.hv"

module mem (
    input clk,
    // sync inst read
    input [`XLEN-1:0] i_inst_addr,
    output reg [`ILEN-1:0] inst,
    output reg [`XLEN-1:0] o_inst_addr,
    // sync data read, require 2 cycles to read. always return 32 bits
    input data_r_en,
    input [`XLEN-1:0] data_addr_r,
    output reg [`XLEN-1:0] data_r,
    // sync data write
    input data_w_en,
    input [`XLEN-1:0] data_addr_w,
    input [`XLEN-1:0] data_w,
    input [1:0] data_len_w,

    // for testbench
    input dump_mem
);

  `define MEM_LEN 2097152 // 21 bit addr space
  reg [7:0] mem[`MEM_LEN-1:0];
  reg [31:0] tmp_mem[`MEM_LEN/4-1:0];

  reg [31:0] i;
  initial begin
    for (i = 0; i < `MEM_LEN / 4; i = i + 1) begin
      tmp_mem[i] = 0;
    end
    $readmemh("data.mem", tmp_mem, 0, `MEM_LEN / 4 - 1);
    for (i = 0; i < `MEM_LEN / 4; i = i + 1) begin
      {mem[i*4+3], mem[i*4+2], mem[i*4+1], mem[i*4]} = tmp_mem[i];
    end
  end

  always @(posedge clk) begin
    inst <= {mem[i_inst_addr+3], mem[i_inst_addr+2], mem[i_inst_addr+1], mem[i_inst_addr]};
    o_inst_addr <= i_inst_addr;

    if (data_r_en) begin
      data_r <= {mem[data_addr_r+3], mem[data_addr_r+2], mem[data_addr_r+1], mem[data_addr_r]};
    end

    if (data_w_en) begin
      // $display("addr:%h, data:%h, len:%d", data_addr_w, data_w, data_len_w);
      case (data_len_w)
        0: begin
          mem[data_addr_w] <= data_w[7:0];
        end
        1: begin
          mem[data_addr_w+1] <= data_w[15:8];
          mem[data_addr_w]   <= data_w[7:0];
        end
        2: begin
          mem[data_addr_w+3] <= data_w[31:24];
          mem[data_addr_w+2] <= data_w[23:16];
          mem[data_addr_w+1] <= data_w[15:8];
          mem[data_addr_w]   <= data_w[7:0];
        end
      endcase
    end
  end

  // for testbench
  always @(dump_mem) begin
    if (dump_mem) begin
      for (i = 0; i < `MEM_LEN / 4; i = i + 1) begin
        tmp_mem[i] = {mem[i*4+3], mem[i*4+2], mem[i*4+1], mem[i*4]};
      end
      $writememh("res.mem", tmp_mem);
    end
  end

endmodule
