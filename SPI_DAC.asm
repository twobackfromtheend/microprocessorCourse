#include p18f87k22.inc

	global	SPI_DAC_Setup, SPI_Transmit_12b
	
	
	extern	LCD_delay_x4us
    
SPI_DAC code
 
 
SPI_DAC_Setup ; Set Clock edge to idle-to-active
	bcf	SSP2STAT, CKE
	; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
	movlw	(1<<SSPEN)|(0<<CKP)|(0x02)
	movwf	SSP2CON1
	; SDO2 output; SCK2 output
	bcf	TRISD, SDO2
	bcf	TRISD, SCK2
	
	bcf	TRISD, 0	; Output on pin 0
	bsf	LATD, 0		; Sets LDAC pin high
	bcf	TRISD, 1	; Output on pin 1
	bsf	LATD, 1		; Sets CS pin high

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
	call	LCD_delay_x4us

	
	
	
	bcf	LATD, 0		; LDAC low edge (write)
	call	LCD_delay_x4us
	bsf	LATD, 0
	return

	end


