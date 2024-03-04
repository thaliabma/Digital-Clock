.equ UBRRvalue = 103

.cseg
.org $0000
rjmp reset ; Reset vector
.org INT0addr
rjmp BotaoMode ; INT0 vector (ext. interrupt from pin D2)
.org INT1addr
rjmp BotaoStart ;
.org 0x000A
rjmp BotaoReset 

 
.equ ClockMHZ = 16 ;
.equ Delay1Ms = 1

.def contUniSeg = r17 ; responsável por guardar o valor da unidade do segundo 
.def contDezSeg = r18 ; responsável por guardar o valor da dezena do segundo 
.def contUniMin = r23 ; responsável por guardar o valor da unidade do minuto 
.def contDezMin = r24 ; 
.def temp = r19
.def display = r16
.def qualModo = r25 ; 0x00: mode 1 | 0x01: mode 2 | 0x02: mode 3
.def qualStart = r26 ; 0x00: pausado | 0x01: continua
.def numero = r27
.def qualDisplayModo3 = r30; 00x00: 000X | 00x01: 00X0 | 00x02: 0X00 | 00x03: X000
.def verificarResetModo3 = r28
.def piscarDisplay = r29
.def inicial = r31

.equ ZERO = 0b11111110
.equ UM =	0b00110000
.equ DOIS = 0b11101101
.equ TRES = 0b11111001
.equ QUATRO = 0b11110011
.equ CINCO = 0b11011011
.equ SEIS = 0b11011111
.equ SETE = 0b11110000
.equ OITO = 0b11111111
.equ NOVE = 0b011111011
	
delay1segundo:
	ldi r22, byte3(ClockMHZ * 1000 * Delay1Ms / 5)
	ldi r21, high(ClockMHZ * 1000 * Delay1Ms / 5)
	ldi r20, low(ClockMHZ * 1000 * Delay1Ms / 5)

	subi r20, 1
	sbci r21, 0
	sbci r22, 0
	brcc pc - 3
	ret


reset:
	;setando display porta C
	ldi display, 0xFF
	out DDRC, display
	;setando display porta B E BOTAO RESET
	ldi display, 0b11111110
	out DDRB, display

	;ldi temp, 0x00
	;out DDRD, temp

	ldi temp,low(RAMEND) ; Set stackptr to ram end
	out SPL,temp
	ldi temp, high(RAMEND)
	out SPH, temp

	ser temp ; Set TEMP to $FF to...
	out PORTD, temp ; ...all high for pullup on inputs
	; ldi temp,(1<<DDD4) ; bit D6 only configured as output,
	; out DDRD,temp ; ...output for piezo buzzer on pin D6
	; set up int0 and int1

	;Inicializar a Porta Serial
	
	ldi temp, high(UBRRvalue)
	sts UBRR0H, temp
	ldi temp, low(UBRRvalue)
	sts UBRR0L, temp

	; Habilita transmissão e recepção
	ldi temp, (1<<RXEN0) | (1<<TXEN0)
	sts UCSR0B, temp

	; Configuração de 8 bits de dados, 1 bit de parada, sem paridade
	ldi temp, (3<<UCSZ00)
	sts UCSR0C, temp


	ldi temp, (0b11 << ISC10) | (0b11 << ISC00) ;positive edge triggers
	sts EICRA, temp
	;enable int0, int1
	ldi temp, (1 << INT0) | (1 << INT1)
	out EIMSK, temp
	;ldi temp, (0 << PD4)
	;out DDRD, temp ; Define o pino PD4 como entrada
	ldi temp, $04
	sts PCICR, temp

	ldi temp, $10
	sts PCMSK2, temp


	;Stack initialization
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	#define CLOCK 8.0e6 ;clock speed
	#define DELAY 2.0 ;seconds
	.equ PRESCALE = 0b100 ;/256 prescale
	.equ PRESCALE_DIV = 256
	.equ WGM = 0b0100 ;Waveform generation mode: CTC
	;you must ensure this value is between 0 and 65535
	.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY))
	.if TOP > 65535
	.error "TOP is out of range"
	.endif

	;On MEGA series, write high byte of 16-bit timer registers first
	ldi temp, high(TOP) ;initialize compare value (TOP)
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp

	ldi temp, ((WGM&0b11) << WGM10) ;lower 2 bits of WGM
	; WGM&0b11 = 0b0100 & 0b0011 = 0b0000
	sts TCCR1A, temp
	;upper 2 bits of WGM and clock select
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	; WGM >> 2 = 0b0100 >> 2 = 0b0001
	; (WGM >> 2) << WGM12 = (0b0001 << 3) = 0b0001000
	; (PRESCALE << CS10) = 0b100 << 0 = 0b100
	; 0b0001000 | 0b100 = 0b0001100
	sts TCCR1B, temp ;start counter

	sei

