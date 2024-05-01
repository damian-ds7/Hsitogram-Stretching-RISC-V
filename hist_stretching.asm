# Damian D'Souza
# Histogram stretching in RISC-V
# Program will edit given image
# in.bmp is provided only to show the difference

        .eqv    size, t0
        .eqv    allocated, t1
        .eqv    offset, t2
        .eqv    file_decriptor, s0
        .eqv    width, s1
        .eqv    height, s2
        .eqv    padding, s3
        .eqv    red_min, s4
        .eqv    red_max, s5
        .eqv    green_min, s6
        .eqv    green_max, s7
        .eqv    blue_min, s8
        .eqv    blue_max, s9
        .eqv    current_pixel_address, t3
        .eqv    current_pixel_value, t4

        .data
buf:    .space  100 # buffor for data
filename:     .space  100 # input filename
title:  .asciz  "Histogram stretching\n"
prompt: .asciz  "Enter input filename: "
error:  .asciz  "Error reading file\n"
info1:   .asciz  "Successfuly opened file\n"
info2:   .asciz  "Successfuly closed file\n"
inv_name:.asciz  "Filename cannot be blank\n"
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

        .macro read_from_file %num_of_bytes %buf
        mv a0, file_decriptor
        la a1, %buf
        li a2, %num_of_bytes
        li a7, 63
        ecall
        .end_macro

        .macro print_int %register
        mv a0, %register
        li a7, 34
        ecall
        .end_macro

        .text
        .globl main
main:
        print title

        print prompt
        li a7, 8
        la a0, filename
        li a1, 100
        ecall

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
        li a7, 1024
        la a0, filename
        li a1, 0
        ecall
        bltz a0, error_reading
        mv file_decriptor, a0
        print info1

read_header:
        read_from_file 2, buf    # read first 2 bytes of bmp header
        read_from_file 12, buf   # read rest of bmp header

        la t4, buf
        lw size, (t4) # load size

        read_from_file 40, buf  # load DIB header
        la t4, buf
        lw width, 4(t4)         # laod width
        lw height, 8(t4)        # load height

        mv a0, file_decriptor
        li a7, 57
        ecall

        li a7, 1024
        la a0, filename
        li a1, 0
        ecall
        bltz a0, error_reading
        mv file_decriptor, a0

size_calc:
        andi padding, width, 3  # calculate padding
        add width, width, padding  # get padded width value

        # allocate memory for pixels
        li a7, 9
        mv a0, size
        ecall

        mv allocated, a0        # save allocated memory address

        # load image data
        mv a0, file_decriptor
        mv a1, allocated
        mv a2, size
        li a7, 63
        ecall

        mv current_pixel_address, allocated  # get adress to the start of pixel array
        addi current_pixel_address, current_pixel_address, 54
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
        bgt t5, height, adjust_values  # if number of iterations is greater than height it will go further

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

# print_extremes: # for debug purposes only !!remove
#         print_int red_min
#         print n
#         print_int red_max
#         print n
#         print_int green_min
#         print n
#         print_int green_max
#         print n
#         print_int blue_min
#         print n
#         print_int blue_max
#         print n

adjust_values:
        sub red_max, red_max, red_min
        sub green_max, green_max, green_min
        sub blue_max, blue_max, blue_min
        .eqv red_diff, s5
        .eqv green_diff, s7
        .eqv blue_diff, s9
        .eqv max_value, s10
        li max_value, 255
        li t5, 0  # reset iteration counter
        mv current_pixel_address, allocated  # get adress to the start of pixel array
        addi current_pixel_address, current_pixel_address, 54
        sub current_pixel_address, current_pixel_address, padding  # sub padding to compensate for addition at the start of get_extremes

adjust_pixels:
        addi t5, t5, 1  # increment iteration counter
        add current_pixel_address, current_pixel_address, padding  # adds padding, used for skipping padding
        mv t6, width    # pixel counter to reset when padding is reached
        # beq t6, padding, get_extremes
        bgt t5, height, save_data_to_file  # if number of iterations is greater than height it will go further

adjust_blue:
        lbu current_pixel_value, (current_pixel_address)
        sub current_pixel_value, current_pixel_value, blue_min
        mul current_pixel_value, current_pixel_value, max_value
        div current_pixel_value, current_pixel_value, blue_diff
        sb current_pixel_value, (current_pixel_address)

adjust_green:
        addi current_pixel_address, current_pixel_address, 1
        lbu current_pixel_value, (current_pixel_address)
        sub current_pixel_value, current_pixel_value, green_min
        mul current_pixel_value, current_pixel_value, max_value
        div current_pixel_value, current_pixel_value, green_diff
        sb current_pixel_value, (current_pixel_address)

adjust_red:
        addi current_pixel_address, current_pixel_address, 1
        lbu current_pixel_value, (current_pixel_address)
        sub current_pixel_value, current_pixel_value, red_min
        mul current_pixel_value, current_pixel_value, max_value
        div current_pixel_value, current_pixel_value, red_diff
        sb current_pixel_value, (current_pixel_address)

next_pixel2:
        addi t6, t6, -1 # decrement pixel counter
        addi current_pixel_address, current_pixel_address, 1    # get next pixel address
        beq t6, padding, adjust_pixels   # if rest of bytes are part of padding it will skip them
        b adjust_blue

save_data_to_file:
        # close file
        mv a0, file_decriptor
        li a7, 57
        ecall

        # open file in write only mode
        li a7, 1024
        la a0, filename
        li a1, 1
        ecall
        bltz a0, error_reading

        mv a1, allocated
        mv a2, size
        li a7, 64
        ecall

        print info2
        quit

error_reading:
        print error
        quit

invalid_name:
        print inv_name
        quit
