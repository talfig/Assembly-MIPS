.data
str: .space 31  # Allocate 31 bytes for the string (30 chars + null terminator)
prompt: .asciiz "Enter a string (max 30 characters): " # Prompt message
palindrome_msg: .asciiz "Palindrome\n"
not_palindrome_msg: .asciiz "Not Palindrome\n"

.text
.globl main

main:
    # Print the prompt message
    li $v0, 4           # Syscall number for print_str (4)
    la $a0, prompt      # Load address of the prompt string
    syscall             # Print the prompt message

    # Read up to 31 bytes of input (30 chars + null terminator)
    li $v0, 8           # Syscall number for read (8)
    la $a0, str         # Load address of str
    li $a1, 31          # Read up to 31 bytes
    syscall

    # Initialize registers for length calculation
    la $a0, str         # Load address of the string
    li $t0, 0           # Length counter

find_length:
    lb $t1, 0($a0)      # Load byte from string
    beq $t1, $zero, length_done # If byte is 0 (null terminator), exit loop
    li $t2, '\n'        # Load the ASCII value for newline character
    beq $t1, $t2, length_done # If byte is '\n' (null terminator), exit loop
    addi $t0, $t0, 1    # Increment length counter
    addi $a0, $a0, 1    # Move to the next byte
    j find_length       # Repeat loop

length_done:
    # $t0 now contains the length of the string
    # Subtract 1 to get the index of the last character
    addi $t0, $t0, -1

    # Initialize registers for palindrome check
    la $a0, str         # Reset $a0 to the start of the string
    add $a1, $a0, $t0   # $a1 points to the end of the string (last character)

# Function: palindrome_check
# Description: This function checks if the input string is a palindrome. A string is considered a palindrome if it reads the same forward and backward.
# Input:
#   - $a0: Address of the start of the string.
#   - $a1: Address of the end of the string (last character).
# Output:
#   - Prints "Palindrome" if the string is a palindrome.
#   - Prints "Not Palindrome" if the string is not a palindrome.
# Detailed Operation:
#   - Checks if the start pointer ($a0) has crossed the end pointer ($a1). If so, the string is a palindrome.
#   - Loads the character from the start of the string into register $t0.
#   - Loads the character from the end of the string into register $t1.
#   - Compares the characters. If they do not match, jumps to the not_palindrome section.
#   - Moves the start pointer one position to the right and the end pointer one position to the left.
#   - Repeats the process until all characters are compared or the pointers cross.
#   - If all compared characters match, prints "Palindrome".
#   - If any characters do not match, prints "Not Palindrome".
palindrome_check:
    bge $a0, $a1, palindrome_true # If $a0 >= $a1, it's a palindrome
    lb $t0, 0($a0)      # Load byte from the start of the string
    lb $t1, 0($a1)      # Load byte from the end of the string
    bne $t0, $t1, not_palindrome # If characters don't match, not a palindrome
    addi $a0, $a0, 1    # Move start pointer to the right
    addi $a1, $a1, -1   # Move end pointer to the left
    j palindrome_check  # Repeat loop

palindrome_true:
    # Print "Palindrome" message
    li $v0, 4           # Syscall number for print_str (4)
    la $a0, palindrome_msg  # Load address of "Palindrome" message
    syscall
    j exit_program      # Jump to program exit

not_palindrome:
    # Print "Not Palindrome" message
    li $v0, 4           # Syscall number for print_str (4)
    la $a0, not_palindrome_msg  # Load address of "Not Palindrome" message
    syscall

exit_program:
    # Exit program
    li $v0, 10          # Syscall number for exit (10)
    syscall
