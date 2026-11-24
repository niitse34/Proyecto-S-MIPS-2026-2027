# Exercises taken and untaken branches, j, jal, jr, and character output.
.text
main:
    addi $t0, $zero, 1
    beq  $t0, $t0, beq_ok
    addi $a0, $zero, 33
    jal  emit
beq_ok:
    addi $a0, $zero, 65
    jal  emit

    bne  $t0, $zero, bne_ok
    addi $a0, $zero, 33
    jal  emit
bne_ok:
    addi $a0, $zero, 66
    jal  emit

    beq  $t0, $zero, branch_error
    bne  $t0, $t0, branch_error
    addi $a0, $zero, 67
    jal  emit

    j    jump_ok
    addi $a0, $zero, 33
    jal  emit
jump_ok:
    jal  make_d
    jal  emit

    addi $a0, $zero, 10
    addi $v0, $zero, 11
    syscall
    addi $v0, $zero, 10
    syscall

branch_error:
    addi $a0, $zero, 33
    jal  emit
    addi $v0, $zero, 10
    syscall

make_d:
    addi $a0, $zero, 68
    jr   $ra

emit:
    addi $v0, $zero, 11
    syscall
    jr   $ra
