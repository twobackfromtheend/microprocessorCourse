#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
	extern	KP_Setup, KP_Read_Column, KP_Read, KP_Decode, KP_Wait_For_Release, KP_Decode_Table
	extern	LCD_Write_Hex			    ; external LCD subroutines
	extern  ADC_Setup, ADC_Read		    ; external ADC routines
	extern	Mul_8_16, Mul_16_16, Mul_8_24
	extern	DAC_Setup
	
	extern	MainSetup, MainLoop

acs0	udata_acs   ; reserve data space in access ram
	
	constant    H2D_MAGIC_NUMBER=0x418A	; LCD enable bit



;; For TEST_MUL	
;tmp_2B  res 2
;tmp_2B_2  res	2
;tmp_3B	res 3
	
;; For TEST_H2D
tmp_4B	res 4
tmp_2B	res 2

H2D_tmp_magic_number	res 2
H2D_result_4B	res 4
H2D_result_2B	res 2
H2D_tmp_multiplicand	res 3
	
ADC2LCD_2B  res	2

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
;	bcf	EECON1, CFGS	; point to Flash program memory  
;	bsf	EECON1, EEPGD 	; access Flash program memory
;	call	UART_Setup	; setup UART
;	call	LCD_Setup	; setup LCD
;	call	KP_Setup	; setup Keypad
;	call	ADC_Setup
;	call	DAC_Setup
	call	MainSetup
;	clrf	TRISD		; PORT D all outputs
;	clrf	LATD
	goto	start
	
	; ******* Main programme ****************************************
start 	call	MainLoop
	
	goto	$
;	call	Write_ADC_to_LCD
;	bra	start
	
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
;	bra	start
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

	
TEST_MUL
;	lfsr	FSR0, tmp_2B
	; Mul 8 16
;	movlw	0xD2
;	movwf	POSTINC0
;	movlw	0x04
;	movwf	POSTDEC0
;;	lfsr	FSR0, tmp_2B
;;	movlw	0x8A
;;	call	Mul_8_16
;	
	; Mul 16 16
;	movlw	0xD2
;	movwf	POSTINC0
;	movlw	0x04
;	movwf	POSTDEC0
;;	lfsr	FSR0, tmp_2B
;	lfsr	FSR1, tmp_2B_2
;	movlw	0x8A
;	movwf	POSTINC1
;	movlw	0x41
;	movwf	POSTDEC1
;;	lfsr	FSR1, tmp_2B_2
;	call	Mul_16_16
	
	; Mul 8 16
;	lfsr	FSR0, tmp_3B
;	movlw	0x34
;	movwf	POSTINC0
;	movlw	0xEB
;	movwf	POSTINC0
;	movlw	0x3B
;	movwf	POSTINC0
;	lfsr	FSR0, tmp_3B
;	movlw	0x0A
;	call	Mul_8_24
;	
;	movf	POSTINC2, W
;	call	LCD_Write_Hex
;	movf	POSTINC2, W
;	call	LCD_Write_Hex
;	movf	POSTINC2, W
;	call	LCD_Write_Hex
;	movf	POSTINC2, W
;	call	LCD_Write_Hex
	return
	
	
TEST_H2D
	; Move 0x04D2 to tmp_4B
	movlw	0xD2
	movwf	tmp_4B
	movlw	0x04
	movwf	tmp_4B + 1
	movlw	0
	movwf	tmp_4B + 2
	movwf	tmp_4B + 3
	lfsr	FSR0, tmp_4B
	; Convert tmp_4B to decimal
	call	Convert_Hex_To_Decimal
	; Output with Write_Hex
	call	LCD_Write_Hex_Message_2B
	
;	movf	POSTINC2, W
;	call	LCD_Write_Hex
;	movf	POSTINC2, W
;	call	LCD_Write_Hex
	return
	
	
Write_ADC_to_LCD
	call	ADC_Read
	movff	ADRESL, ADC2LCD_2B
	movff	ADRESH, ADC2LCD_2B + 1
	lfsr	FSR0, ADC2LCD_2B
	call	Convert_Hex_To_Decimal
	call	LCD_Write_Hex_Message_2B
	return
	
; Converts 16 bits in FSR0 to 16 bits in FSR2.
Convert_Hex_To_Decimal
	movlw	low(H2D_MAGIC_NUMBER)
	movwf	H2D_tmp_magic_number
	movlw	high(H2D_MAGIC_NUMBER)
	movwf	H2D_tmp_magic_number + 1
	
	lfsr	FSR1, H2D_tmp_magic_number
	
	; Move multiplicands to FSR0 and FSR1	
	call	Mul_16_16	; 32-bit result in FSR2
	
	; Store lower 3 bytes in H2D_tmp_multiplicand, move highest byte to H2D_result_4B
	movff	POSTINC2, H2D_tmp_multiplicand
	movff	POSTINC2, H2D_tmp_multiplicand + 1
	movff	POSTINC2, H2D_tmp_multiplicand + 2
	movff	INDF2, H2D_result_4B + 3
	
	; Move FSR0 to H2D_tmp_multiplicand
	lfsr	FSR0, H2D_tmp_multiplicand
	; FSR0 now contains remaining 3 bytes (for multiplication with 0x0A)

	; Read 3 next bytes (by multiplying with 0x0A and reading upper byte).
	movlw	0x0A
	call	Mul_8_24	; 32-bit result in FSR2
	movff	POSTINC2, H2D_tmp_multiplicand
	movff	POSTINC2, H2D_tmp_multiplicand + 1
	movff	POSTINC2, H2D_tmp_multiplicand + 2
	movff	INDF2, H2D_result_4B + 2
	lfsr	FSR0, H2D_tmp_multiplicand
	movlw	0x0A
	call	Mul_8_24	; 32-bit result in FSR2
	movff	POSTINC2, H2D_tmp_multiplicand
	movff	POSTINC2, H2D_tmp_multiplicand + 1
	movff	POSTINC2, H2D_tmp_multiplicand + 2
	movff	INDF2, H2D_result_4B + 1
	lfsr	FSR0, H2D_tmp_multiplicand

	movlw	0x0A
	call	Mul_8_24	; 32-bit result in FSR2
	; Moving to H2D_tmp_multiplicand not strictly necessary as it is not used later.
	; Kept for consistency (and because we have no clue how to shift an FSR)
	; movff	FSR0 + 3, H2D_result_4B is the general idea.
	movff	POSTINC2, H2D_tmp_multiplicand
	movff	POSTINC2, H2D_tmp_multiplicand + 1
	movff	POSTINC2, H2D_tmp_multiplicand + 2
	movff	INDF2, H2D_result_4B
	
	; Convert 0X0Y0Z0A to XYZA
	swapf	H2D_result_4B + 3, W	; X0 in W
	iorwf	H2D_result_4B + 2, W	; XY in W
	movwf	H2D_result_2B + 1	; XY__ in H2D_result_2B
	
	swapf	H2D_result_4B + 1, W	; Z0 in W
	iorwf	H2D_result_4B, W	; ZA in W
	movwf	H2D_result_2B		; XYZA in H2D_result_2B
	
	lfsr	FSR2, H2D_result_2B
	return
	
	
	end
