`timescale 1ps / 1ps
`include "macros.hv"

module testbench ();
  reg clk;
  reg rstn;
  reg dump_mem;

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;
  end

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rstn = 0;
    dump_mem = 0;
    #1 rstn = 1;
    #200000 dump_mem = 1;
    #5 $finish();
  end

  Cpu cpu_inst (
      .clk(clk),
      .rstn(rstn),
      .pc(pc),
      .inst(inst),
      .pc_copy(pc_copy),
      .read_en(read_en),
      .read_addr(read_addr),
      .read_data(read_data),
      .write_en(write_en),
      .write_addr(write_addr),
      .write_data(write_data),
      .write_len(write_len)
  );

  wire [31:0] pc, inst, pc_copy, read_addr, read_data, write_addr, write_data;
  wire [1:0] write_len;
  wire read_en, write_en;

  mem mem_inst (
      .clk(clk),
      .i_inst_addr(pc),
      .inst(inst),
      .o_inst_addr(pc_copy),
      .data_r_en(read_en),
      .data_addr_r(read_addr),
      .data_r(read_data),
      .data_w_en(write_en),
      .data_addr_w(write_addr),
      .data_w(write_data),
      .data_len_w(write_len),
      .dump_mem(dump_mem)
  );



endmodule
