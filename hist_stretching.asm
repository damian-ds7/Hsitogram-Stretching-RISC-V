        .eqv    size, t0
        .eqv    allocated, t1
        .eqv    offset, t2
        .eqv    file_decriptor, s0
        .eqv    out_decriptor, s1
        .eqv    width, s2
        .eqv    height, s3
        .eqv    padding, s4
        .eqv    red_min, s5
        .eqv    red_max, s6
        .eqv    green_min, s7
        .eqv    green_max, s8
        .eqv    blue_min, s9
        .eqv    blue_max, s10
        .eqv    current_pixel_address, t3
        .eqv    current_pixel_value, t4

        .data
buf:    .space  100 # buffor for data
filename:     .space  100 # input filename
title:  .asciz  "Histogram stretching\n"
prompt: .asciz  "Enter input filename: "
error:  .asciz  "Error reading file\n"
info:   .asciz  "File has been opened successfuly"
inv_name:.asciz  "Filename cannot be blank"
out:    .asciz  "out.bmp"
n:      .asciz  "\n"

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

        .macro open_file %name, %flag
        li a7, 1024
        la a0, %name
        li a1, %flag
        ecall
        .end_macro

        .macro read_from_file %num_of_bytes %buf
        mv a0, file_decriptor
        la a1, %buf
        li a2, %num_of_bytes
        li a7, 63
        ecall
        .end_macro

        .macro save_to_file %num_of_bytes %buf
        mv a0, out_decriptor
        la a1, %buf
        li a2, %num_of_bytes
        li a7, 64
        ecall
        .end_macro

        .macro print_int %register
        mv a0, %register
        li a7, 36
        ecall
        .end_macro

        .text
        .globl main
main:
        print title

        print prompt
        get_name filename, 100

        la t0, filename
        lb t1, (t0)
        beqz t1, invalid_name

        li t2, '\n'
        la a0, filename

remove_new_line:
        lbu t1, (a0)
        addi a0, a0, 1
        bne t1, t2, remove_new_line
        addi a0, a0, -1
        sb zero, (a0)

open_files:
        # open input file and save decriptor
        open_file filename, 0
        bltz a0, error_reading
        mv file_decriptor, a0

        # open ouptut file and save decriptor
        # open_file out, 1
        # mv out_decriptor, a0

read_header:
        read_from_file 2, buf    # read first 2 bytes of bmp header
        # save_to_file 2, buf      # save to output file
        read_from_file 12, buf   # read rest of bmp header
        # save_to_file 12, buf     # save to output file

        la t4, buf
        lw size, (t4) # load size

        read_from_file 40, buf  # load DIB header
        la t4, buf
        lw width, 4(t4)         # laod width
        lw height, 8(t4)        # load height
        # save_to_file 40, buf

size_calc:
        andi padding, width, 3  # calculate padding
        add width, width, padding # get padded width value
        addi size, size, -54    # calculate pixels size without the header

        # allocate memory for pixels
        li a7, 9
        mv a0, size
        ecall

        mv allocated, a0        # save allocated memory address

        # load pixels
        mv a0, file_decriptor
        mv a1, allocated
        mv a2, size
        li a7, 63
        ecall

        mv current_pixel_address, allocated  # get adress to the start of pixel array
        sub current_pixel_address, current_pixel_address, padding  # sub padding to compensate for addition at the start of get_extremes

        li red_min, 255
        li red_max, 0
        li green_min, 255
        li green_max, 0
        li blue_min, 255
        li blue_max, 0

        li t5, 0  # iteration counter

get_extremes:
        addi t5, t5, 1  # increment iteration counter
        add current_pixel_address, current_pixel_address, padding  # adds padding, used for skipping padding
        mv t6, width    # pixel counter to reset when padding is reached
        # beq t6, padding, get_extremes
        bgt t5, height, print_extremes  # if number of iterations is greater than height it will go further


check_blue:
        lbu current_pixel_value, (current_pixel_address)
        blt current_pixel_value, blue_min, set_blue_min
        bgt current_pixel_value, blue_max, set_blue_max
        b check_green

set_blue_min:
        mv blue_min, current_pixel_value
        blt current_pixel_value, blue_max, check_green

set_blue_max:
        mv blue_max, current_pixel_value

check_green:
        addi current_pixel_address, current_pixel_address, 1
        lbu current_pixel_value, (current_pixel_address)
        blt current_pixel_value, green_min, set_green_min
        bgt current_pixel_value, green_max, set_green_max
        b check_red

set_green_min:
        mv green_min, current_pixel_value
        blt current_pixel_value, green_max, check_red

set_green_max:
        mv green_max, current_pixel_value

check_red:
        addi current_pixel_address, current_pixel_address, 1
        lbu current_pixel_value, (current_pixel_address)
        blt current_pixel_value, red_min, set_red_min
        bgt current_pixel_value, red_max, set_red_max
        b next_pixel

set_red_min:
        mv red_min, current_pixel_value
        blt current_pixel_value, red_max, next_pixel

set_red_max:
        mv red_max, current_pixel_value

next_pixel:
        addi t6, t6, -1 # decrement pixel counter
        addi current_pixel_address, current_pixel_address, 1    # get next pixel address
        beq t6, padding, get_extremes   # if rest of bytes are part of padding it will skip them
        # bnez t6
        b check_blue

print_extremes: # for debug purposes only !!remove
        print_int red_min
        print n
        print_int red_max
        print n
        print_int green_min
        print n
        print_int green_max
        print n
        print_int blue_min
        print n
        print_int blue_max
        print n

error_reading:
        print error
        quit

invalid_name:
        print inv_name
        quit
