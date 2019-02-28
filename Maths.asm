#include p18f87k22.inc

    global  Mul_8_16, Mul_16_16, Mul_8_24
    global  Compare_2B, compare_2B_1, compare_2B_2
    global  Absolute_2B
    global  Divide_4_2B, Divide_8_2B, Multiply_2_2B
    global  Mul_16_16_2s_complement
    global  Divide_4B_4096

acs0    udata_acs   ; named variables in access ram
result_24   res 3
result_32   res 4

; Arguments for Compare_2B
compare_2B_1    res 2
compare_2B_2    res 2

; temporary variables
_lower_prodl    res 1
_lower_prodh    res 1

_sign_check res 1

; Used for multiplying 2s complement numbers - absolute values are multiplied, sign corrected after.
positive_multiplier_1   res 2
positive_multiplier_2   res 2


Maths   code



; Multiply 8 bit in W with 16 bits in FSR0
; Returned 16 bits in FSR2. 8 bits in W are lost, FSR0 persists.
Mul_8_16
    mulwf   POSTINC0    ; Lower 8bits -> PRODH:PRODL
    movff   PRODL, _lower_prodl
    movff   PRODH, _lower_prodh

    mulwf   POSTDEC0    ; Upper 8bits -> PRODH:PRODL
    ; POSTDEC moves FSR0 back to normal.

;   Multiplication result: PRODH, _lower_prodh+PRODL, _lower_prodl
    movff   _lower_prodl, result_24
    movf    PRODL, W
    addwf   _lower_prodh, W
    movwf   result_24 + 1
    movlw   0
    addwfc  PRODH, W
    movwf   result_24 + 2

    lfsr    FSR2, result_24
    return

; Multiply 16 bits in FSR0 with 16 bits in FSR1
; Returned 32 bits in FSR2. FSR0 persists
Mul_16_16
    ; Multiply lower 8 in FSR1 with 16 bits in FSR0.
    movf    POSTINC1, W ; lower 8 bits of FSR1
    call    Mul_8_16    ; Result: 24 bits in FSR2
    ;   Move 24 bits in FSR2 to result_32
    movff   POSTINC2, result_32
    movff   POSTINC2, result_32 + 1
    movff   INDF2, result_32 + 2

    ; Multiply upper 8 in FSR1 with 16 bits in FSR0.
    movf    INDF1, W    ; Upper 8 bits of FSR1.
    call    Mul_8_16    ; Result: 24 bits in FSR2

    ; Add 24 bits in FSR2 to result_32 (shifted up by 1 byte)
    ; Add lower 8 bits in FSR2 to result_32
    movf    POSTINC2, W
    addwf   result_32 + 1, f
    ; Add middle 8 bits in FSR2 to result_32 with carry
    movf    POSTINC2, W
    addwfc  result_32 + 2, f
    ; Add upper 8 bits in FSR2 to result_32 with carry
    movff   INDF2, result_32 + 3
    movlw   0
    addwfc  result_32 + 3, f

    lfsr    FSR2, result_32
    return


; Multiply 8 bits in W with 24 bits in FSR0
; Returned 32 bits in FSR2. 8 bits in W are lost.
Mul_8_24
    ; Multiply lower 8 in FSR0 with multiplier_8_bit
    mulwf   POSTINC0    ; 16-bit result -> PRODH:PRODL
    ; Store in result_32
    movff   PRODL, result_32
    movff   PRODH, result_32 + 1

    ; Multiply upper 16 in FSR0 with multiplier_8_bit
    call    Mul_8_16    ; 24-bit result in FSR2

    movf    POSTINC2, W
    addwf   result_32 + 1, f    ; only real addition of numbers (additions below just propagate carry)

    ; Zero out bytes for addwfc.
    movlw   0
    movwf   result_32 + 2
    movwf   result_32 + 3

    ; addwfc to propagate carry through bytes.
    movf    POSTINC2, W
    addwfc  result_32 + 2, f
    movf    INDF2, W
    addwfc  result_32 + 3, f

    lfsr    FSR2, result_32
    return

