.global multi_add
.global multi_sub

// extern int multi_add(const void *a, const void *b, void *res, int n_words);
multi_add:
    li   t0, 0
    li   t1, 0
multi_add_start:
    beq  t1, a3, multi_add_end
    lw   t2, (a0)
    lw   t3, (a1)
    add  t4, t2, t0   // res = a + carry
    sltu t0, t4, t2   // check overflow
    add  t4, t4, t3   // res += b
    sltu t5, t4, t3   // check overflow
    or   t0, t0, t5   // combine carry results 
    sw   t4, (a2)
    addi t1, t1, 1
    addi a0, a0, 4
    addi a1, a1, 4
    addi a2, a2, 4
    j    multi_add_start  
multi_add_end:
    mv   a0, t0       // return final carry
    jr   ra

multi_sub:
    li   t0, 1        // initialise carry to 1 for subtract
    li   t1, 0
multi_sub_start:
    beq  t1, a3, multi_sub_end
    lw   t2, (a0)
    lw   t3, (a1)
    not  t3, t3       // invert second arg for subtract
    add  t4, t2, t0   // res = a + carry
    sltu t0, t4, t2   // check overflow
    add  t4, t4, t3   // res += b
    sltu t5, t4, t3   // check overflow
    or   t0, t0, t5   // combine carry results 
    sw   t4, (a2)
    addi t1, t1, 1
    addi a0, a0, 4
    addi a1, a1, 4
    addi a2, a2, 4
    j    multi_sub_start  
multi_sub_end:
    mv   a0, t0       // return final carry
    jr   ra
