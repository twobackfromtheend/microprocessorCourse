#include p18f87k22.inc
#include constants.inc

    global  Graphics_Setup
    global  Graphics_wall, Graphics_net, Graphics_ball, Graphics_slimes, Graphics_scores

    ; Exported for images
    global  Graphics_circle_lowd, circle_x, circle_y, circle_divisor

    extern  ball_x, ball_y
    extern  slime_0_x, slime_0_y, slime_1_x, slime_1_y

    extern  player_0_score, player_1_score

    extern  SPI_Transmit_W

    extern  Compare_2B, compare_2B_1, compare_2B_2


acs0    udata_acs
; temp_xORy are variables that hold the coordinates of the point plotted by Graphics_Plot_temp_xy
temp_x  res 2
temp_y  res 2

; circle_sd (and lowd and hd) are used to draw circles of varying resolution.
circle_sd_points_ram    res .22

counter     res 1   ; Used for copying of points from PM to RAM, Graphics_Slime_circle, Graphics_circle_lowd
counter_1   res 1   ; Used by Divide_W_by_2_cd - which in turn is used by Graphics_circle_sd and Graphics_circle_lowd

bank3   udata   0x300
; circle_xORy are variables that hold the coordinates of the circle plotted by Graphics_circle_sd and Graphics_circle_lowd
circle_x    res 2
circle_y    res 2
circle_divisor  res 1   ; Scaling factor for circles drawn by Graphics_circle_sd and Graphics_circle_lowd

draw_line_end   res 2   ; Argument for Graphics_draw_hline

; Store points used to draw a circle.
circle_hd_points_ram    res .44
circle_lowd_points_ram  res .6

counter_scores  res 1   ; Used for looping through points in drawing scores

    constant    wall_step = 0x30
    constant    slime_eye_offset = .200

    constant    scoreboard_height = .3200
    constant    scoreboard_left = .200
    constant    scoreboard_right = .4000 - scoreboard_left

    constant    scoreboard_padding = .250

Graphics code
circle_sd_points    db      .100,.0,.99,.16,.95,.31,.89,.45,.81,.59,.71,.71,.59,.81,.45,.89,.31,.95,.16,.99,.0,.100
    constant    circle_sd_points_count=.11  ; x2 for number of ints.
;circle_hd_points    db    .200,.5,.199,.16,.198,.26,.197,.36,.194,.47,.192,.57,.189,.67,.185,.77,.181,.86,.176,.95,.171,.104,.165,.113,.159,.122,.152,.130,.145,.138,.138,.145,.130,.152,.122,.159,.113,.165,.104,.171,.95,.176,.86,.181,.77,.185,.67,.189,.57,.192,.47,.194,.36,.197,.26,.198,.16,.199,.5,.200
;       constant    circle_hd_points_count=.30
;circle_hd_points    db     .100,.3,.100,.8,.99,.13,.98,.18,.97,.23,.96,.28,.94,.33,.92,.38,.90,.43,.88,.48,.85,.52,.82,.57,.79,.61,.76,.65,.73,.69,.69,.73,.65,.76,.61,.79,.57,.82,.52,.85,.48,.88,.43,.90,.38,.92,.33,.94,.28,.96,.23,.97,.18,.98,.13,.99,.8,.100,.3,.100
;       constant    circle_hd_points_count=.30
circle_hd_points    db  .100,.4,.99,.11,.98,.18,.97,.25,.95,.32,.92,.38,.89,.45,.86,.51,.82,.57,.78,.63,.73,.68,.68,.73,.63,.78,.57,.82,.51,.86,.45,.89,.38,.92,.32,.95,.25,.97,.18,.98,.11,.99,.4,.100
    constant    circle_hd_points_count=.22
circle_lowd_points  db  .97,.26,.71,.71,.26,.97
    constant    circle_lowd_points_count=.3

    constant    slime_radius_multiplier=.4


Graphics_Setup
    ; Load circle_sd_points from program memory
    lfsr    FSR0, circle_sd_points_ram  ; Load FSR0 with address in RAM
    movlw   upper(circle_sd_points)
    movwf   TBLPTRU
    movlw   high(circle_sd_points)
    movwf   TBLPTRH
    movlw   low(circle_sd_points)
    movwf   TBLPTRL

    movlw   circle_sd_points_count
    movwf   counter         ; counter initialised to circle_sd_points_count
