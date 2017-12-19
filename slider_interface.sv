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
reg [2:0] channel;
wire clk, rst_n, cnv_complete;
wire [11:0] result;
reg start_first_time, start_cnv, conv_ff1, conv_ff2, conv_fall, conv_rise, not_first_conv;
reg [2:0] startup_delay;

spi_master SPI_MODULE(clk, rst_n, channel, start_cnv, result, cnv_complete, MISO, MOSI, SCLK, SS_n);


//edge detection for cnv_complete
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
		conv_ff1 <= 1'b1;
		conv_ff2 <= 1'b1;
	end else begin
	    conv_ff1 <= cnv_complete;
		conv_ff2 <= conv_ff1;
	end  
end
//negedge detection on SCLK
assign conv_fall = ~conv_ff1 & conv_ff2;
//posedge detection on SCLK
assign conv_rise = conv_ff1 & ~conv_ff2;

always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		not_first_conv <= 1'b0; //reset channel to zero at start of transmission
	else if (conv_rise)
		not_first_conv <= 1'b1;
end

always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		channel <= 3'b000; //reset channel to zero at start of transmission
	else
		channel <= channels[channel_num];
end

// starts the very first conversion
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)
		startup_delay <= 3'b000; 
	else
		startup_delay <= startup_delay + 1;
end

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		start_first_time <= 1'b0;
	else if (startup_delay == 3'b111)
		start_first_time <= 1'b1;
end


// starts a new conversion when cnv_complete
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		start_cnv <= 1'b0; 
	else if (startup_delay[2] && !start_first_time)
		start_cnv <= 1'b1;
	else if (conv_rise)
		start_cnv <= 1'b1;
	else
		start_cnv <= 1'b0;
end


always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) begin 		// clear pot values on reset
		pot_0 <= 12'h000;
		pot_1 <= 12'h000;
		pot_2 <= 12'h000;
		pot_3 <= 12'h000;
		pot_4 <= 12'h000;
		pot_5 <= 12'h000;	
	end
	else if (conv_rise & not_first_conv) begin
		case (channel)
			CHNL_0 : pot_5 <= result;
			CHNL_1 : pot_0 <= result;
			CHNL_2 : pot_1 <= result;
			CHNL_3 : pot_2 <= result;
			CHNL_4 : pot_3 <= result;
			CHNL_5 : pot_4 <= result;
		endcase
	end
end

// increment channel pointer
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n) 	
		channel_num <= 3'b000; 
	else if (conv_rise)
		 if (channel_num == 3'b101)
			 channel_num <= 3'b000;
		 else
			 channel_num <= channel_num + 1;
end



endmodule
