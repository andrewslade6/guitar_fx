module slider_interface(clk, rst_n, pot_0, pot_1, pot_2, pot_3, pot_4, pot_5, MISO, MOSI, SCLK, SS_n);

input clk, rst_n, MISO;
output MOSI, SCLK, SS_n;
output reg[11:0] pot_0, pot_1, pot_2, pot_3, pot_4, pot_5;
wire MISO, MOSI, SCLK, SS_n;

// create 2D structure to hold channel number for pot 0-5
localparam CHNL_0 = 3'b000;
localparam CHNL_1 = 3'b001;
localparam CHNL_2 = 3'b010;
localparam CHNL_3 = 3'b011;
localparam CHNL_4 = 3'b100;
localparam CHNL_5 = 3'b111;

reg [2:0] channels [0:5] = '{CHNL_0, CHNL_1, CHNL_2, CHNL_3, CHNL_4, CHNL_5};
reg [2:0] channel_num;
//reg [11:0] pot_0, pot_1, pot_2, pot_3, pot_4, pot_5;
reg [1:0] clk_counter;
reg [2:0] channel;
wire clk, rst_n, start_cnv, cnv_complete;
wire [11:0] result;

adc_spi SPI_MODULE(clk, rst_n, channel, start_cnv, result, cnv_complete, MISO, MOSI, SCLK, SS_n);
//ADC128S ADC_MODULE(clk, rst_n, SS_n, SCLK, MISO, MOSI);

reg first_conversion_flag;

always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		channel <= 3'b000; //reset channel to zero at start of transmission
	else
		channel <= channels[channel_num];
end


// counts four clocks when converion is done to change channel
// and start the next converstion process
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		clk_counter <= 2'b00;
	else if (cnv_complete || ~first_conversion_flag)
		clk_counter <= clk_counter + 1;
	else
		clk_counter <= 2'b00;
end


always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) begin 		// clear pot values on reset
		pot_0 <= 12'h0000;
		pot_1 <= 12'h0000;
		pot_2 <= 12'h0000;
		pot_3 <= 12'h0000;
		pot_4 <= 12'h0000;
		pot_5 <= 12'h0000;	
	end
	else if (cnv_complete && clk_counter == 0) begin
		case (channel)
			CHNL_0 : pot_0 <= result;
			CHNL_1 : pot_1 <= result;
			CHNL_2 : pot_2 <= result;
			CHNL_3 : pot_3 <= result;
			CHNL_4 : pot_4 <= result;
			CHNL_5 : pot_5 <= result;
		endcase
	end
end


// increment the channel number two clocks after converstion complete
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		channel_num <= 3'b000; //reset channel to 6 to wrap around after reset
	else if(clk_counter == 2'b10 && first_conversion_flag)
		 if(channel_num == 3'b101)
			channel_num <= 3'b00;
		 else
			channel_num <= channel_num + 1;
end

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		first_conversion_flag <= 0;
	end else if(clk_counter == 2'b11) begin
		first_conversion_flag <= 1;
	end
end

assign start_cnv = (clk_counter == 2'b11) ? 1'b1 : 1'b0;




endmodule
