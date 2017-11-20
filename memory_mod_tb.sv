module memory_mod_tb();

reg 		clk, rst_n, w_en;
reg[15:0] 	d_in;
reg[14:0] 	r_addr, w_addr;
wire[15:0] 		d_out;

memory_mod MEMORYTHANG(w_en, d_in, d_out, r_addr, w_addr, clk, rst_n);

initial begin
	rst_n = 0;
	clk = 1;
	w_en = 0;
	r_addr = 15'h0;
	#5 rst_n = 1;

	#10;
	// write consecutive 16 bit words in consecutive addresses
	for(reg [15:0] i = 0; i < 29280; i++) begin
		@(negedge clk) begin
			d_in = i;
			w_addr = i[14:0];
			r_addr = i[14:0];
			w_en = 1;
		end

		@(posedge clk) begin
			assert(d_out == i) else $display("ERROR: read write error: Read %h Expected %h", d_out, i);
		end
	end

	@(negedge clk) w_en = 0;

$stop;

end

always begin
#10 clk = ~clk;
end


endmodule

