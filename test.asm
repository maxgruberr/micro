/*
 * test.asm
 *
 *  Created: 23/05/2025 15:22:34
 *   Author: IEM Courses
 */ 

.include "macros.asm"		; include macro definitions
.include "definitions.asm"

 .macro	WS2812b4_WR0
	clr u
	sbi PORTD, 1
	out PORTD, u
	nop
	nop
.endm


.macro	WS2812b4_WR1
	sbi PORTD, 1
	nop
	nop
	cbi PORTD, 1
	;nop	;deactivated on purpose of respecting timings
	;nop

.endm
	

	
board_init :  ; intialise la matrice toute en bleue

	_LDI r0, 64
	ldi zl,low(0x0400)
	ldi zh,high(0x0400)

	loop2 : 
		ldi a0, 0x00        
		ldi a1, 0x00
		ldi a2, 0x02
		st z+, a0
		st z+, a1
		st z+, a2
		dec r0
		brne loop2
		rjmp draw_board

draw_board : 

	ldi zl,low(0x0400)
	ldi zh,high(0x0400)
	_LDI	r0,64

loop4:

	ld a0, z+
	ld a1, z+		
	ld a2,z+
	cli
	rcall ws2812b4_byte3wr
	sei
	dec r0
	brne loop4
	rcall ws2812b4_reset
ret



ws2812b4_init:
	OUTI	DDRD,0x02
ret

; ws2812b4_byte3wr	; arg: a0,a1,a2 ; used: r16 (w)
; purpose: write contents of a0,a1,a2 (24 bit) into ws2812, 1 LED configuring
;     GBR color coding, LSB first
ws2812b4_byte3wr:

	ldi w,8
ws2b3_starta0:
	sbrc a0,7
	rjmp	ws2b3w1
	WS2812b4_WR0			; write a zero
	rjmp	ws2b3_nexta0
ws2b3w1:
	WS2812b4_WR1
ws2b3_nexta0:
	lsl a0
	dec	w
	brne ws2b3_starta0

	ldi w,8
ws2b3_starta1:
	sbrc a1,7
	rjmp	ws2b3w1a1
	WS2812b4_WR0			; write a zero
	rjmp	ws2b3_nexta1
ws2b3w1a1:
	WS2812b4_WR1
ws2b3_nexta1:
	lsl a1
	dec	w
	brne ws2b3_starta1

	ldi w,8
ws2b3_starta2:
	sbrc a2,7
	rjmp	ws2b3w1a2
	WS2812b4_WR0			; write a zero
	rjmp	ws2b3_nexta2
ws2b3w1a2:
	WS2812b4_WR1
ws2b3_nexta2:
	lsl a2
	dec	w
	brne ws2b3_starta2
	
ret

; ws2812b4_byte3wr	; arg: a0,a1,a2 ; used: r16 (w)
; purpose: write contents of a0,a1,a2 (24 bit) into ws2812, 1 LED configuring
;     GBR color coding, LSB first


; ws2812b4_reset	; arg: void; used: r16 (w)
; purpose: reset pulse, configuration becomes effective
ws2812b4_reset:
	cbi PORTD, 1
	WAIT_US	50 	; 50 us are required, NO smaller works
ret