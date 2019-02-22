#include p18f87k22.inc
#include constants.inc
	
	    global  P1_Scored_Image_Setup, P1_Scored_Image_Plot
	    extern  Graphics_circle_lowd, circle_x, circle_y, circle_divisor

	    
bank10   udata	0x0A00
counter  res	1
	    
P1ScoredImage code

;image_points	    db	    .1,.7,.2,.7,.3,.7,.4,.7,.5,.7,.9,.7,.16,.7,.17,.7,.18,.7,.22,.7,.26,.7,.29,.7,.30,.7,.31,.7,.32,.7,.33,.7,.37,.7,.38,.7,.39,.7,.40,.7,.41,.7,.50,.7,.58,.7,.59,.7,.60,.7,.61,.7,.64,.7,.65,.7,.66,.7,.70,.7,.71,.7,.72,.7,.75,.7,.76,.7,.77,.7,.78,.7,.81,.7,.82,.7,.83,.7,.84,.7,.86,.7,.87,.7,.88,.7,.89,.7,.1,.6,.6,.6,.9,.6,.15,.6,.19,.6,.23,.6,.25,.6,.29,.6,.37,.6,.42,.6,.49,.6,.50,.6,.57,.6,.63,.6,.67,.6,.69,.6,.73,.6,.75,.6,.79,.6,.81,.6,.86,.6,.90,.6,.1,.5,.2,.5,.3,.5,.4,.5,.5,.5,.9,.5,.15,.5,.16,.5,.17,.5,.18,.5,.19,.5,.24,.5,.29,.5,.30,.5,.31,.5,.37,.5,.38,.5,.39,.5,.40,.5,.41,.5,.50,.5,.58,.5,.59,.5,.60,.5,.63,.5,.69,.5,.73,.5,.75,.5,.79,.5,.81,.5,.82,.5,.83,.5,.86,.5,.90,.5,.1,.4,.9,.4,.15,.4,.19,.4,.24,.4,.29,.4,.37,.4,.40,.4,.50,.4,.61,.4,.63,.4,.69,.4,.73,.4,.75,.4,.76,.4,.77,.4,.78,.4,.81,.4,.86,.4,.90,.4,.1,.3,.9,.3,.15,.3,.19,.3,.24,.3,.29,.3,.37,.3,.41,.3,.50,.3,.61,.3,.63,.3,.67,.3,.69,.3,.73,.3,.75,.3,.78,.3,.81,.3,.86,.3,.90,.3,.1,.2,.9,.2,.10,.2,.11,.2,.12,.2,.13,.2,.15,.2,.19,.2,.24,.2,.29,.2,.30,.2,.31,.2,.32,.2,.33,.2,.37,.2,.42,.2,.48,.2,.49,.2,.50,.2,.51,.2,.52,.2,.57,.2,.58,.2,.59,.2,.60,.2,.64,.2,.65,.2,.66,.2,.70,.2,.71,.2,.72,.2,.75,.2,.79,.2,.81,.2,.82,.2,.83,.2,.84,.2,.86,.2,.87,.2,.88,.2,.89,.2
image_points	    db	    0x01,0x7,0x2,0x7,0x3,0x7,0x4,0x7,0x5,0x7,0x9,0x7,0x10,0x7,0x11,0x7,0x12,0x7,0x16,0x7,0x1a,0x7,0x1d,0x7,0x1e,0x7,0x1f,0x7,0x20,0x7,0x21,0x7,0x25,0x7,0x26,0x7,0x27,0x7,0x28,0x7,0x29,0x7,0x32,0x7,0x3a,0x7,0x3b,0x7,0x3c,0x7,0x3d,0x7,0x40,0x7,0x41,0x7,0x42,0x7,0x46,0x7,0x47,0x7,0x48,0x7,0x4b,0x7,0x4c,0x7,0x4d,0x7,0x4e,0x7,0x51,0x7,0x52,0x7,0x53,0x7,0x54,0x7,0x56,0x7,0x57,0x7,0x58,0x7,0x59,0x7,0x1,0x6,0x6,0x6,0x9,0x6,0xf,0x6,0x13,0x6,0x17,0x6,0x19,0x6,0x1d,0x6,0x25,0x6,0x2a,0x6,0x31,0x6,0x32,0x6,0x39,0x6,0x3f,0x6,0x43,0x6,0x45,0x6,0x49,0x6,0x4b,0x6,0x4f,0x6,0x51,0x6,0x56,0x6,0x5a,0x6,0x1,0x5,0x2,0x5,0x3,0x5,0x4,0x5,0x5,0x5,0x9,0x5,0xf,0x5,0x10,0x5,0x11,0x5,0x12,0x5,0x13,0x5,0x18,0x5,0x1d,0x5,0x1e,0x5,0x1f,0x5,0x25,0x5,0x26,0x5,0x27,0x5,0x28,0x5,0x29,0x5,0x32,0x5,0x3a,0x5,0x3b,0x5,0x3c,0x5,0x3f,0x5,0x45,0x5,0x49,0x5,0x4b,0x5,0x4f,0x5,0x51,0x5,0x52,0x5,0x53,0x5,0x56,0x5,0x5a,0x5,0x1,0x4,0x9,0x4,0xf,0x4,0x13,0x4,0x18,0x4,0x1d,0x4,0x25,0x4,0x28,0x4,0x32,0x4,0x3d,0x4,0x3f,0x4,0x45,0x4,0x49,0x4,0x4b,0x4,0x4c,0x4,0x4d,0x4,0x4e,0x4,0x51,0x4,0x56,0x4,0x5a,0x4,0x1,0x3,0x9,0x3,0xf,0x3,0x13,0x3,0x18,0x3,0x1d,0x3,0x25,0x3,0x29,0x3,0x32,0x3,0x3d,0x3,0x3f,0x3,0x43,0x3,0x45,0x3,0x49,0x3,0x4b,0x3,0x4e,0x3,0x51,0x3,0x56,0x3,0x5a,0x3,0x1,0x2,0x9,0x2,0xa,0x2,0xb,0x2,0xc,0x2,0xd,0x2,0xf,0x2,0x13,0x2,0x18,0x2,0x1d,0x2,0x1e,0x2,0x1f,0x2,0x20,0x2,0x21,0x2,0x25,0x2,0x2a,0x2,0x30,0x2,0x31,0x2,0x32,0x2,0x33,0x2,0x34,0x2,0x39,0x2,0x3a,0x2,0x3b,0x2,0x3c,0x2,0x40,0x2,0x41,0x2,0x42,0x2,0x46,0x2,0x47,0x2,0x48,0x2,0x4b,0x2,0x4f,0x2,0x51,0x2,0x52,0x2,0x53,0x2,0x54,0x2,0x56,0x2,0x57,0x2,0x58,0x2,0x59,0x2

		constant    image_points_count=.180	; x2 for number of ints.
		constant    image_location=0x400	; Bank 4+
		
		constant    image_multiplier=.10
		constant    x_offset=0
		constant    y_offset=0
	
