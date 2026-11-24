# 07_fibonacci_dp.asm: Bottom-up dynamic programming (hardcoded n=10)
# Covers Tabla 3:
#   add - operandos positivos
#   sw, lw - acceso a array (tabla DP)
#   slt, bne, j - control de bucles
#   sll - multiplicación por 4 (shamt≠0)
#   syscall 11, 10
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
.align 2
table: .space 188      # 47 words, indexes 0..46
error: .asciiz "Use n in 0..46\n"
fmt: .asciiz "F(n) = "
newline: .asciiz "\n"

.text
.globl main
main:
    # Hardcoded n = 10 (F(10) = 55)
    li   $t7, 10
    la   $t0, table
    sw   $zero, 0($t0)
    li   $t1, 1
    sw   $t1, 4($t0)
    li   $t2, 2
loop:
    slt  $t3, $t7, $t2
    bne  $t3, $zero, done
    sll  $t4, $t2, 2
    addu $t4, $t0, $t4
    lw   $t5, -4($t4)
    lw   $t6, -8($t4)
    add  $t5, $t5, $t6
    sw   $t5, 0($t4)
    addiu $t2, $t2, 1
    j    loop
done:
    sll  $t4, $t7, 2
    addu $t4, $t0, $t4
    lw   $t9, 0($t4)
    la   $a0, fmt
    jal  print_str
    move $a0, $t9
    jal  print_hex
    jal  print_newline
    li   $v0, 10
    syscall

# Imprime string en $a0 (usa syscall 11)
print_str:
    move $t0, $a0
print_str_loop:
    lbu  $a0, 0($t0)
    beqz $a0, print_str_done
    li   $v0, 11
    syscall
    addi $t0, $t0, 1
    j    print_str_loop
print_str_done:
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
