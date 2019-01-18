	#include p18f87k22.inc
	
	code
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100

;	DATA
	constant    dCounter0=0x16
	constant    dCounter1=0x20
	
	constant    readData=0x40
	constant    writeData=0x48
	
	
;	Setup
setup	clrf	TRISC		    ; Port C all outputs (display)
	clrf	TRISD		    ; Port D all outputs (controller)
	setf	TRISE		    ; Port E tristate (read/write)
	
;	Keep CP1, CP2, OE1, OE2 high
	movlw	0xF
	movwf	PORTD
	
;	TODO: set output data to something not 0xf
	movlw	0xf
	movwf	writeData
	goto	start
	
	
	
start	call	masterW
	call	read1
	
;	Defaults to read state (E tristate). 
;	masterw has to handle changing state to write and 
;	returning it back to read
masterW	clrf	TRISE		    ; Set E to outputs
	movf	writeData, W	    
	movwf	LATE		    ; Move thing to write to LATE
	call	write1		    ; Lower and raise
	setf	TRISE		    ; Return E to tristate
	return	0
	
	
write1	movlw	0xE		    ; Set OE1, OE2 high - both off
	movwf	PORTD		    ; and CP1 low (CP2 kept high)
				    ; DO NOT SET CLOCK PULSE HIGH
;	call	dLoop0
	movlw	0xF		    ; Set CP1 high (keep OE1, OE2, CP2 high)
	movwf	PORTD
;	call	dLoop0
	return	0
	
	
read1	movlw	0xD		    ; Set OE1 low, OE2 high, CP1 & CP2 high
	movwf	PORTD
	
	movff	PORTE, readData
;	call	dLoop1
	return	0
	
dispC	movff	readData, PORTC
	return	0
	
	
;	256x Delay
dLoop1	call	dLoop0
	decfsz	dCounter1, F, ACCESS
	bra	dLoop1
;	Reset counter to 255
	movlw	0xff
	movwf	dCounter1
	return	0
	
	
	
;	Delay subroutine (ff)
dLoop0	decfsz	dCounter0, F, ACCESS
	bra	dLoop0
;	Next delay set by PORTD
	movlw	0xFF
	movwf	dCounter0	    ; dcounter = w: reset dcounter0 to FF
	return	0
	
	
;
;	; ******* Programme FLASH read Setup Code ****  
;setup	bcf	EECON1, CFGS	; point to Flash program memory  
;	bsf	EECON1, EEPGD 	; access Flash program memory
;	
;	movlw 	0xFF
;	movwf	TRISD, ACCESS	    ; Port D all inputs
;	movlw 	0x0
;	movwf	TRISC, ACCESS	    ; Port C all outputs
;	
;	
;	goto	start
;	; ******* My data and where to put it in RAM *
;myTable db	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80
;	constant 	counter=0x10	; Address of counter variable
;	constant    dcounter0=0x16
;	constant    dcounter1=0x20
;	constant    dcounter2=0x24
;
;	; ******* Main programme *********************
;
;	
;	
;;	CHUNK LOADS 1 BYTE FROM MYTABLE
;;	CREATES TBLPTR THAT POINTS TO MYTABLE
;start	movlw	upper(myTable)	; address of data in PM
;	movwf	TBLPTRU		; load upper bits to TBLPTRU
;	movlw	high(myTable)	; address of data in PM
;	movwf	TBLPTRH		; load high byte to TBLPTRH
;	movlw	low(myTable)	; address of data in PM
;	movwf	TBLPTRL		; load low byte to TBLPTRL
;	
;	movlw	.8		; 8 bytes to read - counter
;	movwf	counter		; Initialise counter
;	
;loop	call	dloop2
;	tblrd*+			; move one byte from PM to TABLAT, increment TBLPTR
;	movf	TABLAT, W	; Move TABLAT (TBLPTR value) to W
;	movwf	PORTC		; Move W to PORTC (TBLPTR value)
;	decfsz	counter		; Decrement counter, skip if zero
;	bra	loop		; keep going until finished
;	
;	goto	0	
;	
;		
;;	256^2 x Delay
;dloop2	call	dloop1
;	decfsz	dcounter2, F, ACCESS
;	bra	dloop2
;;	Reset counter to 255
;	movlw	0xff
;	movwf	dcounter2
;	return	0
;	
;;	256x Delay
;dloop1	call	dloop0
;	decfsz	dcounter1, F, ACCESS
;	bra	dloop1
;;	Reset counter to 255
;	movlw	0xff
;	movwf	dcounter1
;	return	0
;	
;	
;	
;;	Delay subroutine (set by PORT D)
;dloop0	decfsz	dcounter0, F, ACCESS
;	bra	dloop0
;;	Next delay set by PORTD
;	movf	PORTD, W, ACCESS    ; W = PORTD
;	movwf	dcounter0	    ; dcounter = w - reset dcounter0 to PORTD
;
;pause	movlw	0x7F
;	CPFSLT	PORTD	    ; If PORTD < 7F: skip, else repeat check.
;	bra	pause
;	
;	
;	return	0
;	
;	
	
	
	end