;Código Assembly – Parte 1 (Sequência de Semáforos)

.include "m2560def.inc"
jmp START ; posição 0000H
START:
  ldi r16, LOW(RAMEND)
  out SPL, r16
  ldi r16, HIGH(RAMEND)
  out SPH, r16 ; inicialização da stack
  ldi r16, 0xFF out DDRA, R16
  out DDRB, R16

; Tudo a 1s (portos como saída)

estado1:
  ldi R16, 0x01
  out PORTA, R16
  call Delay10s

estado2:
  ldi R16, 0x02
  out PORTA, R16
  call Delay3s

estado3:
  ldi R16, 0x03
  out PORTA, R16
  call Delay10s

estado4:
  ldi R16, 0x04
  out PORTA, R16
  call Delay3s

estado5:
  ldi R16, 0x05
  out PORTA, R16
  call Delay10s

estado6:
  ldi R16, 0x06
  out PORTA, R16
  call Delay3s
  jmp estado1

Delay10s:
  push R17 ; Salva R17
  ldi R17, 20 ; 20 * 0,5s = 10 segundos
  loop10s:
  dec R17 ; Decrementa contador
  brne loop10s ; Se não for zero, repete
  pop R17 ; Recupera R17
  ret ; Retorna da rotina

Delay3s:
  push R17 ; Salva R17
  ldi R17, 6 ; 6 * 0,5s = 3 segundos
  loop3s:
  dec R17 ; Decrementa contador
  brne loop3s ; Se não for zero, repete
  pop R17 ; Recupera R17
ret ; Retorna da rotina
