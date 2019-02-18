#include p18f87k22.inc
#include constants.inc

	global	ball_x, ball_y, ball_vx, ball_vy
;	global	wall_x_lower, wall_x_higher, wall_y_lower, wall_y_higher
	global	Ball_Step

	extern	Mul_16_16
    	extern	slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
	extern	slime_1_x, slime_1_y, slime_1_vx, slime_1_vy
	extern  Compare_2B, compare_2B_1, compare_2B_2
	extern	Absolute_2B
	extern	Divide_8_2B, Multiply_2_2B
	extern	Mul_16_16_2s_complement
	
	extern	LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
    
acs0    udata_acs
ball_x  res	2	; -32768 to 32767 in 2's complement
ball_y  res	2
ball_vx res	2	; -32768 to 32767 in 2's complement
ball_vy res	2

distance_x  res	2
distance_y  res	2
  
temp_2B_x	    res	2
temp_2B_y	    res	2
temp_2B_k	    res	2
	    
rel_vel_x   res	2
rel_vel_y   res	2
   
_collision_check	    res 4
_speed_limiter_sign		res 1
_speed_limiter_positive_temp	res 2

	
; distance_xORy/ball_slime_collision_distance always <= 1
;norm_dist_x res	1	; 8 * distance_x / ball_slime_collision_distance
;norm_dist_y res	1   	; 8 * distance_y / ball_slime_collision_distance
; (  8 / ball_slime_collision_distance (constant) ) * distance_xORy
; BASICALLY
; distance_xORy / 64 = number from -8 to 8. (probably <=8 due to rounding)
 

    constant	ball_wall_x_lower = wall_x_lower + ball_radius
    constant	ball_wall_x_higher = wall_x_higher - ball_radius
    constant	ball_wall_y_lower = wall_y_lower + ball_radius
    constant	ball_wall_y_higher = wall_y_higher - ball_radius
    
    constant	ball_slime_collision_distance = ball_radius + slime_radius
    
    
BallPhysics code
	    
 
Ball_Step
	call	Propagate
	call	Collide_With_Wall
	call	Collide_ball_slime
	call	Speed_Limiter
	
	call	LCD_Clear
	lfsr	FSR2, ball_vx
	call	LCD_Write_Hex_Message_2B
	call	LCD_Cursor_To_Line_2
	lfsr	FSR2, ball_vy
	call	LCD_Write_Hex_Message_2B

	return

; Propagate current positions by 1 frame (x = x + vt)
Propagate
	; x = x + v, t = 1
	movf	ball_vx, W
	addwf	ball_x, f
	movf	ball_vx + 1, W
	addwfc	ball_x + 1, f
	
	movf	ball_vy, W
	addwf	ball_y, f
	movf	ball_vy + 1, W
	addwfc	ball_y + 1, f
	
	; TODO: Look into ensuring no overflows happened
	return
	    
; Update ball velocity based on position
Collide_With_Wall
	; LOWER X
	; if ball_x < wall_x_lower: ball_vx *= -1

	; if ball_vx is negative AND
	; if ball_x + 1 is negative, do flip
	; if ball_x + 1 is 0 and ball_x < wall_x_lower, do flip
	
	btfss	ball_vx + 1, 7	    ; skip if ball_vx is negative
	bra	_lower_x_end
_lower_x_condition_1
	btfss	ball_x + 1, 7	    ; skip if ball_x + 1 is negative
	bra	_lower_x_condition_2
	call	Reverse_ball_vx
	bra	_lower_x_end
_lower_x_condition_2
	tstfsz	ball_x + 1	    ; skip if ball_x + 1 is 0
	bra	_lower_x_end
	
	movlw	ball_wall_x_lower	    ; cpfslt - skip if f < W
	cpfslt	ball_x		    ; skip if ball_x (lower) (positive) < wall_x_lower (positive)
	
	bra	_lower_x_end
	call	Reverse_ball_vx
_lower_x_end
	nop
	
	; HIGHER X
	; if ball_vx is positive AND ball_x + 1 is positive
	;   ball_x + 1 > HIGHER(wall_x_higher) do flip OR
	;   ball_x + 1 = HIGHER(wall_x_higher) AND ball_x > LOWER(wall_x_higher), do flip
	btfsc	ball_vx + 1, 7	    ; skip if ball_vx is positive
	bra	_higher_x_end
	btfsc	ball_x + 1, 7	    ; skip if ball_x + 1 is positive
	bra	_higher_x_end
	
