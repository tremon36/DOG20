`timescale 1ns / 1ps

module serial_mul_v2_tb;

/**
    TESTBENCH FOR SERIAL MULTIPLIER - RICARDO CARRRERO, 13/1/2025

    Purpose:

    Test the serial multipler behavior

    Usage:

    Execute in vivado simulator, then check the output simout.txt.
    Results marked as "NOT_WORKING, UNEXPECTED" mean erros

    Description:

    All input cases are tested for a 9 bit input (ending for loop)
    Each result is saved into a txt file with the working or not working, expected or unexpected tags.

**/

  // open file for results
  int fd;
  initial begin
    fd = $fopen("simout.txt", "w");
  end

  logic clk;
  ClockGenerator #(.CLOCK_FREQ_MHZ(24)) cgen (.clk(clk));

  logic reset;
  initial begin
    reset = 0;
    @(posedge clk);
    #1;
    reset = 1;
  end

  logic [7:0] a;
  logic [7:0] b;
  logic data_ready;
  logic start;
  logic [8:0] result;

  serial_mul #(
      .N_BITS_A(8),
      .N_BITS_B(8),
      .N_BITS_RESULT(9)
  ) DUT (
      .reset(reset),
      .clk(clk),
      .a(a),
      .b(b),
      .data_ready(data_ready),
      .start(start),
      .result(result)
  );

  // TB

  int i;
  int j;
  int expected;
  int should_work;

  initial begin

    start = 0;
    repeat (10) @(posedge clk);
    #1;

    // Test everything because why not

    for (i = -128; i < 128; i = i + 1) begin
      for (j = -128; j < 128; j = j + 1) begin

        expected = i * j;

        a = $signed(i);
        b = $signed(j);
        start = 1;
        @(posedge clk);
        #1;
        start = 0;
        repeat (8) @(posedge clk);  // up to 9 cycle wait because output is 9 bits
        #1;

        should_work = (expected >= -256) && (expected < 256);

        if (expected == $signed(result)) begin
          $fdisplay(fd, "(t = %f) -> %d * %d = %d, WORKING, EXPECTED",$realtime, i, j, $signed(result));
        end else begin
          if (should_work) begin
            $fdisplay(fd, "(t = %f) -> %d * %d != %d, NOT_WORKING, UNEXPECTED",$realtime, i, j, $signed(result));
          end else begin
            $fdisplay(fd, "(t = %f) -> %d * %d != %d, NOT_WORKING, EXPECTED",$realtime, i, j, $signed(result));
          end
        end
      end
    end

    repeat (10) @(posedge clk);
    $fclose(fd);
    $stop;

  end



endmodule
