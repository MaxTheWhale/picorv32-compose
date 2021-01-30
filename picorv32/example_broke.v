`timescale 1 ns / 1 ps
`include "../cores/LedDisplay.v"
`include "../cores/uart.v"

module top (
	input clk,
	output reg led1, led2, led3, led4, led5, led6, led7, led8,
	output lcol1, lcol2, lcol3, lcol4, uart_tx
);

	localparam MULTICORE = 0;
	localparam N_CORES = 1;
	localparam N_CORES_BITS = (N_CORES == 4) ? 2 : 1;

	// -------------------------------
	// LED Display

	reg [31:0] leds = 32'b0;

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

	reg [N_CORES_BITS-1:0] mem_arb_counter = 0;
	reg [N_CORES_BITS-1:0] mem_la_arb_counter = 1;

	always @(posedge clk) begin
		if (!resetn) begin
			resetn_counter <= resetn_counter + 1;
		end
	end

	wire [N_CORES - 1:0] mem_valid;
	wire [32*N_CORES - 1:0] mem_la_addr;
	wire [32*N_CORES - 1:0] mem_la_wdata;
	wire [4*N_CORES - 1:0] mem_la_wstrb;

	reg [N_CORES - 1:0] mem_ready;
	reg [32*N_CORES - 1:0] mem_rdata;

	reg [10:0] mem_addr_low;
	reg [3:0] mem_addr_high;
	reg [31:0] mem_wdata;
	reg [3:0] mem_wstrb;

	wire trap_wire;

	// -------------------------------
	// PicoRV32 Cores
	genvar core_num;
	generate
		for (core_num = 0; core_num < N_CORES; core_num = core_num + 1) begin
			
			/* verilator lint_off PINMISSING */
			picorv32 #(
				.ENABLE_COUNTERS(1),
				.LATCHED_MEM_RDATA(1),
				.TWO_STAGE_SHIFT(0),
				.TWO_CYCLE_ALU(0),
				.CATCH_MISALIGN(0),
				.CATCH_ILLINSN(0),
				.HART_ID(core_num)
			) cpu (
				.clk      (clk      ),
				.resetn   (resetn   ),
				.mem_valid(mem_valid    [core_num]),
				.mem_ready(mem_ready    [core_num]),
				.mem_la_addr(mem_la_addr[32*core_num + 31 -: 32]),
				.mem_la_wdata(mem_la_wdata [32*core_num + 31 -: 32]),
				.mem_la_wstrb(mem_la_wstrb [4*core_num  + 3  -: 4]),
				.mem_rdata(mem_rdata    [32*core_num + 31 -: 32]),
				.trap(trap_wire)
			);
			/* verilator lint_on PINMISSING */

		end
	endgenerate

	reg [7:0] tx_data;
	reg tx_send;
	wire uart_ready;
	uart uart0 (
		.clk12MHz(clk),
		.tx(uart_tx),
		.sendData(tx_data),
		.sendReq(tx_send),
		.ready(uart_ready)
	);

	// -------------------------------
	// Memory/IO Interface

	// 512 32bit words = 2048 bytes memory
	localparam MEM_SIZE = 2048;
	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory);

	always @(posedge clk) begin

		leds[27] <= trap_wire;

		mem_arb_counter <= mem_arb_counter + 1;
		mem_la_arb_counter <= mem_la_arb_counter + 1;

		if (MULTICORE) begin
			// mem_addr_low <= mem_la_addr[32*mem_la_arb_counter + 12 -: 11];
			// mem_addr_high <= mem_la_addr[32*mem_la_arb_counter + 31 -: 4];
			// mem_wdata <= mem_la_wdata[32*mem_la_arb_counter + 31 -: 32];
			// mem_wstrb <= mem_la_wstrb[4*mem_la_arb_counter + 3 -: 4];
		end else begin
			mem_addr_low <= mem_la_addr[12:2];
			mem_addr_high <= mem_la_addr[31:28];
			mem_wdata <= mem_la_wdata[31:0];
			mem_wstrb <= mem_la_wstrb[3:0];
		end

		mem_ready <= 0;
		tx_send <= 0;

		if (MULTICORE) begin
			
			// if (resetn && mem_valid[mem_arb_counter] && !mem_ready[mem_arb_counter]) begin
			// 	(* parallel_case *)
			// 	case (1)
			// 		!(|mem_wstrb) && (mem_addr_high == 4'h0): begin
			// 			mem_rdata[32*mem_arb_counter + 31 -: 32] <= memory[mem_addr_low];
			// 			mem_ready[mem_arb_counter] <= 1;	
			// 		end
			// 		|mem_wstrb && (mem_addr_high == 4'h0): begin
			// 			if (mem_wstrb[0]) memory[mem_addr_low][ 7: 0] <= mem_wdata[ 7: 0];
			// 			if (mem_wstrb[1]) memory[mem_addr_low][15: 8] <= mem_wdata[15: 8];
			// 			if (mem_wstrb[2]) memory[mem_addr_low][23:16] <= mem_wdata[23:16];
			// 			if (mem_wstrb[3]) memory[mem_addr_low][31:24] <= mem_wdata[31:24];
			// 			mem_ready[mem_arb_counter] <= 1;
			// 			if (mem_arb_counter == 1) leds[26:24] <= mem_addr_low[10: 8];
			// 			if (mem_arb_counter == 1) leds[23:16] <= mem_addr_low[ 7: 0];
			// 		end
			// 		|mem_wstrb && (mem_addr_high == 4'h1): begin
			// 			leds[8*mem_addr_low[0] + 7 -: 8] <= mem_wdata[7:0];
			// 			mem_ready[mem_arb_counter] <= 1;
			// 		end
			// 		!(|mem_wstrb) && (mem_addr_high == 4'h2): begin
			// 			mem_ready[mem_arb_counter] <= 1;
			// 			mem_rdata[32*mem_arb_counter + 31 -: 32] <= {31'b0, uart_ready};
			// 		end
			// 		|mem_wstrb && (mem_addr_high == 4'h2): begin
			// 			tx_data <= mem_wdata[7:0];
			// 			tx_send <= 1;
			// 			mem_ready[mem_arb_counter] <= 1;
			// 		end
			// 	endcase
			// end

		end else begin
			
			if (resetn && mem_valid[0] && !mem_ready[0]) begin
				leds[31:28] <= mem_wstrb;
				leds[26:24] <= mem_addr_low[10: 8];
				leds[23:16] <= mem_addr_low[ 7: 0];
				leds[15:8] <= mem_wdata[ 7: 0];
				(* parallel_case *)
				case (1)
					!(|mem_wstrb) && (mem_addr_high == 4'h0): begin
						mem_rdata[31:0] <= memory[mem_addr_low];
						mem_ready <= 1;	
					end
					|mem_wstrb && (mem_addr_high == 4'h0): begin
						if (mem_wstrb[0]) memory[mem_addr_low][ 7: 0] <= mem_wdata[ 7: 0];
						if (mem_wstrb[1]) memory[mem_addr_low][15: 8] <= mem_wdata[15: 8];
						if (mem_wstrb[2]) memory[mem_addr_low][23:16] <= mem_wdata[23:16];
						if (mem_wstrb[3]) memory[mem_addr_low][31:24] <= mem_wdata[31:24];
						mem_ready <= 1;
					end
					|mem_wstrb && (mem_addr_high == 4'h1): begin
						leds[7:0] <= mem_wdata[7:0];
						mem_ready <= 1;
					end
					!(|mem_wstrb) && (mem_addr_high == 4'h2): begin
						mem_rdata[31:0] <= {31'b0, uart_ready};
						mem_ready <= 1;
					end
					|mem_wstrb && (mem_addr_high == 4'h2): begin
						tx_data <= mem_wdata[7:0];
						tx_send <= 1;
						mem_ready <= 1;
					end
				endcase
			end

		end
		
	end
endmodule
