#include p18f87k22.inc
#include constants.inc

    global  Game_Setup, Game_Loop, Game_Plot_Loop

    global  player_0_score, player_1_score


    extern  Ball_Step, ball_x, ball_y, ball_vx, ball_vy
    extern  Slime_Step
    extern  slime_0_x, slime_0_y, slime_0_vx, slime_0_vy
    extern  slime_1_x, slime_1_y, slime_1_vx, slime_1_vy

    extern  LCD_Setup, LCD_Write_Message, LCD_Clear, LCD_Cursor_To_Start, LCD_Cursor_To_Line_2
    extern  LCD_Write_Hex, LCD_Write_Hex_Message_2B
    extern  Graphics_wall, Graphics_net, Graphics_ball, Graphics_slimes, Graphics_scores


        extern  Compare_2B, compare_2B_1, compare_2B_2


    extern  Delay_With_Plot_s, Delay_s, Delay_ms, Delay_x4us, Delay_250_ns


    constant    ball_y_lava = wall_y_lower + ball_radius

acs0    udata_acs
player_0_score  res 1
player_1_score  res 1

last_player_scored  res 1


bank2   udata   0x200
; Used to store LCD messages
player_0_scored_message_ram res .16
player_1_scored_message_ram res .16
player_0_won_message_ram    res .13
player_1_won_message_ram    res .13

counter res 1       ; Used for writing messages from PM to RAM


pdata   code
player_0_scored_message data        "Player 0 scored!"
player_1_scored_message data        "Player 1 scored!"
    constant    player_scored_message_length=.16

player_0_won_message data       "Player 0 won!"
player_1_won_message data       "Player 1 won!"
    constant    player_won_message_length=.13


Game code

;;;;;       GAME SETUP          ;;;;;
;   Initialises game start state    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Game_Setup
    ; Set player scores to 0
    movlw   0
    movwf   player_0_score
    movwf   player_1_score

    ; Give player 0 the first serve (by setting last_player_scored to player 1)
    movlw   1
    movwf   last_player_scored

    ; Set game start state (ball and slime positions and velocities)
    call    Set_Game_Start_State

    ; Copy messages from PM to RAM
    call    Setup_Messages
    return

;;;;;       SETUP MESSAGES      ;;;;;
;   Copies "Player # scored/won!"   ;
;   messages from PM to RAM         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Setup_Messages
    movlb   2

    ; Copies player # scored messages to ram
    ; Points FSR0 to RAM address and TBLPTR to PM address,
    ;   read/writing then incrementing both.

    ; P0 scored
    lfsr    FSR0, player_0_scored_message_ram
    movlw   upper(player_0_scored_message)
    movwf   TBLPTRU
    movlw   high(player_0_scored_message)
    movwf   TBLPTRH
    movlw   low(player_0_scored_message)
    movwf   TBLPTRL
    movlw   player_scored_message_length
    movwf   counter, BANKED
write_0_scored_loop
    tblrd*+
    movff   TABLAT, POSTINC0
    decfsz  counter, BANKED
    bra write_0_scored_loop

    ; P1 scored
    lfsr    FSR0, player_1_scored_message_ram
    movlw   upper(player_1_scored_message)
    movwf   TBLPTRU
    movlw   high(player_1_scored_message)
    movwf   TBLPTRH
    movlw   low(player_1_scored_message)
    movwf   TBLPTRL
    movlw   player_scored_message_length
    movwf   counter, BANKED
write_1_scored_loop
    tblrd*+
    movff   TABLAT, POSTINC0
    decfsz  counter, BANKED
    bra write_1_scored_loop

    ; Copies player # won messages to ram (see above for explanation of method)
    ; P0 won
    lfsr    FSR0, player_0_won_message_ram
    movlw   upper(player_0_won_message)
    movwf   TBLPTRU
    movlw   high(player_0_won_message)
    movwf   TBLPTRH
    movlw   low(player_0_won_message)
    movwf   TBLPTRL
    movlw   player_won_message_length
    movwf   counter, BANKED
write_0_won_loop
    tblrd*+
    movff   TABLAT, POSTINC0
    decfsz  counter, BANKED
    bra write_0_won_loop

    ; P1 won
    lfsr    FSR0, player_1_won_message_ram
    movlw   upper(player_1_won_message)
    movwf   TBLPTRU
    movlw   high(player_1_won_message)
    movwf   TBLPTRH
    movlw   low(player_1_won_message)
    movwf   TBLPTRL
    movlw   player_won_message_length
    movwf   counter, BANKED
write_1_won_loop
    tblrd*+
    movff   TABLAT, POSTINC0
    decfsz  counter, BANKED
    bra write_1_won_loop

    return

;;;;;   SET GAME START STATE    ;;;;;
;   Sets slimes and ball            ;
;   positions and velocities        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Set_Game_Start_State
    ; Set slime starting x positions to provided constants
    movlw   low(slime_0_start_x)
    movwf   slime_0_x
    movlw   high(slime_0_start_x)
    movwf   slime_0_x + 1

    movlw   low(slime_1_start_x)
    movwf   slime_1_x
    movlw   high(slime_1_start_x)
    movwf   slime_1_x + 1

    ; Set all slimes' starting y and velocities to 0
    movlw   0
    movwf   slime_0_y
    movwf   slime_0_y + 1
    movwf   slime_1_y
    movwf   slime_1_y + 1

    movwf   slime_0_vx
    movwf   slime_0_vx + 1
    movwf   slime_1_vx
    movwf   slime_1_vx + 1
    movwf   slime_0_vy
    movwf   slime_0_vy + 1
    movwf   slime_1_vy
    movwf   slime_1_vy + 1

    ; BALL
    ; Set ball_x based on last_player_scored
    tstfsz  last_player_scored      ; Skip if player_0 scored last
    bra set_ball_x_on_player_0          ; Player 1 scored last
    bra set_ball_x_on_player_1          ; Loser's ball (player 0 scored last)

