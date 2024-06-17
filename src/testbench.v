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
    #100000 dump_mem = 1;
    #5 $finish();
  end

  Cpu cpu_inst (
      .clk (clk),
      .rstn(rstn),
      .dump_mem(dump_mem)
  );

endmodule
