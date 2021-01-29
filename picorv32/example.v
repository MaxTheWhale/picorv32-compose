`timescale 1 ns / 1 ps
`include "../cores/LedDisplay.v"

module top (
	input clk,
	output reg led1, led2, led3, led4, led5, led6, led7, led8,
	output lcol1, lcol2, lcol3, lcol4
);

	reg [31:0] leds;

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

		.leds1(leds[7:0]),
		.leds2(leds[15:8]),
		.leds3(leds[23:16]),
		.leds4(leds[31:24]),
		.leds_pwm(brightness)
	);
	
	// -------------------------------
	// Reset Generator

	reg [7:0] resetn_counter = 0;
	wire resetn = &resetn_counter;

	reg [1:0] mem_arb_counter;

	always @(posedge clk) begin
		if (!resetn)
			resetn_counter <= resetn_counter + 1;
	end


	// -------------------------------
	// PicoRV32 Core

	wire [1:0] mem_valid;
	wire [63:0] mem_la_addr;
	wire [63:0] mem_wdata;
	wire [7:0] mem_wstrb;

	reg [1:0] mem_ready;
	reg [63:0] mem_rdata;

	/* verilator lint_off PINMISSING */
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
		.mem_valid(mem_valid[0]),
		.mem_ready(mem_ready[0]),
		.mem_la_addr(mem_la_addr[31:0]),
		.mem_wdata(mem_wdata[31:0]),
		.mem_wstrb(mem_wstrb[3:0]),
		.mem_rdata(mem_rdata[31:0])
	);

	// -------------------------------
	// PicoRV32 Core2

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
		.mem_valid(mem_valid[1]),
		.mem_ready(mem_ready[1]),
		.mem_la_addr(mem_la_addr[63:32]),
		.mem_wdata(mem_wdata[63:32]),
		.mem_wstrb(mem_wstrb[7:4]),
		.mem_rdata(mem_rdata[63:32])
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
	// 	.ENABLE_COUNTERS(1),
	// 	.LATCHED_MEM_RDATA(1),
	// 	.TWO_STAGE_SHIFT(0),
	// 	.TWO_CYCLE_ALU(0),
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
	// 	.ENABLE_COUNTERS(1),
	// 	.LATCHED_MEM_RDATA(1),
	// 	.TWO_STAGE_SHIFT(0),
	// 	.TWO_CYCLE_ALU(0),
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
	/* verilator lint_on PINMISSING */


	// -------------------------------
	// Memory/IO Interface

	reg [31:0] mem_addr;

	// 512 32bit words = 2048 bytes memory
	localparam MEM_SIZE = 2048;
	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory);

	always @(posedge clk) begin
		mem_arb_counter <= mem_arb_counter + 1;

		mem_ready <= 2'b0;

		mem_addr <= mem_la_addr[32*(!mem_arb_counter[0]) + 31 -: 32];

		if (resetn && mem_valid[mem_arb_counter[0]] && !mem_ready[mem_arb_counter[0]]) begin
			(* parallel_case *)
			case (1)
				!(|mem_wstrb[4*mem_arb_counter[0] + 3 -: 4]) && !(|mem_addr[31 -: 19]): begin
					mem_rdata[32*mem_arb_counter[0] + 31 -: 32] <= memory[mem_addr[12 -: 11]];
					mem_ready[mem_arb_counter[0]] <= 1;
				end
				|mem_wstrb[4*mem_arb_counter[0] + 3 -: 4] && !(|mem_addr[31 -: 19]): begin
					if (mem_wstrb[4*mem_arb_counter[0]]) memory[mem_addr[12 -: 11]][ 7: 0] <= mem_wdata[32*mem_arb_counter[0] + 7 -: 8];
					if (mem_wstrb[4*mem_arb_counter[0] + 1]) memory[mem_addr[12 -: 11]][15: 8] <= mem_wdata[32*mem_arb_counter[0] + 15 -: 8];
					if (mem_wstrb[4*mem_arb_counter[0] + 2]) memory[mem_addr[12 -: 11]][23:16] <= mem_wdata[32*mem_arb_counter[0] + 23 -: 8];
					if (mem_wstrb[4*mem_arb_counter[0] + 3]) memory[mem_addr[12 -: 11]][31:24] <= mem_wdata[32*mem_arb_counter[0] + 31 -: 8];
					mem_ready[mem_arb_counter[0]] <= 1;
				end
				|mem_wstrb[4*mem_arb_counter[0] + 3 -: 4] && mem_addr[31 -: 32] == 32'h1000_0000: begin
					leds[8*mem_arb_counter[0] + 7 -: 8] <= mem_wdata[32*mem_arb_counter[0] + 7 -: 8];
					mem_ready[mem_arb_counter[0]] <= 1;
				end
			endcase
		end
		
	end
endmodule
