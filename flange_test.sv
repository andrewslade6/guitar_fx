module flange_test();
reg clk, rst_n;



flanger_dig_core iDUT(clk, rst_n, VALID, left_in, right_in, left_out, right_out, flange_vol_slider, rate_slider);





initial begin
rst_n = 0;
#10;
rst_n = 1;

#(1024*10) $stop;
end


initial begin
	clk = 0;
	forever begin
		#5 clk = ~clk;
	end
end



endmodule // flange_test
