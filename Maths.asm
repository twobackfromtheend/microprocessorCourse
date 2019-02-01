#include p18f87k22.inc

    global  Mul_8_16, Mul_16_16, Mul_8_24

acs0    udata_acs   ; named variables in access ram
result_24	res 3
result_32	res 4

acs_ovr	access_ovr
; For Mul_8_16
_lower_prodl	res 1
_lower_prodh	res 1

Maths	code
    
	

; Multiply 8 bit in W with 16 bits in FSR0
; Returned 16 bits in FSR2. 8 bits in W are lost, FSR0 persists.
Mul_8_16	
	mulwf	POSTINC0	; Lower 8bits -> PRODH:PRODL
	movff	PRODL, _lower_prodl
	movff	PRODH, _lower_prodh
	
	mulwf	POSTDEC0	; Upper 8bits -> PRODH:PRODL
	; POSTDEC moves FSR0 back to normal.
	
;	Multiplication result: PRODH, _lower_prodh+PRODL, _lower_prodl
	movff	_lower_prodl, result_24
	movf	PRODL, W
	addwf	_lower_prodh, W
	movwf	result_24 + 1
	movlw	0
	addwfc	PRODH, W
	movwf	result_24 + 2
	
	; Below is old code that shifts result to FSR2.
;	lfsr	FSR2, result_24
;	movff	_lower_prodl, POSTINC2
;	
;	movf	PRODL, W
;	addwf	_lower_prodh, W
;	movwf	POSTINC2
;	
;	movlw	0
;	addwfc	PRODH, W
;	movwf	INDF2
	
	lfsr	FSR2, result_24
	return
	
; Multiply 16 bits in FSR0 with 16 bits in FSR1
; Returned 32 bits in FSR2. FSR0 persists??
Mul_16_16	
	; Multiply lower 8 in FSR1 with 16 bits in FSR0.
	movf	POSTINC1, W	; lower 8 bits of FSR1
	call	Mul_8_16	; Result: 24 bits in FSR2
	;   Move 24 bits in FSR2 to result_32
	movff	POSTINC2, result_32
	movff	POSTINC2, result_32 + 1
	movff	INDF2, result_32 + 2
	
	; Multiply upper 8 in FSR1 with 16 bits in FSR0.
	movf	INDF1, W	; Upper 8 bits of FSR1.
	call	Mul_8_16	; Result: 24 bits in FSR2
	
	; Add 24 bits in FSR2 to result_32 (shifted up by 1 byte)
	; Add lower 8 bits in FSR2 to result_32
	movf	POSTINC2, W
	addwf	result_32 + 1, f
	; Add middle 8 bits in FSR2 to result_32 with carry
	movf	POSTINC2, W
	addwfc	result_32 + 2, f
	; Add upper 8 bits in FSR2 to result_32 with carry
	movff	INDF2, result_32 + 3
	movlw	0
	addwfc	result_32 + 3, f
	
	lfsr	FSR2, result_32	   
	return
	
	
; Multiply 8 bits in W with 24 bits in FSR0
; Returned 32 bits in FSR2. 8 bits in W are lost.
Mul_8_24	
	; Multiply lower 8 in FSR0 with multiplier_8_bit	
	mulwf	POSTINC0	; 16-bit result -> PRODH:PRODL
	; Store in result_32
	movff	PRODL, result_32
	movff	PRODH, result_32 + 1
	
	; Multiply upper 16 in FSR0 with multiplier_8_bit
	call	Mul_8_16	; 24-bit result in FSR2
	
	movf	POSTINC2, W
	addwf	result_32 + 1, f    ; only real addition of numbers (additions below just propagate carry)
	
	; Zero out bytes for addwfc.
	movlw	0
	movwf	result_32 + 2
	movwf	result_32 + 3
	
	; addwfc to propagate carry through bytes.
	movf	POSTINC2, W
	addwfc	result_32 + 2, f
	movf	INDF2, W
	addwfc	result_32 + 3, f
	
	lfsr	FSR2, result_32
	return
	
    end