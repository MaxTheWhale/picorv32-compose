.section .text
.global main

.equ	OUTPUT_ADDR, 0x10000000

main:
    // Initialise counter and comparison value
    li a0, (2+4+32+64)
    slli a0, a0, 18
    li a1, 0
    not a1, a1
    slli a1, a1, 18
    not a1, a1
counter_loop:
    and a2, a0, a1
    addi a0, a0, 1
    beq a2, zero, call_grey
    j counter_loop
call_grey:
    srli a3, a0, 18
    jal ra, grey_encode
    jal ra, output_byte
    j counter_loop

// a4 <= grey encoded version of a3
grey_encode:
    srli a4, a3, 1
    xor  a4, a4, a3
    jr   ra

// output low byte of a4 to LEDs
output_byte:
    li   t1, OUTPUT_ADDR
    sb   a4, (t1)
    jr   ra
