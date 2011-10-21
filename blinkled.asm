;-------------------------------------------------------------------------------
; blinkasm.S - gcc compatible interrupt driven led blinker in msp430 asm
;-------------------------------------------------------------------------------
#include <msp430.h>

;-------------------------------------------------------------------------------
;;; ---- gcc doesn't know about PC,SP,SR,CG1,CG2 ----

#define PC r0                   
#define SP r1
#define SR r2
#define CG1 r2
#define CG2 r3

;-------------------------------------------------------------------------------
;;; --- devices with only one TimerA don't bother to number the defines ---
#ifndef TA0CCR0
#define TA0CCR0 CCR0
#define TA0CCTL0 CCTL0
#endif

;-------------------------------------------------------------------------------
;;; ---- global register usage ----

#define TIMER_CYCLES R11
#define INTERVAL_CNT R12
#define indx R13

;-------------------------------------------------------------------------------
;;; ---- CONSTANTS ----

#if 0
#define _50uSEC 50         /* @1MHz MCLK this works out to be 50uSec/interrupt */
#define _500MSEC 10000     /* @1MHz MCLK this works out to be 500ms/LED toggle */
#else
#define _50uSEC 24         /* @1MHz MCLK this works out to be 50uSec/interrupt */
#define _500MSEC 1     /* @1MHz MCLK this works out to be 500ms/LED toggle */
#endif
#define LED_PIN BIT6       /* PORT1 pin, Launchpad has BIT0=Red and BIT6=Green */

;-------------------------------------------------------------------------------
        .text
;-------------------------------------------------------------------------------
RESET_ISR:
        mov.w   #__stack,SP
        mov.w   #WDTPW+WDTHOLD,&WDTCTL

	;; initialize clock,gpio,timer
init:
	;; MCLK set to precalibrated 1MHz
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ,&BCSCTL1
        mov.b   &CALDCO_1MHZ,&DCOCTL
	mov.w   #TA0CCR0,R5

	;; setup global register values
	mov.w   #_50uSEC,TIMER_CYCLES           ; initialize register constant 
	mov.w   #_500MSEC,INTERVAL_CNT 		; initialize register constant 
        mov.w   INTERVAL_CNT,indx               ; initialize register counter

	;; initialize GPIO
        bis.b   #LED_PIN,&P1DIR                 ; Configure P1.0 as output pin

	;; intialize TimerA0
        mov.w   #CCIE,&TA0CCTL0                 ; Enable TA0CCR0 interrupt
        mov.w   TIMER_CYCLES,&TA0CCR0           ; Set TIMER_CYCLES cycles
        mov.w   #TASSEL_2+MC_2,&TACTL           ; SMCLK+Continuous Up Mode

	eint

endlessLoop:
	jmp 	endlessLoop

;-------------------------------------------------------------------------------
; TIMER0_A0_ISR - TimerA0 CCR0 interrupt handler
;-------------------------------------------------------------------------------
TIMER0_A0_ISR:
        dec.w   indx                            ; have we reached the interval cnt?
        jnz     timer0_a0_exit                  ; exit if we haven't reached 0

	;; toggle led pin after INTERVAL * TIMER_CYCLES
        xor.b   #LED_PIN,&P1OUT                 ; Toggle P1.0
        mov.w   INTERVAL_CNT,indx               ; Reset count down interval counter
       
timer0_a0_exit:
        add.w   TIMER_CYCLES,&TA0CCR0           ; reload CCR0
        reti

;------------------------------------------------------------------------------
; UNEXPECTED_ISR - default handler for unhandled interrupt
;-------------------------------------------------------------------------------
UNEXPECTED_ISR:
        reti

;------------------------------------------------------------------------------
; Interrupt Vectors - see the datasheet for your chip
;                    *msp430g2553 vectors described below
;------------------------------------------------------------------------------
        .section ".vectors", "ax", @progbits
        .word UNEXPECTED_ISR    ;0xffe0 slot  0  0
        .word UNEXPECTED_ISR  	;0xffe2 slot  1  2
        .word UNEXPECTED_ISR    ;0xffe4 slot  2  4 (PORT1_VECTOR)
        .word UNEXPECTED_ISR    ;0xffe6 slot  3  6 (PORT2_VECTOR)
        .word UNEXPECTED_ISR    ;0xffe8 slot  4  8 
        .word UNEXPECTED_ISR    ;0xffea slot  5  A (ADC10_VECTOR)
        .word UNEXPECTED_ISR    ;0xffec slot  6  C (USCIAB0TX_VECTOR) 
        .word UNEXPECTED_ISR    ;0xffee slot  7  E (USCIAB0RX_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff0 slot  8 10 (TIMER0_A1_VECTOR)
        .word TIMER0_A0_ISR     ;0xfff2 slot  9 12 (TIMER0_A0_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff4 slot 10 14 (WDT_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff6 slot 11 16 (COMPARATORA_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff8 slot 12 18 (TIMER1_A1_VECTOR)
        .word UNEXPECTED_ISR    ;0xfffa slot 13 1a (TIMER1_A0_VECTOR)
        .word UNEXPECTED_ISR    ;0xfffc slot 14 1c (NMI_VECTOR)
        .word RESET_ISR         ;0xfffe slot 15 1e (RESET_VECTOR)
        .end