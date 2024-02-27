outZERO2:
	ldi valorAnalisado, 0x00
	cpse contUniSeg, valorAnalisado
	rjmp outUM2
	
	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display
	
	rjmp outZERO2Dez

outUM2: 
	ldi valorAnalisado, 0x01
	cpse contUniSeg, valorAnalisado
	rjmp outDOIS2
	
	ldi display, UM
	out PORTD, display
	ldi display, 0b00000110
	out PORTB, display


	rjmp outZERO2Dez

outDOIS2: 
	ldi valorAnalisado, 0x02
	cpse contUniSeg, valorAnalisado
	rjmp outTRES2

	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display

	rjmp outZERO2Dez

outTRES2: 
	ldi valorAnalisado, 0x03
	cpse contUniSeg, valorAnalisado
	rjmp outQUATRO2
	
	ldi display, TRES
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display

	
	rjmp outZERO2Dez

outQUATRO2: 
	ldi valorAnalisado, 0x04
	cpse contUniSeg, valorAnalisado
	rjmp outCINCO2

	ldi display, QUATRO
	out PORTD, display
	ldi display, 0b00000110
	out PORTB, display


	rjmp outZERO2Dez

outCINCO2:	
	ldi valorAnalisado, 0x05
	cpse contUniSeg, valorAnalisado
	rjmp outSEIS2
	
	ldi display, CINCO
	out PORTD, display
	ldi display, 0b00000101
	out PORTB, display


	rjmp outZERO2Dez

outSEIS2: 
	ldi valorAnalisado, 0x06
	cpse contUniSeg, valorAnalisado
	rjmp outSETE2
	
	ldi display, SEIS
	out PORTD, display
	ldi display, 0b00000101
	out PORTB, display


	rjmp outZERO2Dez

outSETE2: 
	ldi valorAnalisado, 0x07
	cpse contUniSeg, valorAnalisado
	rjmp outOITO2
	
	ldi display, SETE
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display


	rjmp outZERO2Dez

outOITO2: 
	ldi valorAnalisado, 0x08
	cpse contUniSeg, valorAnalisado
	rjmp outNOVE2
	
	ldi display, OITO
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display


	rjmp outZERO2Dez

outNOVE2:
	ldi display, NOVE
	out PORTD, display
	ldi display, 0b00000111
	out PORTB, display

	rjmp outZERO2Dez
	
outZERO2Dez: 
	ldi valorAnalisado, 0x00
	cpse contDezSeg, valorAnalisado

	rjmp outUM2Dez

	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00001011
	out PORTB, display
	
	rjmp outZERO2Min
	
outUM2Dez: 
	ldi valorAnalisado, 0x01
	cpse contDezSeg, valorAnalisado
	rjmp outDOIS2Dez
	
	ldi display, UM
	out PORTD, display
	ldi display, 0b00001010
	out PORTB, display

	
	rjmp outZERO2Min

outDOIS2Dez: 
	ldi valorAnalisado, 0x02
	cpse contDezSeg, valorAnalisado
	rjmp outTRES2Dez
	
	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00001011
	out PORTB, display

	rjmp outZERO2Min

outTRES2Dez: 
	ldi valorAnalisado, 0x3
	cpse contDezSeg, valorAnalisado
	rjmp outQUATRO2Dez
	
	ldi display, TRES
	out PORTD, display
	ldi display, 0b00001011
	out PORTB, display

	rjmp outZERO2Min

outQUATRO2Dez: 
	ldi valorAnalisado, 0x4
	cpse contDezSeg, valorAnalisado
	rjmp outCINCO2Dez
	
	ldi display, QUATRO
	out PORTD, display
	ldi display, 0b00001010
	out PORTB, display

	rjmp outZERO2Min

outCINCO2Dez: 
	ldi display, CINCO
	out PORTD, display
	ldi display, 0b00001001
	out PORTB, display

	
	rjmp outZERO2Min

; MINUTOS