copy_circle_sd_points_loop
    tblrd*+         ; one byte from PM to TABLAT, increment TBLPTR
    movff   TABLAT, POSTINC0
    tblrd*+         ; one byte from PM to TABLAT, increment TBLPTR
    movff   TABLAT, POSTINC0
    decfsz  counter
    bra copy_circle_sd_points_loop

    ; Load circle_hd_points from program memory
    lfsr    FSR0, circle_hd_points_ram  ; Load FSR0 with address in RAM
    movlw   upper(circle_hd_points)
    movwf   TBLPTRU
    movlw   high(circle_hd_points)
    movwf   TBLPTRH
    movlw   low(circle_hd_points)
    movwf   TBLPTRL

    movlw   circle_hd_points_count
    movwf   counter         ; counter initialised to circle_hd_points_count
copy_circle_hd_points_loop
    tblrd*+         ; one byte from PM to TABLAT, increment TBLPTR
    movff   TABLAT, POSTINC0
    tblrd*+         ; one byte from PM to TABLAT, increment TBLPTR
    movff   TABLAT, POSTINC0
    decfsz  counter
    bra copy_circle_hd_points_loop


    ; Load circle_low_points from program memory
    lfsr    FSR0, circle_lowd_points_ram    ; Load FSR0 with address in RAM
    movlw   upper(circle_lowd_points)
    movwf   TBLPTRU
    movlw   high(circle_lowd_points)
    movwf   TBLPTRH
    movlw   low(circle_lowd_points)
    movwf   TBLPTRL

    movlw   circle_lowd_points_count
    movwf   counter         ; counter initialised to circle_hd_points_count
copy_circle_lowd_points_loop
    tblrd*+         ; one byte from PM to TABLAT, increment TBLPTR
    movff   TABLAT, POSTINC0
    tblrd*+         ; one byte from PM to TABLAT, increment TBLPTR
    movff   TABLAT, POSTINC0
    decfsz  counter
    bra copy_circle_lowd_points_loop
    return


;;;;;       GRAPHICS WALL           ;;;;;
;   Draws walls by inc/decrementing     ;
;   temp_xORy with wall_step            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_wall
    ; Constants are in 2's complement.
    ; But because they're positive, can be used as-is.
;   1   (wall_x_lower, wall_y_lower)
;   2   (wall_x_lower, wall_y_higher)
;   3   (wall_x_higher, wall_y_higher)
;   4   (wall_x_higher, wall_y_lower)
;   5=1 (wall_x_lower, wall_y_lower)

    ; Initialise to point 1.
    movlw   wall_x_lower
    movwf   temp_x
    movlw   wall_y_lower
    movwf   temp_y
    movlw   0
    movwf   temp_x + 1
    movwf   temp_y + 1

    ; Increase y to point 2.
p1_p2   call    Graphics_Plot_temp_xy
    movlw   wall_step
    addwf   temp_y, f
    movlw   0
    addwfc  temp_y + 1

    movlw   low(wall_y_higher)      ; If temp_y < wall_y_higher: loop
    movwf   compare_2B_1
    movlw   high(wall_y_higher)
    movwf   compare_2B_1 + 1        ; 2B_1 = wall_y_higher
    movff   temp_y, compare_2B_2
    movff   temp_y + 1, compare_2B_2 + 1    ; 2B_2 = temp_y
    call    Compare_2B
    tstfsz  WREG        ; Skip if 2B_1 (wall_y_higher) <= 2B_2 (temp_y)
    bra p1_p2

    movlw   high(wall_y_higher)     ; Set temp_y = wall_y_higher (prevent overflow)
    movwf   temp_y + 1
    movlw   low(wall_y_higher)
    movwf   temp_y

    ; Increase x to point 3
p2_p3   call    Graphics_Plot_temp_xy
    movlw   wall_step
    addwf   temp_x, f
    movlw   0
    addwfc  temp_x + 1

    movlw   low(wall_x_higher)      ; If temp_x < wall_x_higher: loop
    movwf   compare_2B_1
    movlw   high(wall_x_higher)
    movwf   compare_2B_1 + 1        ; 2B_1 = wall_x_higher
    movff   temp_x, compare_2B_2
    movff   temp_x + 1, compare_2B_2 + 1    ; 2B_2 = temp_x
    call    Compare_2B
    tstfsz  WREG        ; Skip if 2B_1 (wall_x_higher) <= 2B_2 (temp_x)
    bra p2_p3

    movlw   high(wall_x_higher)     ; Set temp_x = wall_x_higher (prevent overflow)
    movwf   temp_x + 1
    movlw   low(wall_x_higher)
    movwf   temp_x

    ; Decrease y to point 4
