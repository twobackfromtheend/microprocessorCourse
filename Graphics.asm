#include p18f87k22.inc
#include constants.inc
	
	global	Graphics_Setup
	global	Graphics_wall, Graphics_net, Graphics_ball, Graphics_slimes
	
	extern	ball_x, ball_y
	extern	slime_0_x, slime_0_y, slime_1_x, slime_1_y
	extern	SPI_Transmit_W
	extern	LCD_delay_x4us

;	extern	wall_x_lower, wall_x_higher, wall_y_lower, wall_y_higher
	extern  Compare_2B, compare_2B_1, compare_2B_2

acs0    udata_acs
temp_x  res	2
temp_y	res	2
ball_points_ram	res .14
;slime_points_ram    res	.14
counter		res 1


	constant	wall_step = 0x10
	
Graphics code

;ball_points  data    .0,.4,.1,.4,.2,.3,.3,.3,.3,.2,.4,.1,.4,.0
;ball_points  data    .0,.40,.10,.40,.20,.30,.30,.30,.30,.20,.40,.10,.40,.00
;ball_points	db	    .0,.200,.50,.200,.100,.150,.150,.150,.150,.100,.200,.50,.200,.00
ball_points	db	    .0,.100,.25,.100,.50,.75,.75,.75,.75,.50,.100,.25,.100,.00
		constant    ball_points_count=.7	; x2 for number of ints.
;slime_points	dw	    .00,.400,.100,.400,.200,.300,.300,.300,.300,.200,.400,.100,.400,.00
;		constant    slime_points_count=.7
		constant    slime_ball_radius_multiplier=.4
Graphics_Setup
	; Load ball_points_ram from program memory
	lfsr	FSR0, ball_points_ram	; Load FSR0 with address in RAM	
	movlw	upper(ball_points)
	movwf	TBLPTRU	
	movlw	high(ball_points)
	movwf	TBLPTRH	
	movlw	low(ball_points)
	movwf	TBLPTRL

	movlw	ball_points_count
	movwf 	counter			; counter initialised to ball_points_count
copy_ball_points_loop
	tblrd*+			; one byte from PM to TABLAT, increment TBLPTR
	movff	TABLAT, POSTINC0
	tblrd*+			; one byte from PM to TABLAT, increment TBLPTR
	movff	TABLAT, POSTINC0
	decfsz	counter
	bra	copy_ball_points_loop
	
;	; Load slime_points_ram from program memory
;	lfsr	FSR0, slime_points_ram	; Load FSR0 with address in RAM	
;	movlw	upper(slime_points)
;	movwf	TBLPTRU	
;	movlw	high(slime_points)
;	movwf	TBLPTRH	
;	movlw	low(slime_points)
;	movwf	TBLPTRL
;
;	movlw	slime_points_count
;	movwf 	counter			; counter initialised to ball_points_count
;copy_slime_points_loop
;	tblrd*+			; one byte from PM to TABLAT, increment TBLPTR
;	movff	TABLAT, POSTINC0
;	tblrd*+			; one byte from PM to TABLAT, increment TBLPTR
;	movff	TABLAT, POSTINC0
;	decfsz	counter
;	bra	copy_slime_points_loop
	return

; Draws wall
Graphics_wall	
	; constants are in 2's complement. 
	; but since positive (and only 12 bits are written), can be used as-is.
;	1   (wall_x_lower, wall_y_lower)
;	2   (wall_x_lower, wall_y_higher)
; 	3   (wall_x_higher, wall_y_higher)
; 	4   (wall_x_higher, wall_y_lower)
;	5=1 (wall_x_lower, wall_y_lower) 
	
	; Initialise to point 1.
	movlw	wall_x_lower
	movwf	temp_x
	movlw	wall_y_lower
	movwf	temp_y
	movlw	0
	movwf	temp_x + 1
	movwf	temp_y + 1
	
	; Increase y to point 2.
p1_p2	call	Graphics_Plot_temp_xy
	movlw	wall_step
	addwf	temp_y, f
	movlw	0
	addwfc	temp_y + 1
	
	movlw	low(wall_y_higher)		; If temp_y < wall_y_higher: loop
	movwf	compare_2B_1
	movlw	high(wall_y_higher)
	movwf	compare_2B_1 + 1		; 2B_1 = wall_y_higher
	movff	temp_y, compare_2B_2
	movff	temp_y + 1, compare_2B_2 + 1	; 2B_2 = temp_y
	call	Compare_2B		
	tstfsz	WREG		; Skip if 2B_1 (wall_y_higher) <= 2B_2 (temp_y)
	bra	p1_p2
	
	movlw	high(wall_y_higher)		; Set temp_y = wall_y_higher (prevent overflow)
	movwf	temp_y + 1
	movlw	low(wall_y_higher)
	movwf	temp_y
	
	; Increase x to point 3
