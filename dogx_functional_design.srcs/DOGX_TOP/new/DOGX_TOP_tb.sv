`timescale 1ns / 1ps

module DOGX_TOP_tb;

  /**
    FINAL TESTBENCH FOR DOG_21 - RICARDO CARRRERO, 10/1/2025

    Purpose:

    Test that the chip gets programmed and executes everything correctly according to programmed values

    Usage:

    Execute in vivado simulator, then use plot_outputs.m to check the results in matlab
    The results include channel combination and alpha values
    Check for programming errors on the waveform view (Unconnected 'Z' values etc)

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

  /** 
        INPUT SIGNALS FOR CONVERTER: INPUT SINES, OSCILLATORS, GRAY AND EXTENSION
  **/

  real sineval_n = 0;
  real sineval_p = 0;
  real t_delay = 7;
  real sinefreq = 1000;
  int  fd;

  // File for output data

  initial begin
    fd = $fopen("./converter_output.csv", "w");
    if (fd) begin
      $display("file ./converter_output.csv opened succesfully");
    end else begin
      $display("FAILED TO OPEN FILE ./converter_output.csv");
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
    carrier   = 0.6 * $sin(2 * 3.14159 * 4 * $realtime / 1000000000);
    // 1 Khz sine (small)
    sineval_n = 0.025 * $sin(2 * 3.14159 * sinefreq * $realtime / 1000000000) + carrier;
    sineval_p = -sineval_n;
  endfunction

  always begin
    compute_sine();
    #t_delay;
  end


  logic      [15:0] phases_n_HDR;
  logic      [15:0] phases_p_HDR;
  logic      [15:0] phases_n_HSNR;
  logic      [15:0] phases_p_HSNR;

  // Oscillators

  const real        offset_HDR = 0.12;  // For a sine wave with amplitude 1 max;
  const real        offset_HSNR = -0.15;

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

  /**

        PROGRAMMER SETUP

  **/

  logic clk_programmer;
  logic clock_enabled;

  real  CLK_PROGRAMMER_PERIOD = (1 / 3e6) * 1e9;  // 3 MHZ clock for test

  initial begin
    clk_programmer = 0;
    clock_enabled = 0;
    forever begin
      if (clock_enabled) begin
        clk_programmer = !clk_programmer;
        #CLK_PROGRAMMER_PERIOD;
      end else begin
        clk_programmer = 0;
        #CLK_PROGRAMMER_PERIOD;
      end
    end
  end

  // This input was generated using programming software for DOGX. Check that all registers are the same as the desired programming

  logic [55:0] data_to_send;

  initial begin
    data_to_send = {8'd1, 8'd183, 8'd163, 8'd4, 8'd12, 8'd8, 8'd29};
  end

  // Generate Chip select and SDI according to SCLK

  logic chip_select;
  logic SDI;
  logic SCLK;

  logic SCLK_override;  // Used to override SCLK assignment to "clk input if CS"
  logic SDI_override;  // Used to override SCLK assignment to "clk input if CS"

  int   i = 55;

  always begin
    if (!SDI_override) SDI = data_to_send[i];
    if (!SCLK_override) SCLK = clk_programmer;
    #1;
  end

  initial begin

    SDI_override  = 0;
    SCLK_override = 0;

    chip_select   = 1;
    repeat (10) #CLK_PROGRAMMER_PERIOD;  // wait for some time before enabling CS;
    chip_select = 0;
    repeat (2) #CLK_PROGRAMMER_PERIOD;
    clock_enabled = 1;

    repeat (55) begin
      @(negedge clk_programmer);
      i = i - 1;
    end

    #CLK_PROGRAMMER_PERIOD;
    #CLK_PROGRAMMER_PERIOD;

    clock_enabled = 0;
    SDI_override = 1;
    SCLK_override = 1;
    SDI = 0;
    SCLK = 0;

    repeat (2) #CLK_PROGRAMMER_PERIOD;
    chip_select = 1;
    repeat (30) #CLK_PROGRAMMER_PERIOD;

    // Check for DRESET and HO


    SDI = 1;
    repeat (10) #CLK_PROGRAMMER_PERIOD;
    SCLK = 1;
    repeat (10) #CLK_PROGRAMMER_PERIOD;
    SCLK = 0;
    repeat (10) #CLK_PROGRAMMER_PERIOD;
    SDI = 0;

  end

  // DUT

  logic [7:0] GTHDR;
  logic [7:0] GTHSNR;
  logic [3:0] FCHSNR;
  logic HSNR_EN;
  logic HDR_EN;
  logic BG_PROG_EN;
  logic [3:0] BG_PROG;
  logic LDOA_BP;
  logic LDOA_tweak;
  logic REF_OUT;
  logic DLLFILT;
  logic DLL_EN;
  logic DLL_FB_EN;
  logic DLL_TR;
  logic HO;

  logic [10:0] output_data;
  logic alpha;

  DOGX_TOP DUT ( // TO CHECK PROGRAMMING VALUES, USE ATTACHED IMAGE (SAME FOLDER AS THIS TESTBENCH)

      .CLK_24M(CLK_24M),  // CLK from DLL
      .reset  (reset),    // Reset only used for simulation, leave connected to 1

      .SCLK(SCLK),  // CLK for programming port
      .SDI(SDI),  // Serial data for programming port
      .CS(chip_select),  // Chip select for programming port

      .counter_HSNR_p(counter_p_HSNR),  // Counters from VCOs (already extended)
      .counter_HSNR_n(counter_n_HSNR),
      .counter_HDR_p (counter_p_HDR),
      .counter_HDR_n (counter_n_HDR),

      .alpha_in (alpha),  // Alpha out and in
      .alpha_out(alpha),

      .GTHDR     (GTHDR),       // Programming bits for analog side
      .GTHSNR    (GTHSNR),
      .FCHSNR    (FCHSNR),
      .HSNR_EN   (HSNR_EN),
      .HDR_EN    (HDR_EN),
      .BG_PROG_EN(BG_PROG_EN),
      .BG_PROG   (BG_PROG),
      .LDOA_BP   (LDOA_BP),
      .LDOA_tweak(LDOA_tweak),
      .REF_OUT   (REF_OUT),
      .DLLFILT   (DLLFILT),
      .DLL_EN    (DLL_EN),
      .DLL_FB_EN (DLL_FB_EN),
      .DLL_TR    (DLL_TR),
      .HO        (HO),

      .converter_output(output_data)  // Digital output

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
      if (count_cycles % 50000 == 0)
        $display("Progress: %f %%", (100.0 * real'(count_cycles) / real'(CLK_CYCLES_AMOUNT)));
      count_cycles = count_cycles + 1;
    end
    $fclose(fd);
    $display("FILE CLOSED");
    $finish;
  end

endmodule