p3_p4   call    Graphics_Plot_temp_xy
    movlw   wall_step
    subwf   temp_y, f
    movlw   0
    subwfb  temp_y + 1

    ; If temp_y > wall_y_lower: loop
    tstfsz  temp_y + 1          ; Skip if upper byte 0
    bra p3_p4
    movlw   wall_y_lower
    cpfsgt  temp_y              ; Skip if f (temp_y) < W (wall_y_lower)
    bra p3_p4
    movwf   temp_y              ; Set temp_y to wall_y_lower (prevent overflow)

    ; Decrease x to point 5 (=1)
p4_p1   call    Graphics_Plot_temp_xy
    movlw   wall_step
    subwf   temp_x, f
    movlw   0
    subwfb  temp_x + 1

    ; If temp_x > wall_x_lower: loop
    tstfsz  temp_x + 1          ; Skip if upper byte 0
    bra p4_p1
    movlw   wall_x_lower
    cpfsgt  temp_x              ; Skip if f (temp_x) < W (wall_x_lower)
    bra p4_p1
    movwf   temp_x              ; Set temp_x to wall_x_lower (prevent overflow)

    return


;;;;;       GRAPHICS NET        ;;;;;
;   Draws net by incrementing y     ;
;   with wall_step                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_net
    ; Start temp_xy at bottom of net
    movlw   low(net_x)
    movwf   temp_x
    movlw   high(net_x)
    movwf   temp_x + 1
    movlw   0
    movwf   temp_y
    movwf   temp_y + 1

    ; Increase temp_y until net_height
draw_net
    call    Graphics_Plot_temp_xy
    movlw   wall_step
    addwf   temp_y, f
    movlw   0
    addwfc  temp_y + 1

    movlw   low(net_height)     ; If temp_y < net_height: loop
    movwf   compare_2B_1
    movlw   high(net_height)
    movwf   compare_2B_1 + 1        ; 2B_1 = net_height
    movff   temp_y, compare_2B_2
    movff   temp_y + 1, compare_2B_2 + 1    ; 2B_2 = temp_y
    call    Compare_2B
    tstfsz  WREG        ; Skip if 2B_1 (wall_y_higher) <= 2B_2 (temp_y)
    bra draw_net

    return


Graphics_ball
    movff   ball_x, circle_x
    movff   ball_x + 1, circle_x + 1
    movff   ball_y, circle_y
    movff   ball_y + 1, circle_y + 1
    movlw   0
    movwf   circle_divisor
    call    Graphics_circle_sd
    return

; Draws the ball as a point.
; Used for testing.
Graphics_ball_point
    ; Write ball_x to chip 1: CS (pin 1) low
    bcf LATD, 1     ; CS1 low - allow write
    movf    ball_x + 1, W   ; move upper byte to W
    andlw   b'00001111' ; Mask upper bytes - only keep last 4 bits
    iorlw   b'01110000' ; (0) (buffered?) (1x gain?) (active) (... data)
    call    SPI_Transmit_W
    movf    ball_x, W
    call    SPI_Transmit_W
    bsf LATD, 1     ; CS1 raise

    ; Write ball_y to chip 2: CS (pin 2) low
    bcf LATD, 2     ; CS2 low - allow write
    movf    ball_y + 1, W   ; move upper byte to W
    andlw   b'00001111' ; Mask upper bytes - only keep last 4 bits
    iorlw   b'01110000' ; (0) (buffered?) (1x gain?) (active) (... data)
    call    SPI_Transmit_W
    movf    ball_y, W
    call    SPI_Transmit_W
    bsf LATD, 2     ; CS2 raise

    movlw   1
;   call    LCD_delay_x4us

    bcf LATD, 0     ; LDAC low edge (write)
;   call    LCD_delay_x4us
    bsf LATD, 0
    return


; Draws slimes.
Graphics_slimes
    call    Graphics_slime_0
    call    Graphics_slime_1
    return


