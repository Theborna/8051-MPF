;====================================================================
; DEFINITIONS
;====================================================================
; addresses
;====================================================================
; in coding mode
; R0 is the State of the FSM
; R1 is the Input
; R2 is the input data
; R3 is the input address
;====================================================================
; in execution mode
; R6 is the beginning address
; R1 is the PC
; R3 is the stack
; R4 is the IR
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
    ; visualization
    ACALL SHOW_ON_SEGMENT
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
    JMP RUN_CODE ; go to execution
    ISR_NON_END:
    ; reset and return from interrupt   
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
    ; check if input was a special function, should not change accumulator value
    MOV 0FFH, A
    MOV A, R1
    ANL A, #0F0H
    CJNE A, #0C0H, NON_SPECIAL_FUNCTION
    MOV A, 0FFH
    ACALL FUNCTION_CALL
    RET
    NON_SPECIAL_FUNCTION:
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
    ; check if input was END
    CJNE R1, #END_KEY, GENERAL_KEY
    SETB END_FLAG
    MOV R0, #000H   ; reset state
    MOV R2, #000H   ; reset address register
    MOV R3, #000H   ; reset data register
    RET
    ; Perform the switch-case
    GENERAL_KEY:
        CASE_0: CJNE R0, #00H , CASE_1
            ORG_CLICK_0:
                CJNE R1, #ORG_KEY, WRONG_KEY_0
                MOV R0, #001H    ; update state
                JMP DEFAULT_CASE
            WRONG_KEY_0:
                JMP WRONG_KEY
        CASE_1: CJNE R0, #01H , CASE_2
            NUMBER_KEY_1:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_1
                MOV R0, #002H
                ACALL UPDATE_ADDRESS_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_1:
                JMP WRONG_KEY
        CASE_2: CJNE R0, #02H , CASE_3
            NUMBER_KEY_2:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_2
                MOV R0, #003H
                ACALL UPDATE_ADDRESS_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_2:
                JMP WRONG_KEY
        CASE_3: CJNE R0, #03H , CASE_4
            EXE_CLICK_3:
                CJNE R1, #EXECUTE, WRONG_KEY_3
                MOV R0, #004H
                ; beginning value of PC
                MOV A , R3
                MOV R6, A
                SETB EXE_FLAG 
                ACALL RESET_DATA_REG
                JMP DEFAULT_CASE
            WRONG_KEY_3:
                NUMBER_KEY_3: 
                    JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_3
                    ACALL UPDATE_ADDRESS_INPUT
                    JMP DEFAULT_CASE
                NON_NUMBER_KEY_3:
                    JMP WRONG_KEY
        CASE_4: CJNE R0, #04H , CASE_5
            NUMBER_KEY_4:
                JNB NUMBER_INPUT_FLAG, ADR_PLUS_CLICK_4
                MOV R0, #005H
                ACALL UPDATE_DATA_INPUT
                JMP DEFAULT_CASE
            ADR_PLUS_CLICK_4:
                CJNE R1, #ADR_PLUS, ADR_MINUS_CLICK_4
                INC R3
                ACALL RESET_DATA_REG
                JMP DEFAULT_CASE
            ADR_MINUS_CLICK_4:
                CJNE R1, #ADR_MINUS, WRONG_KEY_4
                DEC R3
                ACALL RESET_DATA_REG
                JMP DEFAULT_CASE
            WRONG_KEY_4:
                JMP WRONG_KEY
        CASE_5: CJNE R0, #05H , CASE_6
            NUMBER_KEY_5:
                JNB NUMBER_INPUT_FLAG, NON_NUMBER_KEY_5
                MOV R0, #006H
                ACALL UPDATE_DATA_INPUT
                JMP DEFAULT_CASE
            NON_NUMBER_KEY_5:
                JMP WRONG_KEY
        CASE_6: CJNE R0, #06H , CASE_7
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
        CASE_7: CJNE R0, #07H , DEFAULT_CASE
            ORG_CLICK_7:
                CJNE R1, #ORG_KEY, ADR_PLUS_CLICK_7
                MOV R0, #001H
                ACALL RESET_DATA_REG
                JMP DEFAULT_CASE
            ADR_PLUS_CLICK_7:
                CJNE R1, #ADR_PLUS, ADR_MINUS_CLICK_7
                MOV R0, #004H
                INC R3
                ACALL RESET_DATA_REG
                JMP DEFAULT_CASE
            ADR_MINUS_CLICK_7:
                CJNE R1, #ADR_MINUS, WRONG_KEY_7
                MOV R0, #004H
                DEC R3
                ACALL RESET_DATA_REG
                JMP DEFAULT_CASE
            WRONG_KEY_7:
                JMP WRONG_KEY
    WRONG_KEY:
        SETB WRONG_FLAG
    DEFAULT_CASE:
        ACALL SET_DATA_ON_SEGMENT
        RET

RESET_DATA_REG:
    MOV 0FFH, R0
    MOV A, R3
    MOV R0, A
    MOV A , @R0 
    MOV R2, A
    MOV R0, 0FFH
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

