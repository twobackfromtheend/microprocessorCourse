#include p18f87k22.inc
#include constants.inc

	global	slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
	global	slime_1_x, slime_1_y, slime_1_vx, slime_1_vy

	global	Slime_Step
	
	
;	extern	LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B

	extern	Mul_16_16
    
    
acs0    udata_acs
slime_0_x  res	2	; -32768 to 32767 in 2's complement
slime_0_y  res	2
slime_0_vx res	2	; -32768 to 32767 in 2's complement
slime_0_vy res	2
slime_1_x  res	2
slime_1_y  res	2
slime_1_vx res	2
slime_1_vy res	2
 
 
    
SlimePhysics code
	    
Slime_Setup	
	setf	TRISC		; Set PORTC as all outputs
	return
 
Slime_Step
	call	Update_With_Controls
	call	Slime_0_Propagate
	call	Slime_1_Propagate

;	call	Collide_With_Wall
	return

Update_With_Controls
	; Slime 0: 
	; PORTC 0 1 2 = UP LEFT RIGHT
check_0_up
	btfss	PORTC, 0
	bra	check_0_left
	tstfsz	slime_0_y	
	bra	check_0_left
	tstfsz	slime_0_y + 1
	bra	check_0_left
	movlw	slime_jump_vy
	movwf	slime_0_vy
	movlw	0
	movwf	slime_0_vy + 1
check_0_left	
	btfss	PORTC, 1
	bra	check_0_right_no_left
	btfss	PORTC, 2			; Know that left is pressed, check if right is also pressed
	bra	Set_slime_0_vx_To_Negative	; Right not pressed, move left.
	bra	Set_slime_0_vx_To_0		; Right also pressed
check_0_right_no_left			; Know that left is not pressed.
	btfss	PORTC, 2
	bra	Set_slime_0_vx_To_0	    ; Right not pressed, do not move
	bra	Set_slime_0_vx_To_Positive  ; Right pressed, move right.	
	
Set_slime_0_vx_To_0
	movlw	0
	movwf	slime_0_vx
	movwf	slime_0_vx + 1
	bra	Set_slime_0_vx_end

Set_slime_0_vx_To_Positive
	movlw	slime_move_vx
	movwf	slime_0_vx
	movlw	0
	movwf	slime_0_vx + 1
	bra	Set_slime_0_vx_end
Set_slime_0_vx_To_Negative
	movlw	slime_move_vx
	comf	WREG, W
	addlw	1
	movwf	slime_0_vx
	movlw	0xff
	movwf	slime_0_vx + 1
Set_slime_0_vx_end

	return
	

Slime_0_Propagate
	; x = x + v, t = 1
	movf	slime_0_vx, W
	addwf	slime_0_x, f
	movf	slime_0_vx + 1, W
	addwfc	slime_0_x + 1, f
	
	movf	slime_0_vy, W
	addwf	slime_0_y, f
	movf	slime_0_vy + 1, W
	addwfc	slime_0_y + 1, f
	
	; Gravity
	; Only apply when in the air - y > 0
	btfsc	slime_0_y + 1, 7	    ; Skip if positive
	bra	post_gravity_0		    ; If slime y < 0
	movlw	slime_gravity
	subwf	slime_0_vy, f
	movlw	0
	subwfb	slime_0_vy + 1, f

post_gravity_0
	; If y < 0, set y = 0, vy = 0
	btfsc	slime_0_y + 1, 7	    ; Skip if positive
	call	Set_Slime_0_To_0
	return

Slime_1_Propagate
	; x = x + v, t = 1
	movf	slime_1_vx, W
	addwf	slime_1_x, f
	movf	slime_1_vx + 1, W
	addwfc	slime_1_x + 1, f
	
	movf	slime_1_vy, W
	addwf	slime_1_y, f
	movf	slime_1_vy + 1, W
	addwfc	slime_1_y + 1, f
	
	; Gravity
	; Only apply when in the air - y > 0
	btfsc	slime_1_y + 1, 7	    ; Skip if positive
	bra	post_gravity_1		    ; If slime y < 0
	movlw	slime_gravity
	subwf	slime_1_vy, f
	movlw	0
	subwfb	slime_1_vy + 1, f

post_gravity_1
	; If y < 0, set y = 0, vy = 0
	btfsc	slime_1_y + 1, 7	    ; Skip if positive
	call	Set_Slime_1_To_0
	return

	
Set_Slime_0_To_0
	movlw	0
	movwf	slime_0_y
	movwf	slime_0_y + 1
	movwf	slime_0_vy
	movwf	slime_0_vy + 1
	return
	
Set_Slime_1_To_0
	movlw	0
	movwf	slime_1_y
	movwf	slime_1_y + 1
	movwf	slime_1_vy
	movwf	slime_1_vy + 1
	return


	end


