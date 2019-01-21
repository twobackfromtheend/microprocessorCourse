	#include p18f87k22.inc
	
	code
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100

;	DATA
;myTable	db	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80 ; Moving high bit
;myTable	db	0xFE,0xFD,0xFB,0xF7,0xEF,0xDF,0xBF,0x7F	; Moving low bit
myTable	db	0xFF,0x7E,0x3C,0x18,0x00,0x18,0x3C,0x7E,0xFF ; in n out
	constant    dCounter0=0x08
	constant    dCounter1=0x20
	constant    dCounter2=0x30
	
	constant    tableCounter=0x40
	
	
;	Setup
setup	call	SPI_MasterInit
	goto	start
	
	
start	call	LOOP_OVER_MYTABLE
	
;	CHUNK LOADS 1 BYTE FROM MYTABLE
;	CREATES TBLPTR THAT POINTS TO MYTABLE
LOOP_OVER_MYTABLE
	movlw	upper(myTable)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	
	movlw	.8		; 8 bytes to read - counter
	movwf	tableCounter	; Initialise counter
	
tableLoop
	call	dLoop2
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPTR
	movf	TABLAT, W	; Move TABLAT (TBLPTR value) to W
	
	; DO THING WITH DATA IN W
	call	SPI_MasterTransmit
	
	decfsz	tableCounter	; Decrement counter, skip if zero
	bra	tableLoop	; keep going until finished
	return

	

;	10x Delay
dLoop2	call	dLoop1
	decfsz	dCounter2, F, ACCESS
	bra	dLoop2
;	Reset counter to 10
	movlw	0xA
	movwf	dCounter2
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
	movlw	0xFF
	movwf	dCounter0	    ; dcounter = w: reset dcounter0 to FF
	
	return	0
	
	
; Provided routines	
SPI_MasterInit ; Set Clock edge to negative
	bcf	SSP2STAT, CKE
	; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
	movlw	(1<<SSPEN)|(1<<CKP)|(0x02)
	movwf	SSP2CON1
	; SDO2 output; SCK2 output
	bcf	TRISD, SDO2
	bcf	TRISD, SCK2
	return
SPI_MasterTransmit ; Start transmission of data (held in W)
	movwf	SSP2BUF
Wait_Transmit ; Wait for transmission to complete
	btfss	PIR2, SSP2IF
	bra	Wait_Transmit
	bcf	PIR2, SSP2IF ; clear interrupt flag
	return
	
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