outZERO2Min: 
	ldi valorAnalisado, 0x00
	cpse contUniMin, valorAnalisado
	rjmp outUM2Min

	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display


	rjmp outZERO2MinDez

outUM2Min: 
	ldi valorAnalisado, 0x1
	cpse contUniMin, valorAnalisado
	rjmp outDOIS2Min

	ldi display, UM
	out PORTD, display
	ldi display, 0b00010010
	out PORTB, display


	rjmp outZERO2MinDez

outDOIS2Min: 
	ldi valorAnalisado, 0x2
	cpse contUniMin, valorAnalisado
	rjmp outTRES2Min

	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display

	rjmp outZERO2MinDez

outTRES2Min: 
	ldi valorAnalisado, 0x3
	cpse contUniMin, valorAnalisado
	rjmp outQUATRO2Min

	ldi display, TRES
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display
	
	rjmp outZERO2MinDez

outQUATRO2Min: 
	ldi valorAnalisado, 0x4
	cpse contUniMin, valorAnalisado
	rjmp outCINCO2Min

	ldi display, QUATRO
	out PORTD, display
	ldi display, 0b00010010
	out PORTB, display
	
	rjmp outZERO2MinDez

outCINCO2Min:	
	ldi valorAnalisado, 0x5
	cpse contUniMin, valorAnalisado
	rjmp outSEIS2Min

	ldi display, CINCO
	out PORTD, display
	ldi display, 0b00010001
	out PORTB, display

	rjmp outZERO2MinDez

outSEIS2Min: 
	ldi valorAnalisado, 0x6
	cpse contUniMin, valorAnalisado
	rjmp outSETE2Min

	ldi display, SEIS
	out PORTD, display
	ldi display, 0b00010001
	out PORTB, display
	
	rjmp outZERO2MinDez

outSETE2Min: 
	ldi valorAnalisado, 0x07
	cpse contUniMin, valorAnalisado
	rjmp outOITO2Min

	ldi display, SETE
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display
	
	rjmp outZERO2MinDez

outOITO2Min: 
	ldi valorAnalisado, 0x8
	cpse contUniMin, valorAnalisado
	rjmp outNOVE2Min

	ldi display, OITO
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display

	rjmp outZERO2MinDez

outNOVE2Min: 
	ldi display, NOVE
	out PORTD, display
	ldi display, 0b00010011
	out PORTB, display


	rjmp outZERO2MinDez

outZERO2MinDez: 	
	ldi valorAnalisado, 0x00
	cpse contDezMin, valorAnalisado
    rjmp outUM2MinDez

	ldi display, ZERO
	out PORTD, display
	ldi display, 0b00100011
	out PORTB, display

	rjmp outZero2

outUM2MinDez: 
	ldi valorAnalisado, 0x1
	cpse contDezMin, valorAnalisado
	rjmp outDOIS2MinDez

	ldi display, UM
	out PORTD, display
	ldi display, 0b00100010
	out PORTB, display

	
	rjmp outZero2

outDOIS2MinDez: 
	ldi valorAnalisado, 0x2
	cpse contDezMin, valorAnalisado
	rjmp outTRES2MinDez
	
	ldi display, DOIS
	out PORTD, display
	ldi display, 0b00100011
	out PORTB, display

	rjmp outZero2

outTRES2MinDez: 
	ldi valorAnalisado, 0x3
	cpse contDezMin, valorAnalisado
	rjmp outQUATRO2MinDez
	
	ldi display, TRES
	out PORTD, display
	ldi display, 0b00100011
	out PORTB, display
	
	rjmp outZero2

outQUATRO2MinDez: 
	ldi valorAnalisado, 0x4
	cpse contDezMin, valorAnalisado
	rjmp outCINCO2MinDez
	
	ldi display, QUATRO
	out PORTD, display
	ldi display, 0b00100010
	out PORTB, display

	rjmp outZero2

outCINCO2MinDez: 	
	ldi display, CINCO
	out PORTD, display
	ldi display, 0b00100001
	out PORTB, display

	rjmp outZero2	