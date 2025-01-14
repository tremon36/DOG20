`timescale 1ns / 1ps

module DOGX_digital_converter_v2_tb;

/**
    TESTBENCH FOR DIGITAL CONVERTER - RICARDO CARRRERO, 10/1/2025

    Purpose:

    Test the full converter with specific programming values

    Usage:

    Execute in vivado simulator, then use plot_outputs.m to check the results in matlab
    The results include channel combination and alpha values

    Description:

    An input wave is created, using a 4Hz carrier and a small 1KHz tone.
    This wave is the input to system verilog oscillators with gain 1 and 0.25 respectively.
    The osillators are gray sampled and extended, simulating the analog+fullcustom side of the converter.
    The result of the previous is the two inputs to the HSNR and HDR channel respectively (both differential).
    A DUT for the digital converter is created, with modifiable programming values (alpha block, filter usage, progressive alpha)
    The results are saved to a csv file that can be read using matlab

    notes:

    Noise shaping is not expected to behave correctly in this simulation, because the oscillators are not precise enough.
    Simulation is very long (1s). Might take an hour to complete


**/

  real sineval_n = 0;
  real sineval_p = 0;
  real t_delay = 7;
  real sinefreq = 1000;
  int  fd;

  // File for output data

  initial begin
    fd = $fopen("./data_out2.csv", "w");
    if (fd) begin
      $display("file ./data_out2.csv opened succesfully");
    end else begin
      $display("FAILED TO OPEN FILE ./data_out2.csv");
      $stop;
    end
  end

  final begin
    $fclose(fd);
    $display("closed file sucessfuly");
  end

  //  Clock, reset, and enable generation

  logic CLK_24M;
  logic reset;

  initial begin
    CLK_24M = 1;
    forever begin
      #20.833333333333336;
      CLK_24M = !CLK_24M;
    end
  end


  initial begin
    reset = 0;
    @(posedge CLK_24M);
    reset = 1;
  end

  // enable generation for data write

  logic enable_3M;
  int   count = 0;
  always begin
    @(posedge CLK_24M);
    enable_3M = count == 0;
    count = count + 1;
    if (count == 8) count = 0;
  end


  // Counter values generation using sine, graycount and extension ----------------------------------------------------------------------------------
  real carrier = 0;
  function static void compute_sine();
    // Carrying sine (4 Hz), 0.6 amplitude
     carrier = 0.6 * $sin(2 * 3.14159 * 4 * $realtime / 1000000000);
    // 1 Khz sine (small)
    sineval_n = 0.025 * $sin(2 * 3.14159 * sinefreq * $realtime / 1000000000) + carrier;
    sineval_p = -sineval_n;
  endfunction

  always begin
    compute_sine();
    #t_delay;
  end


  logic [15:0] phases_n_HDR;
  logic [15:0] phases_p_HDR;
  logic [15:0] phases_n_HSNR;
  logic [15:0] phases_p_HSNR;

  // Oscillators

  const real offset_HDR = 0.12;       // For a sine wave with amplitude 1 max;
  const real offset_HSNR = -0.15;

  // GAIN IS SET TO 0.2125, correct gain is 25

  ring_osc_16 #(
      .GAIN(1),
      .F0  (196608000)
  ) HSNR_n (
      .input_voltage(sineval_n + offset_HSNR),
      .phases(phases_n_HSNR)
  );

  ring_osc_16 #(
      .GAIN(1),
      .F0  (196608000)
  ) HSNR_p (
      .input_voltage(sineval_p - offset_HSNR),
      .phases(phases_p_HSNR)
  );

  ring_osc_16 #(
      .GAIN(0.25),
      .F0  (196608000)
  ) HDR_n (
      .input_voltage(sineval_n + offset_HDR),
      .phases(phases_n_HDR)
  );

  ring_osc_16 #(
      .GAIN(0.25),
      .F0  (196608000)
  ) HDR_p (
      .input_voltage(sineval_p - offset_HDR),
      .phases(phases_p_HDR)
  );

  // Counters

  logic [8:0] counter_p_HSNR = 0;
  logic [8:0] counter_n_HSNR = 0;
  logic [8:0] counter_p_HDR = 0;
  logic [8:0] counter_n_HDR = 0;

  graycount direct_counter_p_HSNR (
      .clk(CLK_24M),
      .phases(phases_p_HSNR),
      .sampled_binary(counter_p_HSNR[4:0])
  );

  binary_counter_sync #(
      .N_BITS(4)
  ) extender_p_HSNR (
      .clk  (~counter_p_HSNR[4]),
      .reset(reset),
      .value(counter_p_HSNR[8:5])
  );

  graycount direct_counter_n_HSNR (
      .clk(CLK_24M),
      .phases(phases_n_HSNR),
      .sampled_binary(counter_n_HSNR[4:0])
  );


  binary_counter_sync #(
      .N_BITS(4)
  ) extender_n_HSNR (
      .clk  (~counter_n_HSNR[4]),
      .reset(reset),
      .value(counter_n_HSNR[8:5])
  );

  // HDR

  graycount direct_counter_p_HDR (
      .clk(CLK_24M),
      .phases(phases_p_HDR),
      .sampled_binary(counter_p_HDR[4:0])
  );


  binary_counter_sync #(
      .N_BITS(4)
  ) extender_p_HDR (
      .clk  (~counter_p_HDR[4]),
      .reset(reset),
      .value(counter_p_HDR[8:5])
  );

  graycount direct_counter_n_HDR (
      .clk(CLK_24M),
      .phases(phases_n_HDR),
      .sampled_binary(counter_n_HDR[4:0])
  );


  binary_counter_sync #(
      .N_BITS(4)
  ) extender_n_HDR (
      .clk  (~counter_n_HDR[4]),
      .reset(reset),
      .value(counter_n_HDR[8:5])
  );

  // ---------------------------------------------------------------------------------------------------------------------------

  // DUT

  logic [10:0] output_data;
  logic alpha;

  DOGX_digital_converter dut (
      .CLK_24M(CLK_24M),
      .reset(reset),
      .counter_HSNR_n(counter_n_HSNR),
      .counter_HSNR_p(counter_p_HSNR),
      .counter_HDR_n(counter_n_HDR),
      .counter_HDR_p(counter_p_HDR),
      .alpha_th_high(9'd40),
      .alpha_th_low(9'd38),
      .alpha_timeout_mask(5'b00010),
      .use_progressive_alpha(1'b0),
      .use_dc_filter(1'b1),
      .alpha_out(alpha),
      .alpha_in(alpha),
      .converter_output(output_data)
  );

  // Save data to file

  always_ff @(posedge enable_3M) begin
    $fdisplay(fd, "%d,%d", $signed(output_data), alpha);
  end

  // Run 1 s (3e6 clock cycles)
  int CLK_CYCLES_AMOUNT;
  int count_cycles;
  initial begin
    CLK_CYCLES_AMOUNT = 3000000 * 8;
    count_cycles = 0;
    repeat (3000000 * 8) begin
      @(posedge CLK_24M);
      if(count_cycles % 50000 == 0) $display("Progress: %f %%",(100.0 * real'(count_cycles) / real'(CLK_CYCLES_AMOUNT)));
      count_cycles = count_cycles + 1;
    end
    $fclose(fd);
    $display("FILE CLOSED");
    $finish;
  end

endmodule
