	#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2	    ; external LCD subroutines
	extern	KP_Setup, KP_Read_Column, KP_Read, KP_Decode, KP_Wait_For_Release, KP_Decode_Table
	extern	LCD_Write_Hex			    ; external LCD subroutines
	extern  ADC_Setup, ADC_Read		    ; external ADC routines
	extern	Mul_8_16, multiplier_16

acs0	udata_acs   ; reserve data space in access ram
;counter	    res 1   ; reserve one byte for a counter variable
;delay_count res 1   ; reserve one byte for counter in the delay routine

;tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
;myArray res 0x80    ; reserve 128 bytes for message data

rst	code	0    ; reset vector
	goto	setup

pdata	code    ; a section of programme memory for storing data
	; ******* myTable, data in programme memory, and its length *****
;myTable data	    "Hello World!"	; message, plus carriage return
;	constant    myTable_l=.13	; length of data


main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	
	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	KP_Setup	; setup Keypad
	call	ADC_Setup
;	
	clrf	TRISD		; PORT D all outputs
	clrf	LATD
	goto	start
	
	; ******* Main programme ****************************************
start 	lfsr	FSR0, multiplier_16
	movlw	0xD2
	movwf	POSTINC0
	movlw	0x04
	movwf	INDF0
	movlw	0x8A
	call	Mul_8_16
;	movlw	0x02
;	movf	PLUSW2, W
	movf	POSTINC2, W
	call	LCD_Write_Hex
	movf	POSTINC2, W
	call	LCD_Write_Hex
	movf	POSTINC2, W
	call	LCD_Write_Hex
	goto	$
	
;measure_loop
;	call	ADC_Read
;	movf	ADRESH, W
;	call	LCD_Write_Hex
;	movf	ADRESL, W
;	call	LCD_Write_Hex
;	bra	measure_loop
	
	
	
;	call	KP_Read
;	call	KP_Decode_Table
;	call	Write_Char_To_LCD
;
;	movlw	myTable_l	; output message to UART
;	lfsr	FSR2, myArray
;	call	UART_Transmit_Message
	

;	call	Echo_E_To_D
;	call	KP_Decode
;	call	Write_Char_To_LCD
	bra	start
	goto	$		; goto current line in code

	
	
Echo_E_To_D
;	call	KP_Read_Column
;	movf	PORTE, W
;	call	KP_Read
	movwf	PORTD
	return
	
Write_Char_To_LCD
;	call	KP_Read
;	call	KP_Decode
	tstfsz	WREG
	bra	write
	return
write	call	LCD_Write_Message
	call	KP_Wait_For_Release
	return
	
;hello_world
;	lfsr	FSR0, myArray	; Load FSR0 with address in RAM	
;	movlw	upper(myTable)	; address of data in PM
;	movwf	TBLPTRU		; load upper bits to TBLPTRU
;	movlw	high(myTable)	; address of data in PM
;	movwf	TBLPTRH		; load high byte to TBLPTRH
;	movlw	low(myTable)	; address of data in PM
;	movwf	TBLPTRL		; load low byte to TBLPTRL
;	movlw	myTable_l	; bytes to read
;	movwf 	counter		; our counter register
;loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter		; count down to zero
;	bra	loop		; keep going until finished
;		
;	movlw	myTable_l-1	; output message to LCD (leave out "\n")
;	lfsr	FSR2, myArray
;	call	LCD_Write_Message
;	
;	movlw	myTable_l	; output message to UART
;	lfsr	FSR2, myArray
;	call	UART_Transmit_Message
;	return
	
	
;check_for_user_input
;	BTFSC	PORTD, .0
;	call	LCD_Clear
;	
;	BTFSC	PORTD, .1
;	call	LCD_Cursor_To_Start
;	
;	BTFSC	PORTD, .2
;	call	LCD_Cursor_To_Line_2
;wait_for_release_2
;	BTFSC	PORTD, .2
;	bra	wait_for_release_2
;	
;	BTFSC	PORTD, .7
;	call	hello_world
;wait_for_release_7
;	BTFSC	PORTD, .7
;	bra	wait_for_release_7
;	
;	return

	end
