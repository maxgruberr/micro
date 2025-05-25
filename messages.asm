.include "lcd.asm"
.include "printf.asm"

;-------------------------------------------------------------------------------
; messages.asm
;
; This file contains subroutines for displaying various game-related messages
; on an LCD. It utilizes the `printf.asm` library for formatted text output.
;
; Animation Styles:
; - Default Letter-by-Letter: Most messages are displayed with a character-by-character
;   delay, controlled by a global flag in `printf.asm`. This is the standard
;   display method unless overridden.
; - Instant Text for Flashing Animations: For messages that flash (e.g., "GAME OVER",
;   "Start Game!" in the initial sequence), the letter-by-letter delay is temporarily
;   disabled using `disable_printf_char_delay` before printing the text and
;   re-enabled with `enable_printf_char_delay` afterwards. This ensures the
;   flashing text appears instantly.
; - Specific Delays: The `flash_delay` routine (approx 0.5s) is used to time the
;   visible/blank periods of flashing animations. The `char_delay` routine is
;   used by `printf.asm` for the letter-by-letter effect.
;
; Register Usage:
; - Message routines often use `a0` for LCD positioning via `LCD_pos`.
; - Animated routines may use `r22` or other scratch registers for loop counters;
;   these are typically saved/restored within the routine.
; - Delay routines (`char_delay`, `flash_delay`) save/restore any scratch
;   registers they use.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; char_delay
; Purpose: Creates a pause of approx. 40ms (at 4MHz) for letter-by-letter display.
;          This provides a more noticeable delay between characters.
; Registers used: r20, r21 (pushed/popped to preserve).
; Operation: Uses a two-level nested loop.
;            Outer loop (r21): 212 iterations.
;            Inner loop (r20): 250 iterations.
;            Approx. cycles: Outer_Count * (Inner_Count * 3_cycles_inner + 3_cycles_outer_ops)
;                          = 212 * (250 * 3 + 3) = 212 * 753 = 159,636 cycles.
;            At 4MHz: 159,636 / 4,000,000 = 0.039909 seconds (~39.91 ms).
;-------------------------------------------------------------------------------
char_delay:
  push r20          ; Save r20 first
  push r21          ; Then save r21

  ldi r21, 0xD4     ; Initialize outer loop counter (212 iterations)
char_delay_outer_loop_start:
  ldi r20, 0xFA     ; Initialize inner loop counter (250 iterations) - loaded each outer cycle
char_delay_inner_loop_start:
  dec r20           ; 1 cycle
  brne char_delay_inner_loop_start ; 2 cycles if branch, 1 if not (effectively 3 for the loop)
  
  dec r21           ; 1 cycle
  brne char_delay_outer_loop_start ; 2 cycles if branch, 1 if not

  pop r21           ; Restore r21 first (reverse order of push)
  pop r20           ; Then restore r20
  ret

;-------------------------------------------------------------------------------
; flash_delay
; Purpose: Creates a delay of approximately 0.5 seconds (at 4MHz clock).
;          Used for effects like flashing messages.
; Registers used: r20, r21, r22 (pushed/popped to preserve).
; Operation: Uses three nested loops.
;            Approx. cycles = Outer_Count * Middle_Count * Inner_Count * 4 cycles
;            10 * 200 * 250 * 4 = 2,000,000 cycles = 0.5 seconds at 4MHz.
;-------------------------------------------------------------------------------
flash_delay:
  push r20
  push r21
  push r22

  ldi r22, 0x0A      ; Outer loop counter (10)
flash_delay_outer_loop:
  ldi r21, 0xC8      ; Middle loop counter (200)
flash_delay_middle_loop:
  ldi r20, 0xFA      ; Inner loop counter (250)
flash_delay_inner_loop:
  nop                  ; 1 cycle
  dec r20              ; 1 cycle
  brne flash_delay_inner_loop ; 2 cycles if branch taken
  dec r21              ; 1 cycle
  brne flash_delay_middle_loop ; 2 cycles
  dec r22              ; 1 cycle
  brne flash_delay_outer_loop ; 2 cycles

  pop r22
  pop r21
  pop r20
  ret

reset:
	rcall LCD_init      ;a mettre dans le reset
	                    ; faire tout le reste 

m_game_over :
  push r22          ; Save r22 as it will be used for loop counter

  ldi r22, 5        ; Initialize loop counter for 5 flashes
