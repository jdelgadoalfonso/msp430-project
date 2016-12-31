;-------------------------------------------------------------------------------
; blinkasm.S - gcc compatible interrupt driven led blinker in msp430 asm
;
; Version 1.0 - 10/22/2011 rick@kimballsoftware.com
; Version 1.01 - 7/22/2014 rick@kimballsoftware.com modified for msp430-elf-gcc
; $ msp430-elf-gcc blinkasm.S -D_GNU_ASSEMBLER_ -Wall -Os -g \
;       -fdata-sections -ffunction-sections -mmcu=msp430g2553 -T \
;       -T msp430g2553.ld -I/tmp/a/include -L /tmp/a/include/ -nostdlib
;	
;-------------------------------------------------------------------------------
.file "blinkasm.S"

#include <msp430.h>
#include "registers.h"

;-------------------------------------------------------------------------------
;;; --- devices with only one TimerA don't bother to number the defines ---
#ifndef TA0CCR0
  #define TA0CCR0  CCR0
  #define TA0CCTL0 CCTL0
#endif

;-------------------------------------------------------------------------------
;;; ---- CONSTANTS ----

// #define TEST_IRQ_OVERHEAD

#ifndef TEST_IRQ_OVERHEAD
  #define _50USEC (50-1)  /* @1MHz MCLK results in 50uSec/interrupt */
  #define _500MSEC 10000  /* @1MHz MCLK results in 500ms/LED toggle */
#else
  ;; This test illustrates the minimum CCR0 value that can be used
  ;; 22 cycles is based on the interrupt overhead
  #define _50USEC 22      /* @1MHz MCLK results in 23uSec/interrupt */
  #define _500MSEC 1      /* @1MHz MCLK results in 23uSec/LED toggle */
#endif
#define _LED_PIN BIT6     /* PORT1 pin, Launchpad has BIT0=Red and BIT6=Green */

#define _SPI_PIN BIT5

;-------------------------------------------------------------------------------
;;; ---- Registers used as globals ----

#define LED_PIN r4
#define TIMER_CYCLES r5
#define INTERVAL_CNT r6
#define CNT r7

;; or you could use some ram variables
.lcomm tcycles, 2    ; example use of local bss data variable
.lcomm cnt, 2        ; example use of local bss data variable

;-------------------------------------------------------------------------------
.section .text, "ax", @progbits
;-------------------------------------------------------------------------------
_start:
  ;; disable watchdog and set stack to highest RAM addr
  mov.w   #(WDTPW | WDTHOLD), &WDTCTL
  mov.w   #__stack, SP ; gcc ldscripts compute __stack based on mmcu

  ;; initialize clock, gpio, spi, timer
init:
  ;; configure DCO to precalibrated 1MHz
  clr.b   &DCOCTL
  mov.b   &CALBC1_1MHZ, &BCSCTL1
  mov.b   &CALDCO_1MHZ, &DCOCTL

  ;; initialize global register values
  mov.w   #_LED_PIN, LED_PIN          ; load constant into register constant
  mov.w   #_50USEC, TIMER_CYCLES      ; load constant into register constant
  mov.w   #_500MSEC, INTERVAL_CNT     ; load constant into register constant
  mov.w   INTERVAL_CNT, CNT           ; initialize register based counter

  ;; initialize GPIO
  bic.b   LED_PIN, &P1OUT             ; LED turned off to start
  bis.b   LED_PIN, &P1DIR             ; Configure P1.0 as output pin
  
  ;; initialize SPI
  mov.b #BIT5, r8
  bis.b r8, &P1OUT
  bis.b r8, &P1OUT
  mov.b #(BIT1 | BIT2 | BIT4), r8
  mov.b r8, &P1SEL
  mov.b r8, &P1SEL2
  mov.b #UCSWRST, &UCA0CTL1;
  bis.b #(UCCKPH | UCMSB | UCMST | UCSYNC), &UCA0CTL0 ; 3-pin, 8-bit SPI master
  bis.b #UCSSEL_2, &UCA0CTL1                          ; SMCLK
  bis.b #0x02, &UCA0BR0                               ; /2
  clr.b &UCA0BR1
  clr.b &UCA0MCTL
  bic.b #UCSWRST, &UCA0CTL1   ; **Initialize USCI state machine**

ready:
  bit.b #IFG2, &UCA0TXIFG
  jz ready

  ;; initialize TimerA0
  mov.w   #CCIE, &TA0CCTL0           ; Enable TA0CCR0 interrupt
  mov.w   TIMER_CYCLES, &TA0CCR0     ; Set TIMER_CYCLES cycles
  mov.w   #(TASSEL_2 | MC_2), &TACTL ; SMCLK, Continuous Up Mode

  ;; enable interrupts and loop forever
  ;; real work done in the CCR0 interrupt
  nop
  eint

  mov.w   #2, r12
  mov.w   #3, r13
  call #sum
loop:
  ;; Note: could sleep here instead
  jmp loop                           ; cycles:2

;-------------------------------------------------------------------------------
; TIMER0_A0_ISR - TimerA0 CCR0 interrupt handler
;-------------------------------------------------------------------------------
TIMER0_A0_ISR:
  ;; before we even start running the mcu does a push PC, and a push SR cycles:6
  dec.w   CNT              ; have we looped INTERVAL_CNT times? cycles:1
  jnz     1f               ; exit if we haven't reached 0 cycles:2

  ;; toggle led pin after (INTERVAL * TIMER_CYCLES) has occured
  xor.b   LED_PIN, &P1OUT     ; cycles:4
  mov.w   INTERVAL_CNT, CNT   ; reinitialize interval counter cycles:1
1:
  add.w   TIMER_CYCLES, &TA0CCR0 ; set new CCR0 and go again cycles:4
  reti                           ; cycles:5

;-------------------------------------------------------------------------------
; UNEXPECTED_ISR - default handler for unhandled interrupt
;-------------------------------------------------------------------------------
UNEXPECTED_ISR:
  reti                          ; cycles: 5

;-------------------------------------------------------------------------------
; Interrupt Vectors - see the datasheet for your chip
;                    *msp430g2553 vectors described below
;-------------------------------------------------------------------------------
.section "__interrupt_vector_10", "ax", @progbits
.word TIMER0_A0_ISR       ;0xfff2 (TIMER0_A0_VECTOR)

.section ".resetvec", "ax", @progbits
.word _start              ;0xfffe (RESET_VECTOR)

.end