ldi qualModo, 0x00
ldi qualStart, 0x00
ldi inicial, 0x00

mainLoop:
	rcall imprimir0
	;ldi temp, 0x00
	;cpse qualModo, temp
	;rjmp mainLoop
	in temp, TIFR1 ;request status from timers
	andi temp, 1<<OCF1A ;isolate only timer 1's match
	; 0b1 << OCF1A = 0b1 << 1 = 0b00000010
	; andi --> 1 (OCF1A é um) --> overflow
	; andi --> 0 (OCF1A é zero) --> contando
	breq skipoverflow ;skip overflow handler
	;match handler - done once every DELAY seconds
	ldi temp, 1<<OCF1A ;write a 1 to clear the flag
	out TIFR1, temp
	;overflow event code goes here

	ldi temp, 0x02
	cpse qualModo, temp
	rjmp pularPiscar

	ldi temp, 0x00
	cpse qualDisplayModo3, temp
	rjmp naoEUniSeg
	ldi temp, 0x00
	cpse piscarDisplay, temp
	rjmp fazerPiscar
	ldi piscarDisplay, 0x01
	rjmp pularPiscar

	naoEUniSeg:
	ldi temp, 0x01
	cpse qualDisplayModo3, temp
	rjmp naoEDezSeg
	ldi temp, 0x00
	cpse piscarDisplay, temp
	rjmp fazerPiscar
	ldi piscarDisplay, 0x02
	rjmp pularPiscar

	naoEDezSeg:
	ldi temp, 0x02
	cpse qualDisplayModo3, temp
	rjmp naoEUniMin
	ldi temp, 0x00
	cpse piscarDisplay, temp
	rjmp fazerPiscar
	ldi piscarDisplay, 0x03
	rjmp pularPiscar

	naoEUniMin:
	ldi temp, 0x00
	cpse piscarDisplay, temp
	rjmp fazerPiscar
	ldi piscarDisplay, 0x04
	rjmp pularPiscar

	fazerPiscar:
	ldi piscarDisplay, 0x00

	pularPiscar:
	ldi temp, 0x00
	cpse qualModo, temp
	rjmp modoDois
	inc contUniSeg
	rcall portaSerial
	skipoverflow:
	;main application processing goes here
	nop
	rjmp unidadeSegundoZERO

modoDois:
	ldi temp, 0x01
	cpse qualModo, temp
	rjmp unidadeSegundoZERO
	ldi temp, 0x01
	cpse qualStart, temp
	rjmp unidadeSegundoZERO
	inc contUniSeg
	rjmp unidadeSegundoZERO


incrementaContador:
	ldi temp, 0x0A
	cpse contUniSeg, temp
	rjmp mainLoop
	ldi contUniSeg, 0x00

	inc contDezSeg
	ldi temp, 0x6
	cpse contDezSeg, temp
	rjmp mainLoop
	ldi contDezSeg, 0x00

	inc contUniMin
	ldi temp, 0xA
	cpse contUniMin, temp
	rjmp mainLoop
	ldi contUniMin, 0x00

	inc contDezMin
	ldi temp, 0x6
	cpse contDezMin, temp
	rjmp mainLoop
	ldi contDezMin, 0x00

	rjmp mainLoop

