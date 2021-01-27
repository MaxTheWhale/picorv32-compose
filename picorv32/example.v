`timescale 1 ns / 1 ps
`include "../cores/LedDisplay.v"

module top (
	input clk,
	output reg led1, led2, led3, led4, led5, led6, led7, led8,
	output lcol1, lcol2, lcol3, lcol4
);
	reg [7:0] leds1;
	reg [7:0] leds2;
	reg [7:0] leds3 = 8'b0;
	reg [7:0] leds4 = 8'b0;

	reg [2:0] brightness = 3'b111;

	LedDisplay display (
		.clk12MHz(clk),
		.led1,
		.led2,
		.led3,
		.led4,
		.led5,
		.led6,
		.led7,
		.led8,
		.lcol1,
		.lcol2,
		.lcol3,
		.lcol4,

		.leds1,
		.leds2,
		.leds3,
		.leds4,
		.leds_pwm(brightness)
	);
	
	// -------------------------------
	// Reset Generator

	reg [7:0] resetn_counter = 0;
	wire resetn = &resetn_counter;

	always @(posedge clk) begin
		if (!resetn)
			resetn_counter <= resetn_counter + 1;
	end


	// -------------------------------
	// PicoRV32 Core

	wire mem_valid;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;

	reg mem_ready;
	reg [31:0] mem_rdata;

	picorv32 #(
		.ENABLE_COUNTERS(1),
		.LATCHED_MEM_RDATA(1),
		.TWO_STAGE_SHIFT(0),
		.TWO_CYCLE_ALU(0),
		.CATCH_MISALIGN(0),
		.CATCH_ILLINSN(0)
	) cpu (
		.clk      (clk      ),
		.resetn   (resetn   ),
		.mem_valid(mem_valid),
		.mem_ready(mem_ready),
		.mem_addr (mem_addr ),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata)
	);

	// -------------------------------
	// PicoRV32 Core2

	wire mem_valid2;
	wire [31:0] mem_addr2;
	wire [31:0] mem_wdata2;
	wire [3:0] mem_wstrb2;

	reg mem_ready2;
	reg [31:0] mem_rdata2;

	picorv32 #(
		.ENABLE_COUNTERS(1),
		.LATCHED_MEM_RDATA(1),
		.TWO_STAGE_SHIFT(0),
		.TWO_CYCLE_ALU(0),
		.CATCH_MISALIGN(0),
		.CATCH_ILLINSN(0)
	) cpu2 (
		.clk      (clk      ),
		.resetn   (resetn   ),
		.mem_valid(mem_valid2),
		.mem_ready(mem_ready2),
		.mem_addr (mem_addr2 ),
		.mem_wdata(mem_wdata2),
		.mem_wstrb(mem_wstrb2),
		.mem_rdata(mem_rdata2)
	);

	// // -------------------------------
	// // PicoRV32 Core3

	// wire mem_valid3;
	// wire [31:0] mem_addr3;
	// wire [31:0] mem_wdata3;
	// wire [3:0] mem_wstrb3;

	// reg mem_ready3;
	// reg [31:0] mem_rdata3;

	// picorv32 #(
	// 	.ENABLE_COUNTERS(0),
	// 	.LATCHED_MEM_RDATA(1),
	// 	.TWO_STAGE_SHIFT(0),
	// 	.TWO_CYCLE_ALU(1),
	// 	.CATCH_MISALIGN(0),
	// 	.CATCH_ILLINSN(0)
	// ) cpu3 (
	// 	.clk      (clk      ),
	// 	.resetn   (resetn   ),
	// 	.mem_valid(mem_valid3),
	// 	.mem_ready(mem_ready3),
	// 	.mem_addr (mem_addr3 ),
	// 	.mem_wdata(mem_wdata3),
	// 	.mem_wstrb(mem_wstrb3),
	// 	.mem_rdata(mem_rdata3)
	// );

	// // -------------------------------
	// // PicoRV32 Core4

	// wire mem_valid4;
	// wire [31:0] mem_addr4;
	// wire [31:0] mem_wdata4;
	// wire [3:0] mem_wstrb4;

	// reg mem_ready4;
	// reg [31:0] mem_rdata4;

	// picorv32 #(
	// 	.ENABLE_COUNTERS(0),
	// 	.LATCHED_MEM_RDATA(1),
	// 	.TWO_STAGE_SHIFT(0),
	// 	.TWO_CYCLE_ALU(1),
	// 	.CATCH_MISALIGN(0),
	// 	.CATCH_ILLINSN(0)
	// ) cpu4 (
	// 	.clk      (clk      ),
	// 	.resetn   (resetn   ),
	// 	.mem_valid(mem_valid4),
	// 	.mem_ready(mem_ready4),
	// 	.mem_addr (mem_addr4 ),
	// 	.mem_wdata(mem_wdata4),
	// 	.mem_wstrb(mem_wstrb4),
	// 	.mem_rdata(mem_rdata4)
	// );


	// -------------------------------
	// Memory/IO Interface

	// 512 32bit words = 2048 bytes memory
	localparam MEM_SIZE = 512;
	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory);

	reg [31:0] memory2 [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory2);

	// reg [31:0] memory3 [0:MEM_SIZE-1];
	// initial $readmemh("firmware.hex", memory3);

	// reg [31:0] memory4 [0:MEM_SIZE-1];
	// initial $readmemh("firmware.hex", memory4);

	always @(posedge clk) begin
		mem_ready <= 0;
		mem_ready2 <= 0;
		mem_ready3 <= 0;
		mem_ready4 <= 0;
		if (resetn && mem_valid && !mem_ready) begin
			(* parallel_case *)
			case (1)
				!mem_wstrb && (mem_addr >> 2) < MEM_SIZE: begin
					mem_rdata <= memory[mem_addr >> 2];
					mem_ready <= 1;
				end
				|mem_wstrb && (mem_addr >> 2) < MEM_SIZE: begin
					if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
					if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
					if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
					mem_ready <= 1;
				end
				|mem_wstrb && mem_addr == 32'h1000_0000: begin
					leds1 <= mem_wdata;
					mem_ready <= 1;
				end
			endcase
		end
		if (resetn && mem_valid2 && !mem_ready2) begin
			(* parallel_case *)
			case (1)
				!mem_wstrb2 && (mem_addr2 >> 2) < MEM_SIZE: begin
					mem_rdata2 <= memory2[mem_addr2 >> 2];
					mem_ready2 <= 1;
				end
				|mem_wstrb2 && (mem_addr2 >> 2) < MEM_SIZE: begin
					if (mem_wstrb2[0]) memory2[mem_addr2 >> 2][ 7: 0] <= mem_wdata2[ 7: 0];
					if (mem_wstrb2[1]) memory2[mem_addr2 >> 2][15: 8] <= mem_wdata2[15: 8];
					if (mem_wstrb2[2]) memory2[mem_addr2 >> 2][23:16] <= mem_wdata2[23:16];
					if (mem_wstrb2[3]) memory2[mem_addr2 >> 2][31:24] <= mem_wdata2[31:24];
					mem_ready2 <= 1;
				end
				|mem_wstrb2 && mem_addr2 == 32'h1000_0000: begin
					leds2 <= mem_wdata2;
					mem_ready2 <= 1;
				end
			endcase
		end
		// if (resetn && mem_valid3 && !mem_ready3) begin
		// 	(* parallel_case *)
		// 	case (1)
		// 		!mem_wstrb3 && (mem_addr3 >> 2) < MEM_SIZE: begin
		// 			mem_rdata3 <= memory3[mem_addr3 >> 2];
		// 			mem_ready3 <= 1;
		// 		end
		// 		|mem_wstrb3 && (mem_addr3 >> 2) < MEM_SIZE: begin
		// 			if (mem_wstrb3[0]) memory3[mem_addr3 >> 2][ 7: 0] <= mem_wdata3[ 7: 0];
		// 			if (mem_wstrb3[1]) memory3[mem_addr3 >> 2][15: 8] <= mem_wdata3[15: 8];
		// 			if (mem_wstrb3[2]) memory3[mem_addr3 >> 2][23:16] <= mem_wdata3[23:16];
		// 			if (mem_wstrb3[3]) memory3[mem_addr3 >> 2][31:24] <= mem_wdata3[31:24];
		// 			mem_ready3 <= 1;
		// 		end
		// 		|mem_wstrb3 && mem_addr3 == 32'h1000_0000: begin
		// 			leds3 <= mem_wdata3;
		// 			mem_ready3 <= 1;
		// 		end
		// 	endcase
		// end
		// if (resetn && mem_valid4 && !mem_ready4) begin
		// 	(* parallel_case *)
		// 	case (1)
		// 		!mem_wstrb4 && (mem_addr4 >> 2) < MEM_SIZE: begin
		// 			mem_rdata4 <= memory4[mem_addr4 >> 2];
		// 			mem_ready4 <= 1;
		// 		end
		// 		|mem_wstrb4 && (mem_addr4 >> 2) < MEM_SIZE: begin
		// 			if (mem_wstrb4[0]) memory4[mem_addr4 >> 2][ 7: 0] <= mem_wdata4[ 7: 0];
		// 			if (mem_wstrb4[1]) memory4[mem_addr4 >> 2][15: 8] <= mem_wdata4[15: 8];
		// 			if (mem_wstrb4[2]) memory4[mem_addr4 >> 2][23:16] <= mem_wdata4[23:16];
		// 			if (mem_wstrb4[3]) memory4[mem_addr4 >> 2][31:24] <= mem_wdata4[31:24];
		// 			mem_ready4 <= 1;
		// 		end
		// 		|mem_wstrb4 && mem_addr4 == 32'h1000_0000: begin
		// 			leds4 <= mem_wdata4;
		// 			mem_ready4 <= 1;
		// 		end
		// 	endcase
		// end
	end
endmodule
