#include p18f87k22.inc

	global	MainSetup, MainLoop

    
SPI_DAC code
 
 
SPI_DAC_Setup ; Set Clock edge to negative
	bcf	SSP2STAT, CKE
	; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
	movlw	(1<<SSPEN)|(1<<CKP)|(0x02)
	movwf	SSP2CON1
	; SDO2 output; SCK2 output
	bcf	TRISD, SDO2
	bcf	TRISD, SCK2
	
	bsf	TRISD, 7	; Sets LDAC pin high
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
	movf	POSTINC2, W	; skip to upper byte
	movf	POSTDEC, W	; move upper byte to W
	andlw	b'00001111'	; Mask upper bytes - only keep last 4 bits
	iorlw	b'01110000'	; (0) (buffered?) (1x gain?) (active) (... data)
	
	call	SPI_Transmit_W

	movf	INDF2, W
	call	SPI_Transmit_W
	
	bcf	TRISD, 7	; LDAC low edge (write)
	bsf	TRISD, 7
	return

	end


