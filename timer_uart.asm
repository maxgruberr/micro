/*
 * timer_uart.asm
 *
 *  Created: 22.05.2025 17:13:31
 *   Author: mmgruber
 */ 
 ; timer_uart_lcd.asm
; But : Lire un nombre décimal via UART, décompter chaque seconde, afficher sur LCD

.include "macros.asm"
.include "definitions.asm"
.include "lcd.asm"
.include "uart.asm"      ; depuis ghaxs21/Microcontroleurs
.include "printf.asm"

.org 0
	rjmp reset

reset:
    LDSP RAMEND
    rcall UART_init     ; UART 9600 bauds (voir uart.asm)
    rcall LCD_init
    rcall LCD_clear
	rcall prompt_time_entry
	rcall countdown_timer
	rjmp .
main:
    rcall LCD_clear
    rcall UART_print_string
    .db "Enter seconds:",CR,0

    rcall get_number_ascii_uart  ; r18 ? secondes

    rcall LCD_clear
    loop_countdown:
        mov temp, seconds
        rcall LCD_clear
        rcall print_number_to_lcd

        ldi temp2, 100
        wait_1s:
            WAIT_MS 10
            dec temp2
            brne wait_1s

        dec seconds
        brne loop_countdown

    rjmp main

; ----- Sous-routines -----

; Lecture d'un nombre ASCII via UART, le stocke dans r18
; Ex: "12" -> 0x0C dans r18
get_number_ascii_uart:
    clr r18
get_char_loop:
    rcall UART_getchar_blocking
    cpi r16, 13            ; Entrée (CR)?
    breq get_number_done
    subi r16, '0'
    cpi r16, 10
    brcc get_char_loop     ; ignore caractères non numériques
    ldi temp2, 10
    mul r18, temp2
    mov r18, r0
    add r18, r16
    rjmp get_char_loop
get_number_done:
    ret

; Affiche r18 en décimal sur LCD
print_number_to_lcd:
    mov temp, r18
    ldi r16, 0
    ldi r17, 10
    rcall utoa
    rcall LCD_print_string
    ret

; Routine UART_getchar_blocking
; Attends un caractère depuis UART et le met dans r16
UART_getchar_blocking:
    sbis UCSRA, RXC
    rjmp UART_getchar_blocking
    in r16, UDR
    ret

; Routine UART_print_string (via printf.asm)
UART_print_string:
    PRINTF UART
    ret
