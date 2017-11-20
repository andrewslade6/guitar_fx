module memory_mod(w_en, d_in, d_out, r_addr, w_addr, clk, rst_n);

input wire w_en, clk, rst_n;
input reg[15:0] d_in;
input reg[14:0] r_addr, w_addr;

output reg[15:0] d_out;

// memory
reg [15:0] memory [0:29280];

// read write logic
always_ff @(posedge clk or negedge rst_n) begin
	if(w_en)
		memory[w_addr] <= d_in;
end

assign d_out = memory[r_addr];


endmodule
