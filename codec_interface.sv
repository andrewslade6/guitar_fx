module codec_interface(clk, rst_n, SD_out, left_out, right_out, LRCLK, SCLK, MCLK, RST_n, SD_in, left_in, right_in, VALID);

input 	clk,
		rst_n,
		SD_out,		//serial data OUT from CODEC
		left_out,	//16 bit left channel OUT from DIG CORE
		right_out;	//16 bit right channel OUT from DIG CORE

output	LRCLK,		//left/right clock to select which channel is output/input 50Mhz / 1024
		SCLK,		//Serial clock 50Mhz / 32
		MCLK,		//clock to drive codec 50Mhz / 4
		RST_n,		//codec reset
		SD_in,		//serial data INTO CODEC (out interface) to be sent to DAC
		left_in,	//16 bit data INTO DIG CORE
		right_in, 	//16 bit data INTO DIG CORE
		VALID;		


wire clk, rst_n, SD_out;
wire [15:0] left_out, right_out;

reg LRCLK, SCLK, MCLK, RST_n, SD_in, VALID;
reg [16:0] left_in, right_in;

reg [9:0] LRCLK_counter; // counts to 1024 for LRCLK
reg [4:0] SCLK_counter; // counts to 32 for SCLK
reg [1:0] MCLK_counter; // counts to 4 for MCLK

reg [15:0] in_from_codec; // 16 bit shift reg from codec into interface
reg [15:0] out_to_codec; // 16 bit shift reg out to codec from interface

// clock edge detection signals
reg SCLK_ff1, SCLK_ff2, SCLK_fall, SCLK_rise,
	LRCLK_ff1, LRCLK_ff2, LRCLK_fall, LRCLK_rise,
	MCLK_ff1, MCLK_ff2, MCLK_fall, MCLK_rise;

// LRCLK_counter logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		LRCLK_counter <= 10'h200;	// start high on reset
	else
		LRCLK_counter <= LRCLK_counter + 1;
end

// SCLK_counter logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		SCLK_counter <= 5'h0;	// start low on reset
	else
		SCLK_counter <= SCLK_counter + 1;
end

// MCLK_counter logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		MCLK_counter <= 2'b00;	// start low on reset
	else
		MCLK_counter <= MCLK_counter + 1;
end

// ///////////////////////////////////////////// //
// **********CLK EDGE DETECTION LOGIC*********** //
// ///////////////////////////////////////////// //

//edge detection for LRCLK
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
		LRCLK_ff1 <= 1'b1;
		LRCLK_ff2 <= 1'b1;
	end else begin
	    LRCLK_ff1 <= LRCLK;
		LRCLK_ff2 <= LRCLK_ff1;
	end  
end
//negedge detection on LRCLK
assign LRCLK_fall = ~LRCLK_ff1 & LRCLK_ff2;
//posedge detection on LRCLK
assign LRCLK_rise = LRCLK_ff1 & ~LRCLK_ff2;

//edge detection for SCLK
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
		SCLK_ff1 <= 1'b1;
		SCLK_ff2 <= 1'b1;
	end else begin
	    SCLK_ff1 <= SCLK;
		SCLK_ff2 <= SCLK_ff1;
	end  
end
//negedge detection on SCLK
assign SCLK_fall = ~SCLK_ff1 & SCLK_ff2;
//posedge detection on SCLK
assign SCLK_rise = SCLK_ff1 & ~SCLK_ff2;

//edge detection for MCLK
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
		MCLK_ff1 <= 1'b1;
		MCLK_ff2 <= 1'b1;
	end else begin
	    MCLK_ff1 <= MCLK;
		MCLK_ff2 <= MCLK_ff1;
	end  
end
//negedge detection on MCLK
assign MCLK_fall = ~MCLK_ff1 & MCLK_ff2;
//posedge detection on MCLK
assign MCLK_rise = MCLK_ff1 & ~MCLK_ff2;

// ///////////////////////////////////////////// //
// ********************************************* //
// ///////////////////////////////////////////// //



// input shift reg from codec output
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		in_from_codec = 16'h0000;
	else if()

end


endmodule
