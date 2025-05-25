.include "lcd.asm"
.include "printf.asm"


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

  
  

m_turn
