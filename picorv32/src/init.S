.section .init
.global main

/* set stack pointer */
li sp, 8192

/* adjust stack pointer by hart id (256 bytes per hart) */
csrr t0, 0xF10
slli t0, t0, 8
sub  sp, sp, t0

/* call main */
jal ra, main

/* break */
ebreak



