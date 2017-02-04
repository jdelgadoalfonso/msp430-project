;-------------------------------------------------------------------------------
; spi.S - gcc compatible interrupt driven led blinker in msp430 asm
;
; Version 1.0 - 10/22/2011 rick@kimballsoftware.com
; Version 1.01 - 7/22/2014 rick@kimballsoftware.com modified for msp430-elf-gcc
; $ msp430-elf-gcc blinkasm.S -D_GNU_ASSEMBLER_ -Wall -Os -g \
;       -fdata-sections -ffunction-sections -mmcu=msp430g2553 -T \
;       -T msp430g2553.ld -I/tmp/a/include -L /tmp/a/include/ -nostdlib
;	
;-------------------------------------------------------------------------------
.file "spi.S"

#include <msp430.h>
#include "registers.h"
#include "spi.h"

;-------------------------------------------------------------------------------
.section .text, "ax", @progbits
;-------------------------------------------------------------------------------

// Function init_spi
;-------------------------------------------------------------------------------
.globl init_spi
.type init_spi, @function
;-------------------------------------------------------------------------------

;; initialize SPI
init_spi:
  mov.b   r8, &P1SEL
  mov.b   r8, &P1SEL2
  mov.b   #UCSWRST, &UCA0CTL1
  bis.b   r9, &UCA0CTL0           ; 3-pin, 8-bit SPI master
  bis.b   #UCSSEL_2, &UCA0CTL1    ; SMCLK
  bis.b   #0x02, &UCA0BR0         ; /2
  clr.b   &UCA0BR1
  clr.b   &UCA0MCTL
  bic.b   #UCSWRST, &UCA0CTL1     ; **Initialize USCI state machine**
  ret


/**
 * void send_spi_byte(unsigned char r9)
 */
;-------------------------------------------------------------------------------
.globl send_spi_byte
.type send_spi_byte, @function
;-------------------------------------------------------------------------------
send_spi_byte:
  bic.b   #SCREEN_CS, &_SCREEN_CS(OUT)  ; Active chip select (low level)

1:
  bit.b   #UCA0TXIFG, &IFG1             ; USCI_A0 TX buffer ready?
  jz      1b                            ; Jump -> TX buffer not ready
  mov.b   r9, &UCA0TXBUF                ; Byte to SPI UCA0TXBUF

  bis.b   #SCREEN_CS, &_SCREEN_CS(OUT)  ; Deactive chip select (high level)

  ret


/**
 * void send_spi_word(unsigned int r9)
 */
;-------------------------------------------------------------------------------
.globl send_spi_word
.type send_spi_word, @function
;-------------------------------------------------------------------------------
send_spi_word:
  bic.b   #SCREEN_CS, &_SCREEN_CS(OUT)  ; Active chip select (low level)

1:
  bit.b   #UCA0TXIFG, &IFG1             ; USCI_A0 TX buffer ready?
  jz      1b                            ; Jump -> TX buffer not ready
  mov.b   r9, &UCA0TXBUF                ; Byte to SPI UCA0TXBUF
  swpb    r9
1:
  bit.b   #UCA0TXIFG, &IFG1             ; USCI_A0 TX buffer ready?
  jz      1b                            ; Jump -> TX buffer not ready
  mov.b   r9, &UCA0TXBUF                ; Byte to SPI UCA0TXBUF
  swpb    r9

  bis.b   #SCREEN_CS, &_SCREEN_CS(OUT)  ; Deactive chip select (high level)

  ret

.end
