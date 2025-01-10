`timescale 1ns / 1ps

module sigma_delta_trunc (
    input wire reset,
    input wire clk,
    input wire enable_3M,
    input logic signed [33:0] input_23_decimals_10_integer,
    output logic signed [10:0] output_10_integer
);

  // SIGMA-DELTA for quantization noise shaping

  `define N_DECIMALS_SD 23

  logic signed [`N_DECIMALS_SD:0] decimals;  // Not -1 because of sign
  logic signed [`N_DECIMALS_SD+10:0] h;
  logic signed [`N_DECIMALS_SD+1:0] l;
  logic signed [`N_DECIMALS_SD:0] k;
  logic signed [`N_DECIMALS_SD:0] j;

  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      k <= 0;
      j <= 0;
    end else begin
      if (enable_3M) begin
        j <= decimals;
        k <= j;
      end
    end
  end

  assign decimals = {1'b0, h[`N_DECIMALS_SD - 1 : 0]};

  always_comb begin
    l = (j << 1) - k;
    h = input_23_decimals_10_integer + l;
  end

  assign output_10_integer = h[`N_DECIMALS_SD+10:`N_DECIMALS_SD];

endmodule