;;;;;       DRAW SLIME 0 GRAPHICS       ;;;;;
;   Sets circle_xORy to slime_0_xORy        ;
;   Calls Graphics_Slime_circle.            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_slime_0
    movff   slime_0_x, circle_x
    movff   slime_0_x + 1, circle_x + 1
    movff   slime_0_y, circle_y
    movff   slime_0_y + 1, circle_y + 1
    call    Graphics_Slime_circle
    return

;;;;;       DRAW SLIME 1 GRAPHICS       ;;;;;
;   Sets circle_xORy to slime_1_xORy        ;
;   Calls Graphics_Slime_circle.            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_slime_1
    movff   slime_1_x, circle_x
    movff   slime_1_x + 1, circle_x + 1
    movff   slime_1_y, circle_y
    movff   slime_1_y + 1, circle_y + 1
    call    Graphics_Slime_circle
    return

;;;;;       GRAPHICS PLOT TEMPXY        ;;;;;
;   Sends the values in temp_x and temp_y   ;
;   through the DACs.                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_Plot_temp_xy
    ; Write temp_x to chip 1: CS (pin 1) low
    bcf LATD, 1     ; CS1 low - allow write
    movf    temp_x + 1, W   ; move upper byte to W
    andlw   b'00001111' ; Mask upper bytes - only keep last 4 bits
    iorlw   b'01110000' ; (0) (buffered?) (1x gain?) (active) (... data)
    call    SPI_Transmit_W
    movf    temp_x, W
    call    SPI_Transmit_W
    bsf LATD, 1     ; CS1 raise

    ; Write temp_y to chip 2: CS (pin 2) low
    bcf LATD, 2     ; CS2 low - allow write
    movf    temp_y + 1, W   ; move upper byte to W
    andlw   b'00001111' ; Mask upper bytes - only keep last 4 bits
    iorlw   b'01110000' ; (0) (buffered?) (1x gain?) (active) (... data)
    call    SPI_Transmit_W
    movf    temp_y, W
    call    SPI_Transmit_W
    bsf LATD, 2     ; CS2 raise

    ; LDAC low edge (write)
    bcf LATD, 0
    bsf LATD, 0
    return

;;;;;       GRAPHICS SLIME CIRCLE       ;;;;;
;   Draws slime positioned at circle_xANDy  ;
;   (draws eye depending on slime position) ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_Slime_circle
    ; Draw +x+y quadrant
    ; Draws circle by looping through circle_hd_points, using the points as offsets.
    lfsr    FSR0, circle_hd_points_ram
    movlw   circle_hd_points_count
    movwf   counter
draw_slime_pxpy
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1

    movf    POSTINC0, W     ; x-offset
    mullw   slime_radius_multiplier         ; PRODH:PRODL
    movf    PRODL, W
    addwf   temp_x
    movf    PRODH, W
    addwfc  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    mullw   slime_radius_multiplier         ; PRODH:PRODL
    movf    PRODL, W
    addwf   temp_y
    movf    PRODH, W
    addwfc  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_slime_pxpy

;   ; Draw -x+y quadrant
    lfsr    FSR0, circle_hd_points_ram
    movlw   circle_hd_points_count
    movwf   counter
draw_slime_nxpy
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    mullw   slime_radius_multiplier         ; PRODH:PRODL
    movf    PRODL, W
    subwf   temp_x
    movf    PRODH, W
    subwfb  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    mullw   slime_radius_multiplier         ; PRODH:PRODL
    movf    PRODL, W
    addwf   temp_y
    movf    PRODH, W
    addwfc  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_slime_nxpy


    movlb   3

    ; Draw base
    ; set temp_x, temp_y to left of slime, set draw_line_end to right of slime
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1

    movlw   low(slime_radius)
    subwf   temp_x, f
    movlw   high(slime_radius)
    subwfb  temp_x + 1, f

    movff   circle_x, draw_line_end
    movff   circle_x + 1, draw_line_end + 1

    movlw   low(slime_radius)
    addwf   draw_line_end, f, BANKED
    movlw   high(slime_radius)
    addwfc  draw_line_end + 1, f, BANKED

    call    Graphics_draw_hline

    ; Draw eye
    movlw   slime_eye_offset
    addwf   circle_y, BANKED
    movlw   0
    addwfc  circle_y + 1, BANKED

    movff   circle_x, compare_2B_1
    movff   circle_x + 1, compare_2B_1 + 1
    movlw   low(net_x)
    movwf   compare_2B_2
    movlw   high(net_x)
    movwf   compare_2B_2 + 1
    call    Compare_2B          ; bool(circle_x > net_x) in W
    tstfsz  WREG                ; Skip if circle_x < net_x
    bra offset_right_slime_eye
    bra offset_left_slime_eye