_higher_x_condition_1
	movlw	high(ball_wall_x_higher)    ; cpfsgt - skip if f > W
	cpfsgt	ball_x + 1	    ; skip if ball_x + 1 > higher(wall_x_higher)
	bra	_higher_x_condition_2
	call	Reverse_ball_vx
	bra	_higher_x_end
_higher_x_condition_2
	movlw	high(ball_wall_x_higher)
	cpfseq	ball_x + 1	    ; skip if ball_x + 1 = higher(wall_x_higher)
	bra	_higher_x_end
	movlw	low(ball_wall_x_higher)
	cpfsgt	ball_x		    ; skip if ball_x > lower(wall_x_higher)
	bra	_higher_x_end
	call	Reverse_ball_vx
	
_higher_x_end
	nop
	
	;;; Y AXIS
	; LOWER Y
	btfss	ball_vy + 1, 7	    ; skip if ball_vy is negative
	bra	_lower_y_end
_lower_y_condition_1
	btfss	ball_y + 1, 7	    ; skip if ball_y + 1 is negative
	bra	_lower_y_condition_2
	call	Reverse_ball_vy
	bra	_lower_y_end
_lower_y_condition_2
	tstfsz	ball_y + 1	    ; skip if ball_y + 1 is 0
	bra	_lower_y_end
	movlw	ball_wall_y_lower	    ; cpfslt - skip if f < W
	cpfslt	ball_y		    ; skip if ball_y (lower) (positive) < wall_y_lower (positive)
	bra	_lower_y_end
	call	Reverse_ball_vy
_lower_y_end
	nop
	; HIGHER Y
	btfsc	ball_vy + 1, 7	    ; skip if ball_vy is positive
	bra	_higher_y_end
	btfsc	ball_y + 1, 7	    ; skip if ball_y + 1 is positive
	bra	_higher_y_end
_higher_y_condition_1
	movlw	high(ball_wall_y_higher)    ; cpfsgt - skip if f > W
	cpfsgt	ball_y + 1	    ; skip if ball_y + 1 > higher(wall_y_higher)
	bra	_higher_y_condition_2
	call	Reverse_ball_vy
	bra	_higher_y_end
_higher_y_condition_2
	movlw	high(ball_wall_y_higher)
	cpfseq	ball_y + 1	    ; skip if ball_y + 1 = higher(wall_y_higher)
	bra	_higher_y_end
	; NB ENSURE low(wall_y_higher) + ball_radius DOES NOT OVERFLOW
	movlw	ball_radius
	sublw	low(ball_wall_y_higher)  ; account for ball_radius
	cpfsgt	ball_y		    ; skip if ball_y > lower(wall_y_higher)
	bra	_higher_y_end
	call	Reverse_ball_vy
_higher_y_end
	nop
	
	return

Reverse_ball_vx
	; 2s complement ball_vx
	comf	ball_vx + 1, f
	comf	ball_vx, W
	
	addlw	1
	movwf	ball_vx
	movlw	0
	addwfc	ball_vx + 1
	return
	
Reverse_ball_vy
	; 2s complement ball_vy
	comf	ball_vy + 1, f
	comf	ball_vy, W
	
	addlw	1
	movwf	ball_vy
	movlw	0
	addwfc	ball_vy + 1
	return
	
	
