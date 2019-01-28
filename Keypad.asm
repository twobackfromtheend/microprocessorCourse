#include p18f87k22.inc

    global  KP_Setup, KP_Read_Column, KP_Read_Row, KP_Read, KP_Decode, KP_Wait_For_Release, KP_Decode_Table

acs0    udata_acs   ; named variables in access ram
KP_cnt_l   res 1   ; reserve 1 byte for variable KP_cnt_l
KP_cnt_h   res 1   ; reserve 1 byte for variable KP_cnt_h
KP_cnt_ms  res 1   ; reserve 1 byte for ms counter
KP_cache   res 1   ; reserve 1 byte for cached row/column
;KP_table_data res 0x80    ; reserve 128 bytes for message data
KP_input_to_decode res 1
KP_char_address res 1
KP_decode_cache	res 1
KP_decode_cache_byte	res 1
KP_decode_index	res 1

KP	code
	
myTable data	    "123F456E789DA0BC"
    
KP_Setup
	movlb	.15
	bsf	PADCFG1, REPU, BANKED	; Set pull-ups to on for PORT E
	return
	
;KP_Move_Chars_To_Memory
;	lfsr	FSR0, KP_table_data	; Load FSR0 with address in RAM	
;	movlw	upper(myTable)	; address of data in PM
;	movwf	TBLPTRU		; load upper bits to TBLPTRU
;	movlw	high(myTable)	; address of data in PM
;	movwf	TBLPTRH		; load high byte to TBLPTRH
;	movlw	low(myTable)	; address of data in PM
;	movwf	TBLPTRL		; load low byte to TBLPTRL
;	movlw	myTable_l	; bytes to read
;	movwf 	counter		; our counter register
;loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter		; count down to zero
;	bra	loop		; keep going until finished
;		
;	movlw	myTable_l-1	; output message to LCD (leave out "\n")
	
KP_Read
	call	KP_Read_Column
	movff	PORTE, W
	andlw	b'00001111'
	movwf	KP_cache
	movff	PORTE, KP_cache
	
	call	KP_Read_Row
	movf	PORTE, W
	andlw	b'11110000'
	
	iorwf	KP_cache, 0		; value stored in W
	return
	
KP_Read_Column
	clrf	LATE
	movlw	0x0F
	movwf	TRISE			; Configure E 0-3 inputs, 4-7 outputs
	;	TODO: delay to allow output pins to settle
	movlw	.10
	call	KP_delay_ms
	return
	

KP_Read_Row
	clrf	LATE
	movlw	0xF0
	movwf	TRISE			; Configure E 0-3 outputs, 4-7 inputs
	;	TODO: delay to allow output pins to settle
	movlw	.1
	call	KP_delay_ms
	return

; Decode routines
	
; Value to decode stored in W
; Moves value to memory, compares with known values
; Sets FSR2 to character to write, W to 1
; W set to 0 if null input.
KP_Decode
	movwf	KP_input_to_decode
	
	movlw	b'11111111'
	cpfseq	KP_input_to_decode
	bra	__SKIP_0
	bra	null_write
__SKIP_0
	; 1
	movlw	b'11101110'
	cpfseq	KP_input_to_decode
	bra	__SKIP_1
	movlw	"1"
	bra	write_to_FSR_and_set_length_to_1
__SKIP_1
	; 2
	movlw	b'11101101'
	cpfseq	KP_input_to_decode
	bra	__SKIP_2
	movlw	"2"
	bra	write_to_FSR_and_set_length_to_1
__SKIP_2
	; 3
	movlw	b'11101011'
	cpfseq	KP_input_to_decode
	bra	__SKIP_3
	movlw	"3"
	bra	write_to_FSR_and_set_length_to_1
__SKIP_3
	nop  ; TODO: continue
null_write
	movlw	0
	return
write_to_FSR_and_set_length_to_1
	movwf	KP_char_address
	lfsr	FSR2, KP_char_address
	movlw	1
	return
	
KP_Wait_For_Release
	call	KP_Read
	comf	WREG, 0
	tstfsz	WREG
	bra	KP_Wait_For_Release
	return
	
KP_Decode_Table
	movwf	PORTD

	comf	WREG, W
	tstfsz	WREG
	bra	do_thing
	bra	null_write_table
do_thing 
	; Store W (value to decode) in cache
	movwf	KP_decode_cache
	; Read lower four (complement)
	call	KP_Read_One_Hot_Lower_Four_Bits
	movwf	KP_decode_cache_byte
	; Read upper four (complement)
	movf	KP_decode_cache, W	
	call	KP_Read_One_Hot_Upper_Four_Bits
	mullw	.4	; Result in PRODL
	; index = Upper Four * 4 + lower Four
	movf	PRODL, W
	addwf	KP_decode_cache_byte, W
	; Index in W

	movwf	KP_decode_index
	
	movlw	upper(myTable)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	
	movf	KP_decode_index, W

	tstfsz	WREG		; Handle index of 0
	bra	shift
	bra	_return
	
shift	tblrd*+
	decfsz	WREG
	bra	shift
	
;	movf	KP_decode_index, W
;	addwf	TBLPTRL, f
;	
;	movlw	0
;	addwfc	TBLPTRH, f
;	addwfc	TBLPTRU, f
	
_return	tblrd*
	movff	TABLAT, INDF2
	movlw	1
	return
null_write_table
	movlw	0
	return
	
	
	
KP_Read_One_Hot_Lower_Four_Bits ; Test for hot bit in W
	btfsc	WREG, 0
	retlw	0x00
	btfsc	WREG, 1
	retlw	0x01
	btfsc	WREG, 2
	retlw	0x02
	btfsc	WREG, 3
	retlw	0x03
	
KP_Read_One_Hot_Upper_Four_Bits ; Test for hot bit in W
	btfsc	WREG, 4
	retlw	0x00
	btfsc	WREG, 5
	retlw	0x01
	btfsc	WREG, 6
	retlw	0x02
	btfsc	WREG, 7
	retlw	0x03
	
	
	
; ** a few delay routines ****
KP_delay_ms		    ; delay given in ms in W
	movwf	KP_cnt_ms
lcdlp2	movlw	.250	    ; 1 ms delay
	call	KP_delay_x4us	
	decfsz	KP_cnt_ms
	bra	lcdlp2
	return
    
KP_delay_x4us		    ; delay given in chunks of 4 microsecond in W
	movwf	KP_cnt_l   ; now need to multiply by 16
	swapf   KP_cnt_l,F ; swap nibbles
	movlw	0x0f	    
	andwf	KP_cnt_l,W ; move low nibble to W
	movwf	KP_cnt_h   ; then to KP_cnt_h
	movlw	0xf0	    
	andwf	KP_cnt_l,F ; keep high nibble in KP_cnt_l
	call	KP_delay
	return

KP_delay			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1	decf 	KP_cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	KP_cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

    end