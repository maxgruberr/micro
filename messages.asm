.include "lcd.asm"
.include "printf.asm"

;-------------------------------------------------------------------------------
; simple_delay
; Purpose: Creates a short pause, e.g., for animations.
; Registers used: r20, r21 (as temporary scratch registers).
; Operation: Uses nested loops. Outer loop controlled by r20, inner by r21.
;            Delay duration is approximately r20_val * r21_val * loop_body_cycles.
;            Currently r20 is 0x80, r21 is 0xFF.
;-------------------------------------------------------------------------------
simple_delay:
  ldi r20, 0x80     ; Initialize outer loop counter.
delay_outer_loop:
  ldi r21, 0xFF     ; Initialize inner loop counter.
delay_inner_loop:
  dec r21           ; Decrement inner loop counter.
  brne delay_inner_loop ; Continue if inner loop not finished.
  dec r20           ; Decrement outer loop counter.
  brne delay_outer_loop ; Continue if outer loop not finished.
  ret

reset:
	rcall LCD_init      ;a mettre dans le reset
	                    ; faire tout le reste 

m_start :
	rcall LCD_clear

  ; Ligne 1, position 2
  ldi a0, 2
  rcall LCD_pos
  PRINTF LCD
  .db "Start Game ?", 0

  ; Ligne 2, position 5
  ldi a0, 0x45     ; 0x40 = début ligne 2 + 5
  rcall LCD_pos
  PRINTF LCD
  .db "[y/n]", 0
ret

m_game_over :
  rcall LCD_clear

  PRINTF LCD
  .db "GAME OVER", 0

  ret

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
; Purpose: Animated "Game Start" message.
; Animation: Displays "Prepare" on line 1, pauses, then "for Battle!" on line 2, pauses.
; Registers used: None (beyond those used by sub-calls like simple_delay, LCD_pos).
;-------------------------------------------------------------------------------
m_prepare_for_battle:
  rcall LCD_clear
  ; Display "Prepare" (7 chars) on Line 1, centered. Pos (16-7)/2 = 4.5 -> 4.
  ldi a0, 4 
  rcall LCD_pos
  PRINTF LCD
  .db "Prepare", 0
  rcall simple_delay ; Pause after first part of message.
  ; Display "for Battle!" (11 chars) on Line 2, centered. Pos (16-11)/2 = 2.5 -> 2.
  ; Line 2 starts at address 0x40. Cursor pos: 0x40 + 2.
  ldi a0, 0x40 + 2 
  rcall LCD_pos
  PRINTF LCD
  .db "for Battle!", 0
  rcall simple_delay ; Pause after second part of message.
ret

;-------------------------------------------------------------------------------
; m_battle_stations
; Purpose: Animated "Battle Start" message, indicating transition to active gameplay.
; Animation: Flashes "Battle Stations!" message 3 times.
;            Each flash: display text, delay, clear screen, delay.
;            Finally, displays the message one last time.
; Registers used: r22 for loop counter.
;-------------------------------------------------------------------------------
m_battle_stations:
  rcall LCD_clear
  ldi r22, 3 ; Initialize loop counter for 3 flashes.
battle_stations_loop:
  ; Display "Battle Stations!" (16 chars) on Line 1, position 0.
  ldi a0, 0
  rcall LCD_pos
  PRINTF LCD
  .db "Battle Stations!", 0
  rcall simple_delay  ; Hold message on screen.
  rcall LCD_clear     ; Clear screen for flashing effect.
  rcall simple_delay  ; Pause while screen is clear.
  dec r22             ; Decrement loop counter.
  brne battle_stations_loop ; Repeat if counter > 0.
  ; Display "Battle Stations!" one last time, leaving it on screen.
  ldi a0, 0
  rcall LCD_pos
  PRINTF LCD
  .db "Battle Stations!", 0
ret
