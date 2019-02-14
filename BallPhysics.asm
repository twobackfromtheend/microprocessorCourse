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
    
acs0    udata_acs
ball_x  res	2	; -32768 to 32767 in 2's complement
ball_y  res	2
ball_vx res	2	; -32768 to 32767 in 2's complement
ball_vy res	2

acs_ovr	access_ovr
do_collision   res	1
distance_x  res	2
distance_y  res	2

 
    
    constant	ball_wall_x_lower = wall_x_lower + ball_radius
    constant	ball_wall_x_higher = wall_x_higher - ball_radius
    constant	ball_wall_y_lower = wall_y_lower + ball_radius
    constant	ball_wall_y_higher = wall_y_higher - ball_radius
    
    constant	ball_slime_collision_distance = ball_radius + slime_radius
    
    
BallPhysics code
	    
 
Ball_Step
	call	Propagate
	call	Collide_With_Wall
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
	movlw	0
	movwf	do_collision
	
	; Calculate distance^2
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
	; turn compare_2B_1 into a positive number
	movlw	low(ball_slime_collision_distance)
	movwf	compare_2B_2
	movlw	high(ball_slime_collision_distance)
	movwf	compare_2B_2 + 1	; 1: distance_x, 2: collision_distance
	call	Compare_2B		; W = 1 > 2
	tstfsz	WREG			; Skip if collision possible, collision_distance (2) > (1) distance_x
	bra	no_collision
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
	bra	no_collision
	
no_collision
	
	end