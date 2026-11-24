# 06_binary_search.asm: Binary search with hardcoded key
# Covers Tabla 3:
#   lw - acceso a array
#   beq, bne - tomado y no tomado
#   slt, sltu - comparación con signo y sin signo
#   srl, subu, sll - aritmética de índices
#   jal, jr - procedimiento no hoja
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
.align 2
values: .word -8, -1, 3, 7, 12, 20
fmt: .asciiz "Index: "
newline: .asciiz "\n"

.text
.globl main
main:
    # Hardcoded key = 3 (found at index 2)
    li   $a2, 3
    la   $a0, values
    li   $a1, 6
    jal  binary_search
    move $t9, $v0
    move $a0, $t9
    jal  print_hex
    jal  print_newline
    li   $v0, 10
    syscall

# binary_search(a0=base, a1=n>=0, a2=key) -> v0=index or -1.
# Sorted signed words; half-open interval [lo,hi); any matching duplicate.
# Clobbers t0-t6. Does not change the array.
binary_search:
    move $t0, $zero    # lo
    move $t1, $a1      # hi
bs_loop:
    slt  $t2, $t0, $t1
    beq  $t2, $zero, bs_absent
    subu $t3, $t1, $t0
    srl  $t3, $t3, 1
    addu $t3, $t3, $t0 # mid=lo+(hi-lo)/2
    sll  $t4, $t3, 2
    addu $t4, $a0, $t4
    lw   $t5, 0($t4)
    beq  $t5, $a2, bs_found
    slt  $t6, $t5, $a2
    beq  $t6, $zero, bs_left
    addiu $t0, $t3, 1 # Exclude mid; it is too small
    j    bs_loop
bs_left:
    move $t1, $t3     # Exclude mid; it is too large
    j    bs_loop
bs_found:
    move $v0, $t3
    jr   $ra
bs_absent:
    li   $v0, -1
    jr   $ra
print_hex:
    move $t0, $a0
    li   $t1, 8
print_hex_loop:
    srl  $t2, $t0, 28
    slti $t3, $t2, 10
    beqz $t3, print_hex_letter
    addi $a0, $t2, 48
    j    print_hex_put
print_hex_letter:
    addi $a0, $t2, 87
print_hex_put:
    li   $v0, 11
    syscall
    sll  $t0, $t0, 4
    addi $t1, $t1, -1
    bnez $t1, print_hex_loop
    jr   $ra
print_newline:
    li   $a0, 10
    li   $v0, 11
    syscall
    jr   $ra
