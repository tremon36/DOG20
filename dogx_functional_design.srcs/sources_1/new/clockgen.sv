`timescale 1ns / 1ps

module clockgen (
    input  wire CLK_24M,
    input  wire reset,
    output wire enable_3M
);

  logic [2:0] count;
  logic enable_3M_i;
  assign enable_3M = enable_3M_i;

  always_ff @(posedge CLK_24M or negedge reset) begin
    if (!reset) count <= 0;
    else count <= count + 1;
  end

  always_comb begin
    enable_3M_i = count == 0;
  end


endmodule
