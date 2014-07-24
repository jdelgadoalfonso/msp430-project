#
# Makefile - blinkasm.elf
#
# Author: Rick Kimball
# email: rick@kimballsoftware.com
# Version: 1.03 Initial version 10/21/2011

APP = blinkasm
MCU ?= msp430g2553

CC=msp430-elf-gcc
CXX=msp430-elf-g++
COMMON=-Wall -Os -g -I./ -Iinclude/
CFLAGS   += -mmcu=$(MCU) $(COMMON)
CXXFLAGS += -mmcu=$(MCU) $(COMMON)
#ASFLAGS  += -mmcu=$(MCU) $(COMMON) -D_GNU_ASSEMBLER_
ASFLAGS  += -mmcu=$(MCU) $(COMMON)
LDFLAGS   = -Linclude/ -Wl,-Map,$(APP).map -nostdlib -nostartfiles -T $(MCU).ld

all: $(APP).elf

$(APP).elf: $(APP).o
	$(CC) $(CFLAGS) $(APP).o $(LDFLAGS) -o $(APP).elf
	msp430-elf-objdump -Sd -W $(APP).elf >$(APP).lss
	msp430-elf-size $(APP).elf
	msp430-elf-objcopy -O ihex blinkasm.elf blinkasm.hex

install: all
	mspdebug --force-reset rf2500 "prog $(APP).elf"

cycle_count: all
	naken430util -disasm $(APP).hex > $(APP)_cc.txt

debug: all
	clear
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "-- Make sure you are running mspdebug in another window                       --"
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "$$ # you can start it like this:"
	@echo -e "$$ mspdebug rf2500 gdb\n"
	msp430-elf-gdb --command=blinkasm.gdb $(APP).elf

clean:
	rm -f $(APP).o $(APP).elf $(APP).lss $(APP).map $(APP).hex $(APP)_cc.txt
