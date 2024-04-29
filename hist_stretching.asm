        .data
file:   .space 100
title:  .asciz  "Histogram stretching\n"
prompt: .asciz  "Enter filename, only bmp files supported\n"

        .text
        .globl main
main:
        #title message
        li a7, 4
        la a0, title
        ecall

        #prompt
        li a7, 4
        la a0, prompt
        ecall

        li a7, 8
        la a0, file
        li a1, 100
        ecall

end:
        li a7, 10
        ecall