#include p18f87k22.inc
	
	global  Timer_Setup
	
	extern	Game_Loop
	
		
Timer_Interrupt	code	0x0008	; high vector, no low vector
	btfss	INTCON, TMR0IF	; check that this is timer0 interrupt
	retfie	FAST		; if not then return
	
	; Toggle bit 7 on PORTD
	bcf	LATD, 7
	
	call	Game_Loop
	
	; Toggle bit 7 on PORTD
	bsf	LATD, 7
		
	bcf	INTCON, TMR0IF	; clear interrupt flag
	retfie	FAST		; fast return from interrupt

Timer	code
	
Timer_Setup
	bcf	TRISD, 7	; Output on pin 7
	
;	movlw	b'10000000'
;	; approx 8ms frame
;	movlw	b'10000011'
	; approx 65ms frame
	movlw	b'10000010'
	; approx 30ms frame
	
	
;	movlw	b'10000111'	; Set timer0 to 16-bit, Fosc/4/256
	; Approx 1Hz
	
;	movlw	b'11000000'	; Set timer0 to 8-bit, Fosc/4/256

	movwf	T0CON		; = 62.5KHz clock rate, approx 1sec rollover
	bsf	INTCON,TMR0IE	; Enable timer0 interrupt
	bsf	INTCON,GIE	; Enable all interrupts
	return


	end