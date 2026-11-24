# 03_linear_search.asm: Linear search with hardcoded key
# Covers Tabla 3:
#   lw - acceso a array
#   beq - tomado y no tomado
#   jal, jr - procedimiento hoja
#   slt - comparación con signo
#   sll - multiplicación por 4 (shamt≠0)
#   add, addiu - aritmética básica
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
.align 2
values: .word 4, 8, 4, 12
fmt_found:  .asciiz "Found at index: "
fmt_not:    .asciiz "Not found: "
newline:    .asciiz "\n"

.text
.globl main
main:
    # Hardcoded key = 4 (found at index 0 and 2, returns first = 0)
    li   $a2, 4           # key = 4
    la   $a0, values
    li   $a1, 4
    jal  find_first
    move $t9, $v0
    move $a0, $t9
    jal  print_hex
    jal  print_newline
    li   $v0, 10
    syscall

# find_first(a0=base, a1=count>=0, a2=key) -> v0=index or -1.
# Read-only; clobbers t0-t4, v0. Leaf: no stack frame needed.
find_first:
    move $t0, $zero
find_loop:
    slt  $t1, $t0, $a1
    beq  $t1, $zero, find_absent
    sll  $t2, $t0, 2
    addu $t2, $a0, $t2
    lw   $t3, 0($t2)
    beq  $t3, $a2, find_found
    addiu $t0, $t0, 1
    j    find_loop
find_found:
    move $v0, $t0
    jr   $ra
find_absent:
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
