	#include p18f87k22.inc
	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100

	
;	Data
	constant    counter=0x10
	constant    outputC=0x06
	
	
start
;	Initialise
;	movlw	0xff
;	movwf	counter		    ; Initialise counter
	
	movlw	0xff
	movwf	TRISD, ACCESS	    ; Port D all inputs
	movlw 	0x0
	movwf	TRISC, ACCESS	    ; Port C all outputs 
	
	
	
	bra 	test
loop	call	dloop		    ; Delay
	movff 	outputC, PORTC	    ; Set PORTC to outputC
	incf 	outputC, W, ACCESS  ; W = outputC + 1
test	movwf	outputC, ACCESS	    ; Test for end of loop condition
	
	movf	PORTD, W, ACCESS    ; W = PORTD
	
	cpfsgt 	outputC, ACCESS	    ; Skip if outputC > W?
	bra 	loop		    ; Loop to inc PORTC, read PORTD
	goto 	0x0		    ; Re-run program from start
	
	
;	Delay subroutine
dloop	decfsz	counter, F, ACCESS
	bra	dloop
	movlw	0xff
	movwf	counter
	return	0
	
	
	end
