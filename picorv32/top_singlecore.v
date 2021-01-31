`include "../cores/LedDisplay.v"
`include "../cores/uart.v"

module top (
	input clk,
	output reg led1, led2, led3, led4, led5, led6, led7, led8,
	output lcol1, lcol2, lcol3, lcol4, uart_tx
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

		.leds1   (leds[ 7: 0]),
		.leds2   (leds[15: 8]),
		.leds3   (leds[23:16]),
		.leds4   (leds[31:24]),
		.leds_pwm(brightness)
	);

	// -------------------------------
	// Memory/IO Interface

	// 2048 32bit words = 8192 bytes memory
	localparam MEM_SIZE = 2048;
	localparam MEM_BITS = $clog2(MEM_SIZE);
	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory);

	// -------------------------------
	// PicoRV32 Core

	wire [31:0] mem_la_addr;
	wire [31:0] mem_la_wdata;
	wire [ 3:0] mem_la_wstrb;
	wire        mem_la_read;
	wire        mem_la_write;

	reg [3:0] mem_addr_high;
	reg [MEM_BITS-1:0] mem_addr_low;
	reg [31:0] mem_wdata;
	reg [ 3:0] mem_wstrb;
	reg        mem_read = 0;
	reg        mem_write = 0;

	reg [31:0] mem_rdata;
	reg        mem_ready;

	/* verilator lint_off PINMISSING */
	picorv32 #(
		.ENABLE_COUNTERS(1),
		.LATCHED_MEM_RDATA(1),
		.TWO_STAGE_SHIFT(0),
		.TWO_CYCLE_ALU(0),
		.CATCH_MISALIGN(1),
		.CATCH_ILLINSN(1),
        .HART_ID(0)
	) cpu (
		.clk         (clk      ),
		.resetn      (resetn   ),
		.mem_la_read (mem_la_read),
		.mem_la_write(mem_la_write),
		.mem_ready   (mem_ready),
		.mem_la_addr (mem_la_addr ),
		.mem_la_wdata(mem_la_wdata),
		.mem_la_wstrb(mem_la_wstrb),
		.mem_rdata   (mem_rdata)
	);
	/* verilator lint_on PINMISSING */

	// -------------------------------
	// UART Transmitter

    reg [7:0] tx_data;
	reg       tx_send;

	wire      tx_ready;

	uart uart0 (
		.clk12MHz(clk),
		.tx      (uart_tx),
		.sendData(tx_data),
		.sendReq (tx_send),
		.ready   (tx_ready)
	);

	always @(posedge clk) begin

		if (mem_la_read || mem_la_write) begin
			mem_addr_low <= mem_la_addr[MEM_BITS+1:2];
			mem_addr_high <= mem_la_addr[31:28];
			mem_wdata <= mem_la_wdata;
			mem_read  <= mem_la_read;
			mem_write <= mem_la_write;
			mem_write <= mem_la_write;
			mem_wstrb <= mem_la_wstrb;
		end

		mem_ready <= 0;
        tx_send   <= 0;

		if (resetn && (mem_read || mem_write) && !mem_ready) begin
			(* parallel_case *)
			case (1)
				mem_read && mem_addr_high == 4'h0: begin
					mem_rdata <= memory[mem_addr_low];
					mem_ready <= 1;
				end
				mem_write && mem_addr_high == 4'h0: begin
					if (mem_wstrb[0]) memory[mem_addr_low][ 7: 0] <= mem_wdata[ 7: 0];
					if (mem_wstrb[1]) memory[mem_addr_low][15: 8] <= mem_wdata[15: 8];
					if (mem_wstrb[2]) memory[mem_addr_low][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) memory[mem_addr_low][31:24] <= mem_wdata[31:24];
					mem_ready <= 1;
				end
				mem_write && mem_addr_high == 4'h1: begin
					leds[7:0] <= mem_wdata[7:0];
					mem_ready <= 1;
				end
                mem_read && mem_addr_high == 4'h2: begin
					mem_rdata <= {31'b0, tx_ready};
					mem_ready <= 1;
				end
                mem_write && mem_addr_high == 4'h2: begin
					tx_data   <= mem_wdata[7:0];
					tx_send   <= 1;
					mem_ready <= 1;
				end
			endcase
			mem_read  <= 0;
			mem_write <= 0;
		end
	end
endmodule