p2_p3	call	Graphics_Plot_temp_xy
	movlw	wall_step
	addwf	temp_x, f
	movlw	0
	addwfc	temp_x + 1
	
	movlw	low(wall_x_higher)		; If temp_x < wall_x_higher: loop
	movwf	compare_2B_1
	movlw	high(wall_x_higher)
	movwf	compare_2B_1 + 1		; 2B_1 = wall_x_higher
	movff	temp_x, compare_2B_2
	movff	temp_x + 1, compare_2B_2 + 1	; 2B_2 = temp_x
	call	Compare_2B		
	tstfsz	WREG		; Skip if 2B_1 (wall_x_higher) <= 2B_2 (temp_x)
	bra	p2_p3
	
	movlw	high(wall_x_higher)		; Set temp_x = wall_x_higher (prevent overflow)
	movwf	temp_x + 1
	movlw	low(wall_x_higher)
	movwf	temp_x
	
	; Decrease y to point 4
p3_p4	call	Graphics_Plot_temp_xy
	movlw	wall_step
	subwf	temp_y, f
	movlw	0
	subwfb	temp_y + 1
	
	; If temp_y > wall_y_lower: loop
	tstfsz	temp_y + 1			; Skip if upper byte 0
	bra	p3_p4
	movlw	wall_y_lower
	cpfsgt	temp_y				; Skip if f (temp_y) < W (wall_y_lower)
	bra	p3_p4
	movwf	temp_y				; Set temp_y to wall_y_lower (prevent overflow)
	
	; Decrease x to point 5 (=1)
p4_p1	call	Graphics_Plot_temp_xy
	movlw	wall_step
	subwf	temp_x, f
	movlw	0
	subwfb	temp_x + 1
	
	; If temp_x > wall_x_lower: loop
	tstfsz	temp_x + 1			; Skip if upper byte 0
	bra	p4_p1
	movlw	wall_x_lower
	cpfsgt	temp_x				; Skip if f (temp_x) < W (wall_x_lower)
	bra	p4_p1
	movwf	temp_x				; Set temp_x to wall_x_lower (prevent overflow)
	
	return
	
Graphics_net
	; Start temp_xy at bottom of net
	movlw	low(net_x)
	movwf	temp_x
	movlw	high(net_x)
	movwf	temp_x + 1
	movlw	0
	movwf	temp_y
	movwf	temp_y + 1
	
	; Increase temp_y until net_height
draw_net
	call	Graphics_Plot_temp_xy
	movlw	wall_step
	addwf	temp_y, f
	movlw	0
	addwfc	temp_y + 1
	
	movlw	low(net_height)		; If temp_y < net_height: loop
	movwf	compare_2B_1
	movlw	high(net_height)
	movwf	compare_2B_1 + 1		; 2B_1 = net_height
	movff	temp_y, compare_2B_2
	movff	temp_y + 1, compare_2B_2 + 1	; 2B_2 = temp_y
	call	Compare_2B		
	tstfsz	WREG		; Skip if 2B_1 (wall_y_higher) <= 2B_2 (temp_y)
	bra	draw_net
	
	return
	
	
Graphics_ball
	; Draw +ve quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_ball_pxpy
	movff	ball_x, temp_x
	movff	ball_x + 1, temp_x + 1
	movff	ball_y, temp_y
	movff	ball_y + 1, temp_y + 1

	movf	POSTINC0, W	    ; x-offset
	addwf	temp_x
	movlw	0
	addwfc	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	addwf	temp_y
	movlw	0
	addwfc	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_ball_pxpy
	
;	; Draw -y quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_ball_pxny
	movff	ball_x, temp_x
	movff	ball_x + 1, temp_x + 1
	movff	ball_y, temp_y
	movff	ball_y + 1, temp_y + 1
	movf	POSTINC0, W	    ; x-offset
	addwf	temp_x
	movlw	0
	addwfc	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	subwf	temp_y
	movlw	0
	subwfb	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_ball_pxny
	
	; Draw -x-y quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_ball_nxny
	movff	ball_x, temp_x
	movff	ball_x + 1, temp_x + 1
	movff	ball_y, temp_y
	movff	ball_y + 1, temp_y + 1
	movf	POSTINC0, W	    ; x-offset
	subwf	temp_x
	movlw	0
	subwfb	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	subwf	temp_y
	movlw	0
	subwfb	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_ball_nxny
	
	; Draw -x quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_ball_nxpy
	movff	ball_x, temp_x
	movff	ball_x + 1, temp_x + 1
	movff	ball_y, temp_y
	movff	ball_y + 1, temp_y + 1
	movf	POSTINC0, W	    ; x-offset
	subwf	temp_x
	movlw	0
	subwfb	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	addwf	temp_y
	movlw	0
	addwfc	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_ball_nxpy
	
	return
	