offset_left_slime_eye
    movlw   slime_eye_offset
    addwf   circle_x, BANKED
    movlw   0
    addwfc  circle_x + 1, BANKED
    bra draw_eye_and_pupil
offset_right_slime_eye
    movlw   slime_eye_offset
    subwf   circle_x, BANKED
    movlw   0
    subwfb  circle_x + 1, BANKED

    ; Draw eye
draw_eye_and_pupil
    ; big eye
    movlw   0
    movwf   circle_divisor, BANKED
    call    Graphics_circle_lowd
    ; pupil
    movlw   2
    movwf   circle_divisor, BANKED
    call    Graphics_circle_lowd


    return

;;;;;       GRAPHICS CIRCLE SD      ;;;;;
;   Draws circle (SD) at circle_xANDy   ;
;   scaled down by 2^circle_divisor     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_circle_sd
    ; Draw +x+y quadrant
    ; Draws circle by looping through circle_sd_points, using the points as offsets.
    lfsr    FSR0, circle_sd_points_ram
    movlw   circle_sd_points_count
    movwf   counter
draw_circle_pxpy
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1

    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    addwf   temp_x
    movlw   0
    addwfc  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    addwf   temp_y
    movlw   0
    addwfc  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_pxpy

    ; Draw +x-y quadrant
    lfsr    FSR0, circle_sd_points_ram
    movlw   circle_sd_points_count
    movwf   counter
draw_circle_pxny
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    addwf   temp_x
    movlw   0
    addwfc  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    subwf   temp_y
    movlw   0
    subwfb  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_pxny

    ; Draw -x-y quadrant
    lfsr    FSR0, circle_sd_points_ram
    movlw   circle_sd_points_count
    movwf   counter
draw_circle_nxny
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    subwf   temp_x
    movlw   0
    subwfb  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    subwf   temp_y
    movlw   0
    subwfb  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_nxny

    ; Draw -x+y quadrant
    lfsr    FSR0, circle_sd_points_ram
    movlw   circle_sd_points_count
    movwf   counter
draw_circle_nxpy
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    subwf   temp_x
    movlw   0
    subwfb  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    addwf   temp_y
    movlw   0
    addwfc  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_nxpy

    return


;;;;;       DIVIDE W BY 2 CD        ;;;;;
;   Divides W by 2 ^ circle_divisor     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Divide_W_by_2_cd
    tstfsz  circle_divisor      ; Handle circle_divisor = 0 case
    bra do_divide
    return
do_divide
    movff   circle_divisor, counter_1
divide_loop
    bcf STATUS, C       ; Clear carry flag
    rrcf    WREG, W
    decfsz  counter_1, f
    bra divide_loop
    return


;;;;;           GRAPHICS DRAW HLINE             ;;;;;
;   Draws horizontal line starting at temp_x        ;
;   Increments by wall_step until draw_line_end     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_draw_hline
    ; Increase temp_x until draw_line_end
draw_line
    call    Graphics_Plot_temp_xy
    movlw   wall_step
    addwf   temp_x, f
    movlw   0
    addwfc  temp_x + 1

    movff   draw_line_end, compare_2B_1
    movff   draw_line_end + 1, compare_2B_1 + 1 ; 2B_1 = draw_line_end
    movff   temp_x, compare_2B_2
    movff   temp_x + 1, compare_2B_2 + 1        ; 2B_2 = temp_x
    call    Compare_2B              ; (draw_line_end > temp_x) in W
    tstfsz  WREG                    ; Skip if draw_line_end <= temp_x
    bra draw_line
    return

;;;;;       GRAPHICS SCORES         ;;;;;
;   Draws scoreboard:                   ;
;       draws circle_lowd as outline,   ;
;       fills with circle_divisor = 2   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_scores
    movlb   .3

    ; Player 0 score
    ; Start from left
    movlw   low(scoreboard_height)
    movwf   circle_y, BANKED
    movlw   high(scoreboard_height)
    movwf   circle_y + 1, BANKED

    movlw   low(scoreboard_left)
    movwf   circle_x, BANKED
    movlw   high(scoreboard_left)
    movwf   circle_x + 1, BANKED

    ; Set counter_scores to game_max_points, decrement to zero, plotting empty circle
    movlw   1
    movwf   counter_scores, BANKED

