#include <msp430.h>

#define SCREEN_CS         BIT0
#define _SCREEN_CS(TYPE)  P2 ## TYPE
#define SCREEN_RS         BIT4
#define _SCREEN_RS(TYPE)  P1 ## TYPE
