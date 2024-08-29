.data
stringhex: .space 37         # Allocate 37 bytes for the string (36 chars + null terminator)
prompt_input: .asciiz "Enter a string (max 36 characters): "
err_msg:  .asciiz "Wrong input, please enter the string again.\n"
prompt_unsign_array: .asciiz "\nDecimal representation of the sorted unsigned array is:\n"
prompt_sign_array: .asciiz "\nDecimal representation of the sorted signed array is:\n"
NUM: .space 12               # Allocate 12 bytes for the NUM array
unsign: .space 12            # Allocate 12 bytes for the unsign array
sign: .space 12              # Allocate 12 bytes for the sign array
buffer_unsign: .space 4      # Buffer to store up to 3 digits and null terminator
buffer_sign: .space 4        # Buffer to store up to 3 digits and null terminator

.text
.globl main

main:
    # Print the prompt message
    li $v0, 4                # Syscall number for print_str (4)
    la $a0, prompt_input     # Load address of the prompt string
    syscall                  # Print the prompt message

    # Read up to 37 bytes of input (36 chars + null terminator)
    li $v0, 8                # Syscall number for read (8)
    la $a0, stringhex        # Load address of stringhex
    li $a1, 37               # Read up to 37 bytes
    syscall

    # Call the is_valid function
    la $a0, stringhex        # Load address of the stringhex into $a0
    jal is_valid             # Jump and link to is_valid function

    # Check the return value
    beqz $v0, invalid_input  # If $v0 == 0, input is invalid, branch to invalid_input

    # Call the convert function
    la $a0, stringhex        # Load address of the stringhex into $a0
    la $a1, NUM              # Load address of NUM array into $a1
    move $a2, $v0            # Pass the number of valid pairs to $a2
    jal convert              # Jump and link to convert function
    
    # Call the sortunsign function
    la $a0, unsign           # Load address of the unsign array into $a0
    la $a1, NUM              # Load address of the NUM array into $a1
    move $a2, $v0            # Number of bytes to sort
    jal sortunsign           # Jump and link to sortunsign function
    
    # Call the sortsign function
    la $a0, sign             # Load address of the sign array into $a0
    la $a1, NUM              # Load address of the NUM array into $a1
    move $a2, $v0            # Number of bytes to sort
    jal sortsign             # Jump and link to sortsign function
    
    # Call the printunsign function
    la $a0, unsign           # Load address of the unsign array into $a0
    move $a1, $v0            # Number of bytes to print (from valid pairs)
    jal printunsign          # Jump and link to printunsign function

    # Call the printsign function
    la $a0, sign             # Load address of the sign array into $a0
    move $a1, $v0            # Number of bytes to print (from valid pairs)
    jal printsign            # Jump and link to printsign function

    # Exit the program
    li $v0, 10               # Syscall number for exit (10)
    syscall

# Function: invalid_input
# Description: This function prints an error message and returns to the main procedure to prompt the user for input again.
# Output:
#   - Prints the error message stored in `err_msg` to the standard output.
#   - Jumps back to the `main` procedure to re-prompt the user for input.
invalid_input:
    # Print the error message
    li $v0, 4                # Syscall number for print_str (4)
    la $a0, err_msg          # Load address of the error message
    syscall                  # Print the error message
    j main                   # Go back to the main procedure to ask for input again

# Function: is_valid
# Description: This function validates a string of hexadecimal digit pairs separated by '$' characters.
# Input:
#   - $a0: Address of the string to be validated.
# Output:
#   - Returns 1 in $v0 if the string is valid, 0 otherwise.
# Detailed Operation:
#   - Initializes counters and flags for validating pairs and '$' signs.
#   - Loops through the string character by character:
#     - Checks if the character is a valid hexadecimal digit or '$'.
#     - Validates the formation of hexadecimal digit pairs.
#     - Counts the number of valid pairs and '$' signs.
#   - Determines if the final string format is valid based on the presence of correct pairs and '$' signs.
is_valid:
    # Initialize registers
    li $t0, 0                # Counter for valid pairs
    li $t1, 0                # Flag for checking pairs
    li $t2, 0                # Flag for valid sequence
    li $t3, 0                # Counter for the '$' signs