player_0_score_loop
    movlw   1
    movwf   circle_divisor, BANKED
    call    Graphics_circle_lowd

    ; If counter_scores <= player_0_score, fill circle
    movlw   2
    movwf   circle_divisor, BANKED
    movf    player_0_score, W
    cpfsgt  counter_scores, BANKED      ; Skip if counter_scores > player_0_score
    call    Graphics_circle_lowd        ; Fill circle if counter_scores <= player_0_score

    ; Shift to next circle
    movlw   low(scoreboard_padding)
    addwf   circle_x, f, BANKED
    movlw   high(scoreboard_padding)
    addwfc  circle_x + 1, BANKED

    incf    counter_scores, f, BANKED
    movlw   game_max_points
    cpfsgt  counter_scores          ; Skip if counter_scores > game_max_points
    bra player_0_score_loop


    ; PLAYER 1 SCORE
    ; Start from right
    movlw   low(scoreboard_height)
    movwf   circle_y, BANKED
    movlw   high(scoreboard_height)
    movwf   circle_y + 1, BANKED

    movlw   low(scoreboard_right)
    movwf   circle_x, BANKED
    movlw   high(scoreboard_right)
    movwf   circle_x + 1, BANKED

    movlw   1
    movwf   counter_scores, BANKED

player_1_score_loop
    movlw   1
    movwf   circle_divisor, BANKED
    call    Graphics_circle_lowd

    ; If counter_scores <= player_0_score, fill circle
    movlw   2
    movwf   circle_divisor, BANKED
    movf    player_1_score, W
    cpfsgt  counter_scores, BANKED      ; Skip if counter_scores > player_1_score
    call    Graphics_circle_lowd        ; Fill circle if counter_scores <= player_1_score

    ; Shift to next circle
    movlw   low(scoreboard_padding)
    subwf   circle_x, f, BANKED
    movlw   high(scoreboard_padding)
    subwfb  circle_x + 1, BANKED

    incf    counter_scores, f, BANKED
    movlw   game_max_points
    cpfsgt  counter_scores          ; Skip if counter_scores > game_max_points
    bra player_1_score_loop
    return


;;;;;       GRAPHICS CIRCLE LOWD        ;;;;;
;   Draws circle (lowd) at circle_xANDy     ;
;   scaled down by 2^circle_divisor         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Graphics_circle_lowd
    ; Draw +x+y quadrant
    ; Draws circle by looping through circle_lowd_points, using the points as offsets.
    lfsr    FSR0, circle_lowd_points_ram
    movlw   circle_lowd_points_count
    movwf   counter
draw_circle_lowd_pxpy
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1

    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    addwf   temp_x
    movlw   0
    addwfc  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    addwf   temp_y
    movlw   0
    addwfc  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_lowd_pxpy

    ; Draw +x-y quadrant
    lfsr    FSR0, circle_lowd_points_ram
    movlw   circle_lowd_points_count
    movwf   counter
draw_circle_lowd_pxny
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    addwf   temp_x
    movlw   0
    addwfc  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    subwf   temp_y
    movlw   0
    subwfb  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_lowd_pxny

    ; Draw -x-y quadrant
    lfsr    FSR0, circle_lowd_points_ram
    movlw   circle_lowd_points_count
    movwf   counter
draw_circle_lowd_nxny
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    subwf   temp_x
    movlw   0
    subwfb  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    subwf   temp_y
    movlw   0
    subwfb  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_lowd_nxny

    ; Draw -x+y quadrant
    lfsr    FSR0, circle_lowd_points_ram
    movlw   circle_lowd_points_count
    movwf   counter
draw_circle_lowd_nxpy
    movff   circle_x, temp_x
    movff   circle_x + 1, temp_x + 1
    movff   circle_y, temp_y
    movff   circle_y + 1, temp_y + 1
    movf    POSTINC0, W     ; x-offset
    call    Divide_W_by_2_cd
    subwf   temp_x
    movlw   0
    subwfb  temp_x + 1
    movf    POSTINC0, W     ; y-offset
    call    Divide_W_by_2_cd
    addwf   temp_y
    movlw   0
    addwfc  temp_y + 1
    call    Graphics_Plot_temp_xy
    decfsz  counter
    bra draw_circle_lowd_nxpy
    return


    end





