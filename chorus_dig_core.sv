module chorus_dig_core(clk, rst_n, VALID, left_in, right_in, left_out, right_out, flange_vol_slider, rate_slider);

input clk, rst_n, VALID, left_in, right_in, flange_vol_slider, rate_slider;
output left_out, right_out;


wire clk, rst_n, VALID;
wire[15:0] left_in, right_in;
reg[15:0] left_out, right_out, scaled_buffer;
wire[11:0] flange_vol_slider, rate_slider;


// modulation period
reg[16:0] period_counter_1, period_counter_2, period_counter_3;

reg NOTFIRSTTIME;

reg [9:0] 	MAX_DELAY, delay_samples_1, delay_samples_2, delay_samples_3, index;
reg [15:0] 	circ_buff [0:1023];
reg [15:0] 	input_buffer;
reg [15:0] delayed_to_mult_1, delayed_to_mult_2, delayed_to_mult_3;
reg valid_ff1, valid_ff2;
wire valid_fall;

reg signed [31:0] alphamult_1;
reg signed [31:0] alphamult_2;
reg signed [31:0] alphamult_3;
reg signed [12:0] alpha;

assign alpha = {1'b0, 12'h7ff};
// number of samples of delay for each voice
assign MAX_DELAY = 10'h3ff;

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
	if(~rst_n) begin
		period_counter_1 <= 17'h0;
		period_counter_2 <= 17'h0;
		period_counter_3 <= 17'h0;
	end
	else if(valid_fall) begin
		period_counter_1 <= period_counter_1 + 1;
		period_counter_2 <= period_counter_2 + 1;
		period_counter_3 <= period_counter_3 + 1;
	end
end

// MODULATION TIMES FOR EACH VOICE
// staggered, voice one is early, voice two mid, voice three late

// number of delay samples -- triangle waveforms
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		delay_samples_1 <= 10'h0000;
	else if(~period_counter_1[16])
		delay_samples_1 <= period_counter_1[15:7];
	else
		delay_samples_1 <= MAX_DELAY - ({(period_counter_1[15:7] + 9'h1ff), 1'b0});	// 1023 t0 511 samples of delay
end
// number of delay samples -- triangle waveform
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		delay_samples_2 <= 10'h0000;
	else if(~period_counter_2[16])
		delay_samples_2 <= period_counter_2[15:7];
	else
		delay_samples_2 <= MAX_DELAY - ({(period_counter_2[15:7] + 9'h1ff), 1'b0}); // 1023 t0 511 samples of delay
end
// number of delay samples -- triangle waveform
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		delay_samples_3 <= 10'h0000;
	else if(~period_counter_3[16])
		delay_samples_3 <= period_counter_3[15:7];
	else
		delay_samples_3 <= MAX_DELAY - ({(period_counter_3[15:7] + 9'h1ff), 1'b0}); // 1023 t0 511 samples of delay
end





//create circular buffer
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		input_buffer 	<= 16'h0000;
		delayed_to_mult_1 <= 16'h0000;
		delayed_to_mult_2 <= 16'h0000;
		delayed_to_mult_3 <= 16'h0000;
		left_out  		<= 16'h0000;
		right_out 		<= 16'h0000;
	end
	else if(VALID) begin
		input_buffer 	 <= (left_in + right_in);
		circ_buff[index] <= input_buffer;
		delayed_to_mult_1 <= circ_buff[(index + delay_samples_1)];
		delayed_to_mult_2 <= circ_buff[(index + delay_samples_2)];
		delayed_to_mult_3 <= circ_buff[(index + delay_samples_3)];
		left_out  		 <= input_buffer + scaled_buffer;
		right_out 		 <= input_buffer + scaled_buffer;
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
		scaled_buffer <= (alphamult_1[27:12] + alphamult_2[27:12] + alphamult_3[27:12]);
end


//multiplies alpha (the delay volume) with the delay value
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		alphamult_1 <= 32'h0000_0000;
	else if(valid_rise & NOTFIRSTTIME)
		alphamult_1 <= $signed(alpha) * $signed(delayed_to_mult_1);
end

//multiplies alpha (the delay volume) with the delay value
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		alphamult_2 <= 32'h0000_0000;
	else if(valid_rise & NOTFIRSTTIME)
		alphamult_2 <= $signed(alpha) * $signed(delayed_to_mult_2);
end

//multiplies alpha (the delay volume) with the delay value
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		alphamult_3 <= 32'h0000_0000;
	else if(valid_rise & NOTFIRSTTIME)
		alphamult_3 <= $signed(alpha) * $signed(delayed_to_mult_3);
end


//indicates the delay buffer is filled with valid information
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) 
		NOTFIRSTTIME <= 0;
	else if(index == MAX_DELAY)	
		NOTFIRSTTIME <= 1;
end

endmodule
