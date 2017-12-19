module delay_dig_core(clk, rst_n, VALID, left_in, right_in, left_out, right_out, d_vol_slider, f_vol_slider, d_time_slider);

input clk, rst_n, VALID, left_in, right_in, d_vol_slider, f_vol_slider, d_time_slider;
output left_out, right_out;

wire clk, rst_n, VALID;
wire[15:0] left_in, right_in, d_out;
reg[15:0] left_out, right_out;
wire[11:0] d_vol_slider, f_vol_slider, d_time_slider;

/////////////INTERNAL SIGNALS//////////////

reg[15:0]  input_buffer, d_in, wet;
reg signed [31:0] delay_path, feedback;
wire[15:0] r_addr, w_addr;

reg signed [12:0]  d_volume, feedback_volume;

reg w_en, NOTFIRSTTIME, update_addr;

//////////////////////////////////////////


memory_mod delay_mem(w_en, d_in, d_out, r_addr, w_addr, clk, rst_n);

reg[14:0] delay_address, delay_time;

//assign delay_time = ({d_time_slider,2'b00} + 14'h3260); // add offset to make max delay time.  Better control over longer delay times

assign delay_time = 15'h3260;
//TODO: link with decay slider
assign w_addr[15:0] = delay_address;
assign r_addr[15:0] = delay_address;

assign d_volume[12:0] = {1'b0,d_vol_slider[11:0]};

//assign d_volume[12:0] = {1'b0, 12'h7FF};

assign feedback_volume[12:0] = {1'b0, f_vol_slider[11:0]};

reg valid_ff1, valid_ff2;
wire valid_fall;

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

//flop logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) begin
		input_buffer 	<= 16'h0000;
		d_in[15:0] 		<= 16'h0000;	
		wet 			<= 16'h0000;
		left_out  		<= 16'h0000;
		right_out 		<= 16'h0000;
	end
	else if(VALID) begin
		input_buffer  	<= left_in + right_in;
		d_in[15:0] 		<= input_buffer + feedback[27:12];
		wet 			<= input_buffer + delay_path[27:12];
		left_out  		<= wet;
		right_out 		<= wet;
	end
end

//feedback into memory
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		feedback <= 16'h0000;
	else if(valid_rise && NOTFIRSTTIME)
		//signed multiplication
		feedback <= $signed(wet)*$signed(feedback_volume);
end

//delay path sampled on rising edge of valid
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		delay_path <= 16'h0000;
	else if(valid_rise && NOTFIRSTTIME)
		//signed multiplication
		delay_path <= $signed(d_out)*$signed(d_volume);
end


//update memory location with current 16 bit word
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		w_en <= 0;
	else if(valid_fall)
		w_en <= 1;
	else
		w_en <= 0;
end

// update delay_address 1 clock after valid falls
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		update_addr <= 0;
	else if(valid_fall)
		update_addr <= 1;
	else
		update_addr <= 0;
end

//update memory location address
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		delay_address <= 15'h0000;
		NOTFIRSTTIME  <= 1'b0;
	end
	else if(update_addr) begin
		 	if(delay_address == delay_time) begin // NEED TO CHANGE DYNAMICALLLY
				delay_address <= 15'h0000;
				NOTFIRSTTIME  <= 1'b1;
			end
		 	else
		 		delay_address <= delay_address + 1;
	end
end


endmodule
