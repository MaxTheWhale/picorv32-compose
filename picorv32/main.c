#include <stdint.h>
#include "uart.h"

#define SHIFT_COUNTER_BITS 15

uint32_t get_hart_id() {
    uint32_t id;
    asm ("csrr %0, 0xf10" : "=r"(id) : : );
    return id;
}

void output(uint8_t c)
{
	*(volatile char*)(0x10000000 + get_hart_id()) = c;
    if (get_hart_id() == 0) puts("Hello world!");
}

uint8_t gray_encode_simple(uint8_t c)
{
	return c ^ (c >> 1);
}

uint8_t gray_encode_bitwise(uint8_t c)
{
	unsigned int in_buf = c, out_buf = 0, bit = 1;
	for (int i = 0; i < 8; i++) {
		if ((in_buf & 1) ^ ((in_buf >> 1) & 1))
			out_buf |= bit;
		in_buf = in_buf >> 1;
		bit = bit << 1;
	}
	return out_buf;
}

uint8_t gray_decode(uint8_t c)
{
	uint8_t t = c >> 1;
	while (t) {
		c = c ^ t;
		t = t >> 1;
	}
	return c;
}

void gray(uint8_t c)
{
	uint8_t gray_simple = gray_encode_simple(c);
	uint8_t gray_bitwise = gray_encode_bitwise(c);
	uint8_t gray_decoded = gray_decode(gray_simple);

	if (gray_simple != gray_bitwise || gray_decoded != c)
		while (1) asm volatile ("ebreak");

	output(gray_simple);
}

void main()
{
    uint32_t shift_bits = SHIFT_COUNTER_BITS + get_hart_id();
	for (uint32_t counter = (2+4+32+64) << shift_bits;; counter++) {
		asm volatile ("" : : "r"(counter));
		if ((counter & ~(~0 << shift_bits)) == 0)
			gray(counter >> shift_bits);
	}
}