unidadeSegundoZERO:
	; Verifica se o valor do display das unidades dos segundos é 0
	ldi temp, 0x00
	cpse contUniSeg, temp
	; False: não é zero - chama a verificação se é um
	rjmp unidadeSegundoUM
	; True: é zero - imprime zero no display seguindo a portC e a portB
	ldi display, ZERO
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoUM:
	ldi temp, 0x01
	cpse contUniSeg, temp
	rjmp unidadeSegundoDOIS

	ldi display, UM
	out PORTC, display
	ldi display, 0b00100000
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoDOIS:
	ldi temp, 0x02
	cpse contUniSeg, temp
	rjmp unidadeSegundoTRES

	ldi display, DOIS
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoTRES:
	ldi temp, 0x03
	cpse contUniSeg, temp
	rjmp unidadeSegundoQUATRO

	ldi display, TRES
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoQUATRO:
	ldi temp, 0x04
	cpse contUniSeg, temp
	rjmp unidadeSegundoCINCO

	ldi display, QUATRO
	out PORTC, display
	ldi display, 0b00100000
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoCINCO:
	ldi temp, 0x05
	cpse contUniSeg, temp
	rjmp unidadeSegundoSEIS

	ldi display, CINCO
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoSEIS:
	ldi temp, 0x06
	cpse contUniSeg, temp
	rjmp unidadeSegundoSETE

	ldi display, SEIS
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoSETE:
	ldi temp, 0x07
	cpse contUniSeg, temp
	rjmp unidadeSegundoOITO

	ldi display, SETE
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoOITO:
	ldi temp, 0x08
	cpse contUniSeg, temp
	rjmp unidadeSegundoNOVE

	ldi display, OITO
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

unidadeSegundoNOVE:
	ldi display, NOVE
	out PORTC, display
	ldi display, 0b00100010
	out PORTB, display

	ldi temp, 0x01
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaSegundoZERO

dezenaSegundoZERO:
	ldi temp, 0x00
	cpse contDezSeg, temp
	rjmp dezenaSegundoUM

	ldi display, ZERO
	out PORTC, display
	ldi display, 0b00010010
	out PORTB, display

	ldi temp, 0x02
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp unidadeMinutoZERO

dezenaSegundoUM:
	ldi temp, 0x01
	cpse contDezSeg, temp
	rjmp dezenaSegundoDOIS

	ldi display, UM
	out PORTC, display
	ldi display, 0b00010000
	out PORTB, display

	ldi temp, 0x02
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp unidadeMinutoZERO

dezenaSegundoDOIS:
	ldi temp, 0x02
	cpse contDezSeg, temp
	rjmp dezenaSegundoTRES

	ldi display, DOIS
	out PORTC, display
	ldi display, 0b00010010
	out PORTB, display

	ldi temp, 0x02
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp unidadeMinutoZERO

dezenaSegundoTRES:
	ldi temp, 0x3
	cpse contDezSeg, temp
	rjmp dezenaSegundoQUATRO

	ldi display, TRES
	out PORTC, display
	ldi display, 0b00010010
	out PORTB, display

	ldi temp, 0x02
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp unidadeMinutoZERO

dezenaSegundoQUATRO:
	ldi temp, 0x4
	cpse contDezSeg, temp
	rjmp dezenaSegundoCINCO

	ldi display, QUATRO
	out PORTC, display
	ldi display, 0b00010000
	out PORTB, display

	ldi temp, 0x02
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp unidadeMinutoZERO

dezenaSegundoCINCO:
	ldi display, CINCO
	out PORTC, display
	ldi display, 0b00010010
	out PORTB, display

		ldi temp, 0x02
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp unidadeMinutoZERO

unidadeMinutoZERO:
	; Verifica se o valor do display das unidades dos segundos é 0
	ldi temp, 0x00
	cpse contUniMin, temp
	; False: não é zero - chama a verificação se é um
	rjmp unidadeMinutoUM
	; True: é zero - imprime zero no display seguindo a portC e a portB
	ldi display, ZERO
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoUM:
	ldi temp, 0x01
	cpse contUniMin, temp
	rjmp unidadeMinutoDOIS

	ldi display, UM
	out PORTC, display
	ldi display, 0b00001000
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoDOIS:
	ldi temp, 0x02
	cpse contUniMin, temp
	rjmp unidadeMinutoTRES

	ldi display, DOIS
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoTRES:
	ldi temp, 0x03
	cpse contUniMin, temp
	rjmp unidadeMinutoQUATRO

	ldi display, TRES
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoQUATRO:
	ldi temp, 0x04
	cpse contUniMin, temp
	rjmp unidadeMinutoCINCO

	ldi display, QUATRO
	out PORTC, display
	ldi display, 0b00001000
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoCINCO:
	ldi temp, 0x05
	cpse contUniMin, temp
	rjmp unidadeMinutoSEIS

	ldi display, CINCO
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoSEIS:
	ldi temp, 0x06
	cpse contUniMin, temp
	rjmp unidadeMinutoSETE

	ldi display, SEIS
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoSETE:
	ldi temp, 0x07
	cpse contUniMin, temp
	rjmp unidadeMinutoOITO

	ldi display, SETE
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoOITO:
	ldi temp, 0x08
	cpse contUniMin, temp
	rjmp unidadeMinutoNOVE

	ldi display, OITO
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

