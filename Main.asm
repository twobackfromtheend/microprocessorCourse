#include p18f87k22.inc

    global  Main_Setup

    extern  Ball_Step, ball_x, ball_y, ball_vx, ball_vy
    extern  slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
    extern  slime_1_x, slime_1_y, slime_1_vx, slime_1_vy

    extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2, LCD_Write_Hex_Message_2B
    extern  LCD_delay_ms
    extern  SPI_DAC_Setup
    extern  Graphics_Setup, Graphics_wall, Graphics_ball, Graphics_slimes

Main code

;;;;;       MAIN SETUP          ;;;;;
;   Calls required hardware setups  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Main_Setup
    movlb   1

    call    LCD_Setup
    call    SPI_DAC_Setup
;   call    SPI_DAC_Test
    call    Graphics_Setup
;   call    Graphics_wall_Test
;   call    Graphics_ball_wall_Test
    return


;;;;;    TEST Graphics_wall     ;;;;;
;   Calls Graphics_wall repeatedly  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_wall_Test
    call    Graphics_wall
    bra Graphics_wall_Test
    return

;;;;;    TEST Graphics_ball and wall    ;;;;;
;   Calls Graphics_ball and wall repeatedly ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_ball_wall_Test
    movlw   0
    movwf   ball_x
    movwf   ball_y
    movlw   0x08
    movwf   ball_x + 1
    movwf   ball_y + 1
    call    Graphics_wall
    call    Graphics_ball
    bra Graphics_ball_wall_Test
    return

    end