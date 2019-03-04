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
	extern	Divide_4_2B, Divide_8_2B, Multiply_2_2B
	extern	Mul_16_16_2s_complement
	extern	Divide_4B_4096
	
	extern	LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
    
acs0    udata_acs
ball_x  res	2	; -32768 to 32767 in 2's complement
ball_y  res	2
ball_vx res	2	; -32768 to 32767 in 2's complement
ball_vy res	2

 
bank1   udata	0x100
distance_x  res	2
distance_y  res	2
temp_2B_x	    res	2
temp_2B_y	    res	2
temp_2B_k	    res	2
temp_4B_x   res	4
temp_4B_y   res	4
rel_vel_x   res	2
rel_vel_y   res	2

slime_x	    res	2
slime_y	    res 2
slime_vx    res	2
slime_vy    res	2
    
_collision_check	    res 4
_speed_limiter_sign		res 1
_speed_limiter_positive_temp	res 2
 

    constant	ball_wall_x_lower = wall_x_lower + ball_radius
    constant	ball_wall_x_higher = wall_x_higher - ball_radius
    constant	ball_wall_y_lower = wall_y_lower + ball_radius
    constant	ball_wall_y_higher = wall_y_higher - ball_radius
    
    constant	ball_net_x_left = net_x - ball_radius
    constant	ball_net_x_right = net_x + ball_radius
    constant	ball_net_y = net_height + ball_radius
    constant	ball_net_top_bounce_limit = net_height + .30

    
    constant	ball_slime_rectilinear_distance = ball_radius + slime_radius
    constant	ball_slime_euclidean_distance = (ball_radius + slime_radius) * (ball_radius + slime_radius)
    
BallPhysics code
	    
 
Ball_Step
  	movlb	1

	call	Ball_Propagate
	call	Collide_With_Wall
	call	Collide_With_Net
	
	call	Collide_Ball_Slime_0
	call	Collide_Ball_Slime_1

	call	Speed_Limiter
	
;	call	LCD_Clear
;	lfsr	FSR2, _speed_limiter_sign
;	movlw	0
;	movwf	_speed_limiter_sign + 1
	
;	movlw	upper(ball_slime_euclidean_distance)
;	movwf	_speed_limiter_sign
;	call	LCD_Write_Hex_Message_2B
;	movlw	high(ball_slime_euclidean_distance)
;	movwf	_speed_limiter_sign
;	call	LCD_Write_Hex_Message_2B
;	movlw	low(ball_slime_euclidean_distance)
;	movwf	_speed_limiter_sign
;	call	LCD_Write_Hex_Message_2B
;;	call	LCD_Cursor_To_Line_2
;	lfsr	FSR2, ball_vy
;	call	LCD_Write_Hex_Message_2B

	return

;;;;;;;;;;	    BALL PROPAGATE		   ;;;;;;;;;;
;    Propagate current positions by 1 frame (x = x + vt)    ;
;		    Applies gravity			    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Ball_Propagate
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
	
	movlw	ball_gravity
	subwf	ball_vy, f
	movlw	0
	subwfb	ball_vy + 1, f
	return
	    
	
;;;;;	COLLIDE BALL WALL	;;;;;
;   Collides the ball with walls    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;	btfss	ball_vy + 1, 7	    ; skip if ball_vy is negative
;	bra	_lower_y_end
;_lower_y_condition_1
;	btfss	ball_y + 1, 7	    ; skip if ball_y + 1 is negative
;	bra	_lower_y_condition_2
;	call	Reverse_ball_vy
;	bra	_lower_y_end
;_lower_y_condition_2
;	tstfsz	ball_y + 1	    ; skip if ball_y + 1 is 0
;	bra	_lower_y_end
;	movlw	ball_wall_y_lower	    ; cpfslt - skip if f < W
;	cpfslt	ball_y		    ; skip if ball_y (lower) (positive) < wall_y_lower (positive)
;	bra	_lower_y_end
;	call	Reverse_ball_vy
;_lower_y_end
;	nop
	
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
	
;;;;;	REVERSE BALL VX	;;;;;
;	 ball_vx *= -1	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Reverse_ball_vx
	; 2s complement ball_vx
	comf	ball_vx + 1, f
	comf	ball_vx, W
	addlw	1
	movwf	ball_vx
	movlw	0
	addwfc	ball_vx + 1
	return
	
