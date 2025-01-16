module resistors_decoder (
    input logic [3:0] r_prog,
    output logic [7:0] R_ctr
);

  always_comb begin
      unique case (r_prog)              //   HSNR        HDR
        0: R_ctr = 8'b11101110;   //   1.00k       7.00k
        1: R_ctr = 8'b01011110;   //   1.10k       7.50k
        2: R_ctr = 8'b11011110;   //   1.20k       8.00k
        3: R_ctr = 8'b10111110;   //   1.30k       8.50k
        4: R_ctr = 8'b11100101;   //   1.40k       9.00k
        5: R_ctr = 8'b01010101;   //   1.50k       9.50k
        6: R_ctr = 8'b11010101;   //   1.60k       10.0k
        7: R_ctr = 8'b10110101;   //   1.70k       10.5k
        8: R_ctr = 8'b11101101;   //   1.80k       11.0k
        9: R_ctr = 8'b01011101;  //   1.90k       11.5k
        10: R_ctr = 8'b11011101;  //   2.00k       12.0k
        11: R_ctr = 8'b10111101;  //   2.10k       12.5k
        12: R_ctr = 8'b11101011;  //   2.20k       13.0k
        13: R_ctr = 8'b01011011;  //   2.30k       13.5k
        14: R_ctr = 8'b11011011;  //   2.40k       14.0k
        15: R_ctr = 8'b10111011;  //   2.50k       14.5k
      endcase
  end
endmodule
