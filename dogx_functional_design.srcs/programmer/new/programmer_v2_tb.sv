`timescale 1ns / 1ps

module programmer_v2_tb;

  /**
    TESTBENCH FOR PROGRAMMER - RICARDO CARRRERO, 13/1/2025

    Purpose:

    Test the correct behavior of the programming module interfacing with the exterior of the chip

    Usage:

    Generate an array of bits used for programming using the programming software. An example is given at line 59
    Run the testbench
    Check the results agains the values of the registers in the programming software

    Description:

    An array of programming bits extracted from the programming software is used as the input data for the programming module
    The index used for the current input data value (SDI) is updated every SCLK cycle, simulating a real input.
    There are two variables (SDI_override,SCLK_override) that allow the testbench to override continuous assignments to test High Ohmic and digital reset
    The array of programming bits changed for double testing and sent again

**/

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


  logic [55:0] data_to_send;

  initial begin
    data_to_send = {8'd3, 8'd219, 8'd90, 8'd108, 8'd136, 8'd137, 8'd217};
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
    if (!SCLK_override) SCLK = clk;
    #1;
  end

  initial begin

    SDI_override  = 0;
    SCLK_override = 0;

    chip_select   = 1;
    repeat (10) #CLK_PERIOD;  // wait for some time before enabling CS;
    chip_select = 0;
    repeat (2) #CLK_PERIOD;
    clock_enabled = 1;

    repeat (55) begin
      @(negedge clk);
      i = i - 1;
    end

    #CLK_PERIOD;
    #CLK_PERIOD;

    clock_enabled = 0;
    SDI_override = 1;
    SCLK_override = 1;
    SDI = 0;
    SCLK = 0;

    repeat (2) #CLK_PERIOD;
    chip_select = 1;
    repeat (30) #CLK_PERIOD;

    // Check for DRESET and HO


    SDI = 1;
    repeat (10) #CLK_PERIOD;
    SCLK = 1;
    repeat (10) #CLK_PERIOD;
    SCLK = 0;
    repeat (10) #CLK_PERIOD;
    SDI = 0;

    SDI_override = 0;
    SCLK_override = 0;



    // Test with new data

    data_to_send = {8'd1, 8'd183, 8'd163, 8'd45, 8'd6, 8'd14, 8'd162};
    i = 55;

    chip_select = 1;
    repeat (10) #CLK_PERIOD;  // wait for some time before enabling CS;
    chip_select = 0;
    repeat (2) #CLK_PERIOD;
    clock_enabled = 1;

    repeat (55) begin
      @(negedge clk);
      i = i - 1;
    end

    #CLK_PERIOD;
    clock_enabled = 0;

    repeat (2) #CLK_PERIOD;
    chip_select = 1;
    repeat (30) #CLK_PERIOD;

    $stop;
  end

  // NOW programmer DUT

  logic [3:0] GTHDR_encoded;
  logic [3:0] GTHSNR_encoded;

  logic [8:0] ATHHI;
  logic [8:0] ATHLO;
  logic [4:0] ATO;

  logic       DRESET;
  logic       PALPHA;
  logic       DCFILT;
  logic       DLLFILT;
  logic       DLL_EN;
  logic       DLL_FB_EN;
  logic       DLL_TR;

  logic [3:0] FCHSNR;
  logic       HSNR_EN;
  logic       HDR_EN;
  logic       BG_PROG_EN;
  logic [3:0] BG_PROG;
  logic       LDOA_BP;
  logic       LDOA_tweak;
  logic       REF_OUT;
  logic       HO;

  programmer DUT (
      .reset(reset),
      .SDI(SDI),
      .SCLK(SCLK),
      .CS(chip_select),
      .GTHDR(GTHDR_encoded),
      .GTHSNR(GTHSNR_encoded),
      .FCHSNR(FCHSNR),
      .HSNR_EN(HSNR_EN),
      .HDR_EN(HDR_EN),
      .BG_PROG_EN(BG_PROG_EN),
      .BG_PROG(BG_PROG),
      .LDOA_BP(LDOA_BP),
      .LDOA_tweak(LDOA_tweak),
      .ATHHI(ATHHI),
      .ATHLO(ATHLO),
      .ATO(ATO),
      .REF_OUT(REF_OUT),
      .PALPHA(PALPHA),
      .DCFILT(DCFILT),
      .DLLFILT(DLLFILT),
      .DLL_EN(DLL_EN),
      .DLL_FB_EN(DLL_FB_EN),
      .DLL_TR(DLL_TR),
      .DRESET(DRESET),
      .HO(HO)
  );

  // Add decoder for resistors

  logic [7:0] GTHDR;
  logic [7:0] GTHSNR;

  resistors_decoder HDR_r_decoder_DUT (
      .r_prog(GTHDR_encoded),
      .R_ctr (GTHDR)
  );

  resistors_decoder HSNR_r_decoder_DUT (
      .r_prog(GTHSNR_encoded),
      .R_ctr (GTHSNR)
  );

endmodule