Collide_ball_slime
	; Check if collision needed
	
	; Calculate distance
	; distance = ball_x - slime_x
	; x
	movf	slime_0_x, W
	movff	ball_x, distance_x
	movff	ball_x + 1, distance_x + 1
	subwf	distance_x		; lower byte subtraction
	movf	slime_0_x + 1, W
	subwfb	distance_x + 1		; high byte subtraction w/ borrow
	; y
	movf	slime_0_y, W
	movff	ball_y, distance_y
	movff	ball_y + 1, distance_y + 1
	subwf	distance_y		; lower byte subtraction
	movf	slime_0_y + 1, W
	subwfb	distance_y + 1		; high byte subtraction w/ borrow
	
	
	; if abs_distance_x > ball_slime_collision_distance:
	movff	distance_x, compare_2B_1
	movff	distance_x + 1, compare_2B_1 + 1
	lfsr	FSR0, compare_2B_1
	call	Absolute_2B		; Turn compare_2B_1 into abs_distance_x
	movlw	low(ball_slime_collision_distance)
	movwf	compare_2B_2
	movlw	high(ball_slime_collision_distance)
	movwf	compare_2B_2 + 1	; 1: distance_x, 2: collision_distance
	call	Compare_2B		; W = 1 > 2
	tstfsz	WREG			; Skip if collision possible, collision_distance (2) > (1) distance_x
	return
	
	; if abs_distance_y > ball_slime_collision_distance:
	movff	distance_y, compare_2B_1
	movff	distance_y + 1, compare_2B_1 + 1
	lfsr	FSR0, compare_2B_1
	call	Absolute_2B		; Turn compare_2B_1 into abs_distance_y
	movlw	low(ball_slime_collision_distance)
	movwf	compare_2B_2
	movlw	high(ball_slime_collision_distance)
	movwf	compare_2B_2 + 1	; 1: distance_y, 2: collision_distance
	call	Compare_2B		; W = 1 > 2
	tstfsz	WREG			; Skip if collision possible, collision_distance (2) > (1) distance_y
	return
	
	; Calculate norm_dists
	; distance_xORy = distance_xORy / 64  (represents 8x number)
	lfsr	FSR0, distance_x
	call	Divide_8_2B
	call	Divide_8_2B
	lfsr	FSR0, distance_y
	call	Divide_8_2B
	call	Divide_8_2B
	
	; Displacement vector is from slime to ball
	; Calculate relative velocities = ball_v - slime_v
	; x
	movf	slime_0_vx, W
	movff	ball_vx, rel_vel_x
	movff	ball_vx + 1, rel_vel_x + 1
	subwf	rel_vel_x		; lower byte subtraction
	movf	slime_0_vx + 1, W
	subwfb	rel_vel_x + 1		; high byte subtraction w/ borrow
	; y
	movf	slime_0_vy, W
	movff	ball_vy, rel_vel_y
	movff	ball_vy + 1, rel_vel_y + 1
	subwf	rel_vel_y		; lower byte subtraction
	movf	slime_0_vy + 1, W
	subwfb	rel_vel_y + 1		; high byte subtraction w/ borrow
	
	; Calculate rel_vel_x * distance_x + rel_vel_y * distance_y
	lfsr	FSR0, rel_vel_x
	lfsr	FSR1, distance_x
	call	Mul_16_16_2s_complement	    ; result in FSR2
	movff	POSTINC2, _collision_check
	movff	POSTINC2, _collision_check + 1
	movff	POSTINC2, _collision_check + 2
	movff	POSTINC2, _collision_check + 3

	lfsr	FSR0, rel_vel_y
	lfsr	FSR1, distance_y
	call	Mul_16_16_2s_complement	    ; result in FSR2
	movf	POSTINC2, W
	addwf	_collision_check
	movf	POSTINC2, W
	addwfc	_collision_check + 1
	movf	POSTINC2, W
	addwfc	_collision_check + 2
	movf	POSTINC2, W
	addwfc	_collision_check + 3
	
	; If negative: collide (bit set)
	btfss	_collision_check + 3, 7
	return
	
	

	; ball_vx = ball_vx + (	(slime_0_vx - 2 * ball_vx) distance_x + 
	;			(slime_0_vy - 2 * ball_vy) distance_y	)    * distance_x
	
	movff	ball_vx, temp_2B_x
	movff	ball_vx + 1, temp_2B_x + 1
	lfsr	FSR0, temp_2B_x
	call	Multiply_2_2B		; temp_2B_x = 2 * ball_vx
	
	movf	temp_2B_x, W
	subwf	slime_0_vx, W
	movwf	temp_2B_x
	movf	temp_2B_x + 1, W
	subwfb	slime_0_vx + 1, W
	movwf	temp_2B_x + 1		; temp_2B_x = slime_0_vx - 2 * ball_vx
	

	; temp_2B_x /= 8 *= distance_x    Divide by 8 to counter distance_xORy scaling.
	lfsr	FSR0, temp_2B_x
	call	Divide_8_2B
	
	lfsr	FSR1, distance_x
	call	Mul_16_16
	movff	POSTINC2, temp_2B_x
	movff	INDF2, temp_2B_x + 1	; temp_2B_x = (slime_0_vx - 2 * ball_vx) distance_x
	
	; Repeat for y
	movff	ball_vy, temp_2B_y
	movff	ball_vy + 1, temp_2B_y + 1
	lfsr	FSR0, temp_2B_y
	call	Multiply_2_2B		; temp_2B_y = 2 * ball_vy
	movf	temp_2B_y, W
	subwf	slime_0_vy, W
	movwf	temp_2B_y
	movf	temp_2B_y + 1, W
	subwfb	slime_0_vy + 1, W
	movwf	temp_2B_y + 1		; temp_2B_y = slime_0_vy - 2 * ball_vy
	
	; temp_2B_y /= 8 *= distance_y    Divide by 8 to counter distance_xORy scaling.
	lfsr	FSR0, temp_2B_y
	call	Divide_8_2B
	lfsr	FSR1, distance_y
	call	Mul_16_16
	movff	POSTINC2, temp_2B_y
	movff	INDF2, temp_2B_y + 1	; temp_2B_y = (slime_0_vy - 2 * ball_vy) distance_y

	; temp_2B_k = (temp_2B_x + temp_2B_y) / 8      /8 to counter scaling of distance_xORy
	movff	temp_2B_x, temp_2B_k
	movff	temp_2B_x + 1, temp_2B_k + 1
	movf	temp_2B_y, W
	addwf	temp_2B_k, f
	movf	temp_2B_y + 1, W
	addwfc	temp_2B_k + 1, f
	lfsr	FSR0, temp_2B_k
	call	Divide_8_2B
	
	; temp_2B_x = temp_2B_k * distance_x
	lfsr	FSR1, distance_x
	call	Mul_16_16
	; TODO: Check if only taking two bytes is enough.
	movff	POSTINC2, temp_2B_x
	movff	INDF2, temp_2B_x + 1	    ; temp_2B_x = k dx
	; temp_2B_y = temp_2B_k * distance_y
	lfsr	FSR1, distance_y
	call	Mul_16_16
	movff	POSTINC2, temp_2B_y
	movff	INDF2, temp_2B_y + 1	    ; temp_2B_y = k dy
	
	; Add temp_2B_xORy to ball_vx, ball_vy
	movf	temp_2B_x, W
	addwf	ball_vx, f
	movf	temp_2B_x + 1, W
	addwfc	ball_vx + 1, f
	movf	temp_2B_y, W
	addwf	ball_vy, f
	movf	temp_2B_y + 1, W
	addwfc	ball_vy + 1, f		    ; v = v + k dxORy
	
	return