set_ball_x_on_player_0
    ; ball_x = slime_0_start_x
    movlw   low(slime_0_start_x)
    movwf   ball_x
    movlw   high(slime_0_start_x)
    movwf   ball_x + 1
    bra set_ball_x_end
set_ball_x_on_player_1
    ; ball_x = slime_1_start_x
    movlw   low(slime_1_start_x)
    movwf   ball_x
    movlw   high(slime_1_start_x)
    movwf   ball_x + 1
set_ball_x_end

    ; Drop ball from provided constant height (from rest)
    movlw   low(ball_start_y)
    movwf   ball_y
    movlw   high(ball_start_y)
    movwf   ball_y + 1

    movlw   0
    movwf   ball_vx
    movwf   ball_vx + 1
    movwf   ball_vy
    movwf   ball_vy + 1
    return


;;;;;       GAME LOOP       ;;;;;
;   Does 2 physics ticks,       ;
;   checks if point/game ends   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Game_Loop
    ; Physics ticks
    call    Ball_Step
    call    Slime_Step

    call    Ball_Step
    call    Slime_Step

    ; Post-tick cleanup
    call    Check_Point_End
    call    Write_Player_Scores_To_LCD

    call    Check_Game_End
    return

;;;;;       GAME PLOT LOOP      ;;;;;
;   Draws everything:               ;
;   ball, slimes,                   ;
;   scores,                         ;
;   wall, net - ends on net         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Game_Plot_Loop
    call    Graphics_ball
    call    Graphics_slimes
    call    Graphics_scores
    call    Graphics_wall
    call    Graphics_net
    return

;;;;;         CHECK POINT END           ;;;;;
;   Checks if ball_y is below ball_y_lava   ;
;   If so,                                  ;
;   Increments score count,                 ;
;   set last_player_scored,                 ;
;   prints message to LCD,                  ;
;   holds plot with delay,                  ;
;   resets game state                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Check_Point_End
    ; If ball_y < wall_y_lower + ball_radius (ball_y_lava)
    movff   ball_y, compare_2B_1
    movff   ball_y + 1, compare_2B_1 + 1

    movlw   low(ball_y_lava)
    movwf   compare_2B_2
    movlw   high(ball_y_lava)
    movwf   compare_2B_2 + 1

    call    Compare_2B          ; ball_y > ball_y_lava in W
    tstfsz  WREG                ; Skip if ball_y < ball_y_lava
    return

    ; Point ended
    ; If ball_x < net_x: player_1 wins
    movlw   low(net_x)
    movwf   compare_2B_1
    movlw   high(net_x)
    movwf   compare_2B_1 + 1

    movff   ball_x, compare_2B_2
    movff   ball_x + 1, compare_2B_2 + 1

    call    Compare_2B          ; net_x > ball_x in W
    tstfsz  WREG                ; Skip if net_x < ball_x
    bra player_1_scores
    bra player_0_scores

player_1_scores
    incf    player_1_score, f       ; Increment score
    movlw   1
    movwf   last_player_scored      ; Set last_player_scored

    ; Print scored message
    call    LCD_Clear
    lfsr    FSR2, player_1_scored_message_ram
    movlw   player_scored_message_length
    call    LCD_Write_Message
    bra post_point_cleanup

player_0_scores
    incf    player_0_score, f       ; Increment score
    movlw   0
    movwf   last_player_scored      ; Set last_player_scored

    ; Print scored message
    call    LCD_Clear
    lfsr    FSR2, player_0_scored_message_ram
    movlw   player_scored_message_length
    call    LCD_Write_Message

post_point_cleanup
    ; Hold last position for point_end_wait seconds
    movlw   point_end_wait
    call    Delay_With_Plot_s

    call    Set_Game_Start_State        ; Reset game state
    return


;;;;;       WRITE PLAYER SCORES TO LCD      ;;;;;
;   Writes player_0_score to line 1,            ;
;   player_1_score to line 2                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Write_Player_Scores_To_LCD
    call    LCD_Clear
    movf    player_0_score, W
    call    LCD_Write_Hex           ; Sufficient because score <= 6 (if score goes to 10, this will print "A" which might be undesirable.)
    call    LCD_Cursor_To_Line_2
    movf    player_1_score, W
    call    LCD_Write_Hex
    return


;;;;;               CHECK GAME END                  ;;;;;
;   Checks if either player_score = game_max_points     ;
;   If so,                                              ;
;       prints message to LCD,                          ;
;       holds plot with delay,                          ;
;       resets game state (game setup)                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Check_Game_End
    movlw   game_max_points
    cpfslt  player_0_score      ; Skip if score < max_points
    bra player_0_wins
    cpfslt  player_1_score      ; Skip if score < max_points
    bra player_1_wins
    return

player_0_wins
    call    LCD_Clear
    lfsr    FSR2, player_0_won_message_ram
    movlw   player_won_message_length
    call    LCD_Write_Message
    bra reset_point
player_1_wins
    call    LCD_Clear
    lfsr    FSR2, player_1_won_message_ram
    movlw   player_won_message_length
    call    LCD_Write_Message

reset_point
    movlw   game_end_wait
    call    Delay_With_Plot_s

    call    Game_Setup
    return


    end





