# Exercises word and byte loads/stores using the documented 0x2000 data base.
.data
.align 2
word_value: .word 0x12345678
byte_values: .word 0xff007f80

.text
main:
    lui  $t0, 0
    ori  $t0, $t0, 0x2000
    lw   $a0, 0($t0)
    lui  $s3, 0x1234
    ori  $s3, $s3, 0x5678
    bne  $a0, $s3, fail

    lui  $s0, 0xabcd
    ori  $s0, $s0, 0xef01
    sw   $s0, 0($t0)
    lw   $a0, 0($t0)
    bne  $a0, $s0, fail

    addi $t1, $t0, 4
    lb   $a0, 0($t1)
    addi $s3, $zero, -128
    bne  $a0, $s3, fail
    lbu  $a0, 0($t1)
    addi $s3, $zero, 128
    bne  $a0, $s3, fail
    lb   $a0, 1($t1)
    addi $s3, $zero, 127
    bne  $a0, $s3, fail
    lbu  $a0, 3($t1)
    addi $s3, $zero, 255
    bne  $a0, $s3, fail

    addi $t2, $zero, 65
    sb   $t2, 1($t1)
    lbu  $a0, 1($t1)
    bne  $a0, $t2, fail
    addi $t2, $zero, 85
    sb   $t2, 3($t1)
    lbu  $a0, 3($t1)
    bne  $a0, $t2, fail

    addi $a0, $zero, 77
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
