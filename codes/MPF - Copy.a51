;====================================================================
; DEFINITIONS
;====================================================================
; 00H to 0FH are numeric inputs
ORG_KEY EQU 010H
ADR_PLUS EQU 011H
ADR_MINUS EQU 012H
EXECUTE EQU 013H
END_KEY EQU 014H
NO_KEY EQU 0FFH
; instructions starting from C0H
F1 EQU 0C0H
F2 EQU 0C1H
F3 EQU 0C2H
F4 EQU 0C3H
F5 EQU 0C4H
F6 EQU 0C5H
F7 EQU 0C6H
F8 EQU 0C7H
; flags
NUMBER_INPUT_FLAG EQU F0
EXE_FLAG EQU F1
END_FLAG EQU F2
WRONG_FLAG EQU F3
;====================================================================
; VARIABLES
;====================================================================
ORG 0CFFH
KEY_MAP:
    DB 000H, 001H, 002H, 003H, ORG_KEY, EXECUTE, ADR_PLUS, ADR_MINUS
    DB 004H, 005H, 006H, 007H, END_KEY, NO_KEY, NO_KEY, NO_KEY
    DB 008H, 009H, 00AH, 00BH, F1, F2, F3, F4
    DB 00CH, 00DH, 00EH, 00FH, F5, F6, F7, F8


ORG 0000H
    JMP MAIN

; ISR
ORG 0003H
    CLR P3.1                    ; Disable interrupt
    CLR EA                      ; No interrupt will be acknowledged
    CLR EX0                     ; Disable external interrupt0
    ACALL KEY_INPUT             ; updates R1
    ACALL UPDATE_STATE_FLAGS    ; update R0 which is the state of the FSM, also save input data
    ; check if we should execute
    JNB EXE_FLAG, ISR_NON_EXE
    ACALL RUN_EXE
    ISR_NON_EXE:
    ; check if wrong key was pressed
    JNB WRONG_FLAG, ISR_NON_WRONG
    ACALL WRONG_PRESS
    ISR_NON_WRONG:
    ; check if code should be run
    JNB END_FLAG, ISR_NON_END
    ACALL RUN_CODE
    ISR_NON_END:
    ; reset and return from interrupt
    ACALL SHOW_ON_SEGMENT
    SETB EA             ; Enable interrupt individually
    SETB EX0            ; Enable external interrupt0
    SETB P3.1           ; Enable interrupt
    RETI                ; Return from interrupt

ORG 04FFH

KEY_INPUT:
    ACALL GET_COL
    ACALL GET_ROW 
    ACALL COL_ROW_TO_KEY ; save corresponding key value to R1 register
    MOV P0, #000H
    MOV P2, #0FFH
    RET

GET_COL:
    MOV A, P2
    MOV R4, #000H
    FIND_INDEX_LOOP:
        JNB ACC.0, INDEX_FOUND  ; Jump if the lowest bit of A is set
        INC R4  ; Increment the index counter
        RRC A  ; Rotate A right through carry
        JMP FIND_INDEX_LOOP
    INDEX_FOUND:
        RET
GET_ROW:
    ROW1:
        CPL P0.0
        MOV A, P2
        CJNE A, #0FFH, ROW2
        MOV R5, #000H
        RET
    ROW2:
        CPL P0.0
        CPL P0.1
        MOV A, P2
        CJNE A, #0FFH, ROW3
        MOV R5, #001H
        RET
    ROW3:
        CPL P0.1
        CPL P0.2
        MOV A, P2
        CJNE A, #0FFH, ROW4
        MOV R5, #002H
        RET
    ROW4:
        MOV R5, #003H
        RET
COL_ROW_TO_KEY:
    MOV A, R5
    SWAP A
    RR A
    ORL A, R4
    MOV DPTR, #KEY_MAP
    MOVC A, @A+DPTR  ; Fetch value from the lookup table
    MOV R1, A
    RET


