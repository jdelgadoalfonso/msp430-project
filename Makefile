#
# Makefile - blinkasm.elf
#
# Author: Rick Kimball
# email: rick@kimballsoftware.com
# Version: 1.01 Initial version 10/21/2011

APP=blinkasm
MCU=msp430g2553

CC=msp430-gcc
CXX=msp430-g++
COMMON=-Wall -Os -I. 
CFLAGS   += -mmcu=$(MCU) $(COMMON)
CXXFLAGS += -mmcu=$(MCU) $(COMMON)
ASFLAGS  += -mmcu=$(MCU) $(COMMON)
LDFLAGS   = -Wl,-Map,$(APP).map -nostdlib -nostartfiles

all: $(APP).elf

$(APP).elf: $(APP).o
	$(CC) $(CFLAGS) $(APP).o $(LDFLAGS) -o $(APP).elf
	msp430-objdump -z -EL -D -W $(APP).elf >$(APP).lss
	msp430-size $(APP).elf

install: all
	mspdebug --force-reset rf2500 "prog $(APP).elf"

debug:
	clear
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "-- Make sure you are mspdebug is running in another window                    --"
	@echo -e "--------------------------------------------------------------------------------"
	@echo -e "$$ # you can start it like this:"
	@echo -e "$$ mspdebug rf2500 gdb\n"
	msp430-gdb --command=blinkasm.gdb $(APP).elf

clean:
	rm -f $(APP).o $(APP).elf $(APP).lss $(APP).map