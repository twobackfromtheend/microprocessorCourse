    	constant	wall_x_lower = 0x50	    ; .0
	constant	wall_x_higher = 0xfa0	    ; .100
	constant	wall_y_lower = 0x50	    ; .0
	constant	wall_y_higher = 0xfa0	    ; DOES NOT EXIST

	constant	ball_radius = .110	    ; .25
        constant	slime_radius = .420	    ; .100

	constant	ball_max_vel_x = .60	    ; .15
	constant	ball_max_vel_y = .88	    ; .22
	constant	ball_gravity = .3	    ; 1
	
	constant	slime_jump_vy = .124	    ; .31
	constant	slime_move_vx = .32	    ; .8
	constant	slime_gravity = .8	    ; .2
	
	constant	slime_0_left_limit = slime_radius   ; .50
	constant	slime_0_right_limit = .2000 - slime_radius  ; .445
	constant	slime_1_left_limit = .2000 + slime_radius   ; .555
	constant	slime_1_right_limit = .4000 - slime_radius  ; .950
	
	constant	slime_0_start_x = .800   ; .200
	constant	slime_1_start_x = .3200	    ; .800
	
	
	constant	ball_start_x = slime_0_start_x	; .200 or .800
	constant	ball_start_y = .1680		; .356
	constant	ball_start_vx = 0		; 0
	constant	ball_start_vy = 0		; 0
	