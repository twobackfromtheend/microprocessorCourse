	#include p18f87k22.inc
	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100

	
;	Data
	constant    counter=0x10
	constant    counter2=0x16
	constant    outputC=0x06
	
	
start
;	Initialise
;	movlw	0xff
;	movwf	counter		    ; Initialise counter
	
	movlw	0xff
	movwf	TRISD, ACCESS	    ; Port D all inputs
	movlw 	0x0
	movwf	TRISC, ACCESS	    ; Port C all outputs 
	
;	Reset values to avoid state from previous run persisting
	movlw	0x00
	movwf	outputC
	
	
	
	bra 	test
loop	call	dloop2		    ; Delay
	movff 	outputC, PORTC	    ; Set PORTC's value to outputC
	incf 	outputC, W, ACCESS  ; W = outputC + 1
test	movwf	outputC, ACCESS	    ; outputC = W (=outputC + 1)
	
;	movf	PORTD, W, ACCESS    ; W = PORTD
	movlw	0xff		    ; W = 0xff
	
	cpfsgt 	outputC, ACCESS	    ; Skip if outputC > W?
	bra 	loop		    ; Loop to inc PORTC, read PORTD
	goto 	0x0		    ; Re-run program from start
	
	
	
	
	
;	256x Delay
dloop2	call	dloop
	decfsz	counter2, F, ACCESS
	bra	dloop2
;	Reset counter to 255
	movlw	0xff
	movwf	counter2
	return	0
	
	
	
;	Delay subroutine (set by PORT D)
dloop	decfsz	counter, F, ACCESS
	bra	dloop
;	Next delay set by PORTD
	movf	PORTD, W, ACCESS    ; W = PORTD
	movwf	counter
	return	0
	
	
	end
