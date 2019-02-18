#include p18f87k22.inc
	
;	global  DAC_Setup
	
	extern	LCD_delay_ms
	
;int_hi	code	0x0008	; high vector, no low vector
;	btfss	INTCON,TMR0IF	; check that this is timer0 interrupt
;	retfie	FAST		; if not then return
;	incf	LATD		; increment PORTD
;
;	; Trigger write
;	clrf	PORTC
;;	movlw	.1
;;	call	LCD_delay_ms
;	
;	
;	setf	PORTC
;	
;	bcf	INTCON,TMR0IF	; clear interrupt flag
;	retfie	FAST		; fast return from interrupt

main	code
	
;DAC_Setup
;	clrf	TRISC		; PORTC write
;	setf	LATC
;	
;	clrf	TRISD		; Set PORTD as all outputs
;	clrf	LATD		; Clear PORTD outputs
;;	movlw	b'10000000'	; Set timer0 to 16-bit, Fosc/4/256
;	movlw	b'11000000'	; Set timer0 to 8-bit, Fosc/4/256
;
;	movwf	T0CON		; = 62.5KHz clock rate, approx 1sec rollover
;	bsf	INTCON,TMR0IE	; Enable timer0 interrupt
;	bsf	INTCON,GIE	; Enable all interrupts

	
dd	
	nop
	nop
	return
	
	end