FUNCTION_CALL:
    F1_CALL: CJNE R1, #F1, F2_CALL
    RET ; do nothing, it should show the accumilator
    F2_CALL: CJNE R1, #F2, F3_CALL
    MOV A, R0 ; show current state
    RET
    F3_CALL: CJNE R1, #F3, F4_CALL
    MOV A, R3 ; show current adress
    RET
    F4_CALL: CJNE R1, #F4, F5_CALL
    MOV A, R2 ; show current data
    RET
    F5_CALL: CJNE R1, #F5, F6_CALL
    MOV A, R6 ; show code start
    RET
    F6_CALL: CJNE R1, #F6, F7_CALL
    MOV A, B ; show B register
    RET
    F7_CALL: CJNE R1, #F7, F8_CALL
    MOV A, 0CFH ; show data in specific part of memory
    RET
    F8_CALL: CJNE R1, #F8, DEFAULT_CALL
    DEFAULT_CALL:
    ACALL SET_DATA_ON_SEGMENT
    RET

SET_DATA_ON_SEGMENT:
    MOV A , R0
    ANL A, #11111100B
    CJNE A, #0H , SHOW_R2_ON_SEGMENT
    MOV A, R3
    RET
    SHOW_R2_ON_SEGMENT:
    MOV A, R2
    RET

SHOW_ON_SEGMENT: ; current implementation is very basic
    MOV P1, A
    RET

MAIN:
    MOV P0, #000H   ; define P0 as output
    MOV P2, #0FFH   ; define P2 as input
    MOV P1, #000H   ; define P1 as output
START:
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
LOOP:
    JMP LOOP

WRONG_PRESS: ; make the segments blink
    MOV B, P1 ; save current value showing
    MOV A, #88H
    ACALL SHOW_ON_SEGMENT
    ACALL DELAY
    MOV A, B
    ACALL SHOW_ON_SEGMENT
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
    INIT_RUN:
    MOV A , R6
    MOV R1, A       ; PC
    ; we do not use a MAR since using basic asm we can implement its functionality
    MOV R4, #00H    ; IR
    MOV R3, #00H    ; STACK
    FETCH:
    MOV 0FFH, A
    MOV A, @R1
    MOV R4, A ; IR <- @PC
    ; testing purposes
    ; ACALL SHOW_ON_SEGMENT
    ; ACALL DELAY
    MOV A, 0FFH
    INC R1 ; PC <- PC + 1
    ACALL DECODE_AND_EXECUTE
    JMP FETCH ; will not exit, need to use RST, or write new code
    
