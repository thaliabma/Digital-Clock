.org 0x0000

; 1. Definindo os registradores usados
.def contUniSeg = r17 ; responsável por guardar o valor da unidade do segundo 
.def contDezSeg = r18 ; responsável por guardar o valor da dezena do segundo 
.def contUniMin = r23 ; responsável por guardar o valor da unidade do minuto 
.def contDezMin = r24 ; responsável por guardar o valor da dezena do segundo 
.def display = r16
.def valorAnalisado = r19
.def temp = r25
				
; 2. Definindo os valores de referencia para o display de 7 segmentos e seus leds para cada número
; 2.1 Porta D: sabendo que g->2, f->3, e->4, d->5, c->6, .->7 
.equ ZERO = 0b01111000
.equ UM =	0b01000000
.equ DOIS = 0b00110100
.equ TRES = 0b01100100
.equ QUATRO = 0b01001100
.equ CINCO = 0b01101100
.equ SEIS = 0b01111100
.equ SETE = 0b01000000
.equ OITO = 0b01111100
.equ NOVE = 0b01101100
; 2.2 Porta B: b->8, a->9, DisplayUnidadeSegundos->10, DisplayDezenasSegundos->11, DisplayUnidadeMinutos->12, DisplayDezenaMinutos->13
; A porta B foi configurada no próprio código diretamente.

; Constantes usadas no calculo do delay
.equ ClockMHZ = 16
.equ Delay1Ms = 5

inicio:
	;setando display porta D
	ldi display, 0xFF
	out DDRD, display
	;setando display porta B
	ldi display, 0xFF
	out DDRB, display
	
contador0a9:
	rjmp outZero

delay1segundo:
	ldi r22, byte3(ClockMHZ * 1000 * Delay1Ms / 5)
	ldi r21, high(ClockMHZ * 1000 * Delay1Ms / 5)
	ldi r20, low(ClockMHZ * 1000 * Delay1Ms / 5)

	subi r20, 1
	sbci r21, 0
	sbci r22, 0
	brcc pc - 3
	ret

incrementaContador:
	inc contUniSeg
	ldi valorAnalisado, 0xA
	cpse contUniSeg, valorAnalisado
	rjmp contador0a9
	ldi contUniSeg, 0x00

	inc contDezSeg
	ldi valorAnalisado, 0x6
	cpse contDezSeg, valorAnalisado
	rjmp contador0a9
	ldi contDezSeg, 0x00

	inc contUniMin
	ldi valorAnalisado, 0xA
	cpse contUniMin, valorAnalisado
	rjmp contador0a9
	ldi contUniMin, 0x00

	inc contDezMin
	ldi valorAnalisado, 0x6
	cpse contDezMin, valorAnalisado
	rjmp contador0a9
	ldi contDezMin, 0x00

	rjmp contador0a9

; Funções responsaveis para enviar ao display
outZERO: 
	; Verifica se o valor do display das unidades dos segundos é 0
	ldi valorAnalisado, 0x00
	cpse contUniSeg, valorAnalisado
	; False: não é zero - chama a verificação se é um
	rjmp outUM
	; True: é zero - imprime zero no display seguindo a portD e a portB
	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display
	; Delay 
	rcall delay1segundo
	; Conta mais 1 para a Unidade dos segundos
	; Vai agora mostrar a dezena dos segundos
	rjmp outZERODez

outUM: 
	ldi valorAnalisado, 0x01
	cpse contUniSeg, valorAnalisado
	rjmp outDOIS
	ldi display, UM
	out PORTD, display
	ldi display, 0b00000110
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outDOIS: 
	ldi valorAnalisado, 0x02
	cpse contUniSeg, valorAnalisado
	rjmp outTRES
	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display
	rcall delay1segundo
	
	rjmp outZERODez

outTRES: 
	ldi valorAnalisado, 0x03
	cpse contUniSeg, valorAnalisado
	rjmp outQUATRO
	ldi display, TRES
	out PORTD, display

	ldi display, 0b00000111
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outQUATRO: 
	ldi valorAnalisado, 0x04
	cpse contUniSeg, valorAnalisado
	rjmp outCINCO
	ldi display, QUATRO
	out PORTD, display

	ldi display, 0b00000110
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outCINCO:	
	ldi valorAnalisado, 0x05
	cpse contUniSeg, valorAnalisado
	rjmp outSEIS
	ldi display, CINCO
	out PORTD, display

	ldi display, 0b00000101
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outSEIS: 
	ldi valorAnalisado, 0x06
	cpse contUniSeg, valorAnalisado
	rjmp outSETE
	ldi display, SEIS
	out PORTD, display

	ldi display, 0b00000101
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outSETE: 
	ldi valorAnalisado, 0x07
	cpse contUniSeg, valorAnalisado
	rjmp outOITO
	ldi display, SETE
	out PORTD, display

	ldi display, 0b00000111
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outOITO: 
	ldi valorAnalisado, 0x08
	cpse contUniSeg, valorAnalisado
	rjmp outNOVE
	ldi display, OITO
	out PORTD, display

	ldi display, 0b00000111
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZERODez

outNOVE:
	ldi display, NOVE
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display

	rcall delay1segundo

	rjmp outZERODez
	
outZERODez: 
	ldi valorAnalisado, 0x00
	cpse contDezSeg, valorAnalisado

	rjmp outUMDez

	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00001011
	out PORTB, display
	
	rcall delay1segundo

	rjmp outZEROMin
	

