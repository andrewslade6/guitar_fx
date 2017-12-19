module slider_interface_tb();

wire [11:0] pot_0, pot_1, pot_2, pot_3, pot_4, pot_5;
wire MISO, MOSI, SCLK, SS_n;
reg clk, rst_n;

slider_interface iDUT(clk, rst_n, pot_0, pot_1, pot_2, pot_3, pot_4, pot_5, MISO, MOSI, SCLK, SS_n);
ADC128S ADC_MODULE(clk, rst_n, SS_n, SCLK, MISO, MOSI);  // used for simulation
initial begin
rst_n = 0;

#10 rst_n = 1;

# 206400 $stop;

end


initial begin
	clk = 0;
	forever begin
		#5 clk = ~clk;
	end
end

endmodule
