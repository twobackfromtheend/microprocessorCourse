#include p18f87k22.inc
	
	extern	Main_Setup
	extern	Game_Setup
	extern	Timer_Setup
	
rst	code	0
	goto	setup


main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	
	; Setup to allow Flash program memory access (provided)
	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	
	
	call	Main_Setup
	call	Game_Setup
	goto	start
	
	; ******* Main programme ****************************************
start 	call	Timer_Setup
	goto	$		; Loop and allow Timer to trigger interrupts
	return
	
	end
