module spi_master (clk, rst_n, channel, start_cnv, result, cnv_complete, MISO, MOSI, SCLK, SS_n);

input clk, rst_n, channel, start_cnv, MISO;
output result, cnv_complete, MOSI, SCLK;

output reg SS_n;

//inputs and output type definitions
wire clk, rst_n, start_cnv, MISO, MOSI;
reg [2:0] channel;
reg [11:0] result;


//internal signals
reg [15:0] shift_reg; //transmit and receive shift registers
reg [4:0] sclk_counter; 	//count 32 system clks
reg [3:0] bit_count; 		//count 16 SCLKs, need 5 bits to count 0-16
reg SCLK_rise, SCLK_fall, SCLK_ff1, SCLK_ff2, cnv_complete, last_shift, miso_ff, done;


typedef enum reg[1:0] {IDLE, FRONT_PORCH, TRANSMIT, BACK_PORCH} state_t;
state_t state, next_state;

//sclk_counter logic, counts 32 system clocks in SCLK period
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		sclk_counter <= 5'h00; //reset to zero at start of conversion
	else if(start_cnv)
		sclk_counter <= 5'h10; //start clk high to give a front porch
	else 
		sclk_counter <= sclk_counter + 1;
end
//top bit used as SCLK while SCLK active, changes every 16 system clocks
assign SCLK = (SS_n) ? 1'b1 : sclk_counter[4];


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

// samples MISO on SCLK_rise
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		miso_ff <= 1'b0;
	else if (SCLK_rise)
		miso_ff <= MISO;
end

// shift reg logic
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		shift_reg <= 16'h0000;
	else if (start_cnv)
		shift_reg <= {2'b0, channel, 11'b0};
	else if ((state != FRONT_PORCH) && (SCLK_fall || last_shift))
		shift_reg <= {shift_reg[14:0], miso_ff};
end

assign MOSI = shift_reg[15];

// bit counter on SCLK_rise
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		bit_count <= 4'h0;
	else if (start_cnv)
		bit_count <= 4'h0;
	else if ((state != FRONT_PORCH) && SCLK_fall)
		bit_count <= bit_count + 1;
end

// next state logic
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end


always_comb begin
next_state = IDLE;
last_shift = 1'b0;
done = 1'b0;
	case(state)
		IDLE : begin
			if(start_cnv) next_state = FRONT_PORCH;
		end
		FRONT_PORCH : begin
			next_state = FRONT_PORCH;
			if(SCLK_fall) next_state = TRANSMIT;
		end
		TRANSMIT : begin
			next_state = TRANSMIT;
			if(bit_count == 4'hF) next_state = BACK_PORCH;
		end
		BACK_PORCH : begin
			next_state = BACK_PORCH;
			if(sclk_counter == 5'h18)
				last_shift = 1'b1;
			else if (sclk_counter == 5'h1A) begin
				done = 1'b1;
				next_state = IDLE;
			end
		end
	endcase
end


always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		SS_n <= 1'b1;
	else if (start_cnv)
		SS_n <= 1'b0;
	else if (last_shift)
		SS_n <= 1'b1;
end

// conversion complete logic
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		cnv_complete <= 1'b0;
	else if (start_cnv)
		cnv_complete <= 1'b0;
	else if (done)
		cnv_complete <= 1'b1;
end

assign result = shift_reg[11:0];

/*// store 12 bits of rx in result
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		result <= 12'h000;
	else if (last_shift)
		result <= shift_reg[11:0];
end*/


endmodule 
