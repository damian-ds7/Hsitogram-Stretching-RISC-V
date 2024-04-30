        .eqv    file_decriptor, t0
        .eqv    size, t1
        .eqv    allocated, t2
        .eqv    offset, t3

        .data
buf:    .space  100 # buffor for data
in:     .space  100 # input filename
out:    .space  100 # output filename
title:  .asciz  "Histogram stretching\n"
prompt: .asciz  "Enter filename: "
error:  .asciz  "Error reading file\n"
info:   .asciz  "File has been opened successfuly"

        .text
        .globl main
main:
        #title message
        li a7, 4
        la a0, title
        ecall

        # prompt
        li a7, 4
        la a0, prompt
        ecall

        # ask for filename
        li a7, 8
        la a0, in
        li a1, 100
        ecall

        li t2, '\n'

remove_new_line:
        lbu t1, (a0)
        addi a0, a0, 1
        bne t1, t2, remove_new_line

        addi a0, a0, -1
        sb zero, (a0)

        li a0, 0
        li t1, 0
        li t2, 0

open_file:
        # open file
        li a7, 1024
        la a0, in
        li a1, 0
        ecall

        bltz a0, error_reading
        mv file_decriptor, a0

read_header:
        # read first 2 bytes of bmp header
        la a1, buf
        li a2, 2
        li a7, 63
        ecall

        # read rest of bmp header
        mv a0, file_decriptor
        la a1, buf
        li a2, 12
        li a7, 63
        ecall

        la t4, buf
        lw size, (t4) # load bitmap size
        addi t4, t4, 8
        lw offset, (t4) # load offset

        # allocate memory
        li a7, 9
        mv a0, size
        ecall

        mv allocated, a0

error_reading:
        # erro message
        li a7, 4
        la a0, error
        ecall

        li a7, 10
        ecall
