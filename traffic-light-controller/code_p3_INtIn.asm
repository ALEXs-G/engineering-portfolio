; Código da Parte 3 – Semáforos com Interrupções Independentes (Tentativa sem Contadores)

.include "m2560def.inc"

; Vetores de interrupção
.org 0x0000

jmp START
.org 0x0002
jmp INT0a ; Interrupção INT0
.org 0x0004
jmp INT1a ; Interrupção INT1

; ======================
; INICIALIZAÇÃO
; ======================

START:
  ldi r16, LOW(RAMEND)
  out SPL, r16
  ldi r16, HIGH(RAMEND)
  out SPH, r16
  ldi r17, 0xFF
  ldi r21, 0xFF
  ldi r22, 0xFF
  out DDRA, r17
  out DDRB, r21
  out DDRC, r22
  ldi r19, 0x00
  out DDRD, r19
  ldi r16, 0x00
  out MCUCR, r16
  ldi r16, 0x0F
  sts EICRA, r16
  ldi r16,0x03
  out EIMSK, r16
  sei
  
; ======================
; CICLO PRINCIPAL
; ======================

loop:
  verde:
    ldi r21, 0x02
    out PORTB, r21
    ldi r22, 0x01
    out PORTC, r22
    cpi r19, 0x02
    brne verde
    rcall CheckInt1
    clr r19

estado1:
  ldi r16, 0x01
  out PORTA, r16
  rcall D10

estado2:
  ldi r16, 0x02
  out PORTA, r16
  rcall D3

estado3:
  ldi r16, 0x03
  out PORTA, r16
  rcall D10

estado4:
  ldi r16, 0x04
  out PORTA, r16
  rcall D3

estado5:
  ldi r16, 0x05
  out PORTA, r16
  rcall D10

estado6:
  ldi r16, 0x06
  out PORTA, r16
  rcall D3
  rjmp loop

; ======================
; INTERRUPÇÃO INT1
; ======================
INT1a:
  ldi r19, 0x02
  recall CheckInt1
  reti

CheckInt1:
  cpi r19, 0x02
  brne verde
  clr r19
  rcall Passagem

Passagem:
  ldi r21, 0x04
  out PORTB, r21
  ldi r22, 0x01
  out PORTC, r22
  rcall D3
  ldi r21, 0x08
  out PORTB, r21
  ldi r22, 0x02
  out PORTC, r22
  rcall D5
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
; INTERRUPÇÃO INT0
; ======================
INT0a:
  cpi r16, 0x01
  breq Forca_Estado2
  cpi r16, 0x03
  breq Forca_Estado4
  cpi r16, 0x05
  breq Forca_Estado6
  rcall estado1
  reti

Forca_Estado2:
  ldi r20, 0x02
  out PORTA, r20
  rcall D3
  ldi r20, 0x00
  out PORTA, r20
  rcall D5
  rcall estado3

Forca_Estado4:
  ldi r20, 0x04
  out PORTA, r20
  rcall D3
  ldi r20, 0x00
  out PORTA, r20
  rcall D5
  rcall estado5

Forca_Estado6:
  ldi r20, 0x06
  out PORTA, r20
  rcall D3
  ldi r20, 0x00
  out PORTA, r20
  rcall D5

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
  ldi R25,40

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