outUMDez: 
	ldi valorAnalisado, 0x01
	cpse contDezSeg, valorAnalisado
	rjmp outDOISDez
	ldi display, UM
	out PORTD, display

	ldi display, 0b00001010
	out PORTB, display
	
	rcall delay1segundo

	rjmp outZEROMin

outDOISDez: 
	ldi valorAnalisado, 0x02
	cpse contDezSeg, valorAnalisado
	rjmp outTRESDez
	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00001011
	out PORTB, display
	rcall delay1segundo
	
	rjmp outZEROMin

outTRESDez: 
	ldi valorAnalisado, 0x3
	cpse contDezSeg, valorAnalisado
	rjmp outQUATRODez
	ldi display, TRES
	out PORTD, display

	ldi display, 0b00001011
	out PORTB, display

	rcall delay1segundo

	rjmp outZEROMin

outQUATRODez: 
	ldi valorAnalisado, 0x4
	cpse contDezSeg, valorAnalisado
	rjmp outCINCODez
	ldi display, QUATRO
	out PORTD, display

	ldi display, 0b00001010
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMin

outCINCODez: 
	ldi display, CINCO
	out PORTD, display

	ldi display, 0b00001001
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMin

; MINUTOS

outZEROMin: 
	ldi valorAnalisado, 0x00
	cpse contUniMin, valorAnalisado
	rjmp outUMMin

	ldi display, ZERO
	out PORTD, display

	ldi display, 0b00010011
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outUMMin: 
	ldi valorAnalisado, 0x1
	cpse contUniMin, valorAnalisado
	rjmp outDOISMin

	ldi display, UM
	out PORTD, display

	ldi display, 0b00010010
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outDOISMin: 
	ldi valorAnalisado, 0x2
	cpse contUniMin, valorAnalisado
	rjmp outTRESMin

	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display
	rcall delay1segundo
	
	rjmp outZEROMinDez

outTRESMin: 
	ldi valorAnalisado, 0x3
	cpse contUniMin, valorAnalisado
	rjmp outQUATROMin

	ldi display, TRES
	out PORTD, display

	ldi display, 0b00010011
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outQUATROMin: 
	ldi valorAnalisado, 0x4
	cpse contUniMin, valorAnalisado
	rjmp outCINCOMin

	ldi display, QUATRO
	out PORTD, display

	ldi display, 0b00010010
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outCINCOMin:	
	ldi valorAnalisado, 0x5
	cpse contUniMin, valorAnalisado
	rjmp outSEISMin

	ldi display, CINCO
	out PORTD, display

	ldi display, 0b00010001
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outSEISMin: 
	ldi valorAnalisado, 0x6
	cpse contUniMin, valorAnalisado
	rjmp outSETEMin

	ldi display, SEIS
	out PORTD, display

	ldi display, 0b00010001
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outSETEMin: 
	ldi valorAnalisado, 0x07
	cpse contUniMin, valorAnalisado
	rjmp outOITOMin

	ldi display, SETE
	out PORTD, display

	ldi display, 0b00010011
	out PORTB, display
	
	rjmp outZEROMinDez

outOITOMin: 
	ldi valorAnalisado, 0x8
	cpse contUniMin, valorAnalisado
	rjmp outNOVEMin

	ldi display, OITO
	out PORTD, display

	ldi display, 0b00010011
	out PORTB, display

	rcall delay1segundo
	
	rjmp outZEROMinDez

outNOVEMin: 
	ldi display, NOVE
	out PORTD, display

	ldi display, 0b00010011
	out PORTB, display

	rcall delay1segundo

	rjmp outZEROMinDez

outZEROMinDez: 	
	ldi valorAnalisado, 0x00
	cpse contDezMin, valorAnalisado
    rjmp outUMMinDez

	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00100011
	out PORTB, display

	rcall delay1segundo

	rjmp incrementaContador
	

outUMMinDez: 
	ldi valorAnalisado, 0x1
	cpse contDezMin, valorAnalisado
	rjmp outDOISMinDez
	ldi display, UM
	out PORTD, display

	ldi display, 0b00100010
	out PORTB, display
	
	rcall delay1segundo
	rjmp incrementaContador

outDOISMinDez: 
	ldi valorAnalisado, 0x2
	cpse contDezMin, valorAnalisado
	rjmp outTRESMinDez
	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00100011
	out PORTB, display
	rcall delay1segundo
	
	rjmp incrementaContador
outTRESMinDez: 
	ldi valorAnalisado, 0x3
	cpse contDezMin, valorAnalisado
	rjmp outQUATROMinDez
	ldi display, TRES
	out PORTD, display

	ldi display, 0b00100011
	out PORTB, display

	rcall delay1segundo

	rjmp incrementaContador
outQUATROMinDez: 
	ldi valorAnalisado, 0x4
	cpse contDezMin, valorAnalisado
	rjmp outCINCOMinDez
	ldi display, QUATRO
	out PORTD, display

	ldi display, 0b00100010
	out PORTB, display

	rcall delay1segundo
	
	rjmp incrementaContador
outCINCOMinDez: 
	
	ldi display, CINCO
	out PORTD, display

	ldi display, 0b00100001
	out PORTB, display

	rcall delay1segundo
	
	
	rjmp incrementaContador