unidadeMinutoNOVE:
	ldi display, NOVE
	out PORTC, display
	ldi display, 0b00001010
	out PORTB, display

	ldi temp, 0x03
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp dezenaMinutoZERO

dezenaMinutoZERO:
	ldi temp, 0x00
	cpse contDezMin, temp
	rjmp dezenaMinutoUM

	ldi display, ZERO
	out PORTC, display
	ldi display, 0b00000110
	out PORTB, display

	ldi temp, 0x04
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp incrementaContador

dezenaMinutoUM:
	ldi temp, 0x01
	cpse contDezMin, temp
	rjmp dezenaMinutoDOIS

	ldi display, UM
	out PORTC, display
	ldi display, 0b00000100
	out PORTB, display

	ldi temp, 0x04
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp incrementaContador

dezenaMinutoDOIS:
	ldi temp, 0x02
	cpse contDezMin, temp
	rjmp dezenaMinutoTRES

	ldi display, DOIS
	out PORTC, display
	ldi display, 0b00000110
	out PORTB, display

	ldi temp, 0x04
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp incrementaContador

dezenaMinutoTRES:
	ldi temp, 0x3
	cpse contDezMin, temp
	rjmp dezenaMinutoQUATRO

	ldi display, TRES
	out PORTC, display
	ldi display, 0b00000110
	out PORTB, display

	ldi temp, 0x04
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp incrementaContador

dezenaMinutoQUATRO:
	ldi temp, 0x4
	cpse contDezMin, temp
	rjmp dezenaMinutoCINCO

	ldi display, QUATRO
	out PORTC, display
	ldi display, 0b00000100
	out PORTB, display

	ldi temp, 0x04
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp incrementaContador

dezenaMinutoCINCO:
	ldi display, CINCO
	out PORTC, display
	ldi display, 0b00000110
	out PORTB, display
	ldi temp, 0x04
	cpse piscarDisplay, temp
	rcall delay1segundo
	rjmp incrementaContador

BotaoMode:
	ldi display, 0b00000001
	out PORTB, display
	ldi piscarDisplay, 0x00
	ldi temp, 0x02
	cpse qualModo, temp
	rjmp zerarRelogio
	ldi qualModo, 0x00
	ldi qualDisplayModo3, 0x00
	reti
	zerarRelogio:
	ldi temp, 0x00
	cpse qualModo, temp
	rjmp mudarParaModo3
	ldi contUniSeg, 0x00
	ldi contDezSeg, 0x00
	ldi contUniMin, 0x00
	ldi contDezMin, 0x00
	ldi qualModo, 0x01
	rcall imprimirZero
	reti
	mudarParaModo3:
	ldi temp, 0x00
	cpse qualStart, temp
	reti
	ldi contUniSeg, 0x00
	ldi contDezSeg, 0x00
	ldi contUniMin, 0x00
	ldi contDezMin, 0x00
	ldi qualModo, 0x02
	rcall printSerialModo3D1
	reti

imprimirZero:
	ldi temp, 0x01
	cpse inicial, temp
	rjmp fazNada
	ldi inicial, 0x00
	ldi byte_tx, '['
    rcall transmit
	ldi byte_tx, 'M'
    rcall transmit
    ldi byte_tx, 'O' 
    rcall transmit
    ldi byte_tx, 'D' 
    rcall transmit
    ldi byte_tx, 'O' 
    rcall transmit
	ldi byte_tx, 32 
    rcall transmit
	ldi byte_tx, '2' 
    rcall transmit
	ldi byte_tx, ']'
    rcall transmit
    ldi byte_tx, 32 
    rcall transmit
    ldi byte_tx, 'Z'
    rcall transmit
    ldi byte_tx, 'E' 
    rcall transmit
	ldi byte_tx, 'R'  
    rcall transmit
	ldi byte_tx, 'O' 
    rcall transmit
	ldi byte_tx, 10 
    rcall transmit
	fazNada:
	ldi inicial, 0x01
	ret

