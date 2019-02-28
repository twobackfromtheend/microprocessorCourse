#include p18f87k22.inc

    global  SPI_DAC_Setup, SPI_Transmit_W

    extern  ball_x, ball_y

    extern  Delay_s, Delay_ms, Delay_x4us, Delay_250_ns

SPI_DAC code


SPI_DAC_Setup ; Set Clock edge to idle-to-active
    bcf SSP2STAT, CKE
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw   (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf   SSP2CON1
    ; SDO2 output; SCK2 output
    bcf TRISD, SDO2
    bcf TRISD, SCK2

    bcf TRISD, 0    ; Output on pin 0
    bsf LATD, 0     ; Sets LDAC pin high
    bcf TRISD, 1    ; Output on pin 1
    bsf LATD, 1     ; Sets CS pin high
    bcf TRISD, 2    ; Output on pin 1
    bsf LATD, 2     ; Sets CS pin high

    return


SPI_Transmit_W ; Start transmission of data (held in W)
    movwf   SSP2BUF
Wait_Transmit ; Wait for transmission to complete
    btfss   PIR2, SSP2IF
    bra Wait_Transmit
    bcf PIR2, SSP2IF ; clear interrupt flag
    return

    end


