.section .text
.global main

.equ	OUTPUT_ADDR, 0x10000000

main:
    // Initialise counter and comparison value
    li a0, (2+4+32+64)
    csrr t3, 0xF10
    slli t3, t3, 2
    addi t4, t3, 15
    sll a0, a0, t4
    li a1, 0
    not a1, a1
    sll a1, a1, t4
    not a1, a1
counter_loop:
    and a2, a0, a1
    addi a0, a0, 1
    beq a2, zero, call_grey
    j counter_loop
call_grey:
    srl a3, a0, t4
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
    add  t1, t1, t3
    sb   a3, (t1)
    jr   ra