Speed_Limiter
	nop
_vx_speed_limiter
	movff	ball_vx, _speed_limiter_positive_temp
	movff	ball_vx + 1, _speed_limiter_positive_temp + 1
	lfsr	FSR0, _speed_limiter_positive_temp
	call	Absolute_2B
	; Ensure abs(ball_vx) - ball_max_vel_x < 0 (MSB is clear)
	movlw	ball_max_vel_x
	subwf	_speed_limiter_positive_temp, f
	movlw	0
	subwfb	_speed_limiter_positive_temp + 1, f
	
	btfsc	_speed_limiter_positive_temp + 1, 7
	bra	_vy_speed_limiter	    ; If set: skip to vy
	
	movff	ball_vx + 1, _speed_limiter_sign    ; Store initial sign
	movlw	ball_max_vel_x
	movwf	ball_vx
	movlw	0
	movwf	ball_vx + 1
	
	; Use initial sign to correct literal placed in
	btfss	_speed_limiter_sign, 7
	bra	_vy_speed_limiter	    ; If clear: already positive, skip to vy
	; Change speed to negative.
	comf	ball_vx ,f
	comf	ball_vx + 1, f
	movlw	1
	addwf	ball_vx, f
	movlw	0
	addwfc	ball_vx + 1, f
	
_vy_speed_limiter
	movff	ball_vy, _speed_limiter_positive_temp
	movff	ball_vy + 1, _speed_limiter_positive_temp + 1
	lfsr	FSR0, _speed_limiter_positive_temp
	call	Absolute_2B
	; Ensure abs(ball_vy) - ball_may_vel_y < 0 (MSB is clear)
	movlw	ball_max_vel_y
	subwf	_speed_limiter_positive_temp, f
	movlw	0
	subwfb	_speed_limiter_positive_temp + 1, f
	
	btfsc	_speed_limiter_positive_temp + 1, 7
	bra	_speed_limiter_end	    ; If set: skip to end
	
	movff	ball_vy + 1, _speed_limiter_sign    ; Store initial sign
	movlw	ball_max_vel_y
	movwf	ball_vy
	movlw	0
	movwf	ball_vy + 1
	
	; Use initial sign to correct literal placed in
	btfss	_speed_limiter_sign, 7
	bra	_speed_limiter_end	    ; If clear: already positive, skip to vy
	; Change speed to negative.
	comf	ball_vy, f
	comf	ball_vy + 1, f
	movlw	1
	addwf	ball_vy, f
	movlw	0
	addwfc	ball_vy + 1, f

_speed_limiter_end
	return
	end