game_over_flash_loop:
  rcall LCD_clear
  ; Set cursor for "GAME OVER" (9 chars) -> Line 1, Pos (16-9)/2 = 3 (approx.)
  ldi a0, 3
  rcall LCD_pos

  rcall disable_printf_char_delay ; Ensure "GAME OVER" prints instantly
  PRINTF LCD
  .db "GAME OVER", 0
  rcall enable_printf_char_delay  ; Restore default char delay behavior for subsequent messages

  rcall flash_delay ; Keep "GAME OVER" on screen for 0.5s
  rcall LCD_clear   ; Clear the screen for the "off" part of the flash
  rcall flash_delay ; Keep screen blank for 0.5s

  dec r22           ; Decrement loop counter
  brne game_over_flash_loop ; Continue if not zero

  pop r22           ; Restore r22
  ret               ; Screen is left clear after the last flash_delay

;-------------------------------------------------------------------------------
; m_p1_deploy_fleet
; Event: Player 1's turn to deploy their fleet.
; Displays: "P1: Deploy" (Line 1, centered)
;           "Fleet"      (Line 2, centered)
;-------------------------------------------------------------------------------
m_p1_deploy_fleet:
  rcall LCD_clear
  ; Line 1: "P1: Deploy" (10 chars), Position (16-10)/2 = 3
  ldi a0, 3       
  rcall LCD_pos
  PRINTF LCD
  .db "P1: Deploy", 0
  ; Line 2: "Fleet" (5 chars), Position (16-5)/2 = 5.5 -> 5. Line 2 starts at 0x40.
  ldi a0, 0x40 + 5 
  rcall LCD_pos
  PRINTF LCD
  .db "Fleet", 0
ret

;-------------------------------------------------------------------------------
; m_p2_deploy_fleet
; Event: Player 2's turn to deploy their fleet.
; Displays: "P2: Deploy" (Line 1, centered)
;           "Fleet"      (Line 2, centered)
;-------------------------------------------------------------------------------
m_p2_deploy_fleet:
  rcall LCD_clear
  ; Line 1: "P2: Deploy" (10 chars), Position (16-10)/2 = 3
  ldi a0, 3       
  rcall LCD_pos
  PRINTF LCD
  .db "P2: Deploy", 0
  ; Line 2: "Fleet" (5 chars), Position (16-5)/2 = 5.5 -> 5. Line 2 starts at 0x40.
  ldi a0, 0x40 + 5 
  rcall LCD_pos
  PRINTF LCD
  .db "Fleet", 0
ret

;-------------------------------------------------------------------------------
; m_p1_launch_salvo
; Event: Player 1's turn to drop a bomb.
; Displays: "P1: Drop Bomb!" (Line 1, centered)
;-------------------------------------------------------------------------------
m_p1_launch_salvo:
  rcall LCD_clear
  ; Line 1: "P1: Drop Bomb!" (14 chars), Position (16-14)/2 = 1
  ldi a0, 1
  rcall LCD_pos
  PRINTF LCD
  .db "P1: Drop Bomb!", 0
ret

;-------------------------------------------------------------------------------
; m_p2_launch_salvo
; Event: Player 2's turn to drop a bomb.
; Displays: "P2: Drop Bomb!" (Line 1, centered)
;-------------------------------------------------------------------------------
m_p2_launch_salvo:
  rcall LCD_clear
  ; Line 1: "P2: Drop Bomb!" (14 chars), Position (16-14)/2 = 1
  ldi a0, 1
  rcall LCD_pos
  PRINTF LCD
  .db "P2: Drop Bomb!", 0
ret

;-------------------------------------------------------------------------------
; m_action_timeout
; Event: Player action timed out.
; Displays: "Action Timeout!" (Line 1, position 0)
;-------------------------------------------------------------------------------
m_action_timeout:
  rcall LCD_clear
  ; "Action Timeout!" (15 chars) displayed from the start of Line 1.
  ldi a0, 0 
  rcall LCD_pos
  PRINTF LCD
  .db "Action Timeout!", 0
ret

;-------------------------------------------------------------------------------
; m_direct_hit
; Event: A direct hit was scored.
; Displays: "Direct Hit!" (Line 1, centered)
;-------------------------------------------------------------------------------
m_direct_hit:
  rcall LCD_clear
  ; "Direct Hit!" (11 chars), Position (16-11)/2 = 2.5 -> 2, on Line 1.
  ldi a0, 2 
  rcall LCD_pos
  PRINTF LCD
  .db "Direct Hit!", 0
