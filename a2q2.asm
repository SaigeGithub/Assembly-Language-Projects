;
; a2q2.asm
;
;
; Turn the code you wrote in a2q1.asm into a subroutine
; and then use that subroutine with the delay subroutine
; to have the LEDs count up in binary.
;
;
; These definitions allow you to communicate with
; PORTB and PORTL using the LDS and STS instructions
;
.equ DDRB=0x24
.equ PORTB=0x25
.equ DDRL=0x10A
.equ PORTL=0x10B


; Your code here
; Be sure that your code is an infite loop


clr r0
start:
		call display
		inc r0
		ldi	r20, 0x0A
		call delay

		jmp start




done:		jmp done	; if you get here, you're doing it wrong

;
; display
; 
; display the value in r0 on the 6 bit LED strip
;
; registers used:
;	r0 - value to display
;
display:

pin1:	clr r18
		clr r19
		mov r16, r0
		andi r16, 0b00100000
		breq pin2
		ori r18,0b00000010
		

pin2:	
		mov r16, r0
		andi r16, 0b00010000
		breq pin3
		ori r18,0b00001000

pin3:	
		mov r16, r0
		andi r16,0b00001000
		breq pin4
		ori r19,0b00000010

pin4:
		mov r16, r0
		andi r16,0b00000100
		breq pin5
		ori r19, 0b00001000

pin5:
		mov r16, r0
	
		andi r16,0b00000010
		breq pin6
		ori r19, 0b00100000

pin6:
		mov r16, r0
		andi r16,0b00000001
		breq fin
		ori r19, 0b10000000

fin:
	sts PORTB, r18
	sts PORTL, r19


		ret
;
; delay
;
; set r20 before calling this function
; r20 = 0x40 is approximately 1 second delay
;
; registers used:
;	r20
;	r21
;	r22
;
delay:	
del1:	nop
		ldi r21,0xFF
del2:	nop
		ldi r22, 0xFF
del3:	nop
		dec r22
		brne del3
		dec r21
		brne del2
		dec r20
		brne del1	
		ret
