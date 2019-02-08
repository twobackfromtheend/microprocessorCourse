#include p18f87k22.inc

	global	ball_x, ball_y, ball_vx, ball_vy
	global	Ball_Step

	extern	Mul_16_16
    
    
acs0    udata_acs
ball_x  res	2	; -32768 to 32767 in 2's complement
ball_y  res	2
ball_vx res	2	; -32768 to 32767 in 2's complement
ball_vy res	2
 
 
    constant	ball_radius = 0x10	    ; .25
    constant	wall_x_lower = 0x50	    ; .0
    constant	wall_x_higher = 0xf00	    ; .100
    constant	wall_y_lower = 0x00	    ; .0
    constant	wall_y_higher = 0x200	    ; DOES NOT EXIST
    
    constant	ball_wall_x_lower = wall_x_lower + ball_radius
    constant	ball_wall_x_higher = wall_x_higher - ball_radius
    constant	ball_wall_y_lower = wall_y_lower + ball_radius
    constant	ball_wall_y_higher = wall_y_higher - ball_radius
    
    
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
	
	end