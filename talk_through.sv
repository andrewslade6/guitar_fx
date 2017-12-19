module talk_through(clk, RESET, SD_out, MCLK, SCLK, LRCLK, SD_in, RST_n, LED, MISO, MOSI, A2D_SCLK, A2D_SS_n);

input clk, RESET, SD_out, MISO;
output LRCLK, SCLK, MCLK, SD_in, RST_n, LED, MOSI, A2D_SCLK, A2D_SS_n;

wire clk, RESET;
reg rst_n, rst_ff_n;

//outputs for codec_interface
wire LRCLK, SCLK, MCLK, RST_n, SD_in, SD_out, VALID;
wire[15:0] left_in, right_in;
wire[15:0] left_out, right_out;

//////////////////////go away/////////////////////////////////////////

wire [11:0]  pot_0, pot_1, pot_2, pot_3, pot_4, pot_5;

slider_interface SLIDERS(.clk(clk), .rst_n(rst_n), .pot_0(pot_0), .pot_1(pot_1), 
	.pot_2(pot_2), .pot_3(pot_3), .pot_4(pot_4), .pot_5(pot_5), .MISO(MISO), 
	.MOSI(MOSI), .SCLK(A2D_SCLK), .SS_n(A2D_SS_n));

wire MISO, MOSI, A2D_SCLK, A2D_SS_n;
//////////////////////////////////////////////////////////

//delay_dig_core ddc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	//.right_in(right_in), .left_out(left_out), .right_out(right_out), .d_vol_slider(pot_0), .f_vol_slider(pot_1), .d_time_slider(pot_2));

//flanger_dig_core fdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	//.right_in(right_in), .left_out(left_out), .right_out(right_out), .flange_vol_slider(pot_0), .rate_slider(pot_1));

chorus_dig_core_2 cdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	.right_in(right_in), .left_out(left_out), .right_out(right_out), .flange_vol_slider(pot_0), .rate_slider(pot_1));

codec_interface CODEC_INT(.clk(clk), .rst_n(rst_n), .SD_out(SD_out), 
	.left_out(left_out), .right_out(right_out), .LRCLK(LRCLK), .SCLK(SCLK),
	.MCLK(MCLK), .RST_n(RST_n), .SD_in(SD_in), .left_in(left_in), 
	.right_in(right_in), .VALID(VALID));

// light LEDs so we know our code is running
wire[7:0] LED;
assign LED[7:0] = pot_5[11:4];

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
