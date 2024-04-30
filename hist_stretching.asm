        .eqv    size, t1
        .eqv    allocated, t2
        .eqv    offset, t3
        .eqv    in_decriptor, s0
        .eqv    out_decriptor, s1
        .eqv    width, s2
        .eqv    height, s3

        .data
buf:    .space  100 # buffor for data
in:     .space  100 # input filename
out:    .space  100 # output filename
title:  .asciz  "Histogram stretching\n"
prompt_in: .asciz  "Enter input filename: "
prompt_out: .asciz  "Enter output filename: "
error:  .asciz  "Error reading file\n"
info:   .asciz  "File has been opened successfuly"
inv_name:.asciz  "Filename cannot be blank"

        .macro quit
        li a7, 10
        ecall
        .end_macro

        .macro print %text
        li a7, 4
        la a0, %text
        ecall
        .end_macro

        .macro get_name %buf, %size
        li a7, 8
        la a0, %buf
        li a1, %size
        ecall
        .end_macro

        .macro check_first_character %buf
        la t0, %buf
        lb t1, (t0)
        beqz t1, invalid_name
        .end_macro

        .macro open_file %name, %flag
        li a7, 1024
        la a0, %name
        li a1, %flag
        ecall
        .end_macro

        .macro read_from_file %num_of_bytes %buf
        mv a0, in_decriptor
        la a1, %buf
        li a2, %num_of_bytes
        li a7, 63
        ecall
        .end_macro

        .text
        .globl main
main:
        print title

        print prompt_in
        get_name in, 100

        print prompt_out
        get_name out, 100

        check_first_character in
        check_first_character out

        li t2, '\n'
        la a0, in

remove_new_line_1:
        lbu t1, (a0)
        addi a0, a0, 1
        bne t1, t2, remove_new_line_1

        addi a0, a0, -1
        sb zero, (a0)

load_next_name:
        la a0, out

remove_new_line_2:
        lbu t1, (a0)
        addi a0, a0, 1
        bne t1, t2, remove_new_line_2

        addi a0, a0, -1
        sb zero, (a0)

open_files:
        # open input file and save decriptor
        open_file in, 0
        bltz a0, error_reading
        mv in_decriptor, a0

        # open ouptut file and save decriptor
        open_file out, 1
        mv out_decriptor, a0

read_header:
        read_from_file 2 buf    # read first 2 bytes of bmp header
        read_from_file 12 buf   # read rest of bmp header

        la t4, buf
        lw size, (t4)   # load bitmap size
        lw offset, 8(t4) # load offset

        # allocate memory
        li a7, 9
        mv a0, size
        ecall

        mv allocated, a0

        read_from_file 12 buf

        # load image width and height
        la t4, buf
        lw width, 4(t4)
        lw height, 8(t4)

        beqz width, error_reading
        beqz height, error_reading

error_reading:
        print error
        quit

invalid_name:
        print inv_name
        quit