BotaoStart:
	ldi display, 0b00000001
	out PORTB, display
	ldi temp, 0x01
	cpse qualModo, temp
	rjmp startModo3
	rcall printSerialStart
	ldi temp, 0x00
	cpse qualStart, temp
	rjmp botaoStartParar
	ldi qualStart, 0x01
	reti
	botaoStartParar:
	ldi qualStart, 0x00
	reti
	startModo3:
	ldi temp, 0x02
	cpse qualModo, temp
	reti
	ldi temp, 0x03
	cpse qualDisplayModo3, temp
	rjmp mudarDisplayModo3
	ldi qualDisplayModo3, 0x00
	rcall printSerialModo3D1 // uni seg
	reti
	mudarDisplayModo3:
	ldi temp, 0x00
	cpse qualDisplayModo3, temp
	rjmp mudarDisplayModo3Continuacao
	inc qualDisplayModo3
	rcall printSerialModo3D2 // dez seg
	reti
	mudarDisplayModo3Continuacao:
	ldi temp, 0x01
	cpse qualDisplayModo3, temp
	rjmp mudarDisplayModo3Cont
	inc qualDisplayModo3
	rcall printSerialModo3D3 // uni min
	reti
	mudarDisplayModo3Cont:
	inc qualDisplayModo3
	rcall printSerialModo3D4 // dez min
	reti

	
botaoResetUniSeg:
	ldi temp, 0x00
	cpse verificarResetModo3, temp
	rjmp mudarBotaoModo3
	ldi temp, 0x09
	cpse contUniSeg, temp
	rjmp botaoResetUniSegCont
	ldi contUniSeg, 0x00
	ldi verificarResetModo3, 0x01
	reti
	botaoResetUniSegCont:
	inc contUniSeg
	ldi verificarResetModo3, 0x01
	reti

botaoResetDezSeg:
	ldi temp, 0x00
	cpse verificarResetModo3, temp
	rjmp mudarBotaoModo3
	ldi temp, 0x05
	cpse contDezSeg, temp
	rjmp botaoResetDezSegCont
	ldi contDezSeg, 0x00
	ldi verificarResetModo3, 0x01
	reti
	botaoResetDezSegCont:
	inc contDezSeg
	ldi verificarResetModo3, 0x01
	reti

botaoResetUniMin:
	ldi temp, 0x00
	cpse verificarResetModo3, temp
	rjmp mudarBotaoModo3
	ldi temp, 0x09
	cpse contUniMin, temp
	rjmp botaoResetUniMinCont
	ldi contUniMin, 0x00
	ldi verificarResetModo3, 0x01
	reti
	botaoResetUniMinCont:
	inc contUniMin
	ldi verificarResetModo3, 0x01
	reti

botaoResetDezMin:
	ldi temp, 0x00
	cpse verificarResetModo3, temp
	rjmp mudarBotaoModo3
	ldi temp, 0x05
	cpse contDezMin, temp
	rjmp botaoResetDezMinCont
	ldi contDezMin, 0x00
	ldi verificarResetModo3, 0x01
	reti
	botaoResetDezMinCont:
	inc contDezMin
	ldi verificarResetModo3, 0x01
	reti

mudarBotaoModo3:
	ldi verificarResetModo3, 0x00
	reti

BotaoReset:
	ldi display, 0b00000001
	out PORTB, display
	ldi temp, 0x01
	cpse qualModo, temp
	rjmp resetModo3
	ldi temp, 0x00
	cpse verificarResetModo3, temp
	rjmp mudarBotaoModo3
	ldi verificarResetModo3, 0x01
	rcall printSerialReset
	ldi temp, 0x00
	cpse qualStart, temp
	reti
	ldi contUniSeg, 0x00
	ldi contDezSeg, 0x00
	ldi contUniMin, 0x00
	ldi contDezMin, 0x00
	reti
	resetModo3:
	ldi temp, 0x02
	cpse qualModo, temp
	reti
	ldi temp, 0x00
	cpse qualDisplayModo3, temp
	rjmp dezSeg
	rjmp botaoResetUniSeg
	dezSeg:
	ldi temp, 0x01
	cpse qualDisplayModo3, temp
	rjmp uniMin
	rjmp botaoResetDezSeg
	uniMin:
	ldi temp, 0x02
	cpse qualDisplayModo3, temp
	rjmp botaoResetDezMin
	rjmp botaoResetUniMin
	uniSegZero:
	ldi contUniSeg, 0x00
	reti

