module talk_through(clk, RESET, SD_out, MCLK, SCLK, LRCLK, SD_in, RST_n);

input clk, RESET, SD_out;
output LRCLK, SCLK, MCLK, SD_in, RST_n;

wire clk, RESET;
reg rst_n, rst_ff_n;

//outputs for codec_interface
wire LRCLK, SCLK, MCLK, RST_n, SD_in, SD_out, VALID;
wire[15:0] left_in, right_in;
wire[15:0] left_out, right_out;

fake_dig_core fdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	.right_in(right_in), .left_out(left_out), .right_out(right_out));

codec_interface CODEC_INT(.clk(clk), .rst_n(rst_n), .SD_out(SD_out), 
	.left_out(left_out), .right_out(right_out), .LRCLK(LRCLK), .SCLK(SCLK),
	.MCLK(MCLK), .RST_n(RST_n), .SD_in(SD_in), .left_in(left_in), 
	.right_in(right_in), .VALID(VALID));

  //////////////////////////////////////////////////////
  // Sync deassertion of rst_n with negedge of clock //
  ////////////////////////////////////////////////////
  always @(negedge clk, negedge RESET)
    if (!RESET)
	  begin
	    rst_ff_n <= 1'b0;
	    rst_n <= 1'b0;
	  end
	else
	  begin
	    rst_ff_n <= 1'b1;
		rst_n <= rst_ff_n;
	  end

endmodule//endmodule codec_interface_tb
