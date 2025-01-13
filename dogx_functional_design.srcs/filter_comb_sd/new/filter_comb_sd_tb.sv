`timescale 1ns/1ps

module filter_comb_sd_tb;

/**
    TESTBENCH FOR SIGMA-DELTA COMBINATION AFTER FILTER - RICARDO CARRRERO, 10/1/2025

    Purpose:

    Test the combination of the two signals after the filters, switching at the input of the sigma-delta modulator (DUT)
    Before, we used two SD, one for each filter, and performed the combination afterwards

    Usage:

    Execute in vivado simulator, then use plot_outputs.m to view the results in matlab

    Description:

    Two sine waves are created and sigma-delta modulated. The second one is the first one with x4 amplitude.
    The idea is to not depend on the rest of the converter for this test, thus the sine waves are equivalent to the oscillator + NS
    These waves filtered using the DC filter present in the converter.
    The gain is adjusted digitally for both of them to be suitable for combination
    A combination is performed, simulating alpha behavior. This part of the code is easy to change for different testing putposes
    The mixed signal is fed to the sigma-delta modulator DUT
    The relevant outputs are written to a csv file that can be read by matlab

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

// Generate sine waves. Sine wave 1 is for filter 1, sine wave 2 is for filter 2. They are both first order sigma delta modulated

// SINE WAVE 1

logic signed [8:0] filter_1_input;
logic signed [31:0] filter_1_output;

real amplitude_1 = 100;
real offset_1 = 15;
real period_1_2 = (1 / (1000.0)) * 1e9; // period in ns
real sine_1 = 0;

real a1 = 0;
real b1 = 0;
real c1 = 0;
real c_d1 = 0;
real d1 = 0;
real e1 = 0;
real e_d1 = 0;
real f1 = 0;

int sd_out1 = 0;

initial begin
  forever begin
      @(negedge enable_3M);
      #1;
      sine_1 = (amplitude_1 * $sin(2*3.14159265358979323846/period_1_2 * $realtime) + offset_1);

      // Modulate input to sigma delta for filter input. Filter is intended for use with a 9 bit input sigma delta modulation

      c_d1 = c1;
      e_d1 = e1;

      f1 = $floor(e_d1);
      sd_out1 = $rtoi(f1);
      filter_1_input = sd_out1;

      a1 = sine_1;
      b1 = a1 - f1;
      c1 = b1 + c_d1;
      d1 = c1 - f1;
      e1 = d1 + e_d1;

  end
end

// SINE WAVE 2

logic signed [8:0] filter_2_input;
logic signed [31:0] filter_2_output;

real amplitude_2 = 25;
real offset_2 = -12;
real sine_2 = 0;

real a2 = 0;
real b2 = 0;
real c2 = 0;
real c_d2 = 0;
real d2 = 0;
real e2 = 0;
real e_d2 = 0;
real f2 = 0;

int sd_out2 = 0;

initial begin
  forever begin
      @(negedge enable_3M);
      #1;
      sine_2 = (amplitude_2 * $sin(2*3.14159265358979323846/period_1_2 * $realtime) + offset_2);

      // Modulate input to sigma delta for filter input. Filter is intended for use with a 9 bit input sigma delta modulation

      c_d2 = c2;
      e_d2 = e2;

      f2 = $floor(e_d2);
      sd_out2 = $rtoi(f2);
      filter_2_input = sd_out2;

      a2 = sine_2;
      b2 = a2 - f2;
      c2 = b2 + c_d2;
      d2 = c2 - f2;
      e2 = d2 + e_d2;

  end
end

// Now filters

dc_filter filter1 (
    .reset(reset),
    .CLK_24M(clk),
    .enable_3M(enable_3M),
    .c_data(filter_1_input),
    .filter_out(filter_1_output)
);

dc_filter filter2 (
    .reset(reset),
    .CLK_24M(clk),
    .enable_3M(enable_3M),
    .c_data(filter_2_input),
    .filter_out(filter_2_output)
);

// Alpha logic simplified

logic alpha;

// int timeout;
// int threshold;
// int absval;
// 
// initial begin
// 
//     alpha = 0;
//     timeout = 1000; // Timeout is in 3MHz clock cycles
//     threshold = 50;
// 
//     forever begin
//         @(negedge enable_3M);
//         #1;
//         absval = $signed(filter_1_output[31:23]) >= 0 ? $signed(filter_1_output[31:23]) : -$signed(filter_1_output[31:23]);
//         if(absval > threshold) begin
//             timeout = 1000;
//             alpha = 1;
//         end else begin
//             if(timeout == 0) begin
//                 alpha = 0;
//             end else begin
//                 alpha = 1;
//                 timeout = timeout - 1;
//             end
//         end
//     end
// end

int loopleft;
initial begin
    loopleft = 400_000; // Change every 1e5 cycles for test
    alpha = 1;
    forever begin
        @(negedge enable_3M);
        #1;
        if(loopleft == 0) begin
            alpha = !alpha;
            loopleft = 100_000_000_000; // Big test for just one change. Use 100k cycles for multiple changes to test spectrogram
        end else begin
            loopleft = loopleft - 1;
        end
    end
end

// DUT

logic signed [33:0] mixed_input;
logic signed [10:0] mixed_output;

always_comb begin
    mixed_input = alpha == 1'b0 ? filter_1_output : (filter_2_output << 2);
end

sigma_delta_trunc DUT (
    .reset(reset),
    .clk(clk),
    .enable_3M(enable_3M),
    .input_23_decimals_10_integer(mixed_input),
    .output_10_integer(mixed_output)
);

// Print everything to file
int fd;
initial begin
    fd = $fopen("dc_filter_out.csv","w");
    if(!fd) begin
        $display("FATAL: ERROR OPENING FILE");
        $finish;
    end
    forever begin
        @(posedge enable_3M);
        @(negedge clk);
        $fdisplay(fd,"%f,%f,%d,%d,%0d,%d,%d",sine_1,sine_2,filter_1_input,filter_1_output,mixed_input,mixed_output,alpha);
    end
end

initial begin
    repeat (24_576_000 * 0.25) @(posedge clk);
    $fclose(fd);
    $display("FINISHED");
    $stop;
end


endmodule