module adc_spi_tb();

reg clk, rst_n;
reg start_cnv; 
reg [2:0] channel;

wire cnv_complete, MOSI, MISO, SCLK, SS_n;
wire [11:0] result;


spi_master SPI_MODULE(clk, rst_n, channel, start_cnv, result, cnv_complete, MISO, MOSI, SCLK, SS_n);
ADC128S ADC_MODULE(clk, rst_n, SS_n, SCLK, MISO, MOSI);


initial begin

	channel = 3'b001;
	rst_n = 0;
	start_cnv = 0;

	#50;

	@(negedge clk) begin
		rst_n = 1;
		start_cnv = 1;
	end
	@(negedge clk) begin
		start_cnv = 0;
	end

	# 10640 $stop;

end

initial begin
	clk = 0;
	forever begin
		#5 clk = ~clk;
	end
end



endmodule
