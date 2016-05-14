#define LCD_LIBONLY
.include "lcd.asm"

.cseg
.def temp = r18
.def rmp = R20 ; Multi purpose register
jmp main

main:
	; init. stack
	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	ldi r19, 0 ; LED status 
	ldi r17, 0 ; extra delay count
	out SPH, r29
	out SPL, r28

	call init
	call lcd_init
	call lcd_clr
	call init_strings
	call init_ptrs

	lp: 
		call lcd_clr
		call cpy_msg
		call display_strings
		call inc_pointers
		call pull
		call toggleLED
		call pull
		call extraDelay
		rjmp lp

end:
	rjmp end

extraDelay:
	push r16
	ldi r16, 0
	edForLoop:
		cp r16, r17
		brge edForEnd
		call pull
		inc r16
		rjmp edForEnd
	edForEnd:
	pop r16
	ret

; initialization for ADC
init:
	;init the A/D converter
	;set MUX to channel 0, left adjust the result, AREF taken from AVCC
	ldi rmp, 0b01100000 ; ADMUX channel 0, AREF from AVCC
	ldi r26,ADMUX		;ADMUX is memory mapped
	ldi r27,0
	st X,rmp			; write to ADMUX
	; switch AD conversion on, start conversion, divider rate = 128
	ldi rmp,(1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	ldi r26,ADCSRA
	ldi r27,0
	st X,rmp			;set various required bits and init the A to D converter
	ret

; pull & sleep
pull:
	; wait until the AD conversion is complete
	rcall delay		; 0.5 sec delay
	;cbi PortB, 3; switch off the LED on port b3
	;cbi PortB, 1; switch off the LED on port b3

	; read MSB of the AD conversion result
	ldi r26,ADCH	;ADCH has left shifted value of A to D conersion
	ldi r27,0
	ld temp, X		; get into R18

	; is the value < 10; if so right key pressed.
	CPI temp, 10 ;checks if ADC result is higher or equal to voltage
	BRLO exitRight	
	CPI temp, 40
	BRLO exitUp
	CPI temp, 100
	BRLO exitDown
	CPI temp, 150
	BRLO exitLeft
	ret
exitRight:
	inc r17
	ret
exitUp:
	call pull_paused
	ret
exitDown:
	ret
exitLeft:
	dec r17
	ret

pull_paused:
	; wait until the AD conversion is complete
	rcall delay		; 0.5 sec delay

	; read MSB of the AD conversion result
	ldi r26,ADCH	;ADCH has left shifted value of A to D conersion
	ldi r27,0
	ld temp, X		; get into R18

	; is the value < 10; if so right key pressed.
	CPI temp, 10 ;checks if ADC result is higher or equal to voltage
	BRLO exitRightP	
	CPI temp, 40
	BRLO exitUpP
	CPI temp, 100
	BRLO exitDownP
	CPI temp, 150
	BRLO exitLeftP
	rjmp pull_paused
exitRightP:
	rjmp pull_paused
exitUpP:
	rjmp pull_paused
exitDownP:
	ret
exitLeftP:
	rjmp pull_paused

;;; not used in the latest algorithm, remains here just in case ;;;
;;; memo: stopped using due to performance reason ;;;
; int strlen(char* string)
; string: r21:r20
; return: r25
; uses: r16,r28,r29,r30,r31,r2,r3
stringlen:
	.def count = r2
	.def char = r3

	push r16
	push r31
	push r30
	push r28
	push r29
	push r2
	push r3

	ldi r16, 0

	; allocate space for local variables and parameters
	; var: int count [8 bit]
	; parm: char* string [16 bit]
	; total: 3 bytes
	sbiw r29:r28, 3
	out SPH, r29
	out SPL, r28

	; str parm to stack
	std Y+1, r21 ; std r29:r28+1, r21
	std Y+2, r20 ; std r29:r28+2, r20

	; str count to stack
	std Y+3, r16 ; std r29:r28+3, r16

	; ldr vars to regs
	ldd r31, Y+1
	ldd r30, Y+2
	ldd count, Y+3

	loop:
		; ldr next char
		lpm char, Z+ ; lpm char, r31:r30+
		cp char, r16 ; check for '\0'
		breq loopend
		inc count
		rjmp loop
	loopend:

	; str result to r25
	mov r25, count

	; free local variables and parameters
	adiw r29:r28, 3
	out SPH, r29
	out SPL, r28

	pop r3
	pop r2
	pop r29
	pop r28
	pop r30
	pop r31
	pop r16
	ret

;
; An improved version of the button test subroutine
;
; Returns in r24:
;	0 - no button pressed
;	1 - right button pressed
;	2 - up button pressed
;	4 - down button pressed
;	8 - left button pressed
;	16- select button pressed
;
; this function uses registers:
;	r16
;	r17
;	r24
;
; if you consider the word:
;	 value = (ADCH << 8) +  ADCL
; then:
;
; value > 0x3E8 - no button pressed
;
; Otherwise:
; value < 0x032 - right button pressed
; value < 0x0C3 - up button pressed
; value < 0x17C - down button pressed
; value < 0x22B - left button pressed
; value < 0x316 - select button pressed
; 
check_button:
		push r16
		push r17
		push r24
		
		; start a2d
		lds	r16, ADCSRA	
		ori r16, 0x40
		sts	ADCSRA, r16

		; wait for it to complete
wait:	lds r16, ADCSRA
		andi r16, 0x40
		brne wait

		; read the value
		lds r16, ADCL
		lds r17, ADCH

		clr r24
		cpi r17, 3			;  if > 0x3E8, no button pressed 
		brne bsk1		    ;  
		cpi r16, 0xE8		; 
		brsh bsk_done		; 
bsk1:	tst r17				; if ADCH is 0, might be right or up  
		brne bsk2			; 
		cpi r16, 0x32		; < 0x32 is right
		brsh bsk3
		ldi r24, 0x01		; right button
		rjmp bsk_done
bsk3:	cpi r16, 0xC3		
		brsh bsk4	
		ldi r24, 0x02		; up			
		rjmp bsk_done
bsk4:	ldi r24, 0x04		; down (can happen in two tests)
		rjmp bsk_done
bsk2:	cpi r17, 0x01		; could be up,down, left or select
		brne bsk5
		cpi r16, 0x7c		; 
		brsh bsk7
		ldi r24, 0x04		; other possiblity for down
		rjmp bsk_done
bsk7:	ldi r24, 0x08		; left
		rjmp bsk_done
bsk5:	cpi r17, 0x02
		brne bsk6
		cpi r16, 0x2b
		brsh bsk6
		ldi r24, 0x08
		rjmp bsk_done
bsk6:	ldi r24, 0x10
bsk_done:
		cpi r24, 1
		breq good
		rjmp notGood
		good:
		call toggleLED
		notGood:

		pop r24
		pop r17
		pop r16
		ret

; set l1ptr && l2ptr to point at the start of the display strings
init_ptrs:
	push r26
	push r27
	push r20
	push r21

	ldi r26, low(l1ptr)
	ldi r27, high(l1ptr)

	ldi r20, low(msg1)
	ldi r21, high(msg1)
	st X+, r20
	st X, r21

	ldi r26, low(l2ptr)
	ldi r27, high(l2ptr)

	ldi r20, low(msg2)
	ldi r21, high(msg2)
	st X+, r20
	st X, r21

	pop r21
	pop r20
	pop r27
	pop r26
	ret

; move the pointers forward (wrap around when appropriate)
inc_pointers:
	push r18 ; tempChar
	push YL ; lineN_low
	push YH ; lineN_high
	push ZL ; lNptr_low
	push ZH ; lNptr_high
	push XL ; *lNptr_low
	push XH ; *lNptr_high
	
	; for line1
	ldi ZL, low(l1ptr)
	ldi ZH, high(l1ptr)
	ld XL, Z+
	ld XH, Z

	ld r18, X+
	ld r18, X
	cpi r18, 0x00
	brne noReset01
	; update ptr
	ldi XL, low(msg1)
	ldi XH, high(msg1)
	noReset01:
	ldi ZL, low(l1ptr)
	ldi ZH, high(l1ptr)
	st Z+, XL
	st Z, XH

	; for line2
	ldi ZL, low(l2ptr)
	ldi ZH, high(l2ptr)
	ld XL, Z+
	ld XH, Z

	ld r18, X+
	ld r18, X
	cpi r18, 0x00
	brne noReset02
	; update ptr
	ldi XL, low(msg2)
	ldi XH, high(msg2)
	noReset02:
	ldi ZL, low(l2ptr)
	ldi ZH, high(l2ptr)
	st Z+, XL
	st Z, XH

	pop XH
	pop XL
	pop ZH
	pop ZL
	pop YH
	pop YL
	pop r18
	ret

; copy from the pointers in msg1 and msg2 to line1 and line2
cpy_msg:
	push r17 ; i
	push r18 ; tempChar
	push YL ; lineN_low
	push YH ; lineN_high
	push ZL ; lNptr_low
	push ZH ; lNptr_high
	push XL ; *lNptr_low
	push XH ; *lNptr_high

	; for line1
	ldi YL, low(line1)
	ldi YH, high(line1)
	ldi ZL, low(l1ptr)
	ldi ZH, high(l1ptr)
	ld XL, Z+
	ld XH, Z

	ldi r17, 0
	forLoop1Start:
		cpi r17, 16
		brge forLoop1End
		ld r18, X+
		cpi r18, 0x00
		breq resetPtr1
		st Y+, r18
		rjmp copyCompleted1	
		resetPtr1:
		ldi XL, low(msg1)
		ldi XH, high(msg1)
		rjmp forLoop1Start
		copyCompleted1:
		inc r17
		rjmp forLoop1Start
	forLoop1End:
	ldi r18, 0
	st Y, r18 ; add '\0'

	; for line2
	ldi YL, low(line2)
	ldi YH, high(line2)
	ldi ZL, low(l2ptr)
	ldi ZH, high(l2ptr)
	ld XL, Z+
	ld XH, Z

	ldi r17, 0
	forLoop2Start:
		cpi r17, 16
		brge forLoop2End
		ld r18, X+
		cpi r18, 0x00
		breq resetPtr2
		st Y+, r18
		rjmp copyCompleted2	
		resetPtr2:
		ldi XL, low(msg2)
		ldi XH, high(msg2)
		rjmp forLoop2Start
		copyCompleted2:
		inc r17
		rjmp forLoop2Start
	forLoop2End:
	ldi r18, 0
	st Y, r18 ; add '\0'

	pop XH
	pop XL
	pop ZH
	pop ZL
	pop YH
	pop YL
	pop r18
	pop r17
	ret

; void delay(500); // sleep for 500 ms
delay:
	push r16
	push r24
	push r25
	ldi r16, 8

	loop_i:
		ldi r25, low(3037)
		ldi r25, high(3037)
		loop_j:
			adiw r25:r24, 1
			;push r24
			;call check_button
			;cpi r24, 2
			;breq infiniteLoop
			;rjmp notInTheLoop
			;infiniteLoop:
			;	rjmp infiniteLoop
			;notInTheLoop:
			;pop r24
			brne loop_j

		dec r16
		brne loop_i

	pop r25
	pop r24
	pop r16
	ret

init_strings:
	push r16

	; copyStr(prgmMem, dataMem)
	ldi r16, high(msg1) ; dest
	push r16
	ldi r16, low(msg1)
	push r16
	ldi r16, high(msg1_p << 1) ; src
	push r16
	ldi r16, low(msg1_p << 1)
	push r16
	call str_init	; cpy(prgm, data)
	pop r16			; rm(parm)
	pop r16
	pop r16
	pop r16

	ldi r16, high(msg2)
	push r16
	ldi r16, low(msg2)
	push r16
	ldi r16, high(msg2_p << 1)
	push r16
	ldi r16, low(msg2_p << 1)
	push r16
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16

	pop r16
	ret

display_strings:
	push r16
	call lcd_clr

	ldi r16, 0x00
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	; disp(msg1)
	ldi r16, high(line1)
	push r16
	ldi r16, low(line1)
	push r16
	call lcd_puts
	pop r16
	pop r16

	; mvCurs(secondLine)
	ldi r16, 0x01
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	; disp(msg2)
	ldi r16, high(line2)
	push r16
	ldi r16, low(line2)
	push r16
	call lcd_puts
	pop r16
	pop r16
	
	pop	r16
	ret

toggleLED:
	push r16
	ldi r16, 0xFF
	out DDRB, r16
	cpi r19, 0
	brne turnOn
	sbi PortB, 3; turn off
	cbi PortB, 1
	ldi r19, 1
	rjmp endProcess
	turnOn:
	cbi PortB, 3; turn on
	sbi PortB, 1
	ldi r19,0
	endProcess:
	pop r16
	ret

;button_response:
;	push r24
;	call check_button
;	cpi r24, 0
;	breq infiniteLoop
;	rjmp notInTheLoop
;	infiniteLoop:
;		rjmp infiniteLoop
;	notInTheLoop:
;	pop r24
;	ret

msg1_p:	.db "This is the message on the first line. Here it goes.", 0
msg2_p:	.db "---buy---more---pop---buy ", 0

.dseg
msg1:	.byte 200
msg2:	.byte 200

line1:	.byte 17
line2:	.byte 17

l1ptr:	.byte 2
l2ptr:	.byte 2
