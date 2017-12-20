

module chorus_dig_core_2(clk, rst_n, VALID, left_in, right_in, left_out, flange_vol_slider, rate_slider);

input clk, rst_n, VALID, left_in, right_in, flange_vol_slider, rate_slider;
output left_out;


wire clk, rst_n, VALID;
wire[15:0] left_in, right_in;
reg[15:0] left_out, right_out, scaled_buffer;
wire[11:0] flange_vol_slider, rate_slider;


// modulation period
reg[17:0] period_counter;

// look up table for modulation waveform
// sawtooth wave
// each value from 0-1023 is a signed 8bit value -255 to +255
reg NOTFIRSTTIME;
reg [8:0]	delay_samples, index;
reg [7:0] 	MAX_DELAY;
reg [15:0] 	circ_buff [0:511];
reg [15:0] 	input_buffer;
reg [15:0] delayed_to_mult;
reg valid_ff1, valid_ff2;
wire valid_fall;

reg signed [31:0] alphamult;
reg signed [12:0] alpha;

assign alpha = {1'b0, 12'hfff};
// number of samples of delay
assign MAX_DELAY = 8'hff;

//edge detection for valid
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
		valid_ff1 <= 1'b0;
		valid_ff2 <= 1'b0;
	end else begin
		valid_ff1 <= VALID;
		valid_ff2 <= valid_ff1;
	end  
end
//edge detection on valid
assign valid_fall = ~valid_ff1 & valid_ff2;
assign valid_rise = valid_ff1 & ~valid_ff2;


// modulation period
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		period_counter <= 17'h0;
	else if(valid_fall)
		period_counter <= period_counter + 2;
end

// number of delay samples -- triangle waveform
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		delay_samples <= 9'h000;
	else if(~period_counter[16])
		delay_samples <= period_counter[15:8] + 8'hfe;
	else
		delay_samples <= (MAX_DELAY - (period_counter[15:8])) + 8'hfe;
end





//create circular buffer
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		input_buffer 	<= 16'h0000;
		delayed_to_mult <= 16'h0000;
		left_out  		<= 16'h0000;
		right_out 		<= 16'h0000;
	end
	else if(VALID) begin
		input_buffer 	 <= left_in;
		circ_buff[index] <= input_buffer;
		delayed_to_mult  <= circ_buff[(index + delay_samples)];
		left_out  		 <= input_buffer + scaled_buffer;
		//right_out 		 <= input_buffer + scaled_buffer;  MONO OUT
	end
end

//index for new value in circular buffer
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		index <= 0;
	else if(valid_fall)
		index <= index + 1;
end

//scaled buffer update
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		scaled_buffer <= 16'h0000;
	else
		scaled_buffer <= {alphamult[27:12]};
end


//multiplies alpha (the delay volume) with the delay value
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		alphamult <= 32'h0000_0000;
	else if(valid_rise & NOTFIRSTTIME)
		alphamult <= $signed(alpha) * $signed(delayed_to_mult);
end


//indicates the delay buffer is filled with valid information
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) 
		NOTFIRSTTIME <= 0;
	else if(index == MAX_DELAY)	
		NOTFIRSTTIME <= 1;
end

endmodule