; If compare_2B_1 > compare_2B_2: return with 1 in W
; Numbers are compared as unsigned ints.
Compare_2B
    ;   compare_2B_1 + 1 > HIGHER(compare_2B_2) call FUNCTION OR
    ;   compare_2B_1 + 1 = HIGHER(compare_2B_2) AND compare_2B_1 > LOWER(compare_2B_2), call FUNCTION
    movf    compare_2B_2 + 1, W     ; cpfsgt - skip if f > W
    cpfsgt  compare_2B_1 + 1        ; skip if compare_2B_1 + 1 > compare_2B_2 + 1
    bra _check_VAR1_condition_2
    retlw   1
_check_VAR1_condition_2
    movf    compare_2B_2 + 1, W
    cpfseq  compare_2B_1 + 1        ; skip if compare_2B_1 + 1 = compare_2B_2 + 1
    retlw   0
    movf    compare_2B_2, W
    cpfsgt  compare_2B_1            ; skip if compare_2B_1 > compare_2B_2
    retlw   0
    retlw   1


; Turns a 2s complement number in FSR0 to its absolute_value
Absolute_2B
    movlw   1
    btfss   PLUSW0, 7       ; Skip if bit is set (is negative).
    return
    comf    PLUSW0, f       ; Complement
    comf    INDF0, f
    movlw   1
    addwf   INDF0, f        ; Add 1
    movlw   0
    addwfc  PLUSW0, f
    return

; Divides a 2s complement number in FSR0 by 8, places back.
Divide_8_2B
    movlw   1
    btfsc   PLUSW0, 7       ; Skip if bit is clear (is positive).
    bra negative_division
positive_division
    bcf STATUS, C       ; Clear carry flag
    rrcf    PLUSW0, f       ; Rotate top byte, carry to lower byte
    rrcf    INDF0, f
    bcf STATUS, C       ; Clear carry flag
    rrcf    PLUSW0, f
    rrcf    INDF0, f

    bcf STATUS, C       ; Clear carry flag
    ; Divide and round last bit
    btfsc   INDF0, 0        ; If last bit is clear, do not round
    bra round_pdiv
no_round_pdiv
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    return
round_pdiv
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    movlw   1
    addwf   INDF0, f
    movlw   0
    addwfc  PLUSW0, f
    return

negative_division
    bsf STATUS, C       ; Set carry flag (pad left with 1s)
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    bsf STATUS, C       ; Set carry flag (pad left with 1s)
    rrcf    PLUSW0, f
    rrcf    INDF0, f

    bsf STATUS, C       ; Set carry flag (pad left with 1s)
    ; Divide and round last bit
    btfsc   INDF0, 0        ; If last bit is clear, do not round
    bra round_ndiv
no_round_ndiv
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    return
round_ndiv
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    movlw   1
    addwf   INDF0, f
    movlw   0
    addwfc  PLUSW0, f
    return

; Divides a 2s complement number in FSR0 by 4, places back.
Divide_4_2B
    movlw   1
    btfsc   PLUSW0, 7       ; Skip if bit is clear (is positive).
    bra negative_division4
positive_division4
    bcf STATUS, C       ; Clear carry flag
    rrcf    PLUSW0, f       ; Rotate top byte, carry to lower byte
    rrcf    INDF0, f

    bcf STATUS, C       ; Clear carry flag
    ; Divide and round last bit
    btfsc   INDF0, 0        ; If last bit is clear, do not round
    bra round_pdiv4
no_round_pdiv4
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    return
round_pdiv4
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    movlw   1
    addwf   INDF0, f
    movlw   0
    addwfc  PLUSW0, f
    return

