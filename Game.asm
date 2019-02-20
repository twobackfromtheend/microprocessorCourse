#include p18f87k22.inc
#include constants.inc

	global	Game_Setup, Game_Loop

	extern	Ball_Step, ball_x, ball_y, ball_vx, ball_vy
	extern	Slime_Step
	extern	slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
	extern	slime_1_x, slime_1_y, slime_1_vx, slime_1_vy
	
	extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2
	extern	LCD_Write_Hex, LCD_Write_Hex_Message_2B
	extern	LCD_delay_ms
	extern	SPI_Transmit_12b, SPI_Transmit_ball_xy
	extern	Graphics_wall, Graphics_net, Graphics_ball, Graphics_slimes
	
	
    	extern  Compare_2B, compare_2B_1, compare_2B_2

	
	constant    ball_y_lava = wall_y_lower + ball_radius
	
acs0    udata_acs
player_0_score  res 1
player_1_score	res 1
	
last_player_scored  res	1
  
  
bank2   udata	0x200
player_0_scored_message_ram res .16
player_1_scored_message_ram res .16
counter	res 1


pdata	code    ; a section of programme memory for storing data
player_0_scored_message data	    "Player 0 scored!"
player_1_scored_message data	    "Player 1 scored!"
	constant    player_scored_message_length=.16
	
	
Game code
 
Game_Setup
	movlw	0
	movwf	player_0_score
	movwf	player_1_score
	movlw	1
	movwf	last_player_scored
	call	Set_Game_Start_State
	
	call	Setup_Messages
	return
	
Setup_Messages
	movlb	2
 	lfsr	FSR0, player_0_scored_message_ram
	movlw	upper(player_0_scored_message)
	movwf	TBLPTRU
	movlw	high(player_0_scored_message)
	movwf	TBLPTRH
	movlw	low(player_0_scored_message)
	movwf	TBLPTRL
	movlw	player_scored_message_length
	movwf 	counter, BANKED
write_0_scored_loop
	tblrd*+	
	movff	TABLAT, POSTINC0
	decfsz	counter, BANKED
	bra	write_0_scored_loop
	
 	lfsr	FSR0, player_1_scored_message_ram
	movlw	upper(player_1_scored_message)
	movwf	TBLPTRU
	movlw	high(player_1_scored_message)
	movwf	TBLPTRH
	movlw	low(player_1_scored_message)
	movwf	TBLPTRL
	movlw	player_scored_message_length
	movwf 	counter, BANKED
write_1_scored_loop
	tblrd*+	
	movff	TABLAT, POSTINC0
	decfsz	counter, BANKED
	bra	write_1_scored_loop
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
;	movlw	low(ball_start_x)
;	movwf	ball_x
;	movlw	high(ball_start_x)
;	movwf	ball_x + 1
	; Set ball_x based on last_player_scored
	tstfsz	last_player_scored	    ; Skip if player_0 scored last
	bra	set_ball_x_on_player_0		    ; Player 1 scored last
	bra	set_ball_x_on_player_1		    ; Loser's ball (player 0 scored last)
	
set_ball_x_on_player_0
	movlw	low(slime_0_start_x)
	movwf	ball_x
	movlw	high(slime_0_start_x)
	movwf	ball_x + 1
	bra	set_ball_x_end
set_ball_x_on_player_1
	movlw	low(slime_1_start_x)
	movwf	ball_x
	movlw	high(slime_1_start_x)
	movwf	ball_x + 1
	
set_ball_x_end
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
	call	Graphics_net
	call	Graphics_ball
	call	Graphics_slimes
	call	Check_Point_End
	call	Update_LCD
	return
	
Check_Point_End
	; If ball_y < wall_y_lower + ball_radius
	movff	ball_y, compare_2B_1
	movff	ball_y + 1, compare_2B_1 + 1
	
	movlw	low(ball_y_lava)
	movwf	compare_2B_2
	movlw	high(ball_y_lava)
	movwf	compare_2B_2 + 1
	
	call	Compare_2B		    ; ball_y > ball_y_lava in W
	tstfsz	WREG			    ; Skip if ball_y < ball_y_lava
	return
	
	; Point ended
	; If ball_x < net_x: player_1 wins
	movlw	low(net_x)
	movwf	compare_2B_1
	movlw	high(net_x)
	movwf	compare_2B_1 + 1
	
	movff	ball_x, compare_2B_2
	movff	ball_x + 1, compare_2B_2 + 1
	
	call	Compare_2B		    ; net_x > ball_x in W
	tstfsz	WREG			    ; Skip if net_x < ball_x
	bra	player_1_scores
	bra	player_0_scores
	
player_1_scores
	incf	player_1_score, f
	movlw	1
	movwf	last_player_scored
	call	LCD_Clear
	lfsr	FSR2, player_1_scored_message_ram
	movlw	player_scored_message_length
	call	LCD_Write_Message
	bra	post_point_cleanup
player_0_scores
	incf	player_0_score, f
	movlw	0
	movwf	last_player_scored
	call	LCD_Clear
	lfsr	FSR2, player_0_scored_message_ram
	movlw	player_scored_message_length
	call	LCD_Write_Message
	
post_point_cleanup
	movlw	.200
	call	LCD_delay_ms
	movlw	.200
	call	LCD_delay_ms
	movlw	.200
	call	LCD_delay_ms
	movlw	.200
	call	LCD_delay_ms
	movlw	.200
	call	LCD_delay_ms
	
	call	Set_Game_Start_State
	
	return
    
Update_LCD  
	call	LCD_Clear
	movf	player_0_score, W
	call	LCD_Write_Hex
	call	LCD_Cursor_To_Line_2
	movf	player_1_score, W
	call	LCD_Write_Hex
	return
	
	end