portaSerial:
	rcall serialModo
	ldi temp, 0x00
	cp qualModo, temp
	breq contagem
	
	ldi temp, 0x01
	cpse qualModo, temp
	ret
	rcall printSerialZero
	ret

serialModo:
	ldi byte_tx, '['
    rcall transmit
	ldi byte_tx, 'M' ; Valor ASCII para 'M'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
    rcall transmit
    ldi byte_tx, 'D' ; Valor ASCII para 'D'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
    rcall transmit
	ldi byte_tx, 32  ; 
    rcall transmit
	mov numero, qualModo
	inc numero
	rcall representarNumero
	rcall transmit
	ldi byte_tx, ']'
    rcall transmit
	ldi byte_tx, 32  ; espaço
    rcall transmit
	ret

imprimir0:
	ldi temp, 0x00
	cpse inicial, temp
	ret
	ldi inicial, 0x01
	ldi byte_tx, '['
    rcall transmit
	ldi byte_tx, 'M'
    rcall transmit
    ldi byte_tx, 'O' 
    rcall transmit
    ldi byte_tx, 'D' 
    rcall transmit
    ldi byte_tx, 'O' 
    rcall transmit
	ldi byte_tx, 32 
    rcall transmit
	ldi byte_tx, '1' 
    rcall transmit
	ldi byte_tx, ']'
    rcall transmit
    ldi byte_tx, 32 
    rcall transmit
    ldi byte_tx, '0'
    rcall transmit
    ldi byte_tx, '0' 
    rcall transmit
	ldi byte_tx, ':'  
    rcall transmit
	ldi byte_tx, '0' 
    rcall transmit
    ldi byte_tx, '0' 
    rcall transmit
	ldi byte_tx, 10 
    rcall transmit
	ret

contagem:
	mov numero, contDezMin
	ldi temp, 0x0A
	cpse contUniSeg, temp
	rjmp contagemNormalDezMin
	ldi temp, 0x05
	cpse contDezSeg, temp
	rjmp contagemNormalDezMin
	ldi temp, 0x09
	cpse contUniMin, temp
	rjmp contagemNormalDezMin
	mov numero, contDezMin
	inc numero
	ldi temp, 0x06
	cpse numero, temp
	rjmp contagemNormalDezMin
	ldi numero, 0x00
	contagemNormalDezMin:
	rcall representarNumero
	rcall transmit
	mov numero, contUniMin
	ldi temp, 0x0A
	cpse contUniSeg, temp
	rjmp contagemNormal
	ldi temp, 0x05
	cpse contDezSeg, temp
	rjmp contagemNormal
	mov numero, contUniMin
	inc numero
	contagemNormal:
	rcall representarNumero
	rcall transmit
	ldi byte_tx, ':'
	rcall transmit  
	mov numero, contDezSeg
	rcall representarNumeroDezenas
	rcall transmit
	mov numero, contUniSeg
	rcall representarNumero
	rcall transmit
	ldi byte_tx, 10  
    rcall transmit
	ret

printSerialZero:
    ldi byte_tx, 'Z' ; Valor ASCII para 'M'
    rcall transmit
    ldi byte_tx, 'E' ; Valor ASCII para 'O'
    rcall transmit
    ldi byte_tx, 'R' ; Valor ASCII para 'D'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
    rcall transmit
	ldi byte_tx, 10  
    rcall transmit
	ret

printSerialReset:
	ldi byte_tx, '['
    rcall transmit
	ldi byte_tx, 'M' ; Valor ASCII para 'M'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
    rcall transmit
    ldi byte_tx, 'D' ; Valor ASCII para 'D'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
	rcall transmit
	ldi byte_tx, 32  ; 
    rcall transmit
    mov numero, qualModo
	inc numero
	rcall representarNumero
	rcall transmit
	ldi byte_tx, ']'
	rcall transmit
	ldi byte_tx, 32  ; 
    rcall transmit
    ldi byte_tx, 'R' ; Valor ASCII para 'M'
    rcall transmit
    ldi byte_tx, 'E' ; Valor ASCII para 'O'
    rcall transmit
    ldi byte_tx, 'S' ; Valor ASCII para 'D'
    rcall transmit
    ldi byte_tx, 'E' ; Valor ASCII para 'O'
    rcall transmit
	ldi byte_tx, 'T' ; Valor ASCII para 'O'
    rcall transmit
	ldi byte_tx, 10  
    rcall transmit
	ret

