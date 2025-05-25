.include "drawing.asm"		
.include "uart.asm"

board_init : 
	_LDI r0, 64
	rcall	point_memory_placement

	loop2 : 
		ldi a0, 0x00        
		ldi a1, 0x00
		ldi a2, 0x04
		st z+, a0
		st z+, a1
		st z+, a2
		dec r0
		brne loop2
		   
	rcall	pixel_addr_bateau
	lds		w, player
	cpi		w, 2
	breq	PC+2
	rcall	boat_red
	cpi		w, 1
	breq	PC+2
	rcall	boat_green
	rcall	draw_board

ret

boat_red :
	clr		a3
	ldi		a0, 0x00        
	ldi		a1, 0x05
	ldi		a2, 0x00
	loop3:
		st     z+, a0
		st     z+, a1
		st     z+, a2       
		inc	   a3
		cpi	   a3, 0x03
		brne   loop3
	ret

boat_green : 
	clr	   a3
	ldi		a0, 0x005       
	ldi		a1, 0x00
	ldi		a2, 0x00
	loop5:
		st     z+, a0
		st     z+, a1
		st     z+, a2       
		inc	   a3
		cpi	   a3, 0x03
		brne   loop5
	ret
	

;//////////////////////////////////////////////////////////////////

boat_positions:

	sbic	UCSR0A,RXC0
	rcall   read_uart_boat
	ret

read_uart_boat:
	
	push w
	in	r0,UDR0

	ch1:
		_CPI r0, 'z'
		brne ch2
		rjmp move_up
	ch2:
		_CPI r0, 'q'
		brne ch3
		rjmp move_left
	ch3:
		_CPI r0, 's'
		brne ch4
		rjmp move_down
	ch4:
		_CPI r0, 'd'
		brne ch5
		rjmp move_right	

	ch5: 
		_CPI r0, 'c'
		brne PC+2
		rjmp confirm_pos
	fin:
		pop w
		ret


move_right : 
	pop w
	dec b0
	cpi b0, 0
	brne PC+2
	ldi b0, 1
	rjmp update

move_left : 
	pop w
	inc b0
	cpi b0, 7
	brne PC+2
	ldi b0, 6
	rjmp update

move_up : 
	pop w
	inc b1
	cpi b1, 8
	brne PC+2
	ldi b1, 7
	rjmp update

move_down : 
	pop w
	dec b1
	cpi b1, -1
	brne PC+2
	ldi b1, 0
	rjmp update

confirm_pos :
	pop		w
	lds		w, player 
	cpi		w, 2
	breq	PC+2
	rjmp	save_P1
	cpi		w, 1
	breq	PC+2
	rjmp	save_P2

save_P1 :

	sts		x1, b0
	sts		y1, b1
	ldi		b0, 3
	ldi		b1, 3
	ldi		w, 2
	sts		player, w
	ldi		w, 1
	rjmp	update


save_P2 :

	sts		x2, b0
	sts		y2, b1
	ldi		b0, 3
	ldi		b1, 3
	ldi		w, 1
	sts		player, w
	sts		battle, w
	OUTI	TCCR0,5   ; CS0=5  Clk/128


update : 
	rcall	point_memory_placement
    clr		r16           ; y = 0
    clr		r17           ; x = 0
	mov		b2, b0
	dec		b2
	mov		b3, b1

	row_loop_update:

		cpi    r16, 8
		breq   done_load     ; si y==8, on a fini
		clr    r17           ; x = 0 pour chaque nouvelle ligne

	col_loop_update:

		cpi		r17, 8
		breq	next_row_update      ; si x==8, ligne terminée
		cp		r16, b3  ; y correct
		brne	skip_pixel
		cp		r17, b2 ; x correct
		brne	skip_pixel
		push	r16
		lds		w, player
		cpi		w, 2
		breq	PC+2
		rcall	boat_red
		cpi		w, 1
		breq	PC+2
		rcall	boat_green
		pop		r16

		rjmp  inc_x

	skip_pixel:
		ldi a0, 0x00        
		ldi a1, 0x00
		ldi a2, 0x04
		st	z+, a0
		st  z+, a1
		st	z+, a2 

	inc_x:
		inc   r17
		rjmp  col_loop_update

	next_row_update:
		inc    r16           ; y++
		rjmp   row_loop_update

	done_load:
		clr    r17
		rcall   draw_board

ret
  

pixel_addr_bateau:
    ; --- y*24 = y*16 + y*8 -------------------------------
    mov   r18, b1         ; r18 = y
    lsl   r18              ; x2
    lsl   r18              ; x4
    lsl   r18              ; x8   (y*8)
    mov   r19, r18         ; r19 = y*8
    lsl   r18              ; x16 (=y*16)
    add   r18, r19         ; y*16 + y*8 = y*24
    ; --- x*3 = x + 2x ------------------------------------
    mov   r19, b0
	dec	  r19	
	mov	  r20, r19		   ; r19 = x
    lsl   r19              ; 2x
    add   r19, r20         ; 3x
    ; --- offset total ------------------------------------
    add   r18, r19   
	rcall point_memory_placement
	add	  zl, r18 
ret






