`timescale 1ns / 1ps

module DOGX_digital_converter (
    input wire CLK_24M,
    input wire reset,
    input wire [8:0] counter_HSNR_p,
    input wire [8:0] counter_HSNR_n,
    input wire [8:0] counter_HDR_p,
    input wire [8:0] counter_HDR_n,
    input wire [8:0] alpha_th_high,
    input wire [8:0] alpha_th_low,
    input wire [4:0] alpha_timeout_mask,
    input wire use_progressive_alpha,
    input wire use_dc_filter,
    input wire alpha_in,
    output wire alpha_out,
    output wire [10:0] converter_output
);

  // Clock gate enable generation

  logic enable_3M;

  clockgen cg_enable_generator (
      .CLK_24M(CLK_24M),
      .reset(reset),
      .enable_3M(enable_3M)
  );

  // HDR and HSNR channels

  logic [ 8:0] HSNR_ns_output;
  logic [ 8:0] HDR_ns_output;

  logic [ 8:0] HSNR_output;
  logic [ 8:0] HDR_output;

  logic [10:0] HSNR_output_extended;
  logic [10:0] HDR_output_extended;

  datapath_one_clock #(
      .N_BITS_ACC_EXT(3)
  ) HSNR_datapath (
      .enable_3M(enable_3M),
      .CLK_24M(CLK_24M),
      .reset(reset),
      .counter_p(counter_HSNR_p),
      .counter_n(counter_HSNR_n),
      .channel_output(HSNR_ns_output)
  );

  datapath_one_clock #(
      .N_BITS_ACC_EXT(3)
  ) HDR_datapath (
      .enable_3M(enable_3M),
      .CLK_24M(CLK_24M),
      .reset(reset),
      .counter_p(counter_HDR_p),
      .counter_n(counter_HDR_n),
      .channel_output(HDR_ns_output)
  );

  // DC filter

  logic [31:0] HSNR_filter_output;
  logic [31:0] HDR_filter_output;

  dc_filter filter_HSNR (
      .reset(reset),
      .CLK_24M(CLK_24M),
      .enable_3M(enable_3M),
      .c_data(HSNR_ns_output),
      .filter_out(HSNR_filter_output)
  );

  dc_filter filter_HDR (
      .reset(reset),
      .CLK_24M(CLK_24M),
      .enable_3M(enable_3M),
      .c_data(HDR_ns_output),
      .filter_out(HDR_filter_output)
  );

  logic [31:0] HSNR_output_filtered;
  logic [31:0] HDR_output_filtered;

  always_comb begin

    HSNR_output_filtered = HSNR_filter_output;
    HDR_output_filtered = HDR_filter_output;

    HSNR_output = HSNR_ns_output;
    HDR_output = HDR_ns_output;

  end

  // ALPHA LOGIC (ALPHA GENERATION)

  logic alpha_internal;
  assign alpha_out = alpha_internal;

  logic [8:0] alpha_channel_input;

  always_comb begin
    if (use_dc_filter) alpha_channel_input = HDR_filter_output[31:23];  // MSBs
    else alpha_channel_input = HDR_output;
  end

  alpha_block_v2 alpha_gen (
      .clk(CLK_24M),
      .enable_sampling(enable_3M),
      .reset(reset),
      .hdr_current_value(alpha_channel_input),
      .threshold_high(alpha_th_high),
      .threshold_low(alpha_th_low),
      .timeout_mask(alpha_timeout_mask),
      .alpha(alpha_internal)
  );

  // --------------------------------------------------------------------------------------------------------------

  // Generate converter output in different modes

  // MODE 1: USE PROGRESSIVE ALPHA AND NO FILTER
  // This mode can't use the DC filter.

  // --------------------------------------------------------------------------------------------------------------

  always_comb begin
    HSNR_output_extended = {{2{HSNR_output[8]}}, HSNR_output};
    HDR_output_extended  = {HDR_output, 2'b00};
  end

  // The output of the progressive combinator is combinational (changes in the process of multiplication)
  // Although viable, since the output is 3MHz, might cause a lot of activity in the output buffers. Therefore,
  // It is registered before output

  logic [10:0] p_comb_output_combinational;
  logic [10:0] p_comb_output_registered;

  channel_combinator progressive_combinator (
      .reset(reset),
      .clk(CLK_24M),
      .enable_3M(enable_3M),
      .select(alpha_in),
      .data_c1(HSNR_output_extended),
      .data_c2(HDR_output_extended),
      .data_output(p_comb_output_combinational)
  );

  always_ff @(posedge CLK_24M or negedge reset) begin
    if (!reset) p_comb_output_registered <= 0;
    else begin
      if (enable_3M && use_progressive_alpha) begin // And in enables is allowed
        p_comb_output_registered <= p_comb_output_combinational;
      end
    end
  end

  logic [10:0] converter_output_internal_unfiltered; // Output for MODE 1. Assigned based on use progressive alpha below

  always_comb begin
    if (use_progressive_alpha) begin
      converter_output_internal_unfiltered = p_comb_output_registered;
    end else begin
      if (alpha_in) begin
        converter_output_internal_unfiltered = HDR_output_extended; // Only unregistered output to allow for DDR mode
      end else begin
        converter_output_internal_unfiltered = HSNR_output_extended;
      end
    end
  end

  // --------------------------------------------------------------------------------------------------------------

  // MODE 2: USE DC FILTER
  // This mode selects before to enable the DC filter
  // The filters are above, this part of the code just combines the otputs of the filters and uses the final SD

  // --------------------------------------------------------------------------------------------------------------

  logic signed [33:0] HSNR_output_extended_f;
  logic signed [33:0] HDR_output_extended_f;
  logic signed [33:0] mixed_output_before_filter;
  logic [10:0] converter_output_internal_filtered;  // Output for MODE 2

  // gain compensation

  always_comb begin
    HSNR_output_extended_f = {{2{HSNR_output_filtered[31]}}, HSNR_output_filtered};
    HDR_output_extended_f  = {HDR_output_filtered, 2'b00};
  end

  // Perform combination after filters

  always_comb begin
    if (alpha_in) mixed_output_before_filter = HDR_output_extended_f;
    else mixed_output_before_filter = HSNR_output_extended_f;
  end

  // Use sigma-delta

  logic [10:0] sd_after_filt_output;
  sigma_delta_trunc sd_after_filt (
      .reset(reset),
      .clk(CLK_24M),
      .enable_3M(enable_3M),
      .input_23_decimals_10_integer(mixed_output_before_filter),
      .output_10_integer(sd_after_filt_output)
  );

  // Pipeline register to not load output pins with a lot of changes

  always_ff @(posedge CLK_24M) begin
    if(enable_3M) begin
      converter_output_internal_filtered <= sd_after_filt_output;
    end
  end

  // --------------------------------------------------------------------------------------------------------------

  // CHOOSE OUTPUT OF MODE 1 or MODE 2. DC filter mode has priority if both enabled

  // --------------------------------------------------------------------------------------------------------------

  logic [10:0] converter_output_internal;
  always_comb begin
    if (use_dc_filter) begin
      converter_output_internal = converter_output_internal_filtered;
    end else begin
      converter_output_internal = converter_output_internal_unfiltered;
    end
  end

  assign converter_output = converter_output_internal;

endmodule