;;;;;	REVERSE BALL VY	;;;;;
;	 ball_vy *= -1	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Reverse_ball_vy
	; 2s complement ball_vy
	comf	ball_vy + 1, f
	comf	ball_vy, W
	addlw	1
	movwf	ball_vy
	movlw	0
	addwfc	ball_vy + 1
	return
	

;;;;;	COLLIDE BALL NET	;;;;;
;   Collides the ball with net    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Collide_With_Net
	; For ANY collision:
	; ball_net_x_left < ball_x < ball_net_x_right AND
	; ball_y < ball_net_y
	
	movlw	low(ball_net_x_left)
	movwf	compare_2B_1
	movlw	high(ball_net_x_left)
	movwf	compare_2B_1 + 1
	
	movff	ball_x, compare_2B_2
	movff	ball_x + 1, compare_2B_2 + 1
	call	Compare_2B		    ; bool(ball_net_x_left > ball_x) in W
	tstfsz	WREG			    ; Skip if ball_x >= ball_net_x_left
	return
	
	movff	ball_x, compare_2B_1
	movff	ball_x + 1, compare_2B_1 + 1
	
	movlw	low(ball_net_x_right)
	movwf	compare_2B_2
	movlw	high(ball_net_x_right)
	movwf	compare_2B_2 + 1

	call	Compare_2B		    ; bool(ball_x > ball_net_x_right) in W
	tstfsz	WREG			    ; Skip if ball_x <= ball_net_x_right
	return
	
	
	movff	ball_y, compare_2B_1
	movff	ball_y + 1, compare_2B_1 + 1
	
	movlw	low(ball_net_y)
	movwf	compare_2B_2
	movlw	high(ball_net_y)
	movwf	compare_2B_2 + 1

	call	Compare_2B		    ; bool(ball_y > ball_net_y) in W
	tstfsz	WREG			    ; Skip if ball_y <= ball_net_y
	return

	
	; Met conditions for collision
	
	; if ball_vy > 0 AND ball_y > ball_net_top_bounce_limit:
	; Top bounce, flip ball_vy
	btfss	ball_vy + 1, 7		    ; Skip if ball_vy < 0
	bra	net_side_bounce
	movlw	low(ball_net_top_bounce_limit)
	cpfsgt	ball_y			    ; Know ball_y is 1 byte already, skip if ball_y > ball_net_top_bounce_limit
	bra	net_side_bounce
	call	Reverse_ball_vy
	return	
	

net_side_bounce
	call	Reverse_ball_vx		    ; Here, we know that ball bounced off net, and off the sides.
	
	; if ball_x < net_x, set ball_x to (ball_net_x_left - buffer)
	; else: set ball_x = ball_net_x_right + buffer
	movlw	low(net_x)
	movwf	compare_2B_1
	movlw	high(net_x)
	movwf	compare_2B_1 + 1
	
	movff	ball_x, compare_2B_2
	movff	ball_x + 1, compare_2B_2 + 1
	
	call	Compare_2B		    ; (net_x > ball_x) in W
	tstfsz	WREG			    ; Skip if ball_x > net_x
	bra	set_ball_x_left_net
	bra	set_ball_x_right_net

set_ball_x_left_net
	movlw	low(ball_net_x_left)
	sublw	.10
	movwf	ball_x
	movlw	high(ball_net_x_left)
	movwf	ball_x + 1
	movlw	0
	subwfb	ball_x + 1, f
	return
	
set_ball_x_right_net
	movlw	low(ball_net_x_right)
	addlw	.10
	movwf	ball_x
	movlw	high(ball_net_x_right)
	movwf	ball_x + 1
	movlw	0
	addwfc	ball_x + 1, f
	return
	
Collide_Ball_Slime_0
	movff	slime_0_x, slime_x
	movff	slime_0_x + 1, slime_x + 1
	movff	slime_0_y, slime_y
	movff	slime_0_y + 1, slime_y + 1
	movff	slime_0_vx, slime_vx
	movff	slime_0_vx + 1, slime_vx + 1
	movff	slime_0_vy, slime_vy
	movff	slime_0_vy + 1, slime_vy + 1
	call	Collide_Ball_Slime
	return
	
