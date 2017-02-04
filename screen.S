;-------------------------------------------------------------------------------
; screen.S - gcc compatible interrupt driven led blinker in msp430 asm
;
; Version 1.0 - 10/22/2011 rick@kimballsoftware.com
; Version 1.01 - 7/22/2014 rick@kimballsoftware.com modified for msp430-elf-gcc
; $ msp430-elf-gcc blinkasm.S -D_GNU_ASSEMBLER_ -Wall -Os -g \
;       -fdata-sections -ffunction-sections -mmcu=msp430g2553 -T \
;       -T msp430g2553.ld -I/tmp/a/include -L /tmp/a/include/ -nostdlib
;	
;-------------------------------------------------------------------------------
.file "screen.S"

#include <msp430.h>
#include "registers.h"
#include "spi.h"
#include "delay.h"

;-------------------------------------------------------------------------------
.section .text, "ax", @progbits
;-------------------------------------------------------------------------------

// Function init_screen
;-------------------------------------------------------------------------------
.globl init_screen
.type init_screen, @function
;-------------------------------------------------------------------------------

init_screen:
  mov.b #SCREEN_RS, r8

  mov.b #0x11, r9
  bic.b r8, &_SCREEN_RS(OUT)
  call #send_spi_byte

  delay_ms(10000)

  mov.b #0xcf, r9
  call #send_spi_byte

  bis.b r8, &_SCREEN_RS(OUT)
  mov.w #0xc300, r9
  call #send_spi_word
  mov.b #0x30, r9
  call #send_spi_byte

  bic.b r8, &_SCREEN_RS(OUT)
  mov.b #0xed, r9
  call #send_spi_byte

  bis.b r8, &_SCREEN_RS(OUT)
  mov.w #0x0364, r9
  call #send_spi_word
  mov.w #0x8112, r9
  call #send_spi_word

  bic.b r8, &_SCREEN_RS(OUT)
  mov.b #0x11, r9

  delay_ms(10000)

  mov.b #0x29, r9       ; Display on

  delay_ms(10000)

  ret


// Function init_screen
;-------------------------------------------------------------------------------
.globl init_screen
.type init_screen, @function
;-------------------------------------------------------------------------------

.end
