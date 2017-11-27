module memory_mod(w_en, d_in, d_out, r_addr, w_addr, clk, rst_n);

input wire w_en, clk, rst_n;
input wire[15:0] d_in;
input reg[14:0] r_addr, w_addr;

output reg[15:0] d_out;

// memory
reg [15:0] memory [29280:0];

// read write logic
always_ff @(posedge clk) begin
	if(w_en)
		memory[w_addr] <= d_in;
	d_out = memory[r_addr];
	
end

endmodule
