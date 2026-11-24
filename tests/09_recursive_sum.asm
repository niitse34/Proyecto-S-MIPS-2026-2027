# 09_recursive_sum.asm: Two recursive calls and saved registers
# Covers Tabla 3:
#   add - operandos positivos y negativos
#   addi - inmediato negativo
#   addiu/addu - via li/move (para sp, ra)
#   srl - shamt≠0
#   beq, bne - tomado y no tomado
#   jal, jr - procedimiento no hoja, guardando $ra en la pila
#   lw, sw - acceso a array y pila
#   syscall 11, 10
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
.align 2
values: .word 1, 2, 3, 4, 5, 6, 7, 8
.text
.globl main
main:
    addiu $sp, $sp, -4
    la   $a0, values
    li   $a1, 8
    jal  sum_range
    move $t9, $v0
    move $a0, $t9
    jal  print_hex
    jal  print_newline
    li   $v0, 10
    syscall

# sum_range(a0=base,a1=n>=0) -> v0=sum; all intermediate sums must fit.
# Preserves s0-s3. 24-byte frame: saved s0..s3, ra, padding.
sum_range:
    addiu $sp, $sp, -24
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)
    move $s0, $a0
    move $s1, $a1
    beq  $s1, $zero, sum_empty
    li   $t0, 1
    beq  $s1, $t0, sum_one
    srl  $s2, $s1, 1   # k=floor(n/2), survives first recursive call
    move $a1, $s2
    jal  sum_range
    move $s3, $v0     # Left answer must survive SECOND recursive call
    sll  $t0, $s2, 2
    addu $a0, $s0, $t0
    subu $a1, $s1, $s2
    jal  sum_range
    add  $v0, $s3, $v0
    j    sum_return
sum_one:
    lw   $v0, 0($s0)
    j    sum_return
sum_empty:
    move $v0, $zero
sum_return:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addiu $sp, $sp, 24
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