validate_loop:
    lb $t4, 0($a0)           # Load the current character
    beqz $t4, end_validate   # If null terminator is found, end validation
    li $t5, '\n'             # Load the ASCII value for newline character
    beq $t4, $t5, end_validate   # If newline is found, end validation
    li $t9, 36               # ASCII '$'

    # Check for valid hexadecimal characters
    li $t5, 70               # ASCII 'F'
    li $t6, 65               # ASCII 'A'
    li $t7, 48               # ASCII '0'
    li $t8, 57               # ASCII '9'
    
    blt $t4, $t7, check_dollar   # If $t4 (current value) < $t7 (previous value), branch to check_dollar
    sgt $t7, $t4, $t8            # Set $t7 to 1 if $t4 > $t8 (comparison result), otherwise 0
    slt $t8, $t4, $t6            # Set $t8 to 1 if $t4 < $t6 (comparison result), otherwise 0
    and $t7, $t7, $t8            # Perform bitwise AND between $t7 and $t8, store result in $t7
    li $t8, 1                    # Load immediate value 1 into $t8
    beq $t7, $t8, invalid        # If $t7 == $t8 (result of the AND operation is 1), branch to invalid
    bgt $t4, $t5, invalid        # If character is greater than 'F', check for '$'
    
    # Check for pair validity
    addi $t1, $t1, 1         # Increment the pair flag
    li $t5, 2 
    bne $t1, $t5, next_char  # If it's not the second in the pair, continue
    li $t1, 0                # Reset pair flag
    addi $t0, $t0, 1         # Increment valid pair counter
    li $t2, 1                # Set the valid sequence flag

next_char:
    addi $a0, $a0, 1         # Move to the next character
    j validate_loop          # Continue validation

check_dollar:
    beq $t4, $t9, dollar_sign # If character is '$', check it

# If the character is not valid
invalid:
    li $v0, 0                # Set return value to 0 (invalid)
    jr $ra                   # Return to the caller

dollar_sign:
    beqz $t2, invalid        # If there's no valid sequence before, invalid
    li $t2, 0                # Reset the valid sequence flag
    addi $t3, $t3, 1         # Increment the '$' counter
    addi $a0, $a0, 1         # Move to the next character
    j validate_loop          # Continue validation

end_validate:
    # If the last character was a valid hexadecimal digit and followed by '$'
    sne $t5, $t0, $t3       # Set $t5 to 1 if $t0 (current count of valid pairs) is not equal to $t3 (expected number of pairs)
    sne $t6, $t1, $zero     # Set $t6 to 1 if $t1 (flag for checking pairs) is not equal to 0 (indicating an issue with the pairs)
    or $t5, $t5, $t6        # Combine the results of the above checks: $t5 will be 1 if either $t0 != $t3 or $t1 != 0
    beqz $t5, valid         # Branch to 'valid' label if $t5 is 0 (both checks passed, meaning the input is valid)
    li $v0, 0                # Else, set return value to 0 (invalid)
    jr $ra                   # Return to the caller

valid:
    move $v0, $t0            # Set return value to the count of valid pairs
    jr $ra                   # Return to the caller

# Function: convert
# Description: This function converts a string of hexadecimal digit pairs into bytes and stores them in a destination array.
# Input:
#   - $a0: Address of the input string (`stringhex`), which contains hexadecimal digit pairs.
#   - $a1: Address of the destination array (`NUM`), where converted bytes are stored.
#   - $a2: Number of hexadecimal pairs to process.
# Output:
#   - Converts pairs of hexadecimal digits to bytes and stores them in the destination array.
#   - Updates pointers and counters accordingly.
# Detailed Operation:
#   - Checks if there are more pairs to process (`$a2` is non-zero).
#   - Loads and converts each character of the hexadecimal pairs:
#     - If the character is '$', it skips over it.
#     - Converts the hexadecimal digits to numerical values.
#     - Combines the two nibbles (4-bit values) into a byte.
#     - Stores the resulting byte in the destination array.
#   - Updates the pointers to move to the next pair and decrements the counter.
#   - Continues until all pairs are processed or the end of the string is reached.
convert:
    beqz $a2, end_convert    # If all pairs are processed, end conversion

    # Check if the first character is '$'
    li $t3, 36               # ASCII value of '$'
    lb $t0, 0($a0)           # Load the first character from stringhex
    beq $t0, $t3, skip_dollar

    li $t1, 48               # ASCII '0'
    sub $t0, $t0, $t1        # Convert ASCII to numerical value
    li $t2, 9
    ble $t0, $t2, next_char_convert
    
    lb $t0, 0($a0)           # Load the first character from stringhex
    li $t1, 55               # ASCII 'A'
    sub $t0, $t0, $t1        # Convert ASCII to numerical value
    j next_char_convert

