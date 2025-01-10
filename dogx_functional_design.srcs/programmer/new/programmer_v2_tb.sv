`timescale 1ns / 1ps

module programmer_v2_tb;

  // First generate clock and reset

  logic clk;
  logic reset;
  logic clock_enabled;

  real  CLK_PERIOD = (1 / 3e6) * 1e9;  // 3 MHZ clock for test

  initial begin
    reset = 0;
    #10;
    reset = 1;
  end

  initial begin
    clk = 0;
    clock_enabled = 0;
    forever begin
      if (clock_enabled) begin
        clk = !clk;
        #CLK_PERIOD;
      end else begin
        clk = 0;
        #CLK_PERIOD;
      end
    end
  end

  // This input was generated using programming software for DOGX. Check that all registers are the same as the desired programming
  // [5, 189, 217, 218, 179, 33, 161, 165] where 3 is the first number to be sent


  logic [63:0] data_to_sent;

  initial begin
    data_to_sent = {8'd2, 8'd170, 8'd170, 8'd218, 8'd85, 8'd85, 8'd85, 8'd85};
  end

  // Generate Chip select and SDI according to SCLK

  logic chip_select;
  logic SDI;

  int i = 63;
  assign SDI = data_to_sent[i];

  initial begin

    chip_select = 1;
    repeat (10) #CLK_PERIOD;  // wait for some time before enabling CS;
    chip_select = 0;
    repeat (2) #CLK_PERIOD;
    clock_enabled = 1;
    repeat (64) @(posedge clk);
    #1;
    clock_enabled = 0;
    repeat (2) #CLK_PERIOD;
    chip_select = 1;
    repeat (30) #CLK_PERIOD;

    // Now invert the data to send, and run a new one

    data_to_sent = {8'd5, 8'd189, 8'd217, 8'd218, 8'd179, 8'd33, 8'd161, 8'd165};
    chip_select = 1;
    repeat (10) #CLK_PERIOD;  // wait for some time before enabling CS;
    chip_select = 0;
    repeat (2) #CLK_PERIOD;
    clock_enabled = 1;
    repeat (64) @(posedge clk);
    #1;
    clock_enabled = 0;
    repeat (2) #CLK_PERIOD;
    chip_select = 1;
    repeat (30) #CLK_PERIOD;

    $stop;
  end

  
  

  always_ff @(posedge clk) begin
    i <= i - 1;
  end

  // NOW programmer DUT

  logic [7:0] GTHDR;
  logic [7:0] GTHSNR;
  logic [3:0] FCHSNR;
  logic HSNR_EN;
  logic HDR_EN;
  logic BG_PROG_EN;
  logic [3:0] BG_PROG;
  logic LDOA_BP;
  logic LDOD_BP;
  logic LDOD_mode_1V;
  logic LDOA_tweak;
  logic [8:0] ATHHI;
  logic [8:0] ATHLO;
  logic [4:0] ATO;
  logic PALPHA;
  logic DCFILT;
  logic REF_OUT;
  logic digital_RESET;
  logic HO;

  programmer DUT (
      .reset       (reset),
      .SDI         (SDI),
      .SCLK        (clk),
      .CS          (chip_select),
      .GTHDR       (GTHDR),
      .GTHSNR      (GTHSNR),
      .FCHSNR      (FCHSNR),
      .HSNR_EN     (HSNR_EN),
      .HDR_EN      (HDR_EN),
      .BG_PROG_EN  (BG_PROG_EN),
      .BG_PROG     (BG_PROG),
      .LDOA_BP     (LDOA_BP),
      .LDOD_BP     (LDOD_BP),
      .LDOD_mode_1V(LDOD_mode_1V),
      .LDOA_tweak  (LDOA_tweak),
      .ATHHI       (ATHHI),
      .ATHLO       (ATHLO),
      .ATO         (ATO),
      .PALPHA      (PALPHA),
      .DCFILT      (DCFILT),
      .REF_OUT     (REF_OUT),
      .DRESET      (digital_RESET),
      .HO          (HO)
  );

endmodule
