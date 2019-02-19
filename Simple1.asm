#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
	extern	KP_Setup, KP_Read_Column, KP_Read, KP_Decode, KP_Wait_For_Release, KP_Decode_Table
	extern	LCD_Write_Hex			    ; external LCD subroutines
	extern  ADC_Setup, ADC_Read		    ; external ADC routines
	extern	Mul_8_16, Mul_16_16, Mul_8_24
	
	extern	Main_Setup
	extern	Game_Setup
	extern	Timer_Setup

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
;	bcf	EECON1, CFGS	; point to Flash program memory  
;	bsf	EECON1, EEPGD 	; access Flash program memory
;	call	UART_Setup	; setup UART
;	call	LCD_Setup	; setup LCD
;	call	KP_Setup	; setup Keypad
;	call	ADC_Setup
;	call	DAC_Setup
	
	call	Main_Setup
	call	Game_Setup
	goto	start
	
	; ******* Main programme ****************************************
start 	call	Timer_Setup
	goto	$
	return
	
	end
