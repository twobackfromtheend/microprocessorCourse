	#include p18f87k22.inc
	
	code
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100

	; ******* Programme FLASH read Setup Code ****  
;setup	bcf	EECON1, CFGS	; point to Flash program memory  
;	bsf	EECON1, EEPGD 	; access Flash program memory
	
	movlw 	0x0
	movwf	TRISC, ACCESS	    ; Port C all outputs
	
	
	goto	start
	; ******* My data and where to put it in RAM *
myTable db	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80
	constant 	counter=0x10	; Address of counter variable
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
	
loop	tblrd*+			; move one byte from PM to TABLAT, increment TBLPTR
	movfw	TABLAT		; Move TABLAT (TBLPTR value) to W
	movwf	PORTC		; Move W to PORTC (TBLPTR value)
	decfsz	counter		; Decrement counter, skip if zero
	bra	loop		; keep going until finished
	
	goto	0

	end