Collide_Ball_Slime_1
	movff	slime_1_x, slime_x
	movff	slime_1_x + 1, slime_x + 1
	movff	slime_1_y, slime_y
	movff	slime_1_y + 1, slime_y + 1
	movff	slime_1_vx, slime_vx
	movff	slime_1_vx + 1, slime_vx + 1
	movff	slime_1_vy, slime_vy
	movff	slime_1_vy + 1, slime_vy + 1
	call	Collide_Ball_Slime
	return
	
	
;;;;;		COLLIDE BALL SLIME	    ;;;;;
;   Checks to see if ball and slime collide	;
;   Performs collision if needed.
;   Assumes slime_x, slime_y set,		;
;	slime_vx, slime_vy set.			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Collide_Ball_Slime
	; Check if collision needed
	; Calculate distance
	; distance = ball_x - slime_x
	; x
	movf	slime_x, W
	movff	ball_x, distance_x
	movff	ball_x + 1, distance_x + 1
	subwf	distance_x, BANKED		; lower byte subtraction
	movf	slime_x + 1, W
	subwfb	distance_x + 1, BANKED		; high byte subtraction w/ borrow
	; y
	movf	slime_y, W
	movff	ball_y, distance_y
	movff	ball_y + 1, distance_y + 1
	subwf	distance_y, BANKED 		; lower byte subtraction
	movf	slime_y + 1, W
	subwfb	distance_y + 1, BANKED		; high byte subtraction w/ borrow
	
	
	; RECTANGULAR HITBOX
	; if abs_distance_x > ball_slime_rectilinear_distance:
	movff	distance_x, compare_2B_1
	movff	distance_x + 1, compare_2B_1 + 1
	lfsr	FSR0, compare_2B_1
	call	Absolute_2B		; Turn compare_2B_1 into abs_distance_x
	movlw	low(ball_slime_rectilinear_distance)
	movwf	compare_2B_2
	movlw	high(ball_slime_rectilinear_distance)
	movwf	compare_2B_2 + 1	; 1: distance_x, 2: collision_distance
	call	Compare_2B		; W = 1 > 2
	tstfsz	WREG			; Skip if collision possible, collision_distance (2) > (1) distance_x
	return
	
	; if abs_distance_y > ball_slime_rectilinear_distance:
	movff	distance_y, compare_2B_1
	movff	distance_y + 1, compare_2B_1 + 1
	lfsr	FSR0, compare_2B_1
	call	Absolute_2B		; Turn compare_2B_1 into abs_distance_y
	movlw	low(ball_slime_rectilinear_distance)
	movwf	compare_2B_2
	movlw	high(ball_slime_rectilinear_distance)
	movwf	compare_2B_2 + 1	; 1: distance_y, 2: collision_distance
	call	Compare_2B		; W = 1 > 2
	tstfsz	WREG			; Skip if collision possible, collision_distance (2) > (1) distance_y
	return
	
	; CIRCULAR HITBOX
	lfsr	FSR0, distance_x
	lfsr	FSR1, distance_x
	call	Mul_16_16_2s_complement	    ; Result in FSR2
	movff	POSTINC2, _collision_check
	movff	POSTINC2, _collision_check + 1
	movff	POSTINC2, _collision_check + 2
	movff	POSTINC2, _collision_check + 3
	
	lfsr	FSR0, distance_y
	lfsr	FSR1, distance_y
	call	Mul_16_16_2s_complement	    ; Result in FSR2
	
	movf	POSTINC2, W
	addwf	_collision_check, f, BANKED
	movf	POSTINC2, W
	addwfc	_collision_check + 1, f, BANKED
	movf	POSTINC2, W
	addwfc	_collision_check + 2, f, BANKED
;	movf	POSTINC2, W
;	addwfc	_collision_check + 3, f	    ; This high byte is not checked.
	
	; 4 byte dx**2 + dy**2 in _collision_check
	movlw	upper(ball_slime_euclidean_distance)
	cpfsgt	_collision_check + 2, BANKED	    ; f > w: skip
	bra	continue_check_1
	return
