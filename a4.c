/*
Saige Liu
V00812068
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "main.h"
#include "lcd_drv.h"
#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>


// These are included by the LCD driver code, so 
// we don't need to include them here.
// #include <avr/io.h>
// #include <util/delay.h>

int main( void )
{

	// Before loop
	lcd_init();
	//initialize the lcd
	int speed=500;
	//change the number value to change speed.
	char *msg1 =" My name is Saige, How are you today";
	char *msg2 =" press left to speed up, press right to slow down";
	char *mp1=msg1;
	char *mp2 =msg2;
	char line1[17];
	char line2[17];
	char *ptr1=msg1;
	char *ptr2=msg2;


	line1[16]='\0';
	line2[16]='\0';
		
	
	lcd_puts(line1);

	int e=17;
	//to light the LED, use e to contorl the display value function.
	for (;;)
	{
		e--;
		if(e==1){
			e=17;
		}
		//The display function have no larger than 17 return value
		lcd_init();
	
		lcd_xy( 0, 0 );
			if(*ptr1==0){
				ptr1=msg1;
	
			}
			if(*ptr2==0){
				ptr2=msg2;
		
		
			}
		char *lp1=line1;
		char *lp2=line2;
		mp1=ptr1;
		mp2=ptr2;

		for(int k=0;k<16;k++){
			if(*mp1==0){
				mp1=msg1;
	
			}
			if(*mp2==0){
	
				mp2=msg2;
	
			}	
			*lp1=*mp1;
			lp1++;
			mp1++;
			*lp2=*mp2;
			lp2++;
			mp2++;
		}

		lcd_puts(line1);


		lcd_xy( 0, 1 );
		lcd_puts(line2);
	
		_delay_ms(speed);
	
		if(check_buttons()==2){
			suspend();
	
		}else if(check_buttons()==4){

			speed=250;


		}else if(check_buttons()==1){

			speed=6000;
		}
		ptr1++;
		ptr2++;

		displayValue(e);
	}
}


void suspend(){
	for(;;){
		if(check_buttons()==3){
			return;
		}



	}


}

int check_buttons(void)
{
	unsigned int count = 0;

	/* set PORTL and PORTB for output*/
	DDRL = 0xFF;
	DDRB = 0xFF;


	/* enable A2D: */

	/* ADCSRA:
	 * bit 7 - ADC enable
	 * bit 6 - ADC start conversion
	 * bit 5 - ADC auto trigger enable
	 * bit 4 - ADC interrupt flag
	 * bit 3 - ADC interrupt enable
	 * bit 2 |
	 * bit 1 |- ADC prescalar select bits
	 * bit 0 |
	 * 
	 * we want:
	 * 0b1000 0111
	 * which is:
	 * 0x87
	 */
	ADCSRA = 0x87;

	/* ADMUX - ADC Multiplexer Selection Register
	 *
	 * Select ADC0
     */
	ADMUX = 0x40;
	
	//for (;;)
	//{

	// start conversion
	ADCSRA |= 0x40;

	// bit 6 in ADCSRA is 1 while conversion is in progress
	// 0b0100 0000
	// 0x40
	while (ADCSRA & 0x40)
		;
	unsigned int val = ADCL;
	unsigned int val2 = ADCH;

	val += (val2 << 8);

	count = count + 1;
	
	if (val > 1000 )
	{
		//displayValue(0);
		//continue;
	}
			 
   if (val < 50) 
	 // displayValue(1);  
	 return 1;
    else if (val < 195)
		
		return 2;
	 // displayValue(2);
    else if (val < 380)  
	 // displayValue(4);
	 	return 3;
    else if (val < 555)  
	//  displayValue(8);
	return 4;
    else 
//	  //displayValue(16);
	   return 5;
	
//	}
}
/*
 * button.c
 *
 * An example of using the buttons on the LCD shield
 *
 * The buttons are all wired to Analog Pin 0 which is PORT F, Pin 0
 * Also known as ADC0
 *
 * From the arduino example sketch, we have:
 *
 *  if (adc_key > 1000 )   return btnNONE;
 *  if (adc_key_in < 50)   return btnRIGHT;  
 *  if (adc_key_in < 195)  return btnUP; 
 *  if (adc_key_in < 380)  return btnDOWN; 
 *  if (adc_key_in < 555)  return btnLEFT; 
 *  if (adc_key_in < 790)  return btnSELECT;   
 */

void displayValue ( int val )
{
	unsigned char toL = 0x00;
	unsigned char toB = 0x00;

	// We only have six LEDs, so only six bits of precision
	// mask off the rest
	// 0b0011 1111
	// 0x3F
	val = val & 0x3F;

	// This should be a loop but... 
	if (val & 0x01)
		toL |= 0x80;
	if (val & 0x02)
		toL |= 0x20;
	if (val & 0x04)
		toL |= 0x08;
	if (val & 0x08)
		toL |= 0x02;
	if (val & 0x10)
		toB |= 0x08;
	if (val & 0x20)
		toB |= 0x02;
	
	PORTB = toB;
	PORTL = toL;	
}
