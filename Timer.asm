#include p18f87k22.inc

    global  Timer_Setup

    extern  Game_Loop, Game_Plot_Loop


Timer_Interrupt code    0x0008  ; high vector, no low vector
    btfss   INTCON, TMR0IF  ; check that this is timer0 interrupt
    retfie  FAST        ; if not then return

    call    Game_Loop

    bcf LATD, 7         ; Toggle bit 7 on PORTD
    call    Game_Plot_Loop
    bsf LATD, 7         ; Toggle bit 7 on PORTD (Trigger)

    bcf INTCON, TMR0IF  ; clear interrupt flag
    retfie  FAST        ; fast return from interrupt

Timer   code

Timer_Setup
    bcf TRISD, 7    ; Output on pin 7

;   movlw   b'10000000'
;   ; approx 8ms frame
;   movlw   b'10000011'
    ; approx 65ms frame
    movlw   b'10000010'
    ; approx 30ms frame

    movwf   T0CON
    bsf INTCON,TMR0IE   ; Enable timer0 interrupt
    bsf INTCON,GIE      ; Enable all interrupts
    return


    end