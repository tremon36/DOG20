
`define N_DECIMALS 23

module dc_filter (
    input wire reset,
    input wire CLK_24M,
    input wire enable_3M,
    input wire [8:0] c_data,
    output logic [`N_DECIMALS+8:0] filter_out
);

  // FILTER
  // d is the otuput of filter

  logic signed [8:0] b;
  logic signed [8:0] c;
  logic signed [`N_DECIMALS+8:0] d;
  logic signed [`N_DECIMALS+8:0] e;
  logic signed [`N_DECIMALS+8:0] e_shifted;
  logic signed [`N_DECIMALS+8:0] g;

  always_ff @(posedge CLK_24M or negedge reset) begin
    if (!reset) begin
      b <= 0;
      e <= 0;
    end else begin
      if (enable_3M) begin
        b <= c_data;
        e <= d;
      end
    end
  end

  always_comb begin
    c = c_data - b;
    e_shifted = e >>> 16;
    g = e - (e_shifted + e_shifted[`N_DECIMALS-1]); // Add MSB of decimals to round instead of truncate
    d = (c << `N_DECIMALS) + g;
  end

  assign filter_out = d;


endmodule
