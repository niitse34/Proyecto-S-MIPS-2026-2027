# 08_array_stats.asm: Traverse a word array
# Covers Tabla 3:
#   add - operandos positivos y negativos
#   slt - resultado 1 y 0; con negativos (signo vs sin signo)
#   lw - acceso a array
#   beq, bne - tomado y no tomado; salto hacia atrás
#   j - al menos una vez
# Solo S-MIPS + pseudo (li, move); syscalls 11,10.
# MARS 4.5; Default memory; pseudo habilitadas.

.data
.align 2
values: .word 7, -2, 9, 0
fmt_sum: .asciiz "sum: "
fmt_min: .asciiz " min: "
fmt_max: .asciiz " max: "
newline: .asciiz "\n"

.text
.globl main
main:
    la   $t0, values      # Puntero al elemento actual
    li   $t1, 4          # Elementos restantes
    lw   $t3, 0($t0)     # min inicializado desde elemento real
    move $t4, $t3        # max
    move $t2, $zero      # sum

loop:
    beq  $t1, $zero, done
    lw   $t5, 0($t0)
    add  $t2, $t2, $t5   # Suma (desbordamiento permitido)
    slt  $t6, $t5, $t3
    beq  $t6, $zero, check_max
    move $t3, $t5
check_max:
    slt  $t6, $t4, $t5
    beq  $t6, $zero, next
    move $t4, $t5
next:
    addiu $t0, $t0, 4    # Stride de palabra = 4 bytes
    addiu $t1, $t1, -1
    bne  $t1, $zero, loop
done:
    # Imprimir sum
    la   $a0, fmt_sum
    jal  print_str
    move $a0, $t2
    jal  print_hex
    jal  print_newline

    # Imprimir min
    la   $a0, fmt_min
    jal  print_str
    move $a0, $t3
    jal  print_hex
    jal  print_newline

    # Imprimir max
    la   $a0, fmt_max
    jal  print_str
    move $a0, $t4
    jal  print_hex
    jal  print_newline

    # Salir
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
