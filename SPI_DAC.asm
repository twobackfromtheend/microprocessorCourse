#include p18f87k22.inc

	global	SPI_DAC_Setup, SPI_Transmit_12b, SPI_Transmit_W
	global	SPI_Transmit_ball_xy
	
	extern	ball_x, ball_y
    
	extern	Delay_s, Delay_ms, Delay_x4us, Delay_250_ns

SPI_DAC code
 
 
SPI_DAC_Setup ; Set Clock edge to idle-to-active
	bcf	SSP2STAT, CKE
	; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
	movlw	(1<<SSPEN)|(1<<CKP)|(0x02)
	movwf	SSP2CON1
	; SDO2 output; SCK2 output
	bcf	TRISD, SDO2
	bcf	TRISD, SCK2
	
	bcf	TRISD, 0	; Output on pin 0
	bsf	LATD, 0		; Sets LDAC pin high
	bcf	TRISD, 1	; Output on pin 1
	bsf	LATD, 1		; Sets CS pin high
	bcf	TRISD, 2	; Output on pin 1
	bsf	LATD, 2		; Sets CS pin high

	return

 
 
SPI_Transmit_W ; Start transmission of data (held in W)
	movwf	SSP2BUF
Wait_Transmit ; Wait for transmission to complete
	btfss	PIR2, SSP2IF
	bra	Wait_Transmit
	bcf	PIR2, SSP2IF ; clear interrupt flag
	return

; Transmit 2 bytes from FSR2
; Sets write low (and back to high)
SPI_Transmit_12b
	bcf	LATD, 1		; CS low - allow write
	
	movf	POSTINC2, W	; skip to upper byte
	movf	POSTDEC2, W	; move upper byte to W
	andlw	b'00001111'	; Mask upper bytes - only keep last 4 bits
	iorlw	b'01110000'	; (0) (buffered?) (1x gain?) (active) (... data)
	
	call	SPI_Transmit_W

	movf	INDF2, W
	call	SPI_Transmit_W
	
	bsf	LATD, 1		; CS raise
	movlw	1
	call	Delay_x4us

	bcf	LATD, 0		; LDAC low edge (write)
	call	Delay_x4us
	bsf	LATD, 0
	return


SPI_Transmit_ball_xy
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
	call	Delay_x4us

	bcf	LATD, 0		; LDAC low edge (write)
	call	Delay_x4us
	bsf	LATD, 0		
	return
	

	end


