#include p18f87k22.inc

    global  Delay_With_Plot_s, Delay_s, Delay_ms, Delay_x4us, Delay_250_ns
    
    extern  Game_Plot_Loop
    

acs0    udata_acs   ; named variables in access ram
delay_counter_low   res 1   ; reserve 1 byte for variable delay_counter_low
delay_counter_high  res 1   ; reserve 1 byte for variable delay_counter_high
delay_counter_ms    res 1   ; reserve 1 byte for ms counter
delay_counter_s     res 1

Delay   code

; Delays WREG seconds (inexact - actual duration = 840ms + 4x GamePlotLoops),
; calls Game_Plot_loop every 210ms (4 times for a delay of roughly 1s)
Delay_With_Plot_s
    movwf   delay_counter_s
delay_with_plot_s_loop
    bcf LATD, 7
    call    Game_Plot_Loop
    bsf LATD, 7
    movlw   .210
    call    Delay_ms
    
    bcf LATD, 7
    call    Game_Plot_Loop
    bsf LATD, 7
    movlw   .210
    call    Delay_ms
    
    bcf LATD, 7
    call    Game_Plot_Loop
    bsf LATD, 7
    movlw   .210
    call    Delay_ms
    
    bcf LATD, 7
    call    Game_Plot_Loop
    bsf LATD, 7
    movlw   .210
    call    Delay_ms
    
    decfsz  delay_counter_s
    bra delay_with_plot_s_loop
    return
    

; Below are derived from the provided LCD module, with minimal (mostly naming) changes .

; Delays WREG seconds
Delay_s
    movwf   delay_counter_s
delay_s_loop
    movlw   .250        ; 250 ms delay
    call    Delay_ms
    movlw   .250        ; 250 ms delay
    call    Delay_ms
    movlw   .250        ; 250 ms delay
    call    Delay_ms
    movlw   .250        ; 250 ms delay
    call    Delay_ms    
    decfsz  delay_counter_s
    bra delay_s_loop
    return
    
    
; Delays WREG milliseconds.
Delay_ms
    movwf   delay_counter_ms
delay_ms_loop
    movlw   .250        ; 1 ms delay
    call    Delay_x4us  
    decfsz  delay_counter_ms
    bra delay_ms_loop
    return
    
; Delays WREG x 4 microseconds
Delay_x4us
    movwf   delay_counter_low   ; now need to multiply by 16
    swapf   delay_counter_low,F ; swap nibbles
    movlw   0x0f        
    andwf   delay_counter_low,W ; move low nibble to W
    movwf   delay_counter_high   ; then to delay_counter_high
    movlw   0xf0        
    andwf   delay_counter_low,F ; keep high nibble in delay_counter_low
    call    Delay_250_ns
    return

Delay_250_ns            ; delay routine 4 instruction loop == 250ns     
    movlw   0x00        ; W=0
delay_loop_1
    decf    delay_counter_low,F ; no carry when 0x00 -> 0xff
    subwfb  delay_counter_high,F    ; no carry when 0x00 -> 0xff
    bc  delay_loop_1        ; carry, then loop again
    return          ; carry reset so return

    end





