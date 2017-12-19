module codec_interface_tb();

reg clk, rst_n;

//inputs our codec_interface needs to work
wire SD_out;
wire[15:0] left_out, right_out;

//outputs for codec_interface
wire LRCLK, SCLK, MCLK, RST_n, SD_in, VALID;
wire[15:0] left_in, right_in, aout_lft, aout_rht;

//delay_dig_core ddc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
//	.right_in(right_in), .left_out(left_out), .right_out(right_out));

/*flanger_dig_core fdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	.right_in(left_in), .left_out(left_out), .right_out(right_out), .flange_vol_slider(flange_vol_slider), .rate_slider(rate_slider));
*/
chorus_dig_core_2 cdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	.right_in(right_in), .left_out(left_out), .right_out(right_out), .flange_vol_slider(pot_0), .rate_slider(pot_1));


codec_interface CODEC_INT(.clk(clk), .rst_n(rst_n), .SD_out(SD_out), 
	.left_out(left_out), .right_out(right_out), .LRCLK(LRCLK), .SCLK(SCLK),
	.MCLK(MCLK), .RST_n(RST_n), .SD_in(SD_in), .left_in(left_in), 
	.right_in(right_in), .VALID(VALID));

CS4272 CODEC(.MCLK(MCLK), .RSTn(RST_n), .SCLK(SCLK), .LRCLK(LRCLK),
	.SDout(SD_out),.SDin(SD_in), .aout_lft(aout_lft), .aout_rht(aout_rht));

initial begin
	rst_n = 0;

	#10 rst_n = 1;

	#8000000000;

	$stop;
end

initial begin
	clk = 1;
	forever begin
		#5 clk = ~clk;
	end
end

endmodule//endmodule codec_interface_tb
