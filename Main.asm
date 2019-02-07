#include p18f87k22.inc

	global	MainSetup, MainLoop

	extern	Plot
	extern	Ball_Step, ball_x, ball_y, ball_vx, ball_vy

	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
	extern	LCD_delay_ms
	extern	UART_Setup, UART_Transmit_Message
    
Main code
 
 
MainSetup
; 	call	UART_Setup	; setup UART
	call	LCD_Setup
 
 	; Setup ball pos and vel
	movlw	0xff
	movwf	ball_vx
	movwf	ball_vx + 1
	movwf	ball_vy
	movlw	0xC8
	movwf	ball_x
	movlw	0x00
	movwf	ball_x + 1
	
	movwf	ball_y
	return
 
 
MainLoop
	call	Ball_Step
	
	lfsr	FSR2, ball_x
	movlw	.2
;	call	UART_Transmit_Message
	call	LCD_Clear
	call	LCD_Write_Hex_Message_2B
	movlw	.50
	call	LCD_delay_ms
	bra	MainLoop
	return




	end