continue_check_1
	cpfseq	_collision_check + 2, BANKED
	bra	do_collide		    ; Not greater than, not equal: therefore f (actual distance) < W (threshold), do collision
	; Upper bytes equal, check high bytes
	movlw	high(ball_slime_euclidean_distance)
	cpfsgt	_collision_check + 1, BANKED	    ; f > w: skip
	bra	continue_check_2
	return
continue_check_2
	cpfseq	_collision_check + 1, BANKED
	bra	do_collide		    ; Not greater than, not equal: therefore f (actual distance) < W (threshold), do collision
	; High bytes equal, check low bytes
	movlw	low(ball_slime_euclidean_distance)
	cpfsgt	_collision_check, BANKED	    ; f > w: skip
	bra	do_collide
	return

do_collide
	; Calculate norm_dists
	; Assume distance is approx 512
	; distance_xORy = distance_xORy / 8  (represents 64x number)
	lfsr	FSR0, distance_x
	call	Divide_8_2B
;	call	Divide_4_2B
	lfsr	FSR0, distance_y
	call	Divide_8_2B
;	call	Divide_4_2B

	; Displacement vector is from slime to ball
	; Calculate relative velocities = ball_v - slime_v
	; x
	movf	slime_vx, W
	movff	ball_vx, rel_vel_x
	movff	ball_vx + 1, rel_vel_x + 1
	subwf	rel_vel_x, BANKED		; lower byte subtraction
	movf	slime_vx + 1, W
	subwfb	rel_vel_x + 1, BANKED		; high byte subtraction w/ borrow
	; y
	movf	slime_vy, W
	movff	ball_vy, rel_vel_y
	movff	ball_vy + 1, rel_vel_y + 1
	subwf	rel_vel_y, BANKED		; lower byte subtraction
	movf	slime_vy + 1, W
	subwfb	rel_vel_y + 1, BANKED		; high byte subtraction w/ borrow
	
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
	addwf	_collision_check, BANKED
	movf	POSTINC2, W
	addwfc	_collision_check + 1, BANKED
	movf	POSTINC2, W
	addwfc	_collision_check + 2, BANKED
	movf	POSTINC2, W
	addwfc	_collision_check + 3, BANKED
	
	; If negative: collide (bit set)
	btfss	_collision_check + 3, 7, BANKED
	return		; Positive: skip recollision
	
	call	Update_Ball_With_Collision
	return


	