printSerialStart:
	ldi byte_tx, '['
    rcall transmit
	ldi byte_tx, 'M' ; Valor ASCII para 'M'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
    rcall transmit
    ldi byte_tx, 'D' ; Valor ASCII para 'D'
    rcall transmit
    ldi byte_tx, 'O' ; Valor ASCII para 'O'
	rcall transmit
	ldi byte_tx, 32  ; 
    rcall transmit
	mov numero, qualModo
	inc numero
	rcall representarNumero
	rcall transmit
	ldi byte_tx, ']'
    rcall transmit
	ldi byte_tx, 32  ; espaço
    rcall transmit
    ldi byte_tx, 'S' ; Valor ASCII para 'M'
    rcall transmit
    ldi byte_tx, 'T' ; Valor ASCII para 'O'
    rcall transmit
    ldi byte_tx, 'A' ; Valor ASCII para 'D'
    rcall transmit
    ldi byte_tx, 'R' ; Valor ASCII para 'O'
    rcall transmit
	ldi byte_tx, 'T' ; Valor ASCII para 'O'
    rcall transmit
	ldi byte_tx, 10  
    rcall transmit
	ret

representarNumeroDezenas:
	ldi temp, 0x00 
	cpse numero, temp
	rjmp pularZero
	ldi display, 0x0A
	cpse contUniSeg, display
	breq numero_eh_zero_dezena
	breq numero_eh_um_dezena

	pularZero:
	ldi temp, 0x01
	cpse numero, temp
	rjmp pularUm
	ldi display, 0x0A
	cpse contUniSeg, display
	breq numero_eh_um_dezena
	breq numero_eh_dois_dezena

	pularUm:
	ldi temp, 0x02
	cpse numero, temp
	rjmp pularDois
	ldi display, 0x0A
	cpse contUniSeg, display
	breq numero_eh_dois_dezena
	breq numero_eh_tres_dezena

	pularDois:
	ldi temp, 0x03
	cpse numero, temp
	rjmp pularTres
	ldi display, 0x0A
	cpse contUniSeg, display
	breq numero_eh_tres_dezena
	breq numero_eh_quatro_dezena

	pularTres:
	ldi temp, 0x04
	cpse numero, temp
	rjmp pularQuatro
	ldi display, 0x0A
	cpse contUniSeg, display
	breq numero_eh_quatro_dezena
	breq numero_eh_cinco_dezena

	pularQuatro:
	ldi display, 0x0A
	cpse contUniSeg, display
	breq numero_eh_cinco_dezena
	breq numero_eh_zero_dezena

	ret

numero_eh_zero_dezena:
    ldi byte_tx, '0'
    ret

numero_eh_um_dezena:
    ldi byte_tx, '1'
    ret

numero_eh_dois_dezena:
    ldi byte_tx, '2'
    ret

numero_eh_tres_dezena:
    ldi byte_tx, '3'
    ret

numero_eh_quatro_dezena:
    ldi byte_tx, '4'
    ret

numero_eh_cinco_dezena:
    ldi byte_tx, '5'
    ret

representarNumero:
	ldi temp, 0x00 ; Carrega o valor zero em um registrador temporário
	cp numero, temp
	breq numero_eh_zero

	ldi temp, 0x01 ; Carrega o valor 1 em um registrador temporário
	cp numero, temp
	breq numero_eh_um

	ldi temp, 0x02 ; Carrega o valor 2 em um registrador temporário
	cp numero, temp
	breq numero_eh_dois

	ldi temp, 0x03 ; Carrega o valor 3 em um registrador temporário
	cp numero, temp
	breq numero_eh_tres

	ldi temp, 0x04 ; Carrega o valor 4 em um registrador temporário
	cp numero, temp
	breq numero_eh_quatro

	ldi temp, 0x05 ; Carrega o valor 5 em um registrador temporário
	cp numero, temp
	breq numero_eh_cinco

	ldi temp, 0x06 ; Carrega o valor 6 em um registrador temporário
	cp numero, temp
	breq numero_eh_seis

	ldi temp, 0x07 ; Carrega o valor 7 em um registrador temporário
	cp numero, temp
	breq numero_eh_sete

	ldi temp, 0x08 ; Carrega o valor 8 em um registrador temporário
	cp numero, temp
	breq numero_eh_oito

	ldi temp, 0x09 ; Carrega o valor 9 em um registrador temporário
	cp numero, temp
	breq numero_eh_nove

	ldi temp, 0xA ; Carrega o valor 9 em um registrador temporário
	cp numero, temp
	breq numero_eh_dez