P1_Scored_Image_Setup
	; Load points from program memory
	lfsr	FSR0, image_location	; Load FSR0 with address in RAM	
	movlw	upper(image_points)
	movwf	TBLPTRU	
	movlw	high(image_points)
	movwf	TBLPTRH	
	movlw	low(image_points)
	movwf	TBLPTRL

	movlw	image_points_count
	movwf 	counter			; counter initialised to circle_sd_points_count
copy_points_loop
	tblrd*+			; one byte from PM to TABLAT, increment TBLPTR
	movff	TABLAT, POSTINC0
	tblrd*+			; one byte from PM to TABLAT, increment TBLPTR
	movff	TABLAT, POSTINC0
	decfsz	counter
	bra	copy_points_loop
	return
	
P1_Scored_Image_Plot
	lfsr	FSR1, image_location
	movlw	image_points_count
	movwf 	counter	
	
draw_image_loop
	movf	POSTINC1, W
	mullw	image_multiplier	    ; PRODH:PRODL
	movff	PRODH, circle_x + 1
	movff	PRODL, circle_x
	movf	POSTINC1, W
	mullw	image_multiplier	    ; PRODH:PRODL
	movff	PRODH, circle_y + 1
	movff	PRODL, circle_y
	
	movlb	.3
	
	movlw	low(x_offset)
	addwf	circle_x, BANKED
	movlw	high(x_offset)
	addwfc	circle_x + 1, BANKED
	
	movlw	low(y_offset)
	addwf	circle_y, BANKED
	movlw	high(y_offset)
	addwfc	circle_y + 1, BANKED
	
	movlw	2
	movwf	circle_divisor, BANKED
	call	Graphics_circle_lowd
	decfsz	counter
	bra	draw_image_loop
	
	
	return
	
	end

