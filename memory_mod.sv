module memory_mod(w_en, d_in, d_out, r_addr, w_addr, clk, rst_n);

input wire w_en, clk, rst_n;
input reg[15:0] d_in;
input reg[15:0] r_addr, w_addr;

output reg[15:0] d_out;

// memory d29280 = h7260 = 0.6 seconds of samples
reg [15:0] memory [48827:0];

// read write logic
always_ff @(posedge clk)	begin
	if(w_en) 
		memory[w_addr] <= d_in;
	d_out = memory[r_addr];

end

endmodule 
