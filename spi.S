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
.file "spi.S"

#include <msp430.h>
#include "registers.h"

;-------------------------------------------------------------------------------
.section .text, "ax", @progbits
;-------------------------------------------------------------------------------

// Function write_cmd
;-------------------------------------------------------------------------------
.globl write_cmd
.type write_cmd, @function
;-------------------------------------------------------------------------------

write_cmd:
  nop
  ret

.end
