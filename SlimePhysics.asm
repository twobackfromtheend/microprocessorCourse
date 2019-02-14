#include p18f87k22.inc
#include constants.inc

	global	slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
	global	slime_1_x, slime_1_y, slime_1_vx, slime_1_vy

	global	Slime_Step

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
	    
 
Slime_Step
	call	Update_Velocity
;	call	Propagate
;	call	Collide_With_Wall
	return

Update_Velocity
	
	return
	
	end


