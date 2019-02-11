#include p18f87k22.inc

	global	MainSetup, MainLoop

	extern	Plot
	extern	Ball_Step, ball_x, ball_y, ball_vx, ball_vy

	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
	extern	LCD_delay_ms
	extern	UART_Setup, UART_Transmit_Message
	extern	SPI_DAC_Setup, SPI_Transmit_12b, SPI_Transmit_ball_xy
	extern	Graphics_Setup, Graphics_wall, Graphics_ball
    
Main code
 
 
MainSetup
; 	call	UART_Setup	; setup UART
	call	LCD_Setup
	call	SPI_DAC_Setup
;	call	SPI_DAC_Test
	call	Graphics_Setup
;	call	Graphics_wall_Test
;	call	Graphics_ball_wall_Test
 
 	; Setup ball pos and vel
;	movlw	0xff
;	movwf	ball_vx		
;	movwf	ball_vx + 1	; ball_vx = -1
	movlw	0x10
	movwf	ball_vx	
	movlw	0x00
	movwf	ball_vx + 1	; ball_vx = 0x10
	movlw	0x00
	movwf	ball_vy + 1
	movlw	0x05
	movwf	ball_vy	    	; ball_vy = 5
	movlw	0xC8
	movwf	ball_x

	
	movlw	0xA8
	movwf	ball_y
	
	movlw	0x00
	movwf	ball_x + 1
	movwf	ball_y + 1
	return
 
 
MainLoop
	call	Ball_Step
	
	call	Graphics_wall
	call	Graphics_ball
	bra	MainLoop
	
;	call	LCD_Clear
;	lfsr	FSR2, ball_x
;;	call	SPI_Transmit_12b
;	call	SPI_Transmit_ball_xy
;	call	LCD_Write_Hex_Message_2B
;	call	LCD_Cursor_To_Line_2
;	lfsr	FSR2, ball_y
;	call	LCD_Write_Hex_Message_2B
;	
;	movlw	.50
;	call	LCD_delay_ms
;	bra	MainLoop
	return

;SPI_DAC_Test
;	movlw	0x00
;	movwf	ball_x
;	movwf	ball_x + 1
;	lfsr	FSR2, ball_x
;	
;loop	movlw	0x10
;	addwf	ball_x
;	movlw	0x0
;	addwfc	ball_x + 1
;
;	call	LCD_Clear
;	call	LCD_Write_Hex_Message_2B
;
;	call	SPI_Transmit_12b
;	movlw	.50
;	call	LCD_delay_ms
;	bra	loop
;	return

	
Graphics_wall_Test
	call	Graphics_wall
	bra	Graphics_wall_Test
	return

Graphics_ball_wall_Test
	movlw	0
	movwf	ball_x
	movwf	ball_y
	movlw	0x08
	movwf	ball_x + 1
	movwf	ball_y + 1
	call	Graphics_wall
	call	Graphics_ball
	bra	Graphics_ball_wall_Test
	return

	end