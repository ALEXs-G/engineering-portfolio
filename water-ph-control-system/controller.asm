.include "m2560def.inc"

  ; Salta para o início do programa e para a rotina de interrupção RINT0
  jmp START
  jmp RINT0

; Definição de constantes
.equ POUTCTR = PINA
.equ PINREF = PINC
.equ PINph = ADCH

; Vetor de interrupção para o ADC
.org 0x003A
  JMP LERADC
START:
; Inicialização da stack
  ldi r16, LOW(RAMEND) ; Carrega o byte baixo do endereço final da RAM em r16
  out SPL, r16 ; Define o byte baixo do ponteiro da stack
  ldi r16, HIGH(RAMEND) ; Carrega o byte alto do endereço final da RAM em r16
  out SPH, r16 ; Define o byte alto do ponteiro da stack

; Inicialização do modo sleep
  ldi R16, $01 ; Configura o registo de controle do modo sleep
  out SMCR, R16 ; Habilita o modo sleep

; Inicialização das interrupções externas
  ldi R16, 0x00 ; Configura o registo de controlo da MCU
  out MCUCR, R16
  ldi R16, 0x03 ; Configura o registo de controlo das interrupções ext.
  sts EICRA, R16
  ldi R16, 0x01 ; Habilita a interrupção externa INT0
  out EIMSK, R16
  sei ; Habilita interrupções globais

; Configuração das direções dos pinos: 0 = entrada, 1 = saída
  ldi R16, $B3 ; Configura os pinos de PORTA
  out DDRA, R16 ; PORTA: |0|0|0|PHs|0|PhA|PHB|
  ldi R16, $0F ; Configura os pinos de PORTB
  out DDRB, R16 ; PORTB: (00001111)
  ldi R16, $F0 ; Configura os pinos de PORTC
  out DDRC, R16 ; PORTC: (11110000)
  out DDRD, R16 ; PORTD: Interruptor INT0

; Inicialização do ADC
  ldi R16, $20 ; Configura o registo ADMUX
  sts ADMUX, R16

ModoSleep:
SLEEP ; Entra no modo sleep

CLKInicFilt:
  in R19, PINFILTER ; Lê o valor do filtro de entrada
  andi R19, $00 ; Coloca a 0 R19
  out POUTCTR, R19 ; Envia o valor para o POUTCTR
  jmp INIC_CICLO_DE_FILTRAGEM ; Pula para INIC_CICLO_DE_FILTRAGEM

INIC_CICLO_DE_FILTRAGEM:
  sbr R18, $80 ; Define Mon=1
  out POUTCTR, R18 ; Envia o valor para o POUTCTR
  jmp MEDIRPH ; Pula para MEDIRPH

MEDIRPH:
  in R18, PINA ; Lê o valor de PINA
  andi R18, $88 ; Verifica PhS
  out PORTA, R18 ; Envia o valor para PORTA
  sbrs R18, 3 ; Salta a próxima instrução se o bit 3 de R18 for 0
  rjmp MEDIRPH ; Repete a leitura se PhS não estiver definido
  in R18, PINA ; Lê novamente o valor de PINA
  andi R18, $0C ; Verifica o ADC
  breq MEDIRPH ; Repete a leitura se a condição for atendida
  jmp STARTADC ; Pula para STARTADC

STARTADC:
  ldi R16, $CF ; Inicia a conversão ADC
  sts ADCSRA, R16
  sleep ; Entra no modo sleep
  loop:
  lds R19, ADCH ; Lê o valor do ADC
  mov R30, R19 ; Move o valor de R19 para R30
  lsr R19 ; Desloca R19 quatro vezes para a direita
  lsr R19 ; Para visualizar os LEDS nas posições mais signific.
  lsr R19
  out PORTC, R19 ; Envia o valor deslocado para PORTC
  ldi R16, $07 ; Reinicia o ADC
  sts ADCSRA, R16

Comparacao:
  in R20, PINREF ; Lê o valor de PINREF
  ldi R22, $03 ; Carrega o valor 3 em R22
  adc R20, R22 ; Soma R20 com R22 mais o valor de carry
  out PINREF, R20 ; Envia o valor para PINREF
  cp R19, R20 ; Compara R19 com R20
  breq sbtracao ; Salta para sbtracao se igual
  brpl MAIOR ; Salta para MAIOR se R19 > R20
  subi R20, $03 ; Subtrai 3 de R20
  out PINREF, R20 ; Envia o valor para PINREF
  cp R19, R20 ; Compara R19 com R20
  brmi MENOR ; Salta para MENOR se R19 < R20
  jmp N0 ; Salta para N0

sbtracao:
  subi R20, $03 ; Subtrai 3 de R20
  out PINREF, R20 ; Envia o valor para PINREF
  cp R19, R20 ; Compara R19 com R20
  brmi MENOR ; Salta para MENOR se R19 < R20
  jmp N0 ; Salta para N0

N0:
  cbr R18, $03 ; Limpa os bits 0 e 1 de R18
  sbr R18, $80 ; Define o bit 7 de R18  
  out PORTA, R18 ; Envia o valor para PORTA
  jmp Verif ; Salta para Verif

Verif:
; Verifica se deve iniciar o fecho do sistema de filtragem
  in R20, PINA ; Lê o valor de PINA
  sbrs R20, 4 ; Salta a próxima instrução se o bit 4 de R20 for 0
  jmp STARTADC ; Pula para STARTADC
  jmp CLKTmpFilt ; Pula para CLKTmpFilt

MAIOR:
  ldi R18, $8E ; Define PhA=1
  out PORTA, R18 ; Envia o valor para PORTA
  jmp Verif ; Salta para Verif

MENOR:
  ldi R18, $8D ; Define PhB=1
  out PORTA, R18 ; Envia o valor para PORTA
  jmp Verif ; Salta para Verif

CLKTmpFilt:
; Configura os bits de PORTA
  sbr R18, $70 ; Define bits 4 a 6 de R18
  cbr R18, $80 ; Limpa o bit 7 de R18
  out PORTA, R17 ; Envia o valor para PORTA |0|0|0|0|0|0|0|

RINT0:
  reti ; Retorna da interrupção

LERADC:
  reti ; Retorna da interrupção
