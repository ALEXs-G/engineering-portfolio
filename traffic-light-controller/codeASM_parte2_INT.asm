;Código Assembly – Parte 2 (Interrupção INT0 para pedido de peões)

  .include "m2560def.inc"
; Vetores de interrupção
.org 0x0000

jmp START
.org 0x0002
jmp INT0a ; Interrupção INT0

; ======================
; INICIALIZAÇÃO
; ======================

  START:
; Inicialização da Stack
  ldi r16, LOW(RAMEND)
  out SPL, r16
  ldi r16, HIGH(RAMEND)
  out SPH, r16

; Configura PORTA e PORTB como saída
  ldi r17, 0xFF
  out DDRA, r17
  out DDRB, r17

; Configura PORTD como entrada (INT0 = PD0)
  ldi r19, 0x00
  out DDRD, r19

; Configura INT0: bordo de subida
  ldi r16, 0x00
  out MCUCR, r16
  ldi r16, 0x0F
  sts EICRA, r16

  ; Ativa INT0
  ldi r16, 0x03
  out EIMSK, r16

  ; Ativa interrupções globais
  sei
  clr r19 ; r19 será a flag do pedido

; ======================
; CICLO PRINCIPAL
; ======================
loop:
  estado1:
    ldi r16, 0x01  
    out PORTA, r16
    rcall D10
    cpi r19, 0x01
    brne estado2
    rcall CheckInt
    clr r19

estado2:
  ldi r16, 0x02
  out PORTA, r16
  rcall D3
  estado3:
  ldi r16, 0x03
  out PORTA, r16
  rcall D10
  cpi r19, 0x01
  brne estado4
  rcall CheckInt
  clr r19

estado4:
  ldi r16, 0x04
  out PORTA, r16
  rcall D3

estado5:
  ldi r16, 0x05
  out PORTA, r16
  rcall D10
  cpi r19, 0x01
  brne estado6
  rcall CheckInt
  clr r19

estado6:
  ldi r16, 0x06
  out PORTA, r16
  rcall D3
  rjmp loop

; ======================
; INTERRUPÇÃO INT0
; ======================
INT0a:
  ldi r19, 0x01 reti
; ativa flag de pedido de peão

  ; ======================
; VERIFICA PEDIDO DE INTERRUPÇÃO
; ======================
CheckInt:
  cpi r19, 0x01
  brne Retorna
  rcall Estado0
  clr r19
  Retorna:
  ret
; ======================
; ROTINA: Passagem de peão (força amarelo + vermelho)
; ======================

Estado0:
  cpi r16, 0x01
  breq Forca_Estado2
  cpi r16, 0x03
  breq Forca_Estado4
  cpi r16, 0x05
  breq Forca_Estado6
  clr r19
  rcall estado1

Forca_Estado2:
  ldi r20, 0x02
  out PORTA, r20
  rcall D3
  ldi r20, 0x00
  out PORTA, r20
  rcall D5
  clr r19
  rcall estado3

Forca_Estado4:
  ldi r20, 0x04
  out PORTA, r20
  rcall D3
  ldi r20, 0x00
  out PORTA, r20
  rcall D5
  clr r19
  rcall estado5
  Forca_Estado6:
  ldi r20, 0x06
  out PORTA, r20
  rcall D3
  ldi r20, 0x00
  out PORTA, r20
  rcall D5
  clr r19
  rjmp loop

  
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
  ldi r18,  10

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
