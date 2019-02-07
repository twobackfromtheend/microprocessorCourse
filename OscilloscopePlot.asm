#include p18f87k22.inc

	global	Plot

	extern	ball_x, ball_y
	
OscilloscopePlot code	
 

Oscilloscope_Setup
	clrf	TRISC		; PORTC outputs
	clrf	PORTC
	
; Plots ball x and y as a point
; 0V to 1V
; Position of 0, 0 to 65535, 65535
Plot
	
	; convert 2's complement to unsigned int
	; plot unsigned int.
	return
	

	end