UPDATE_STATE_FLAGS:
    ; check if input is numeric
    MOV A, R1
    ANL A, #0F0H
    CLR NUMBER_INPUT_FLAG
    CJNE A, #0H, NON_NUMERIC
    SETB NUMBER_INPUT_FLAG
    NON_NUMERIC:
    CLR EXE_FLAG    ; will be set in cases
    CLR WRONG_FLAG  ; will be set in cases
    CLR END_FLAG
    ; check if input was a special function
    ; TODO
    ; check if input was END
    CJNE R1, #END_KEY, GENERAL_KEY
    SETB END_FLAG
    MOV R0, #000H   ; reset state
    MOV R2, #000H   ; reset address register
    MOV R3, #000H   ; reset data register
    RET
    ; Perform the switch-case
    GENERAL_KEY:
        CASE_0:
            CJNE R0, #00H , CASE_1
            ORG_CLICK_0:
                CJNE R1, #ORG_KEY, WRONG_KEY_0
                MOV R0, #001H    ; update state
                JMP DEFAULT_CASE
            WRONG_KEY_0:
                JMP WRONG_KEY
        CASE_1:
            CJNE R0, #01H , CASE_2
            NUMBER_KEY_1:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_1
                MOV R0, #002H
                ACALL UPDATE_ADDRESS_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_1:
                JMP WRONG_KEY
        CASE_2:
            CJNE R0, #02H , CASE_3
            NUMBER_KEY_2:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_2
                MOV R0, #003H
                ACALL UPDATE_ADDRESS_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_2:
                JMP WRONG_KEY
        CASE_3:
            CJNE R0, #03H , CASE_4
            EXE_CLICK_3:
                CJNE R1, #EXECUTE, WRONG_KEY_3
                MOV R0, #004H
                SETB EXE_FLAG 
                JMP DEFAULT_CASE
            WRONG_KEY_3:
                NUMBER_KEY_3: 
                    JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_3
                    ACALL UPDATE_ADDRESS_INPUT
                    JMP DEFAULT_CASE
                NON_NUMBER_KEY_3:
                    JMP WRONG_KEY
        CASE_4:
            CJNE R0, #04H , CASE_5
            NUMBER_KEY_4:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_4
                MOV R0, #005H
                ACALL UPDATE_DATA_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_4:
                JMP WRONG_KEY
        CASE_5:
            CJNE R0, #05H , CASE_6
            NUMBER_KEY_5:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_4
                MOV R0, #006H
                ACALL UPDATE_DATA_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_5:
                JMP WRONG_KEY
        CASE_6:
            CJNE R0, #06H , CASE_7
            EXE_CLICK_6:
                CJNE R1, #EXECUTE, WRONG_KEY_6
                MOV R0, #007H
                SETB EXE_FLAG
                JMP DEFAULT_CASE
            WRONG_KEY_6:
                NUMBER_KEY_6: 
                    JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_6
                    ACALL UPDATE_DATA_INPUT
                    JMP DEFAULT_CASE
                NON_NUMBER_KEY_6:
                    JMP WRONG_KEY
        CASE_7:
            CJNE R0, #07H , DEFAULT_CASE
            ORG_CLICK_7:
                CJNE R1, #ORG_KEY, ADR_PLUS_CLICK_7
                MOV R0, #001H
                MOV R2, #000H ; reset data register
                JMP DEFAULT_CASE
            ADR_PLUS_CLICK_7:
                CJNE R1, #ADR_PLUS, ADR_MINUS_CLICK_7
                MOV R0, #004H
                MOV R2, #000H ; reset data register
                MOV A, R3
                INC A
                MOV R3, A
                JMP DEFAULT_CASE
            ADR_MINUS_CLICK_7:
                CJNE R1, #ADR_MINUS, WRONG_KEY_7
                MOV R0, #004H
                MOV R2, #000H ; reset data register
                MOV A, R3
                DEC A
                MOV R3, A
                JMP DEFAULT_CASE
            WRONG_KEY_7:
                JMP WRONG_KEY
    WRONG_KEY:
        SETB WRONG_FLAG
    DEFAULT_CASE:
        RET

UPDATE_ADDRESS_INPUT:
    MOV A, R3 ; load current input address
    SWAP A
    ANL A, #0F0H
    ORL A, R1 
    MOV R3, A
    RET

UPDATE_DATA_INPUT:
    MOV A, R2 ; load current input data
    SWAP A
    ANL A, #0F0H
    ORL A, R1 
    MOV R2, A
    RET

SHOW_ON_SEGMENT: ; current implementation is very basic
    
    RET

MAIN:
    ACALL INIT
LOOP:
    JMP LOOP

INIT:
    MOV P0, #000H   ; define P0 as output
    MOV P2, #0FFH   ; define P2 as input
    MOV P1, #000H   ; define P1 as output
    SETB IT0        ; Falling edge interrupt
    CLR EX1         ; Disable external interrupt 1
    MOV R0, #000H   ; initialize R0 which is the state register
    MOV R1, #000H   ; initialize R1 which is the input register
    MOV R2, #000H   ; initialize R2 which is the current data 
    MOV R3, #000H   ; initialize R3 which is the current address
    CLR NUMBER_INPUT_FLAG 
    CLR END_FLAG
    CLR EXE_FLAG
    SETB EA         ; Enable interrupt individually
    SETB EX0        ; Enable external interrupt0
    RET

WRONG_PRESS:
    RET
    
RUN_EXE:
    CJNE R0, #004H, UPDATE_MEMORY
    RET ; address is already saved in R3, no need for change
    UPDATE_MEMORY:
    MOV B, R0 ; temporary memory
    MOV A, R3
    MOV R0, A
    MOV A, R2
    MOV @R0, A
    MOV R0, B
    RET

RUN_CODE:
    RET
    
END