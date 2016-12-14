.data
.text
.align 2
# Saving variables
main:   #main
sub   $sp, $sp, 8
sw    $fp, 8($sp)
sw    $ra, 4($sp)
addi  $fp, $sp, 8
sub   $sp, $sp, 8
# Line 4
#  fp 
li    $t0, 4
add   $v1, $fp, $t0
li    $t1, 5
sw    $v1, 0($t1)
# Line 5
#  fp 
add   $t2, $fp, $t0
lw    $t3, 0($t2)
# T3
li    $t5, 2
add   $t4, $t3, $t5
#  fp 
li    $t7, 0
add   $t6, $fp, $t7
sw    $t6, 0($t4)
# Line 6
#  fp 
add   $t8, $fp, $t7
lw    $t9, 0($t8)
#  fp 
add   $s0, $fp, $t0
lw    $s1, 0($s0)
# T7
add   $s2, $t9, $s1
#  fp 
add   $s3, $fp, $t0
sw    $s3, 0($s2)
li    $v0, 10
syscall