numero_eh_zero:
    ldi byte_tx, '0'
    ret

numero_eh_um:
    ldi byte_tx, '1'
    ret

numero_eh_dois:
    ldi byte_tx, '2'
    ret

numero_eh_tres:
    ldi byte_tx, '3'
    ret

numero_eh_quatro:
    ldi byte_tx, '4'
    ret

numero_eh_cinco:
    ldi byte_tx, '5'
    ret

numero_eh_seis:
    ldi byte_tx, '6'
    ret

numero_eh_sete:
    ldi byte_tx, '7'
   ret

numero_eh_oito:
    ldi byte_tx, '8'
    ret

numero_eh_nove:
    ldi byte_tx, '9'
   	ret
numero_eh_dez:
    ldi byte_tx, '0'
   	ret

printSerialModo3D1:
    ; Imprime "[MODO 3] Ajustando a unidade dos segundos"
    ldi byte_tx, '[' ;
    rcall transmit
    ldi byte_tx, 'M' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 'D' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, '3' ; 
    rcall transmit
    ldi byte_tx, ']' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'A' ; 
    rcall transmit
    ldi byte_tx, 'j' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 't' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
	ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'i' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 'g' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 10  ; Nova linha
    rcall transmit
    ret

printSerialModo3D2:
    ; Imprime "[MODO 3] Ajustando a dezena dos segundos"
    ldi byte_tx, '[' ;
    rcall transmit
    ldi byte_tx, 'M' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 'D' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, '3' ; 
    rcall transmit
    ldi byte_tx, ']' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'A' ; 
    rcall transmit
    ldi byte_tx, 'j' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 't' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
	ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 'z' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 'g' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 10  ; Nova linha
    rcall transmit
    ret


printSerialModo3D3:
    ; Imprime "[MODO 3] Ajustando a unidade dos minutos"
    ldi byte_tx, '[' ;
    rcall transmit
    ldi byte_tx, 'M' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 'D' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, '3' ; 
    rcall transmit
    ldi byte_tx, ']' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'A' ; 
    rcall transmit
    ldi byte_tx, 'j' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 't' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
	ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'i' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'm' ; 
    rcall transmit
    ldi byte_tx, 'i' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 't' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 10  ; Nova linha
    rcall transmit
    ret

printSerialModo3D4:
    ; Imprime "[MODO 3] Ajustando a dezena dos minutos"
    ldi byte_tx, '[' ;
    rcall transmit
    ldi byte_tx, 'M' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 'D' ; 
    rcall transmit
    ldi byte_tx, 'O' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, '3' ; 
    rcall transmit
    ldi byte_tx, ']' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'A' ; 
    rcall transmit
    ldi byte_tx, 'j' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 't' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
	ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 'z' ; 
    rcall transmit
    ldi byte_tx, 'e' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'a' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'd' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 32 ; 
    rcall transmit
    ldi byte_tx, 'm' ; 
    rcall transmit
    ldi byte_tx, 'i' ; 
    rcall transmit
    ldi byte_tx, 'n' ; 
    rcall transmit
    ldi byte_tx, 'u' ; 
    rcall transmit
    ldi byte_tx, 't' ; 
    rcall transmit
    ldi byte_tx, 'o' ; 
    rcall transmit
    ldi byte_tx, 's' ; 
    rcall transmit
    ldi byte_tx, 10  ; Nova linha
    rcall transmit
    ret


.def byte_tx = r16
transmit:
    lds r27, UCSR0A
    sbrs r27, UDRE0    ; Espera até que o buffer de transmissão esteja vazio
    rjmp transmit
	sts UDR0, byte_tx  ; Transmite o byte
    ret

