ORG     00h

START:
    CLR     RS0         ; Clear RS0 flag
    CLR     RS1         ; Clear RS1 flag
    MOV     DPTR, #1000 ; Load the address of the lookup table to DPTR
    MOV     P1, #0FFH   ; Set P1 port as input
MAIN:
    CALL    WHICHROW        ; Call WHICHROW subroutine to determine the active row
    CALL    WHICHCOLUMN     ; Call WHICHCOLUMN subroutine to determine the active column
    MOV     A, R0           ; Move the value of R0 (row) to the accumulator
    MOV     B, #3           ; Set B to 3 for multiplication
    MUL     AB              ; Multiply A and B, result stored in A
    ADD     A, R1           ; Add the value of R1 (column) to A
SHOW:
    MOVC    A, @A+DPTR  ; Move the value from the lookup table to A
    MOV     P2, A       ; Display the value on the 7-segment display
    JMP     MAIN        ; Jump back to M to repeat the process

WHICHROW:
    MOV     P1, #0FEH       ; Set P1 port to check row 1
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0FEH, ROW1  ; If A is not equal to 0FEH, jump to ROW1
    MOV     P1, #0FDH       ; Set P1 port to check row 2
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0FDH, ROW2  ; If A is not equal to 0FDH, jump to ROW2
    MOV     P1, #0FBH       ; Set P1 port to check row 3
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0FBH, ROW3  ; If A is not equal to 0FBH, jump to ROW3
    MOV     P1, #0F7H       ; Set P1 port to check row 4
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0F7H, ROW4  ; If A is not equal to 0F7H, jump to ROW4
    JMP     WHICHROW        ; If none of the conditions met, repeat the process
ROW1:
    MOV     R0, #0      ; Set R0 to 0 (row 1)
    RET                 ; Return from the subroutine
ROW2:
    MOV     R0, #1      ; Set R0 to 1 (row 2)
    RET                 ; Return from the subroutine
ROW3:
    MOV     R0, #2      ; Set R0 to 2 (row 3)
    RET                 ; Return from the subroutine
ROW4:
    MOV     R0, #3      ; Set R0 to 3 (row 4)
    RET                 ; Return from the subroutine

WHICHCOLUMN:
    MOV     P1, #0EFH       ; Set P1 port to check column 1
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0EFH, COL1  ; If A is not equal to 0EFH, jump to COL1
    MOV     P1, #0DFH       ; Set P1 port to check column 2
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0DFH, COL2  ; If A is not equal to 0DFH, jump to COL2
    MOV     P1, #0BFH       ; Set P1 port to check column 3
    MOV     A, P1           ; Move the value of P1 to A
    CJNE    A, #0BFH, COL3  ; If A is not equal to 0BFH, jump to COL3
    JMP     WHICHCOLUMN     ; If none of the conditions met, repeat the process
COL1:
    MOV     R1, #1      ; Set R1 to 1 (column 1)
    RET                 ; Return from the subroutine
COL2:
    MOV     R1, #2      ; Set R1 to 2 (column 2)
    RET                 ; Return from the subroutine
COL3:
    MOV     R1, #3      ; Set R1 to 3 (column 3)
    RET                 ; Return from the subroutine

ORG 1000
LOOK_UP_TABLE:                  
    DB     #3FH      ; Lookup table entry for digit 0
    DB     #06H      ; Lookup table entry for digit 1
    DB     #5BH      ; Lookup table entry for digit 2
    DB     #4FH      ; Lookup table entry for digit 3
    DB     #66H      ; Lookup table entry for digit 4
    DB     #6DH      ; Lookup table entry for digit 5
    DB     #7DH      ; Lookup table entry for digit 6
    DB     #07H      ; Lookup table entry for digit 7
    DB     #7FH      ; Lookup table entry for digit 8
    DB     #6FH      ; Lookup table entry for digit 9
    DB     #77H      ; Lookup table entry for digit A
    ; DB     #7CH      ; Lookup table entry for digit B
    DB     #3FH      ; Lookup table entry for digit 0
    DB     #39H      ; Lookup table entry for digit C
    DB     #5EH      ; Lookup table entry for digit D
    DB     #79H      ; Lookup table entry for digit E
    DB     #71H      ; Lookup table entry for digit F
