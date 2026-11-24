# Final smoke test for the requested S-MIPS instruction subset.
.data
.align 2
initial_word: .word 0x12345678
byte_values:  .word 0xff007f80

.text
main:
    jal  check_alu
    addi $t7, $zero, 0
    beq  $v0, $zero, fail
    addi $t7, $zero, 0
    jal  check_memory
    addi $t7, $zero, 0
    beq  $v0, $zero, fail
    addi $t7, $zero, 0
    jal  check_control
    addi $t7, $zero, 0
    beq  $v0, $zero, fail
    addi $t7, $zero, 0

    addi $a0, $zero, 80
    j    report
    addi $t7, $zero, 0
fail:
    addi $a0, $zero, 33
report:
    addi $v0, $zero, 11
    syscall
    addi $a0, $zero, 10
    addi $v0, $zero, 11
    syscall
    addi $v0, $zero, 10
    syscall

check_alu:
    addi $s0, $zero, 7
    addi $s1, $zero, 3
    add  $t0, $s0, $s1
    addi $t1, $zero, 10
    bne  $t0, $t1, alu_fail
    sub  $t0, $s0, $s1
    addi $t1, $zero, 4
    bne  $t0, $t1, alu_fail
    and  $t0, $s0, $s1
    addi $t1, $zero, 3
    bne  $t0, $t1, alu_fail
    or   $t0, $s0, $s1
    addi $t1, $zero, 7
    bne  $t0, $t1, alu_fail
    slt  $t0, $s1, $s0
    addi $t1, $zero, 1
    bne  $t0, $t1, alu_fail
    slt  $t0, $s0, $s1
    bne  $t0, $zero, alu_fail
    slti $t0, $s1, 4
    bne  $t0, $t1, alu_fail
    slti $t0, $s0, 4
    bne  $t0, $zero, alu_fail
    sll  $t0, $s0, 2
    addi $t1, $zero, 28
    bne  $t0, $t1, alu_fail
    srl  $t0, $s0, 1
    addi $t1, $zero, 3
    bne  $t0, $t1, alu_fail
    addi $t0, $s0, -2
    addi $t1, $zero, 5
    bne  $t0, $t1, alu_fail
    addiu $t0, $zero, -1
    addi  $t1, $zero, -1
    bne   $t0, $t1, alu_fail
    addu  $t0, $t0, $s0
    addi  $t1, $zero, 6
    bne   $t0, $t1, alu_fail
    addiu $t0, $zero, -1
    andi  $t0, $t0, 0x00ff
    addi  $t1, $zero, 255
    bne   $t0, $t1, alu_fail
    ori   $t0, $zero, 0x1234
    addi  $t1, $zero, 0x1234
    bne   $t0, $t1, alu_fail
    lui   $t0, 0x1234
    sll   $t1, $t1, 16
    bne   $t0, $t1, alu_fail

    add  $zero, $s0, $s1
    sub  $zero, $s0, $s1
    and  $zero, $s0, $s1
    or   $zero, $s0, $s1
    slt  $zero, $s1, $s0
    sll  $zero, $s0, 1
    srl  $zero, $s0, 1
    addi $zero, $zero, 5
    addiu $zero, $zero, 5
    addu $zero, $s0, $s1
    slti $zero, $s0, 8
    andi $zero, $s0, 7
    ori  $zero, $zero, 1
    lui  $zero, 0x1234
    bne  $zero, $zero, alu_fail
    addi $v0, $zero, 1
    jr   $ra
alu_fail:
    add  $v0, $zero, $zero
    jr   $ra

check_memory:
    lui  $t0, 0
    ori  $t0, $t0, 0x2000
    lw   $t1, 0($t0)
    lui  $t2, 0x1234
    ori  $t2, $t2, 0x5678
    bne  $t1, $t2, memory_fail
    lui  $t2, 0xabcd
    ori  $t2, $t2, 0xef01
    sw   $t2, 0($t0)
    lw   $t1, 0($t0)
    bne  $t1, $t2, memory_fail
    addi $t3, $t0, 4
    lb   $t1, 0($t3)
    addi $t2, $zero, -128
    bne  $t1, $t2, memory_fail
    lbu  $t1, 0($t3)
    addi $t2, $zero, 128
    bne  $t1, $t2, memory_fail
    lb   $t1, 1($t3)
    addi $t2, $zero, 127
    bne  $t1, $t2, memory_fail
    lbu  $t1, 3($t3)
    addi $t2, $zero, 255
    bne  $t1, $t2, memory_fail
    addi $t2, $zero, 65
    sb   $t2, 1($t3)
    lbu  $t1, 1($t3)
    bne  $t1, $t2, memory_fail
    addi $t2, $zero, 85
    sb   $t2, 3($t3)
    lbu  $t1, 3($t3)
    bne  $t1, $t2, memory_fail
    addi $v0, $zero, 1
    jr   $ra
memory_fail:
    add  $v0, $zero, $zero
    jr   $ra

check_control:
    addi $t0, $zero, 1
    beq  $t0, $t0, beq_ok
    addi $v0, $zero, 0
    jr   $ra
beq_ok:
    bne  $t0, $zero, bne_ok
    addi $v0, $zero, 0
    jr   $ra
bne_ok:
    beq  $t0, $zero, control_fail
    addi $t7, $zero, 0
    bne  $t0, $t0, control_fail
    j    jump_ok
    addi $v0, $zero, 0
    jr   $ra
jump_ok:
    addi $v0, $zero, 1
    jr   $ra
control_fail:
    add  $v0, $zero, $zero
    jr   $ra