;;;;;	UPDATE BALL VELOCITY WITH COLLISION	;;;;;
;   Collides the ball with slime		    ;
;   Assumes distance_x AND distance_y are set	    ;
;       AND slime_vx, slime_vy are set		    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Update_Ball_With_Collision
	; ball_vx = ball_vx + (	(slime_vx - 2 * ball_vx) distance_x + 
	;			(slime_vy - 2 * ball_vy) distance_y	)    * distance_x
	movff	ball_vx, temp_2B_x
	movff	ball_vx + 1, temp_2B_x + 1
	lfsr	FSR0, temp_2B_x
	call	Multiply_2_2B			; temp_2B_x = 2 * ball_vx
	movf	temp_2B_x, W, BANKED
	subwf	slime_vx, W
	movwf	temp_2B_x, BANKED
	movf	temp_2B_x + 1, W, BANKED
	subwfb	slime_vx + 1, W
	movwf	temp_2B_x + 1, BANKED		; temp_2B_x = slime_vx - 2 * ball_vx
	
	; temp_2B_x *= distance_x
	lfsr	FSR0, temp_2B_x
	lfsr	FSR1, distance_x
	call	Mul_16_16_2s_complement
	movff	POSTINC2, temp_2B_x
	movff	INDF2, temp_2B_x + 1		; temp_2B_x = 64 * (slime_vx - 2 * ball_vx) distance_x
	
	; Repeat for y
	movff	ball_vy, temp_2B_y
	movff	ball_vy + 1, temp_2B_y + 1
	lfsr	FSR0, temp_2B_y
	call	Multiply_2_2B			; temp_2B_y = 2 * ball_vy
	movf	temp_2B_y, W, BANKED
	subwf	slime_vy, W
	movwf	temp_2B_y, BANKED
	movf	temp_2B_y + 1, W, BANKED
	subwfb	slime_vy + 1, W
	movwf	temp_2B_y + 1, BANKED		; temp_2B_y = slime_vy - 2 * ball_vy
	
	; temp_2B_y *= distance_y
	lfsr	FSR0, temp_2B_y
	lfsr	FSR1, distance_y
	call	Mul_16_16_2s_complement
	movff	POSTINC2, temp_2B_y
	movff	INDF2, temp_2B_y + 1		; temp_2B_y = 64 * (slime_vy - 2 * ball_vy) distance_y

	; temp_2B_k = (temp_2B_x + temp_2B_y)	; k =  64 * (slime_vx - 2 * ball_vx) distance_x 
							+ 64 * (slime_vy - 2 * ball_vy) distance_y
	movff	temp_2B_x, temp_2B_k
	movff	temp_2B_x + 1, temp_2B_k + 1
	movf	temp_2B_y, W, BANKED
	addwf	temp_2B_k, f, BANKED
	movf	temp_2B_y + 1, W, BANKED
	addwfc	temp_2B_k + 1, f, BANKED
	
	lfsr	FSR0, temp_2B_k
	; temp_4B_x = temp_2B_k * distance_x
	lfsr	FSR1, distance_x
	call	Mul_16_16_2s_complement			; Result in FSR2
	movff	POSTINC2, temp_4B_x
	movff	POSTINC2, temp_4B_x + 1
	movff	POSTINC2, temp_4B_x + 2
	movff	INDF2, temp_4B_x + 3		; temp_4B_x = k dx
	; temp_4B_y = temp_2B_k * distance_y
	lfsr	FSR1, distance_y
	call	Mul_16_16_2s_complement			; Result in FSR2
	movff	POSTINC2, temp_4B_y
	movff	POSTINC2, temp_4B_y + 1
	movff	POSTINC2, temp_4B_y + 2
	movff	INDF2, temp_4B_y + 3		; temp_4B_y = k dy
	
	; Add temp_4B_xORy to ball_vx, ball_vy after dividing by 64^2 (4096)
	; v = v + k dxORy
	lfsr	FSR0, temp_4B_x
	call	Divide_4B_4096			; Result in FSR2
	movf	POSTINC2, W
	addwf	ball_vx, f
	movf	POSTINC2, W
	addwfc	ball_vx + 1, f
	lfsr	FSR0, temp_4B_y
	call	Divide_4B_4096			; Result in FSR2
	movf	POSTINC2, W
	addwf	ball_vy, f
	movf	POSTINC2, W
	addwfc	ball_vy + 1, f
	
	return
	
	
;;;;;	BALL SPEED LIMITER	;;;;;
;   Limits speed of ball according  ;
;	to defined constants	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
Speed_Limiter
	nop
_vx_speed_limiter
	movff	ball_vx, _speed_limiter_positive_temp
	movff	ball_vx + 1, _speed_limiter_positive_temp + 1
	lfsr	FSR0, _speed_limiter_positive_temp
	call	Absolute_2B
	; Ensure abs(ball_vx) - ball_max_vel_x < 0 (MSB is clear)
	movlw	ball_max_vel_x
	subwf	_speed_limiter_positive_temp, f, BANKED
	movlw	0
	subwfb	_speed_limiter_positive_temp + 1, f, BANKED
	
	btfsc	_speed_limiter_positive_temp + 1, 7, BANKED
	bra	_vy_speed_limiter	    ; If set: skip to vy
	
	movff	ball_vx + 1, _speed_limiter_sign    ; Store initial sign
	movlw	ball_max_vel_x
	movwf	ball_vx
	movlw	0
	movwf	ball_vx + 1
	
	; Use initial sign to correct literal placed in
	btfss	_speed_limiter_sign, 7, BANKED
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
	subwf	_speed_limiter_positive_temp, f, BANKED
	movlw	0
	subwfb	_speed_limiter_positive_temp + 1, f, BANKED
	
	btfsc	_speed_limiter_positive_temp + 1, 7, BANKED
	bra	_speed_limiter_end	    ; If set: skip to end
	
	movff	ball_vy + 1, _speed_limiter_sign    ; Store initial sign
	movlw	ball_max_vel_y
	movwf	ball_vy
	movlw	0
	movwf	ball_vy + 1
	
	; Use initial sign to correct literal placed in
	btfss	_speed_limiter_sign, 7, BANKED
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
