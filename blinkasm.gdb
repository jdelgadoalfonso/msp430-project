target remote localhost:2000
monitor reset
monitor erase
load blinkasm.elf
b
disassemble
nexti
disassemble
nexti
info registers
b timer0_toggle
continue