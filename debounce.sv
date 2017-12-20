module debounce(
    input clk, //this is a 50MHz clock provided on FPGA pin PIN_Y2
    input rst_n,
    input PB,  //this is the input to be debounced
     output reg b_fall  //this is the debounced switch
);

reg PB_state;
// Synchronize the switch input to the clock
reg PB_sync_0;
always @(posedge clk) PB_sync_0 <= PB; 
reg PB_sync_1;
always @(posedge clk) PB_sync_1 <= PB_sync_0;

// Debounce the switch
reg [15:0] PB_cnt;
always @(posedge clk)
if(PB_state==PB_sync_1)
    PB_cnt <= 0;
else
begin
    PB_cnt <= PB_cnt + 1'b1;  
    if(PB_cnt == 16'hffff) PB_state <= ~PB_state;  
end

reg b1, b2;
//edge detection for valid
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
		b1 <= 1'b0;
		b2 <= 1'b0;
	end else begin
		b1 <= PB_state;
		b2 <= b1;
	end  
end
//edge detection on valid
assign b_fall = ~b1 & b2;

endmodule