; Draws the ball as a point.
; Used for testing.
Graphics_ball_point	
	; Write ball_x to chip 1: CS (pin 1) low
	bcf	LATD, 1		; CS1 low - allow write
	movf	ball_x + 1, W	; move upper byte to W
	andlw	b'00001111'	; Mask upper bytes - only keep last 4 bits
	iorlw	b'01110000'	; (0) (buffered?) (1x gain?) (active) (... data)
	call	SPI_Transmit_W
	movf	ball_x, W
	call	SPI_Transmit_W
	bsf	LATD, 1		; CS1 raise
	
	; Write ball_y to chip 2: CS (pin 2) low
	bcf	LATD, 2		; CS2 low - allow write
	movf	ball_y + 1, W	; move upper byte to W
	andlw	b'00001111'	; Mask upper bytes - only keep last 4 bits
	iorlw	b'01110000'	; (0) (buffered?) (1x gain?) (active) (... data)
	call	SPI_Transmit_W
	movf	ball_y, W
	call	SPI_Transmit_W
	bsf	LATD, 2		; CS2 raise

	movlw	1
	call	LCD_delay_x4us

	bcf	LATD, 0		; LDAC low edge (write)
	call	LCD_delay_x4us
	bsf	LATD, 0		
	return
	
	
;;;;;	 DRAW SLIMES GRAPHICS	    ;;;;;
;   Draws slimes using ball graphics	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
Graphics_slimes
	call	Graphics_slime_0
	call	Graphics_slime_1
	return
	
;;;;;	DRAW SLIME 0 GRAPHICS	;;;;;
;   Draws slime using ball graphics ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_slime_0
	; Draw +ve quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_slime_0_pxpy
	movff	slime_0_x, temp_x
	movff	slime_0_x + 1, temp_x + 1
	movff	slime_0_y, temp_y
	movff	slime_0_y + 1, temp_y + 1

	movf	POSTINC0, W	    ; x-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	addwf	temp_x
	movf	PRODH, W
	addwfc	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	addwf	temp_y
	movf	PRODH, W
	addwfc	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_slime_0_pxpy
	
;	; Draw -x quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_slime_0_nxpy
	movff	slime_0_x, temp_x
	movff	slime_0_x + 1, temp_x + 1
	movff	slime_0_y, temp_y
	movff	slime_0_y + 1, temp_y + 1
	movf	POSTINC0, W	    ; x-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	subwf	temp_x
	movf	PRODH, W
	subwfb	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	addwf	temp_y
	movf	PRODH, W
	addwfc	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_slime_0_nxpy
	return
	
;;;;;	DRAW SLIME 1 GRAPHICS	;;;;;
;   Draws slime using ball graphics ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_slime_1
	; Draw +ve quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_slime_1_pxpy
	movff	slime_1_x, temp_x
	movff	slime_1_x + 1, temp_x + 1
	movff	slime_1_y, temp_y
	movff	slime_1_y + 1, temp_y + 1

	movf	POSTINC0, W	    ; x-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	addwf	temp_x
	movf	PRODH, W
	addwfc	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	addwf	temp_y
	movf	PRODH, W
	addwfc	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_slime_1_pxpy
	
;	; Draw -x quadrant
	lfsr	FSR0, ball_points_ram
	movlw	ball_points_count
	movwf 	counter	
draw_slime_1_nxpy
	movff	slime_1_x, temp_x
	movff	slime_1_x + 1, temp_x + 1
	movff	slime_1_y, temp_y
	movff	slime_1_y + 1, temp_y + 1
	movf	POSTINC0, W	    ; x-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	subwf	temp_x
	movf	PRODH, W
	subwfb	temp_x + 1
	movf	POSTINC0, W	    ; y-offset
	mullw	.4		    ; PRODH:PRODL
	movf	PRODL, W
	addwf	temp_y
	movf	PRODH, W
	addwfc	temp_y + 1
	call	Graphics_Plot_temp_xy
	decfsz	counter
	bra	draw_slime_1_nxpy
	return
	
Graphics_Plot_temp_xy	
	; Write temp_x to chip 1: CS (pin 1) low
	bcf	LATD, 1		; CS1 low - allow write
	movf	temp_x + 1, W	; move upper byte to W
	andlw	b'00001111'	; Mask upper bytes - only keep last 4 bits
	iorlw	b'01110000'	; (0) (buffered?) (1x gain?) (active) (... data)
	call	SPI_Transmit_W
	movf	temp_x, W
	call	SPI_Transmit_W
	bsf	LATD, 1		; CS1 raise
	
	; Write temp_y to chip 2: CS (pin 2) low
	bcf	LATD, 2		; CS2 low - allow write
	movf	temp_y + 1, W	; move upper byte to W
	andlw	b'00001111'	; Mask upper bytes - only keep last 4 bits
	iorlw	b'01110000'	; (0) (buffered?) (1x gain?) (active) (... data)
	call	SPI_Transmit_W
	movf	temp_y, W
	call	SPI_Transmit_W
	bsf	LATD, 2		; CS2 raise

	movlw	1
;	call	LCD_delay_x4us

	bcf	LATD, 0		; LDAC low edge (write)
;	call	LCD_delay_x4us
	bsf	LATD, 0		
	return
	end





