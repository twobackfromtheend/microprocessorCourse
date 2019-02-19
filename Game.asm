#include p18f87k22.inc
#include constants.inc

	global	Game_Setup, Game_Loop

	extern	Ball_Step, ball_x, ball_y, ball_vx, ball_vy
	extern	Slime_Step
	extern	slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
	extern	slime_1_x, slime_1_y, slime_1_vx, slime_1_vy
	
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
	extern	LCD_delay_ms
	extern	SPI_Transmit_12b, SPI_Transmit_ball_xy
	extern	Graphics_wall, Graphics_ball, Graphics_slimes
    
Game code
 
 
Game_Setup
 	; Setup ball pos and vel
;	movlw	0xff
;	movwf	ball_vx		
;	movwf	ball_vx + 1	; ball_vx = -1
;	movlw	0x50
;	movwf	ball_vx	
;	movlw	0x00
;	movwf	ball_vx + 1	; ball_vx = 0x10
;	movlw	0x00
;	movwf	ball_vy + 1
;	movlw	0x30
;	movwf	ball_vy	    	; ball_vy = 5
;	movlw	0xC8
;	movwf	ball_x
;
;	
;	movlw	0xA8
;	movwf	ball_y
;	
;	movlw	0x00
;	movwf	ball_x + 1
;	movwf	ball_y + 1
	
;	; Ball dropping down
;	movlw	0xD0
;	movwf	ball_x
;	movlw	0x07
;	movwf	ball_x + 1
;	
;	movlw	0x60
;	movwf	ball_y
;	movlw	0x02
;	movwf	ball_y + 1
;	
;	movlw	0x23
;	movwf	ball_vx
;	movlw	0
;	movwf	ball_vx + 1
;	movlw	0xd0
;	movwf	ball_vy
;	movlw	0xff
;	movwf	ball_vy + 1
	
;	; Slime to bottom centre.
;	movlw	0x00
;	movwf	slime_0_vx
;	movwf	slime_0_vx + 1
;	movwf	slime_0_vy
;	movwf	slime_0_vy + 1
;	movwf	slime_0_y
;	movwf	slime_0_y + 1
;	movlw	0xD0
;	movwf	slime_0_x
;	movlw	0x07
;	movwf	slime_0_x + 1
	
	call	Set_Game_Start_State
	return
	
; GAME STATE
Set_Game_Start_State	
	movlw	low(slime_0_start_x)
	movwf	slime_0_x
	movlw	high(slime_0_start_x)
	movwf	slime_0_x + 1
	
	movlw	low(slime_1_start_x)
	movwf	slime_1_x
	movlw	high(slime_1_start_x)
	movwf	slime_1_x + 1
	
	movlw	0
	movwf	slime_0_y
	movwf	slime_0_y + 1
	movwf	slime_1_y
	movwf	slime_1_y + 1
	
	movwf	slime_0_vx
	movwf	slime_0_vx + 1
	movwf	slime_1_vx
	movwf	slime_1_vx + 1
	movwf	slime_0_vy
	movwf	slime_0_vy + 1
	movwf	slime_1_vy
	movwf	slime_1_vy + 1
	
	; BALL
	movlw	low(ball_start_x)
	movwf	ball_x
	movlw	high(ball_start_x)
	movwf	ball_x + 1	
	
	movlw	low(ball_start_y)
	movwf	ball_y
	movlw	high(ball_start_y)
	movwf	ball_y + 1
	
	movlw	0
	movwf	ball_vx
	movwf	ball_vx + 1
	movwf	ball_vy
	movwf	ball_vy + 1
	
	return
 
 
Game_Loop
	call	Ball_Step
	call	Slime_Step
	
	call	Graphics_wall
	call	Graphics_ball
	call	Graphics_slimes
	return
	

	end





