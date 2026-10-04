; =============================================================================
; codeController_reviewed.asm
;
; REVIEWED COPY of codeControler.asm (original preserved unchanged).
; Purpose: make the program assemble and remove unambiguous defects found in
; the code review (see CODE_REVIEW.md). Every change is marked "; REVIEW Cx",
; where Cx matches the correction ID in CODE_REVIEW.md.
;
; Verification status: assembles without errors with AVRA 1.4.2 (m2560def.inc).
; NOT simulated, NOT run on hardware. Design-level issues that need the
; original specification or hardware to resolve (end-of-cycle input, ADC
; scaling vs. reference port, LED mapping, ADC reference) are documented in
; CODE_REVIEW.md and intentionally NOT changed here.
; =============================================================================

.include "m2560def.inc"

  ; Salta para o início do programa e para a rotina de interrupção RINT0
  jmp START                 ; 0x0000 reset vector
  jmp RINT0                 ; 0x0002 = INT0addr

; Definição de constantes
.equ POUTCTR = PORTA        ; REVIEW C2: was PINA (writing PINx toggles PORTx bits)
.equ PINREF = PINC
.equ PINFILTER = PINB       ; REVIEW C1: was undefined (assembler error). PORTB is
                            ;   assumed (DDRB = $0F leaves bits 7..4 as inputs); the
                            ;   actual wiring is not documented.

; Vetor de interrupção para o ADC
.org ADCCaddr               ; = 0x003A (REVIEW: symbolic name instead of literal)
  jmp LERADC

.org INT_VECTORS_SIZE       ; REVIEW C15: start code after the full vector table
START:
; Inicialização da stack
  ldi r16, LOW(RAMEND)
  out SPL, r16
  ldi r16, HIGH(RAMEND)
  out SPH, r16

  clr R17                   ; REVIEW C8: registers are not cleared at reset
  clr R18                   ; REVIEW C8

; Inicialização do modo sleep
  ldi R16, $01              ; SE = 1, SM = 000 (Idle)
  out SMCR, R16

; Inicialização das interrupções externas
  ldi R16, 0x00
  out MCUCR, R16
  ldi R16, 0x03             ; INT0 on rising edge
  sts EICRA, R16
  ldi R16, 0x01             ; enable INT0
  out EIMSK, R16

; Configuração das direções dos pinos: 0 = entrada, 1 = saída
  ldi R16, $B3
  out DDRA, R16
  ldi R16, $0F
  out DDRB, R16
  ldi R16, $F0
  out DDRC, R16
  out DDRD, R16

; Inicialização do ADC
  ldi R16, $20              ; REFS = 00 (external AREF), ADLAR = 1, ADC0 (see CODE_REVIEW.md, D5)
  sts ADMUX, R16

  sei                       ; REVIEW C14: enable interrupts after I/O is configured

ModoSleep:
  sleep                     ; wait for INT0 (ClkInicFilt)

CLKInicFilt:
  in R19, PINFILTER
  andi R19, $00
  out POUTCTR, R19          ; with C2 this now clears PORTA (all outputs low)
  jmp INIC_CICLO_DE_FILTRAGEM

INIC_CICLO_DE_FILTRAGEM:
  sbr R18, $80              ; Mon = 1
  out POUTCTR, R18
  jmp MEDIRPH

MEDIRPH:
  in R18, PINA
  andi R18, $88
  out PORTA, R18
  sbrs R18, 3
  rjmp MEDIRPH
  in R18, PINA
  andi R18, $0C
  breq MEDIRPH              ; see CODE_REVIEW.md, D7 (practically unreachable)
  jmp STARTADC

STARTADC:
  ldi R16, $CF              ; ADEN | ADSC | ADIF | ADIE | prescaler /128
  sts ADCSRA, R16
  sleep                     ; woken by the ADC conversion-complete interrupt
loop:
  lds R19, ADCH
  mov R30, R19
  lsr R19                   ; NOTE: 3 shifts (comment in original says 4), see D3
  lsr R19
  lsr R19
  out PORTC, R19
  ldi R16, $07              ; ADEN = 0: disables the ADC until the next STARTADC
  sts ADCSRA, R16

Comparacao:
  in R20, PINREF            ; reference value
  ldi R22, $03
  add R20, R22              ; REVIEW C4: was ADC (result depended on a stale carry)
                            ; REVIEW C3: removed "out PINREF, R20" (wrote to PINC = toggled PORTC)
  cp R19, R20               ; sensor vs. reference + 3
  breq sbtracao
  brsh MAIOR                ; REVIEW C5: was BRPL (signed test on unsigned values)
  subi R20, $03             ; back to the reference value
                            ; REVIEW C3: removed "out PINREF, R20"
  cp R19, R20
  brlo MENOR                ; REVIEW C5: was BRMI (signed test on unsigned values)
  jmp N0

sbtracao:
  subi R20, $03
                            ; REVIEW C3: removed "out PINREF, R20"
  cp R19, R20
  brlo MENOR                ; REVIEW C5: was BRMI
  jmp N0

N0:
  cbr R18, $03              ; PhA = PhB = 0
  sbr R18, $80
  out PORTA, R18
  jmp Verif

Verif:
; Verifica se deve iniciar o fecho do sistema de filtragem
  in R20, PINA
  sbrs R20, 4               ; NOTE: PA4 is configured as an OUTPUT (DDRA = $B3), see D1
  jmp STARTADC
  jmp CLKTmpFilt

MAIOR:
  ldi R18, $8E              ; PhA = 1
  out PORTA, R18
  jmp Verif

MENOR:
  ldi R18, $8D              ; PhB = 1
  out PORTA, R18
  jmp Verif

CLKTmpFilt:
  sbr R18, $70
  cbr R18, $80              ; Mon = 0
  out PORTA, R17            ; R17 = 0 (cleared at START, C8): all PORTA outputs low, as commented
  rjmp ModoSleep            ; REVIEW C9: original fell through into RINT0's RETI with an
                            ;   empty stack (undefined return address)

RINT0:
  reti

LERADC:
  reti
