; file	wire1_temp2.asm   target ATmega128L-4MHz-STK300		
; purpose Dallas 1-wire(R) temperature sensor interfacing: temperature

.dseg
x1 :			.byte 1
y1 :			.byte 1
x2 :			.byte 1
y2 :			.byte 1
player:			.byte 1	; 1 = player 1		2 = player 2
battle:			.byte 1 ; 0 = placement		1 = battle
hit_count_1 :	.byte 1	; indique le nombre de pixels touchés par le joueur 1
hit_count_2 :	.byte 1 ; indique le nombre de pixels touchés par le joueur 2
game_over :		.byte 1 ; 1 si un joueur a gagné la partie. 0 sinon
pixel1 : 		.byte 3
pixel2 :		.byte 3
ov_count :		.byte 1 ; overflow counter 

.cseg 
.org 0
	jmp reset
.org	OVF0addr
	rjmp overflow0

.org 0x60

overflow0: 
	lds		_w, ov_count
	inc		_w
	cpi		_w, 10
	breq	timer_over
	sts		ov_count, _w
	reti

	timer_over :
	lds		_w, player
	cpi		_w, 1
	breq	PC+2
	rcall	restore_pixel_2
	cpi		_w, 2
	breq	PC+2
	rcall	restore_pixel_1	
	rcall	switch_player
	clr		_w
	sts		ov_count, _w
	reti
	
	
	

.include "battle.asm"

reset:
	LDSP	RAMEND			; Load Stack Pointer (SP)
	rcall	ws2812b4_init	; initialize led matrix
	rcall	UART0_init		
	OUTI	DDRB, 0xff		; connect LEDs to PORTB, output mode
	OUTI	DDRC, 0x00
	OUTI    PORTB, 0xfe
	OUTI	ASSR, (1<<AS0)
	OUTI	TIMSK,(1<<TOIE0)
	sei

	ldi		b0, 0x03 ; initial x position
	ldi		b1, 0x03 ; initial y position

	ldi		w, 1	; player 1 starts
	sts		player, w

	clr		w
	sts		battle, w
	sts		hit_count_1, w
	sts		hit_count_2, w
	sts		game_over, w
	sts		ov_count, w
	ldi		a0, 0
	ldi		a1, 0
	ldi		a2, 4
	sts		pixel1, a0 
	sts		pixel1+1, a1
	sts		pixel1+2, a2
	sts		pixel2, a0 
	sts		pixel2+1, a1
	sts		pixel2+2, a2
	clr		r1			; connect buttons to PORTC, input mode
	rcall   board_init	; board bleu avec bateau 1 au milieu
	rcall	battle_init_1
	rcall	battle_init_2
	rjmp	main
	

main :
 
	lds		w, game_over
	cpi		w, 1
	breq	restart

	lds		w, battle
	cpi		w, 1
	breq	PC+2
	rcall	boat_positions
	cpi		w, 0
	breq	PC+2
	rcall	bataille
	rjmp	main

	restart : 
	;jmp	winner_flashing
	rjmp	reset 































/*.include "macros.asm"		; include macro definitions
.include "definitions.asm"	; include register/constant definitions

; === initialization (reset) ===
reset:		
	LDSP	RAMEND				; load stack pointer (SP)
	;rcall	wire1_init			; initialize 1-wire(R) interface
	rcall	lcd_init			; initialize LCD
	rjmp	main

.include "lcd.asm"				; include LCD driver routines
.include "printf.asm"			; include formatted printing routines

; === main program ===
main:
	/*rcall	wire1_reset			; send a reset pulse
	CA	wire1_write, skipROM	; skip ROM identification
	CA	wire1_write, convertT	; initiate temp conversion 

	WAIT_MS	750					; wait 750 msec
	
	rcall	lcd_home			; place cursor to home position
	;rcall	wire1_reset			; send a reset pulse
	;CA	wire1_write, skipROM
	;CA	wire1_write, readScratchpad	
	;rcall	wire1_read			; read temperature LSB
	;mov	c0,a0
	;rcall	wire1_read			; read temperature MSB
	;mov	a1,a0
	;mov	a0,c0

	PRINTF	LCD
    .db	"micropenis ?",CR,0
	rjmp	main*/