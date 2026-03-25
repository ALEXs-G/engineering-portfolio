;Código Assembly – Parte 2/3 (Passadeira Independente Isolada com INT1)

.include "m2560def.inc"

; Vetores de interrupção
.org 0x0000
jmp START
.org 0x0002
jmp INT1a ; Interrupção INT1

; ======================
; INICIALIZAÇÃO
; ======================

START:
; Inicialização da Stack
  ldi r16, LOW(RAMEND)
  out SPL, r16
  ldi r16, HIGH(RAMEND)
  out SPH, r16
; Configura PORTA, PORTB e PORTC como saída
  ldi r17, 0xFF
  ldi r21, 0xFF
  ldi r22, 0xFF
  out DDRA, r17 ; parte2
  out DDRB, r21 ; semáforo da passadeira
  out DDRC, r22 ; luzes dos peões
; Configura PORTD como entrada (INT1 = PD1)
  ldi r19, 0x00
  out DDRD, r19
; Configura INT0 e INT1 para bordo de subida
  ldi r16, 0x00
  out MCUCR, r16
  ldi r16, 0x0F
  sts EICRA, r16
; Ativa INT0 e INT1
  ldi r16, 0x03
  out EIMSK, r16
; Ativa interrupções globais
  sei
  clr r19 ; r19 será a flag do pedido
verde:
  ldi r21, 0x02 out PORTB, r21
  ldi r22, 0x01 out PORTC, r22
; Verde carros
; Vermelho peões
  cpi r19, 0x02
  brne verde
  rcall CheckInt1
  clr r19
; ======================
; INTERRUPÇÃO INT1
; ======================
INT1a:
  ldi r19, 0x02 reti
; Pedido de peão (INT1)
; ======================
; VERIFICAÇÃO DO PEDIDO
; ======================
CheckInt1:
  cpi r19, 0x02
  brne verde
  clr r19
  rcall Passagem
; ======================
; ROTINA DE PASSAGEM PEÕES
; ======================
Passagem:
; Amarelo carros
  ldi r21, 0x04
  out PORTB, r21
  ldi r22, 0x01
  out PORTC, r22
  rcall D3
; Vermelho carros / Verde peões
  ldi r21, 0x08
  out PORTB, r21
  ldi r22, 0x02

  out PORTC, r22
  rcall D5
; Volta ao estado normal (carros a verde, peões vermelho)
  ldi r21, 0x02
  out PORTB, r21
  ldi r22, 0x01
  out PORTC, r22
  rcall D10
  rcall D10
  rcall D10
  clr r19
  rcall verde
; ======================
; ROTINAS DE ATRASO
; ======================
D10:
  ldi r18, 20
D10_Loop:
  rcall Delay500
  dec r18
  brne D10_Loop
  ret
D5:
  ldi r18, 10
D5_Loop:
  rcall Delay500
  dec r18
  brne D5_Loop
  ret
D3:
  ldi r18, 6
D3_Loop:
  rcall Delay500
  dec r18
  brne D3_Loop
  ret

Delay500:
  push R25
  ldi R25, 40

a01dj500:
  rcall a01dr500
  dec R25
  brne a01dj500
  pop R23
  ret

a01dr500:
  push R0
  clr R0

a02dj500:
  rcall a02dr500
  dec R0
  brne a02dj500
  pop R0
  ret

a02dr500:
  push R0
  clr R0

a03dj500:
  dec R0
  brne a03dj500
  pop R0
ret