next_char_convert:
    # Load the second character of the pair
    lb $t1, 1($a0)           # Load the second character from stringhex
    li $t2, 48               # ASCII '0'
    sub $t1, $t1, $t2        # Convert ASCII to numerical value
    li $t3, 9
    ble $t1, $t3, store_byte
    
    lb $t1, 1($a0)           # Load the first character from stringhex
    li $t2, 55               # ASCII 'A'
    sub $t1, $t1, $t2        # Convert ASCII to numerical value
    j store_byte

store_byte:
    li $t2, 16               # Set $t2 to 16 (base for hexadecimal conversion)
    mul $t0, $t0, $t2        # Multiply $t0 by 16 to convert to hexadecimal
    add $t0, $t0, $t1        # Combine the two nibbles into a byte
    sb $t0, 0($a1)           # Store the byte in NUM array

    # Update pointers and counters
    addi $a0, $a0, 2         # Move to the next pair of characters in stringhex
    addi $a1, $a1, 1         # Move to the next byte in NUM array
    addi $a2, $a2, -1        # Decrement the pair counter
    j convert                # Repeat for the next pair

skip_dollar:
    addi $a0, $a0, 1         # Skip the '$' and move to the next character
    j convert                # Continue with the loop

end_convert:
    jr $ra                   # Return to the caller

# Function: sortunsign
# Description: This function sorts an array of unsigned bytes in ascending order using the bubble sort algorithm.
# Input:
#   - $a0: Address of the output array where sorted bytes will be stored.
#   - $a1: Address of the input array (`NUM`) containing bytes to be sorted.
#   - $a2: Number of bytes in the `NUM` array.
# Output:
#   - The function sorts the `NUM` array in ascending order and stores the sorted result in the output array.
# Detailed Operation:
#   - Initializes loop counters for sorting.
#   - The outer loop iterates over each byte in the array.
#   - The inner loop compares each byte with every other byte in the array.
#   - If a byte is less than another byte, they are swapped.
#   - After sorting, the sorted array is copied to the output array.
#   - Continues until all bytes are sorted.
sortunsign:
    # Initialize loop counters
    li $t0, 0                # Index i
    li $t1, 0                # Index j
    li $t2, 0                # Temp variable

outer_loop_unsign:
    bge $t0, $a2, end_sort_unsign   # If i >= number of bytes, end sort
    addi $t1, $t0, 1         # Set j to i + 1

inner_loop_unsign:
    bge $t1, $a2, next_i_unsign     # If j >= number of bytes, go to next i
    
    # Corrected address calculation for the j-th element
    add $t5, $a1, $t0        # Calculate the address of NUM[i]
    lbu $t3, 0($t5)          # Load NUM[i] into t3
    
    add $t6, $a1, $t1        # Calculate the address of NUM[j]
    lbu $t4, 0($t6)          # Load NUM[j] into t4
    
    blt $t3, $t4, swap_unsign       # If NUM[i] < NUM[j], swap them

next_j_unsign:
    addi $t1, $t1, 1         # Increment j
    j inner_loop_unsign      # Repeat inner loop

swap_unsign:
    sb $t4, 0($t5)           # Swap NUM[i] with NUM[j]
    sb $t3, 0($t6)
    j next_j_unsign

next_i_unsign:
    add $t5, $a1, $t0        # Calculate the address of NUM[i]
    add $t6, $a0, $t0        # Calculate the address of unsign[i]
    lbu $t3, 0($t5)          # Load NUM[i] into t3
    sb $t3, 0($t6)           # store NUM[i] in unsign[i]
    addi $t0, $t0, 1         # Increment i
    j outer_loop_unsign      # Repeat outer loop

end_sort_unsign:
    jr $ra                   # Return to the caller

# Function: sortsign
# Description: This function sorts an array of signed bytes in ascending order using the bubble sort algorithm.
# Input:
#   - $a0: Address of the output array where sorted bytes will be stored.
#   - $a1: Address of the input array (`NUM`) containing bytes to be sorted.
#   - $a2: Number of bytes in the `NUM` array.
# Output:
#   - The function sorts the `NUM` array in ascending order and stores the sorted result in the output array.
# Detailed Operation:
#   - Initializes loop counters for sorting.
#   - The outer loop iterates over each byte in the array.
#   - The inner loop compares each byte with every other byte in the array.
#   - If a byte is less than another byte, they are swapped.
#   - After sorting, the sorted array is copied to the output array.
#   - Continues until all bytes are sorted.
sortsign:
    # Initialize loop counters
    li $t0, 0                # Index i
    li $t1, 0                # Index j
    li $t2, 0                # Temp variable

