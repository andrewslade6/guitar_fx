module delay_dig_core(clk, rst_n, VALID, left_in, right_in, left_out, right_out);

input clk, rst_n, VALID, left_in, right_in;
output left_out, right_out;

wire clk, rst_n, VALID;
wire[15:0] left_in, right_in;
reg[15:0] left_out, right_out;

memory_mod delay_mem(w_en, d_in, d_out, r_addr, w_addr, clk, rst_n);

reg[15:0] delay_path;
reg[15:0] input_buffer;
reg[13:0] delay_addresses; 
reg read_flag;

//average of left and right input paths for mono signal
assign input_buffer[15:0] = (left_in + right_in) / 2;

//delay path values 1/2 as loud as input
//TODO: link with decay slider
assign delay_path[15:0] ? (read_flag) = d_out>>1 : 16'h0000;
assign w_addr = delay_addresses;
assign r_addr = delay_addresses;


// talkthrough flop logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) begin
		left_out  <= 16'h0000;
		right_out <= 16'h0000;
		delay_addresses <= 13'h0;
	end
	else if(VALID) begin
		if(~read_flag)
			w_en = 1'b1;

		delay_addresses = delay_addresses + 1;
		d_in <= input_buffer;
		left_out  <= input_buffer + delay_path;
		right_out <= input_buffer + delay_path;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) 
		read_flag <= 0;
	else if (delay_addresses == 14'd16383)
		read_flag <= 1;
end



endmodule
