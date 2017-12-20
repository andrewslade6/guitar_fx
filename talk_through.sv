module talk_through(clk, RESET, SD_out, MCLK, SCLK, LRCLK, SD_in, RST_n, LED, MISO, MOSI, A2D_SCLK, A2D_SS_n, PB);

input clk, RESET, SD_out, MISO, PB;
output LRCLK, SCLK, MCLK, SD_in, RST_n, LED, MOSI, A2D_SCLK, A2D_SS_n;

wire clk, RESET;
reg rst_n, rst_ff_n;
wire [7:0] LED;

// wires for interconnecting all effects
wire [15:0] F_wire, C_wire, D_wire, R_wire;
wire [15:0] F_out,  C_out,  D_out,  R_out;
reg F_on, C_on, D_on, R_on;

//outputs for codec_interface
wire LRCLK, SCLK, MCLK, RST_n, SD_in, SD_out, VALID;
wire[15:0] left_in, right_in;
wire[15:0] left_out, right_out;

// connections for 6 sliders
wire [11:0]  pot_0, pot_1, pot_2, pot_3, pot_4, pot_5;
wire MISO, MOSI, A2D_SCLK, A2D_SS_n;


typedef enum reg[2:0] {TALK_THROUGH, FLANGER, CHORUS, DELAY, REVERB} state_t;
state_t state, next_state;


slider_interface SLIDERS(.clk(clk), .rst_n(rst_n), .pot_0(pot_0), .pot_1(pot_1), 
	.pot_2(pot_2), .pot_3(pot_3), .pot_4(pot_4), .pot_5(pot_5), .MISO(MISO), 
	.MOSI(MOSI), .SCLK(A2D_SCLK), .SS_n(A2D_SS_n));

wire PB_state;
debounce PB_debounce(.clk(clk), .rst_n(rst_n),.PB(PB), .b_fall(PB_state));


//////////////////////////////////////////////////////////


flanger_dig_core fdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(left_in),
	.right_in(right_in), .left_out(F_out), .flange_vol_slider(pot_1), .rate_slider(pot_2));

chorus_dig_core_2 cdc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(F_wire),
	.right_in(right_in), .left_out(C_out), .flange_vol_slider(pot_1), .rate_slider(pot_2));

delay_dig_core ddc(.clk(clk), .rst_n(rst_n), .VALID(VALID), .left_in(C_wire),
	.right_in(right_in), .left_out(D_out), .d_vol_slider(pot_1), .f_vol_slider(pot_2), .d_time_slider(pot_3));

codec_interface CODEC_INT(.clk(clk), .rst_n(rst_n), .SD_out(SD_out), 
	.left_out(R_wire), .right_out(R_wire), .LRCLK(LRCLK), .SCLK(SCLK),
	.MCLK(MCLK), .RST_n(RST_n), .SD_in(SD_in), .left_in(left_in), 
	.right_in(right_in), .VALID(VALID));

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		F_on <= 0;
		C_on <= 0;
		D_on <= 0;
		R_on <= 0;
	end else begin
		case(state)
			FLANGER : begin 
				if (PB_state) F_on <= ~F_on;
			end
			CHORUS 	: begin 
				if (PB_state) C_on <= ~C_on;
			end
			DELAY 	: begin 
				if (PB_state) D_on <= ~D_on;
			end
			REVERB 	: begin
				if (PB_state) R_on <= ~R_on;
			end
		endcase 
	end
end




// interconnect all pedals
assign F_wire = (F_on) ? F_out : left_in;
assign C_wire = (C_on) ? C_out : F_wire;
assign D_wire = (D_on) ? D_out : C_wire;
assign R_wire = (R_on) ? R_out : D_wire;



  //////////////////////////////////////////////////////
  // Sync deassertion of rst_n with negedge of clock //
  ////////////////////////////////////////////////////
  always @(negedge clk, negedge RESET)
    if (!RESET)
	  begin
	    rst_ff_n <= 1'b0;
	    rst_n <= 1'b0;
	  end
	else
	  begin
	    rst_ff_n <= 1'b1;
		rst_n <= rst_ff_n;
	  end


// next state logic
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= TALK_THROUGH;
	else
		state <= next_state;
end


always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		next_state <= TALK_THROUGH;
		LED   <= 8'h00;
	end else begin
		case(pot_0[11:8])
			4'b1111 : begin
				LED 	<= {1'b1, R_on, 6'b000000};
				next_state 	<= REVERB;
			end
			4'b0111 : begin
				LED 	<= {3'b001, D_on, 4'b0000};
				next_state 	<= DELAY;
			end
			4'b0011 : begin
				LED 	<= {5'b00001, C_on, 2'b00};
				next_state 	<= CHORUS;
			end
			4'b0001 : begin
				LED 	<= {7'b0000001, F_on};
				next_state 	<= FLANGER;
			end
			default : begin
				LED 	<= 8'h00;
				next_state 	<= TALK_THROUGH;
			end
		endcase
	end
end




/*always_comb begin
next_state = TALK_THROUGH;
lights = 8'b0000_0000;
	case(state)
		TALK_THROUGH : begin
			lights = 8'b0000_0000;
			if(PB_state) next_state = FLANGER;
		end
		FLANGER : begin
			next_state = FLANGER;
			lights = 8'b0000_0011;
			lights[1] = F_on;
			if(PB_state) next_state = CHORUS;
		end
		CHORUS : begin
			next_state = CHORUS;
			lights = 8'b0000_1100;
			lights[3] = C_on;
			if(PB_state) next_state = DELAY;
		end
		DELAY : begin
			next_state = DELAY;
			lights = 8'b0011_0000;
			lights[5] = D_on;
			if(PB_state) next_state = REVERB;
		end
		REVERB : begin
			next_state = REVERB;
			lights = 8'b1100_0000;
			lights[7] = R_on;
			if(PB_state) next_state = TALK_THROUGH;
		end
	endcase
end*/

endmodule//endmodule codec_interface_tb