outer_loop_sign:
    bge $t0, $a2, end_sortsign   # If i >= number of bytes, end sort
    addi $t1, $t0, 1         # Set j to i + 1

inner_loop_sign:
    bge $t1, $a2, next_i_sign    # If j >= number of bytes, go to next i
    
    # Corrected address calculation for the j-th element
    add $t5, $a1, $t0        # Calculate the address of NUM[i]
    lb $t3, 0($t5)           # Load NUM[i] into t3
    
    add $t6, $a1, $t1        # Calculate the address of NUM[j]
    lb $t4, 0($t6)           # Load NUM[j] into t4
    
    blt $t3, $t4, swap_sign  # If NUM[i] < NUM[j], swap them

next_j_sign:
    addi $t1, $t1, 1         # Increment j
    j inner_loop_sign        # Repeat inner loop

swap_sign:
    sb $t4, 0($t5)           # Swap NUM[i] with NUM[j]
    sb $t3, 0($t6)
    j next_j_sign

next_i_sign:
    add $t5, $a1, $t0        # Calculate the address of NUM[i]
    add $t6, $a0, $t0        # Calculate the address of sign[i]
    lb $t3, 0($t5)           # Load NUM[i] into t3
    sb $t3, 0($t6)           # store NUM[i] in sign[i]
    addi $t0, $t0, 1         # Increment i
    j outer_loop_sign        # Repeat outer loop

end_sortsign:
    jr $ra                   # Return to the caller

# Function: printunsign
# Description: This function prints the elements of an unsigned byte array in decimal format, with each value separated by two spaces.
# Input:
#   - $a0: Address of the array to be printed.
#   - $a1: Number of bytes in the array.
#   - $v0: Address of the prompt string to be printed before the array elements.
# Output:
#   - The function prints the array elements in decimal format, followed by two spaces between each element.
# Detailed Operation:
#   - Initializes the loop counter and saves the input values to temporary registers.
#   - Prints a prompt message.
#   - Loops through each byte in the array.
#   - For each byte:
#     - Loads the byte from the array.
#     - Converts the byte to its decimal representation.
#     - Stores the decimal digits in a buffer in reverse order.
#     - Prints the digits from the buffer in the correct order.
#     - Prints two spaces after each number.
#   - Continues until all bytes in the array are printed.
printunsign:
    # Initialize loop counter
    li $t0, 0                # Set $t0 to 0 (counter)
    
    # Copy input values to temporary registers
    move $t1, $a0
    move $t2, $v0
    
    # Print two spaces
    li $v0, 4
    la $a0, prompt_unsign_array
    syscall
    
    # Restore original values for further operations
    move $a0, $t1
    move $v0, $t2
    
printunsign_loop:
    bge $t0, $a1, end_printunsign  # If counter >= number of bytes, end print
    
    # Load the current element from unsign array
    lbu $t1, 0($a0)          # Load byte from unsign array into $t1
    
    # Copy input values to temporary registers
    move $t7, $a0
    move $t8, $v0
    
    # Prepare for digit extraction
    li $t2, 10               # Set divisor to 10
    move $t3, $t1            # Move the number to $t3
    
    # Initialize buffer for digits (reverse order)
    li $t4, 0                # Buffer index
    la $t5, buffer_unsign    # Load address of buffer
    
extractunsign_digits:
    divu $t3, $t2            # Divide $t3 by 10
    mfhi $t6                 # Get remainder (current digit)
    mflo $t3                 # Update quotient (remaining number)
    
    addi $t6, $t6, '0'       # Convert digit to ASCII
    sb $t6, 0($t5)           # Store ASCII digit in buffer
    addi $t5, $t5, 1         # Move to next buffer position
    addi $t4, $t4, 1         # Increment buffer index
    
    bnez $t3, extractunsign_digits # Repeat if quotient is not zero

    # Print digits in reverse order
    li $v0, 11               # Syscall number for print_char (11)
    addi $t4, $t4, -1        # Point to last digit
    addi $t5, $t5, -1
    
printunsign_buffer:
    lb $a0, 0($t5)           # Load digit from buffer
    syscall                  # Print digit
    addi $t4, $t4, -1        # Move to previous digit
    addi $t5, $t5, -1
    bgez $t4, printunsign_buffer   # Repeat until all digits are printed

    # Print two spaces
    li $v0, 11               # Syscall number for print_char (11)
    li $a0, ' '              # Load ASCII value of space
    syscall                  # Print first space
    syscall                  # Print second space
    
    # Restore original values for further operations
    move $a0, $t7
    move $v0, $t8
    
    # Update the loop counter and address
    addi $t0, $t0, 1         # Increment counter
    addi $a0, $a0, 1         # Move to the next element in unsign array
    j printunsign_loop       # Repeat loop
    