negative_division4
    bsf STATUS, C       ; Set carry flag (pad left with 1s)
    rrcf    PLUSW0, f
    rrcf    INDF0, f

    bsf STATUS, C       ; Set carry flag (pad left with 1s)
    ; Divide and round last bit
    btfsc   INDF0, 0        ; If last bit is clear, do not round
    bra round_ndiv4
no_round_ndiv4
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    return
round_ndiv4
    rrcf    PLUSW0, f
    rrcf    INDF0, f
    movlw   1
    addwf   INDF0, f
    movlw   0
    addwfc  PLUSW0, f
    return


; Multiply a 2s complement number in FSR0 by 2, places back.
Multiply_2_2B
    movlw   1
    btfsc   PLUSW0, 7       ; Skip if bit is clear (is positive).
    bra negative_multiply
positive_multiply
    bcf STATUS, C       ; Clear carry flag
    rlcf    POSTINC0, f     ; Rotate low byte, carry to high byte
    rlcf    POSTDEC0, f
    return
negative_multiply
    bcf STATUS, C       ; Clear carry flag
    rlcf    POSTINC0, f
    rlcf    POSTDEC0, f
    return


; Multiply 16 bits in FSR0 with 16 bits in FSR1
; Returned 32 bits in FSR2. FSR0 persists
Mul_16_16_2s_complement
    ; Move sign bit from FSR0 to _sign_check
    movlw   1
    movff   PLUSW0, _sign_check
    ; XOR sign bit from FSR1 with _sign_check
    movf    PLUSW1, W
    xorwf   _sign_check, f
    ; Sign of result is now MSB of _sign_check
    movff   POSTINC0, positive_multiplier_1
    movff   POSTDEC0, positive_multiplier_1 + 1
    lfsr    FSR0, positive_multiplier_1     ; Absolute_2B modifies FSR0 inplace
    call    Absolute_2B

    movff   POSTINC1, positive_multiplier_2
    movff   POSTDEC1, positive_multiplier_2 + 1
    lfsr    FSR0, positive_multiplier_2     ; Absolute_2B modifies FSR0 inplace
    call    Absolute_2B

    lfsr    FSR0, positive_multiplier_1
    lfsr    FSR1, positive_multiplier_2
    call    Mul_16_16               ; Result in FSR2, result_32

    ; Change result_32 based on _sign_check
    btfss   _sign_check, 7              ; Skip if has to change to negative
    return
    comf    result_32, f
    comf    result_32 + 1, f
    comf    result_32 + 2, f
    comf    result_32 + 3, f
    movlw   1
    addwf   result_32
    movlw   0
    addwfc  result_32 + 1
    addwfc  result_32 + 2
    addwfc  result_32 + 3

    return

; Divides 4 bytes in FSR0 by 4096 (2^12) and places it in FSR2 (Result spans 4 bytes, but is 3-byte number)
Divide_4B_4096
    ; Move 4 bytes in FSR0 to result_32
    movff   POSTINC0, result_32
    movff   POSTINC0, result_32 + 1
    movff   POSTINC0, result_32 + 2
    movff   INDF0, result_32 + 3
    movff   INDF0, _sign_check      ; Keep high byte for sign.

    movlw   .12         ; Counter in WREG

    btfss   _sign_check, 7          ; Skip if negative
    bra positive_divide_4B
    bra negative_divide_4B

positive_divide_4B
    bcf STATUS, C       ; Set carry flag (pad left with 0s)
    rrcf    result_32 + 3, f
    rrcf    result_32 + 2, f
    rrcf    result_32 + 1, f
    rrcf    result_32, f
    decfsz  WREG, W
    bra positive_divide_4B
    bra divide_4096_end

negative_divide_4B
    bsf STATUS, C       ; Set carry flag (pad left with 1s)
    rrcf    result_32 + 3, f
    rrcf    result_32 + 2, f
    rrcf    result_32 + 1, f
    rrcf    result_32, f
    decfsz  WREG, W
    bra negative_divide_4B

divide_4096_end

    lfsr    FSR2, result_32
    return


    end