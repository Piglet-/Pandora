    .data 
strings: .word 42

    .text 

main:   jal readI 
        addi $sp, $sp, -4
        sw $t1, 0($sp)
        j writeI

writeI: li $v0, 1
        lw $a0, 0($sp)
        syscall
        
        li $v0, 10
        syscall

readI:  li $v0, 5
        syscall
        move $t1, $v0
        j $ra