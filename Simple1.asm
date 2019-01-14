	#include p18f87k22.inc
	
	code
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100

	; ******* Programme FLASH read Setup Code ****  
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	
	movlw 	0xFF
	movwf	TRISD, ACCESS	    ; Port D all inputs
	movlw 	0x0
	movwf	TRISC, ACCESS	    ; Port C all outputs
	
	
	goto	start
	; ******* My data and where to put it in RAM *
myTable db	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80
	constant 	counter=0x10	; Address of counter variable
	constant    dcounter0=0x16
	constant    dcounter1=0x20
	constant    dcounter2=0x24

	; ******* Main programme *********************

	
	
;	CHUNK LOADS 1 BYTE FROM MYTABLE
;	CREATES TBLPTR THAT POINTS TO MYTABLE
start	movlw	upper(myTable)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	
	movlw	.8		; 8 bytes to read - counter
	movwf	counter		; Initialise counter
	
loop	call	dloop2
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPTR
	movf	TABLAT, W	; Move TABLAT (TBLPTR value) to W
	movwf	PORTC		; Move W to PORTC (TBLPTR value)
	decfsz	counter		; Decrement counter, skip if zero
	bra	loop		; keep going until finished
	
	goto	0	
	
		
;	256^2 x Delay
dloop2	call	dloop1
	decfsz	dcounter2, F, ACCESS
	bra	dloop2
;	Reset counter to 255
	movlw	0xff
	movwf	dcounter2
	return	0
	
;	256x Delay
dloop1	call	dloop0
	decfsz	dcounter1, F, ACCESS
	bra	dloop1
;	Reset counter to 255
	movlw	0xff
	movwf	dcounter1
	return	0
	
	
	
;	Delay subroutine (set by PORT D)
dloop0	decfsz	dcounter0, F, ACCESS
	bra	dloop0
;	Next delay set by PORTD
	movf	PORTD, W, ACCESS    ; W = PORTD
	movwf	dcounter0	    ; dcounter = w - reset dcounter0 to PORTD

pause	movlw	0x7F
	CPFSLT	PORTD	    ; If PORTD < 7F: skip, else repeat check.
	bra	pause
	
	
	return	0
	
	
	
	
	end