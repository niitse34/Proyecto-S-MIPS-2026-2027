# 08_recursive_factorial.asm: Non-leaf recursion and stack frames (hardcoded n=6)
# Covers Tabla 3:
#   add, mult, mflo - aritmética (using add loop instead of mult/mflo)
#   addi, slti, bne - control
#   jal, jr - recursión no hoja con pila
#   syscall 11, 10
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
error: .asciiz "Use n in 0..12\n"
fmt: .asciiz "Factorial: "
newline: .asciiz "\n"

.text
.globl main
main:
    # Hardcoded n = 6 (6! = 720)
    li   $a0, 6
    jal  factorial
    move $t9, $v0
    move $a0, $t9
    jal  print_hex
    jal  print_newline
    li   $v0, 10
    syscall

# factorial(a0=n in 0..12) -> v0=n!; preserves all s registers and sp.
# Every invocation owns 8 bytes: n at 0(sp), saved ra at 4(sp).
factorial:
    addiu $sp, $sp, -8
    sw    $a0, 0($sp)
    sw    $ra, 4($sp)     # jal below overwrites the live return address
    slti  $t0, $a0, 2
    bne   $t0, $zero, fact_base
    addiu $a0, $a0, -1
    jal   factorial
    lw    $t0, 0($sp)     # Do not trust a0 or t registers across the call
    # Replace mult/mflo with add loop for multiplication
    move $t1, $zero       # result = 0
    beq   $v0, $zero, mult_done
mult_loop:
    beq  $t0, $zero, mult_done
    add  $t1, $t1, $v0
    addiu $t0, $t0, -1
    bnez $t0, mult_loop
mult_done:
    move $v0, $t1
fact_return:
    lw    $ra, 4($sp)
    addiu $sp, $sp, 8
    jr    $ra
fact_base:
    li    $v0, 1
    j     fact_return
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
