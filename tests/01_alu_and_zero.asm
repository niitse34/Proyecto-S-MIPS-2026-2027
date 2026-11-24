# Checks the requested integer ALU instructions and the immutable $zero register.
.text
main:
    addi $s0, $zero, 7
    addi $s1, $zero, 3

    add  $a0, $s0, $s1
    addi $s3, $zero, 10
    bne  $a0, $s3, fail
    sub  $a0, $s0, $s1
    addi $s3, $zero, 4
    bne  $a0, $s3, fail
    and  $a0, $s0, $s1
    addi $s3, $zero, 3
    bne  $a0, $s3, fail
    or   $a0, $s0, $s1
    addi $s3, $zero, 7
    bne  $a0, $s3, fail
    slt  $a0, $s1, $s0
    addi $s3, $zero, 1
    bne  $a0, $s3, fail
    slt  $a0, $s0, $s1
    bne  $a0, $zero, fail
    slti $a0, $s1, 4
    bne  $a0, $s3, fail
    slti $a0, $s0, 4
    bne  $a0, $zero, fail
    sll  $a0, $s0, 2
    addi $s3, $zero, 28
    bne  $a0, $s3, fail
    srl  $a0, $s0, 1
    addi $s3, $zero, 3
    bne  $a0, $s3, fail

    addiu $s2, $zero, -1
    addi  $s3, $zero, -1
    bne   $s2, $s3, fail
    addu  $a0, $s2, $s0
    addi  $s3, $zero, 6
    bne   $a0, $s3, fail
    andi  $a0, $s2, 0x00ff
    addi  $s3, $zero, 255
    bne   $a0, $s3, fail
    ori   $a0, $zero, 0x1234
    addi  $s3, $zero, 0x1234
    bne   $a0, $s3, fail
    lui   $a0, 0x1234
    addi  $s3, $zero, 0x1234
    sll   $s3, $s3, 16
    bne   $a0, $s3, fail

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
    bne  $zero, $zero, fail

    addi $a0, $zero, 65
    j    report
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
