# 01_bitwise_imm.asm: andi/ori with bit15=1; lui with bit15=1
# Covers Tabla 3:
#   andi, ori - inmediato con bit15=1 (extensión en cero)
#   lui       - inmediato con bit15=1
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
fmt_andi:  .asciiz "andi: 0x"
fmt_ori:   .asciiz " ori: 0x"
fmt_lui:   .asciiz " lui: 0x"
newline:   .asciiz "\n"

.text
.globl main
main:
    # Test 1: andi con inmediato bit15=1 (0x8000 = bit15=1, extensión en cero)
    # 0xFFFF & 0x8000 = 0x8000
    li   $t0, 0xFFFF
    andi $t1, $t0, 0x8000
    la   $a0, fmt_andi
    jal  print_str
    move $a0, $t1
    jal  print_hex
    jal  print_newline

    # Test 2: ori con inmediato bit15=1 (0x8000)
    # 0x0000 | 0x8000 = 0x8000
    li   $t0, 0x0000
    ori  $t1, $t0, 0x8000
    la   $a0, fmt_ori
    jal  print_str
    move $a0, $t1
    jal  print_hex
    jal  print_newline

    # Test 3: lui con inmediato bit15=1 (0x8000)
    # 0x8000 << 16 = 0x80000000
    lui  $t1, 0x8000
    la   $a0, fmt_lui
    jal  print_str
    move $a0, $t1
    jal  print_hex
    jal  print_newline

    # Salir
    li   $v0, 10
    syscall

# Imprime string en $a0 (syscall 4 no permitido, usa 11 por char)
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
    addi $a0, $t2, 48     # '0' + d
    j    print_hex_put
print_hex_letter:
    addi $a0, $t2, 87     # 'a' + d - 10
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
