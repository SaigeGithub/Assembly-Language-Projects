;
; CSc 230 Assignment 1 
; Question 3
;
.include "m2560def.inc"
; This program should calculate:
; (D) = (A) + (B) + (C)
; 
; Where:
;   (A) refers to the byte stored at memory location A in data memory 
;   (B) refers to the byte stored at memory location B in data memory
;   (C) refers to the byte stored at memory location C in data memory
;   (D) refers to the byte stored at memory location D in data memory
;
; The sample code you've been given already contains labels named A, B, C and D.
;
; In the AVR there is no way to automatically initialize data memory
; with constant values.  This is why I have supplied code that copies values
; from program memory (which can be initialized by the assembler) into
; data memory. 
;

;--*1 Do not change anything between here and the line starting with *--
;
; You don't need to understand this code, we will get to it later
;
; But, if you are keen -- I am using the Z register as a pointer into
; program memory and X as a pointer into data memory
;
.cseg
	ldi ZH,high(init<<1)		; initialize Z to point to init
	ldi ZL,low(init<<1)
	lpm r0,Z+				; get the first byte and increment Z
	sts A,r0				; store into A
	lpm r0,Z+
	sts B,r0
	lpm r0,Z+
	sts C,r0
	clr r0
	sts D,r0
;*--1 Do not change anything above this line to the --*

;***
; Your code goes here:
;	
	clr r18
	clr r19
	clr r20
	lds r18,A
	lds r19,B
	lds r20,C
	add r18,r19
	add r18,r20
	sts D,r18

;****

;--*2 Do not change anything between here and the line starting with *--
done:	jmp done
;*--2

;--*3 Do not change anything between here and the line starting with *--
; These are the constants to initialize A, B and C to.
; Program memory must be specified in words (2 bytes) which
; is why there is a 4th byte (0x00) at the end.
init:	.db 0x03,0x05,0x08,0x00
;*--3

;--*4 Do not change anything between here and the line starting with *--
; This is in the data segment (ie. SRAM)
; The first real memory location in SRAM starts at location 0x200 on
; the ATMega 2560 processor.  Locations less than 0x200 are special
; and will be discussed much more later
;
.dseg
.org 0x200
A:	.byte 1
B:	.byte 1
C:	.byte 1
D:	.byte 1	
;*--4
