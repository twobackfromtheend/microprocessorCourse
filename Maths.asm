#include p18f87k22.inc

    global  Mul_8_16, multiplier_16

acs0    udata_acs   ; named variables in access ram
multiplier_16   res 2
result_24	res 3

acs_ovr	access_ovr
_lower_prodl	res 1
_lower_prodh	res 1

Maths	code
    
	

; Multiply 8 bit in W with 16 bits in multiplier_16
Mul_8_16
	lfsr	FSR2, multiplier_16
	mulwf	POSTINC2	; Lower 8bits -> PRODH:PRODL
	movff	PRODL, _lower_prodl
	movff	PRODH, _lower_prodh
	
	mulwf	INDF2		; Upper 8bits -> PRODH:PRODL
;	PRODH, _lower_prodh+PRODL, _lower_prodl
	lfsr	FSR2, result_24
	movff	_lower_prodl, POSTINC2
	
	movf	PRODL, W
	addwf	_lower_prodh, W
	movwf	POSTINC2
	
	movlw	0
	addwfc	PRODH, W
	movwf	INDF2
	
	lfsr	FSR2, result_24
	
	return
	
    end