ret

;-------------------------------------------------------------------------------
; m_missed
; Event: A shot missed.
; Displays: "Missed." (Line 1, centered)
;-------------------------------------------------------------------------------
m_missed:
  rcall LCD_clear
  ; "Missed." (7 chars), Position (16-7)/2 = 4.5 -> 4, on Line 1.
  ldi a0, 4
  rcall LCD_pos
  PRINTF LCD
  .db "Missed.", 0
ret

;-------------------------------------------------------------------------------
; m_victory
; Event: A player has won the game.
; Displays: "Victory!" (Line 1, centered)
;-------------------------------------------------------------------------------
m_victory:
  rcall LCD_clear
  ; "Victory!" (8 chars), Position (16-8)/2 = 4, on Line 1.
  ldi a0, 4
  rcall LCD_pos
  PRINTF LCD
  .db "Victory!", 0
ret

;-------------------------------------------------------------------------------
; m_prepare_for_battle
; Purpose: Displays "Prepare for Battle!" message using letter-by-letter effect.
; Layout: "Prepare for" (Line 1, centered), "Battle!" (Line 2, centered).
;-------------------------------------------------------------------------------
m_prepare_for_battle:
  rcall LCD_clear
  ; Line 1: "Prepare for" (11 chars). Centered: (16-11)/2 = 2.5 -> Pos 2.
  ldi a0, 2
  rcall LCD_pos
  PRINTF LCD
  .db "Prepare for", 0

  ; Line 2: "Battle!" (7 chars). Centered: (16-7)/2 = 4.5 -> Pos 4. Address: 0x40 + 4.
  ldi a0, 0x40 + 4
  rcall LCD_pos
  PRINTF LCD
  .db "Battle!", 0
  ; Note: PRINTF now handles letter-by-letter delay if enabled globally.
  ; No explicit delays (like simple_delay) needed here anymore.
ret

;-------------------------------------------------------------------------------
; m_battle_stations
; Purpose: Displays "Battle Stations!" message using letter-by-letter effect.
; Layout: "Battle Stations!" (Line 1, position 0).
;-------------------------------------------------------------------------------
m_battle_stations:
  rcall LCD_clear
  ; Display "Battle Stations!" (16 chars) on Line 1, position 0.
  ldi a0, 0
  rcall LCD_pos
  PRINTF LCD
  .db "Battle Stations!", 0
  ; Note: PRINTF now handles letter-by-letter delay if enabled globally.
  ; Removed old flashing animation and r22 usage.
ret

;-------------------------------------------------------------------------------
; m_initial_sequence
; Purpose: Displays the initial game start sequence.
;          - Flashes "Start Game!" 3 times (instant text display).
;          - Then displays "P1: Deploy Fleet" (letter-by-letter).
; Registers used: r22 (for loop counter, pushed/popped).
;                 a0 (for LCD positioning).
; Calls: LCD_clear, LCD_pos, PRINTF, flash_delay,
;        disable_printf_char_delay, enable_printf_char_delay.
;-------------------------------------------------------------------------------
m_initial_sequence:
  push r22          ; Save r22

  ldi r22, 3        ; Loop counter for 3 flashes
initial_sequence_flash_loop:
  rcall LCD_clear
  ; Set cursor for "Start Game!" (11 chars) -> Line 1, Pos (16-11)/2 = 2
  ldi a0, 2
  rcall LCD_pos
  rcall disable_printf_char_delay ; Print instantly
  PRINTF LCD
  .db "Start Game!", 0
  rcall enable_printf_char_delay  ; Restore letter-by-letter for other messages

  rcall flash_delay ; Delay for 0.5s
  rcall LCD_clear   ; Clear for flashing effect
  rcall flash_delay ; Delay for 0.5s (screen blank)

  dec r22
  brne initial_sequence_flash_loop

  ; Display "P1: Deploy Fleet" (16 chars) letter-by-letter
  ; LCD should be clear from the last part of the loop.
  ; Set cursor for "P1: Deploy Fleet" -> Line 1, Pos (16-16)/2 = 0
  ldi a0, 0
  rcall LCD_pos
  ; enable_printf_char_delay is already called, so char delay is active.
  PRINTF LCD
  .db "P1: Deploy Fleet", 0
  ; Note: No delay after this message in this routine, game flow will continue.

  pop r22           ; Restore r22
  ret
