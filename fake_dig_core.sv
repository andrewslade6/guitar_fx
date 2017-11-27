module fake_dig_core(clk, rst_n, VALID, left_in, right_in, left_out, right_out);

input clk, rst_n, VALID, left_in, right_in;
output left_out, right_out;

wire clk, rst_n, VALID;
wire[15:0] left_in, right_in;
reg[15:0] left_out, right_out;

reg[15:0] input_buffer;





// talkthrough flop logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) begin
		left_out  <= 16'h0000;
		right_out <= 16'h0000;
	end
	else if(VALID) begin
				
		left_out  <= input_buffer; 
		right_out <= input_buffer;	
		
		//left_out  <= left_in;
		//right_out <= right_in;
	end
end


always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		input_buffer <= 16'h0000;
	else if (VALID)
		input_buffer <= (right_in + left_in);
end

endmodule
