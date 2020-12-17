.section .text
.balign 4

.global multi_add
.global multi_sub

#define carry       t0
#define temp_carry  t5
#define index       t1
#define a_addr      a0
#define b_addr      a1
#define res_addr    a2
#define a_value     t2
#define b_value     t3
#define res_value   t4
#define n_words     a3
#define carry_out   a0


// extern int multi_add(const void *a, const void *b, void *res, int n_words);
multi_add:
    li   carry, 0
    li   index, 0
multi_add_start:
    beq  index, n_words, multi_add_end
    lw   a_value, (a_addr)
    lw   b_value, (b_addr)
    add  res_value, a_value, carry   // res = a + carry
    sltu carry, res_value, a_value   // check overflow
    add  res_value, res_value, b_value   // res += b
    sltu temp_carry, res_value, b_value   // check overflow
    or   carry, carry, temp_carry   // combine carry results 
    sw   res_value, (res_addr)
    addi index, index, 1
    addi a_addr, a_addr, 4
    addi b_addr, b_addr, 4
    addi res_addr, res_addr, 4
    j    multi_add_start  
multi_add_end:
    mv   carry_out, carry       // return final carry
    ret

// extern int multi_sub(const void *a, const void *b, void *res, int n_words);
multi_sub:
    li   carry, 1        // initialise carry to 1 for subtract
    li   index, 0
multi_sub_start:
    beq  index, n_words, multi_sub_end
    lw   a_value, (a_addr)
    lw   b_value, (b_addr)
    not  b_value, b_value       // invert second arg for subtract
    add  res_value, a_value, carry   // res = a + carry
    sltu carry, res_value, a_value   // check overflow
    add  res_value, res_value, b_value   // res += b
    sltu temp_carry, res_value, b_value   // check overflow
    or   carry, carry, temp_carry   // combine carry results 
    sw   res_value, (res_addr)
    addi index, index, 1
    addi a_addr, a_addr, 4
    addi b_addr, b_addr, 4
    addi res_addr, res_addr, 4
    j    multi_sub_start
multi_sub_end:
    mv   carry_out, carry       // return final carry
    ret