end_printunsign:
    jr $ra                   # Return to the caller

# Function: printsign
# Description: This function prints the elements of a signed byte array in decimal format, with each value separated by two spaces.
# Input:
#   - $a0: Address of the array to be printed.
#   - $a1: Number of bytes in the array.
#   - $v0: Address of the prompt string to be printed before the array elements.
# Output:
#   - The function prints each element of the array in decimal format, separated by two spaces. Negative numbers are preceded by a minus sign.
# Detailed Operation:
#   - Initializes the loop counter and saves the input values to temporary registers.
#   - Prints a prompt message.
#   - Loops through each byte in the array.
#   - For each byte:
#     - Checks if the byte is negative.
#     - If negative:
#       - Prints a minus sign.
#       - Converts the negative number to its positive representation using 2's complement.
#     - If positive, prints the number directly.
#     - Converts the number to its decimal representation.
#     - Stores the decimal digits in a buffer in reverse order.
#     - Prints the digits from the buffer in the correct order.
#     - Prints two spaces after each number.
#   - Continues until all bytes are printed.
printsign:
    # Initialize loop counter
    li $t0, 0                # Set $t0 to 0 (counter)
    
    # Copy input values to temporary registers
    move $t1, $a0
    move $t2, $v0
    
    # Print two spaces
    li $v0, 4
    la $a0, prompt_sign_array
    syscall
    
    # Restore original values for further operations
    move $a0, $t1
    move $v0, $t2
    
printsign_loop:
    bge $t0, $a1, end_printsign  # If counter >= number of bytes, end print
    
    # Load the current element from sign array
    lb $t1, 0($a0)           # Load byte from sign array into $t1
    
    # Copy input values to temporary registers
    move $t7, $a0
    move $t8, $v0
    
    # Check for negative number
    bltz $t1, handle_negative
    
    # Print positive number
    move $t3, $t1            # Move the number to $t3
    j print_positive

handle_negative:
    # Print negative sign
    li $v0, 11               # Syscall number for print_char (11)
    li $a0, '-'              # Load ASCII value of minus sign
    syscall                  # Print minus sign
    
    # Convert the negative number to positive (2's complement)
    not $t1, $t1             # Perform bitwise NOT (inversion)
    addi $t1, $t1, 1         # Add 1 to get 2's complement
    move $t3, $t1            # Move the positive number to $t3

print_positive:
    # Prepare for digit extraction
    li $t2, 10               # Set divisor to 10
    
    # Initialize buffer for digits (reverse order)
    li $t4, 0                # Buffer index
    la $t5, buffer_sign      # Load address of buffer

extractsign_digits:
    div $t3, $t2             # Divide $t3 by 10
    mfhi $t6                 # Get remainder (current digit)
    mflo $t3                 # Update quotient (remaining number)
    
    addi $t6, $t6, '0'       # Convert digit to ASCII
    sb $t6, 0($t5)           # Store ASCII digit in buffer
    addi $t5, $t5, 1         # Move to next buffer position
    addi $t4, $t4, 1         # Increment buffer index
    
    bnez $t3, extractsign_digits # Repeat if quotient is not zero

    # Print digits in reverse order
    li $v0, 11               # Syscall number for print_char (11)
    addi $t4, $t4, -1        # Point to last digit
    addi $t5, $t5, -1
    
printsign_buffer:
    lb $a0, 0($t5)           # Load digit from buffer
    syscall                  # Print digit
    addi $t4, $t4, -1        # Move to previous digit
    addi $t5, $t5, -1
    bgez $t4, printsign_buffer   # Repeat until all digits are printed

    # Print two spaces
    li $v0, 11               # Syscall number for print_char (11)
    li $a0, ' '              # Load ASCII value of space
    syscall                  # Print first space
    syscall                  # Print second space
    
    # Restore original values for further operations
    move $a0, $t7
    move $v0, $t8
    
    # Update the loop counter and address
    addi $t0, $t0, 1         # Increment counter
    addi $a0, $a0, 1         # Move to the next element in unsign array
    j printsign_loop         # Repeat loop
            
end_printsign:
    jr $ra                   # Return to the caller
