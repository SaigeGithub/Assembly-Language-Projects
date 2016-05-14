;
; a2q1.asm
;
; Write a program that displays the binary value in r16
; on the LEDs.
;
; See the assignment PDF for details on the pin numbers and ports.
;
;
;
; These definitions allow you to communicate with
; PORTB and PORTL using the LDS and STS instructions
;
.equ DDRB=0x24
.equ PORTB=0x25
.equ DDRL=0x10A
.equ PORTL=0x10B



		ldi r16, 0xFF
		sts DDRB, r16		; PORTB all output
		sts DDRL, r16		; PORTL all output

		ldi r16, 0x33		; display the value
		mov r0, r16			; in r0 on the LEDs

; Your code here
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

;
; Don't change anything below here
;
done:	jmp done
