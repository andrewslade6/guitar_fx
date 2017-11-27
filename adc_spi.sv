module adc_spi (clk, rst_n, channel, start_cnv, result, cnv_complete, MISO, MOSI, SCLK, SS_n);

input clk, rst_n, channel, start_cnv, MISO;
output result, cnv_complete, MOSI, SCLK;

output reg SS_n;

//inputs and output type definitions
wire clk, rst_n, start_cnv, MISO;
reg [2:0] channel;
reg [11:0] result;
reg MOSI, done;


//internal signals
reg [15:0] tx_register, rx_register; //transmit and receive shift registers
reg [4:0] sclk_counter; 	//count 32 system clks
reg [4:0] bit_count; 		//count 16 SCLKs, need 4 bits to count 0-16
reg [1:0] two_clk_delay;
reg SCLK_rise, SCLK_fall, SCLK_ff1, SCLK_ff2, cnv_complete, shift_last_bit;
reg set_SS_n, clear_SS_n;


typedef enum reg[2:0] {IDLE, SEND_ADDRESS, GET_ADC_DATA, LAST_SHIFT} state_t;
state_t state, next_state;

//sclk_counter logic, counts 32 system clocks in SCLK period
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		sclk_counter <= 0; //reset to zero at start of conversion
	else if(start_cnv)
		sclk_counter <= 5'h11; //start clk high to give a front porch
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


//counts to 16 for # of bits transferred
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		bit_count <= 0;
	else if(SS_n)	//reset to zero when
		bit_count <= 0;
	else if(SCLK_rise) 
		bit_count <= bit_count + 1;
end


//tx_register
//2 system clock delay
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)  
		two_clk_delay <= 0;
	else if(SCLK_rise)  		//1st system clock
	 	two_clk_delay <= 1;
	else if(two_clk_delay[0])	//2nd system clock
		two_clk_delay <= 2;
	else						//otherwise zero
		two_clk_delay <= 0;
end


//shift tx_register logic
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		tx_register <= 16'h0000;
	else if(start_cnv)
		//tx_register <= {2'b0, channel, 11'b0};
		tx_register <= 16'h0000;
	else if( two_clk_delay[1])
		tx_register <= {tx_register[14:0], 1'b0};
end

assign MOSI = tx_register[15];

//shift rx_register logic
// sample MISO on falling edge of clk
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		rx_register <= 16'h0000;
	else if(SCLK_fall || shift_last_bit)
		rx_register <= {rx_register[14:0], MISO};
end


// next state logic
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end


// state machine combinational logic
always_comb begin
	// default outputs
	done = 1'b0; 
	shift_last_bit = 1'b0;
	next_state = IDLE;
	set_SS_n = 1'b0;
	clear_SS_n = 1'b0;
	
	case (state)
		IDLE :	begin 
				if (start_cnv) begin
					next_state = SEND_ADDRESS;
					clear_SS_n = 1'b1;
				end
			end

		SEND_ADDRESS : 	begin
				next_state = SEND_ADDRESS;
				//SS_n = 1'b0;
				if (bit_count == 5'h10) begin
					//SS_n = 1'b1; // deselect chip briefly
					next_state = GET_ADC_DATA;
				end
			end

		GET_ADC_DATA :  begin
				next_state = GET_ADC_DATA;
				//SS_n = 1'b0;	
				if (bit_count == 5'h10) begin
					//done = 1'b1;
					next_state = LAST_SHIFT;
				end
			end

		LAST_SHIFT : begin
				next_state = LAST_SHIFT;
				//SS_n = 1'b0;
				if (sclk_counter == 5'h14) begin // wait 1/8 SCLK and shift in last
					shift_last_bit = 1'b1;
				end 
				else if (sclk_counter == 5'h18) begin
					next_state = IDLE;
					set_SS_n = 1'b1;
					done = 1'b1;
				end
 			end
	
	endcase

end


always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		SS_n <= 1'b1;
	else if (clear_SS_n)
		SS_n <= 1'b0;
	else if (set_SS_n)
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

// store 12 bits of rx in result
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		result <= 12'h000;
	else if (done)
		result <= rx_register[11:0];  // check order bits get shifted in!!!!
end


endmodule 
