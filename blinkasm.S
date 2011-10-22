;-------------------------------------------------------------------------------
; blinkasm.S - gcc compatible interrupt driven led blinker in msp430 asm
;
; Version 1.0 - 10/22/2011 rick@kimballsoftware.com
;	
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
;;; ---- CONSTANTS ----

//#define TEST_IRQ_OVERHEAD

#ifndef TEST_IRQ_OVERHEAD
 #define _50USEC (50-1)   /* @1MHz MCLK results in 50uSec/interrupt */
 #define _500MSEC 10000   /* @1MHz MCLK results in 500ms/LED toggle */
#else
 ;; This test illustrates the minimum CCR0 value that can be used
 ;; 22 cycles is based on the interrupt overhead
 #define _50USEC 22       /* @1MHz MCLK results in 23uSec/interrupt */
 #define _500MSEC 1       /* @1MHz MCLK results in 23uSec/LED toggle */
#endif
#define _LED_PIN BIT6     /* PORT1 pin, Launchpad has BIT0=Red and BIT6=Green */

;-------------------------------------------------------------------------------
;;; ---- Registers used as globals ----

#define LED_PIN r4
#define TIMER_CYCLES r5
#define INTERVAL_CNT r6
#define cnt r7

;-------------------------------------------------------------------------------
        .text
;-------------------------------------------------------------------------------
RESET_ISR:
        ;; disable watchdog and set stack to highest RAM addr
        mov.w   #WDTPW+WDTHOLD,&WDTCTL
        mov.w   #__stack,SP                     ; gcc ldscripts compute __stack based on mmcu

        ;; initialize clock,gpio,timer
init:
        ;; set MCLK to precalibrated 1MHz
        clr.b   &DCOCTL
        mov.b   &CALBC1_1MHZ,&BCSCTL1
        mov.b   &CALDCO_1MHZ,&DCOCTL

        ;; initialize global register values
        mov.w   #_LED_PIN,LED_PIN               ; load constant into register constant
        mov.w   #_50USEC,TIMER_CYCLES           ; load constant into register constant
        mov.w   #_500MSEC,INTERVAL_CNT          ; load constant into register constant
        mov.w   INTERVAL_CNT,cnt                ; initialize register based counter

        ;; initialize GPIO
        bic.b   LED_PIN,&P1OUT                  ; LED turned off to start
        bis.b   LED_PIN,&P1DIR                  ; Configure P1.0 as output pin

        ;; initialize TimerA0
        mov.w   #CCIE,&TA0CCTL0                 ; Enable TA0CCR0 interrupt
        mov.w   TIMER_CYCLES,&TA0CCR0           ; Set TIMER_CYCLES cycles
        mov.w   #TASSEL_2+MC_2,&TACTL           ; SMCLK+Continuous Up Mode

        ;; enable interrupts and loop forever
        ;; real work done in the CCR0 interrupt
        eint

endlessLoop:
        ;; Note: could sleep here instead
        jmp     endlessLoop                     ; cycles:2

;-------------------------------------------------------------------------------
; TIMER0_A0_ISR - TimerA0 CCR0 interrupt handler
;-------------------------------------------------------------------------------
TIMER0_A0_ISR:
        dec.w   cnt                             ; have we looped INTERVAL_CNT times? cycles:1
        jnz     timer0_a0_exit                  ; exit if we haven't reached 0 cycles:2

timer0_toggle:  
        ;; toggle led pin after (INTERVAL * TIMER_CYCLES) has occured
        xor.b   LED_PIN,&P1OUT                  ; cycles: 4
        mov.w   INTERVAL_CNT,cnt                ; reinitialize interval counter cycles:1
       
timer0_a0_exit:
        add.w   TIMER_CYCLES,&TA0CCR0           ; set new CCR0 and go again cycles:1
        reti                                    ; cycles:5

;------------------------------------------------------------------------------
; UNEXPECTED_ISR - default handler for unhandled interrupt
;-------------------------------------------------------------------------------
UNEXPECTED_ISR:
        reti                    ; cycles: 5

;------------------------------------------------------------------------------
; Interrupt Vectors - see the datasheet for your chip
;                    *msp430g2553 vectors described below
;------------------------------------------------------------------------------
        .section ".vectors", "ax", @progbits
        .word UNEXPECTED_ISR    ;0xffe0 slot  0  0
        .word UNEXPECTED_ISR    ;0xffe2 slot  1  2
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