DECODE_AND_EXECUTE:
    NOP_MNEMONIC: CJNE R4, #000H, INC_A_MNEMONIC
        EXECUTE_END: 
            ACALL SHOW_ON_SEGMENT ; show accumilator on segment
            JMP START ; end execution
    RET
    
    INC_A_MNEMONIC: CJNE R4, #004H, INC_R0_MNEMONIC
        INC A ; Increase A
    RET
    
    INC_R0_MNEMONIC: CJNE R4, #008H, INC_R2_MNEMONIC
        INC R0 ; Increase R0
    RET
    
    INC_R2_MNEMONIC: CJNE R4, #00AH, INC_R5_MNEMONIC
        INC R2 ; Increase R2
    RET
    
    INC_R5_MNEMONIC: CJNE R4, #00DH, INC_R7_MNEMONIC
        INC R5 ; Increase R5
    RET
    
    INC_R7_MNEMONIC: CJNE R4, #00FH, ACALL_MNEMONIC
        INC R7 ; Increase R7
    RET
    
    ACALL_MNEMONIC: CJNE R4, #011H, DEC_A_MNEMONIC
        INC R1 ; PC=PC+1
        MOV 0FFH, A
        MOV A, R1
        MOV R3, A ; Move next PC value to stack
        DEC R1
        MOV A, @R1 
        MOV R1, A ; Move the next address to PC
        MOV A, 0FFH
    RET
    
    DEC_A_MNEMONIC: CJNE R4, #014H, DEC_R0_MNEMONIC
        DEC A
    RET
    
    DEC_R0_MNEMONIC: CJNE R4, #018H, DEC_R2_MNEMONIC
        DEC R0
    RET
    
    DEC_R2_MNEMONIC: CJNE R4, #01AH, DEC_R5_MNEMONIC
        DEC R2
    RET
    
    DEC_R5_MNEMONIC: CJNE R4, #01DH, DEC_R7_MNEMONIC
        DEC R5
    RET
    
    DEC_R7_MNEMONIC: CJNE R4, #01FH, JB_MNEMONIC
        DEC R7
    RET
    
    JB_MNEMONIC: CJNE R4, #020H, RET_MNEMONIC
        
    RET
    
    RET_MNEMONIC: CJNE R4, #022H, ADD_IMMEDIATE_MNEMONIC
        MOV 0FFH, A
        MOV A, R3
        MOV R1, A ; Move stack to PC
        MOV A, 0FFH
    RET
    
    ADD_IMMEDIATE_MNEMONIC: CJNE R4, #024H, ADD_R0_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1 
        MOV R4, A ; Move the value in next memory location to R4
        MOV A, 0FFH
        ADD A, R4 ; Add A with the value in the next memory location
        INC R1 ; PC=PC+1
    RET
    
    ADD_R0_MNEMONIC: CJNE R4, #028H, ADD_R2_MNEMONIC
        ADD A, R0
    RET
    
    ADD_R2_MNEMONIC: CJNE R4, #02AH, ADD_R5_MNEMONIC
        ADD A, R2
    RET
    
    ADD_R5_MNEMONIC: CJNE R4, #02DH, ADD_R7_MNEMONIC
        ADD A, R5
    RET
    
    ADD_R7_MNEMONIC: CJNE R4, #02FH, ADDC_IMMIDIATE_MNEMONIC
        ADD A, R7
    RET
    
    ADDC_IMMIDIATE_MNEMONIC: CJNE R4, #034H, JZ_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1 
        MOV R4, A ; Move the value in next memory location to R4
        MOV A, 0FFH
        ADDC A, R4 ; Add A with the value in the next memory location
        INC R1 ; PC=PC+1
    RET
    
    JZ_MNEMONIC: CJNE R4, #060H, JNZ_MNEMONIC
        JZ ZERO_JZ_MNEMONIC
        INC R1
        RET
        ZERO_JZ_MNEMONIC:
        MOV 0FFH, A
        MOV A, @R1 
        MOV R1, A
        MOV A, 0FFH
    RET
    
    JNZ_MNEMONIC: CJNE R4, #070H, AJMP_MNEMONIC
        JNZ NZERO_JNZ_MNEMONIC
        INC R1
        RET
        NZERO_JNZ_MNEMONIC:
        MOV 0FFH, A
        MOV A, @R1 
        MOV R1, A
        MOV A, 0FFH
    RET
    
    AJMP_MNEMONIC: CJNE R4, #061H, MOV_A_IMMIDIATE_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1 
        MOV R1, A ; Move the next address to PC
        MOV A, 0FFH
    RET
    
    MOV_A_IMMIDIATE_MNEMONIC: CJNE R4, #074H, MOV_R0_IMMIDIATE_MNEMONIC
        MOV A, @R1
        INC R1
    RET
    
    MOV_R0_IMMIDIATE_MNEMONIC: CJNE R4, #078H, MOV_R2_IMMIDIATE_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1
        MOV R0, A
        MOV A, 0FFH
        INC R1
    RET
    
    MOV_R2_IMMIDIATE_MNEMONIC: CJNE R4, #07AH, MOV_R5_IMMIDIATE_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1
        MOV R2, A
        MOV A, 0FFH
        INC R1
    RET
    
    MOV_R5_IMMIDIATE_MNEMONIC: CJNE R4, #07DH, MOV_R7_IMMIDIATE_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1
        MOV R5, A
        MOV A, 0FFH
        INC R1
    RET
    
    MOV_R7_IMMIDIATE_MNEMONIC: CJNE R4, #07FH, MOV_A_R0_MNEMONIC
        MOV 0FFH, A
        MOV A, @R1
        MOV R7, A
        MOV A, 0FFH
        INC R1
    RET
    
    MOV_A_R0_MNEMONIC: CJNE R4, #0E8H, MOV_A_R2_MNEMONIC
        MOV A, R0
    RET
    
    MOV_A_R2_MNEMONIC: CJNE R4, #0EAH, MOV_A_R5_MNEMONIC
        MOV  A, R2
    RET
    
    MOV_A_R5_MNEMONIC: CJNE R4, #0EDH, MOV_A_R7_MNEMONIC
        MOV A, R5
    RET
    
    MOV_A_R7_MNEMONIC: CJNE R4, #0EFH, CPL_A_MNEMONIC
        MOV A, R7
    RET
    
    CPL_A_MNEMONIC: CJNE R4, #0F4H, MOV_addrR1_A_MNEMONIC
        CPL A
    RET

    MOV_addrR1_A_MNEMONIC: CJNE R4, #0F6H, MOV_R0_A_MNEMONIC
        MOV @R0, A
    RET
    
    MOV_R0_A_MNEMONIC: CJNE R4, #0F8H, MOV_R2_A_MNEMONIC
        MOV R0, A
    RET
    
    MOV_R2_A_MNEMONIC: CJNE R4, #0FAH, MOV_R5_A_MNEMONIC
        MOV R2, A
    RET
    
    MOV_R5_A_MNEMONIC: CJNE R4, #0FDH, MOV_R7_A_MNEMONIC
        MOV R5, A
    RET
    
    MOV_R7_A_MNEMONIC: CJNE R4, #0FFH, INVALID_OPCODE
        MOV R7, A
    RET
    
    INVALID_OPCODE:
        MOV P1, #0FFH
        JMP LOOP
    RET


; delay  generator subroutine
DELAY:
    MOV 0FEH, #00AH ; Following delay will reapeat  31 times
    WAIT2:MOV TMOD, #001H
    MOV TL0, #000H
    MOV TH0, #000H
    SETB TR0
    WAIT1: JNB TF0, WAIT1
    CLR TF0
    CLR TR0
    DJNZ 0FEH, WAIT2
    RET
    
END