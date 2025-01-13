module sd_after_filt_tb;

  /**
    TESTBENCH FOR SIGMA-DELTA MODULATOR (FIXED POINT PRECISION NOISE-SHAPING) - RICARDO CARRRERO, 10/1/2025

    Purpose:

    Test the sigma-delta modulator used to reduce number of bits of the outputs of the filters (33 bit) to the output of the converter (11 bit)

    Usage:

    Execute in vivado simulator, then use plot_outputs.m to view the results in matlab

    Description:

    A sine wave is created and second order sigma delta modulated, simulating the current waveform at the input of the sigma-delta under test
    This is used as the input for the DUT
    results are saved to a csv file that can be read by matlab, displaying time domain and fft results

**/

  logic clk;

  ClockGenerator #(.CLOCK_FREQ_MHZ(24.576)) cgen (.clk(clk));

  logic reset;
  initial begin
    reset = 0;
    @(posedge clk);
    #1;
    reset = 1;
  end

  logic enable_3M;
  initial begin
    forever begin
      enable_3M = 1;
      @(posedge clk);
      #1;
      enable_3M = 0;
      repeat (7) @(posedge clk);
      #1;
    end
  end

  // Generate input sine wave for sigma-delta modulator

  real amplitude_1 = 100;
  real offset_1 = 15;
  real period_1_2 = (1 / (1000.0)) * 1e9;  // period in ns
  real sine_1 = 0;

  logic signed [33:0] sine_quantized;
  longint aux;

  initial begin
    forever begin
      @(negedge enable_3M);
      #1;
      sine_1 = (amplitude_1 * $sin(2 * 3.14159265358979323846 / period_1_2 * $realtime) + offset_1);
      aux = sine_1 * real'(2 ** 23);
      sine_quantized = aux + (aux >= 0 ? 0.5 : -0.5);
    end
  end

  // DUT

  logic [10:0] sd_output;

  sigma_delta_trunc DUT (
      .reset(reset),
      .clk(clk),
      .enable_3M(enable_3M),
      .input_23_decimals_10_integer(sine_quantized),
      .output_10_integer(sd_output)
  );

  int fd;
  initial begin
    fd = $fopen("sd_out.csv", "w");
    if (!fd) begin
      $display("FATAL: ERROR OPENING FILE");
      $finish;
    end
  end

  initial begin
    forever begin
      @(posedge enable_3M);
      @(negedge clk);
      $fdisplay(fd, "%0d,%d", sine_quantized, $signed(sd_output));
    end
  end

  initial begin
    repeat (24.576 * 1_000_000 * 0.25) @(posedge clk);
    $fclose(fd);
    $finish;
  end

endmodule
