#define CLOCK_SPEED_MHZ 8

#define N_CYCLES(ms) ((ms*CLOCK_SPEED_MHZ*1000-10)/3)
#define N_CYCLES_BY(ms, mul) ((ms*CLOCK_SPEED_MHZ*1000-12-8*mul)/(3*mul))

/*
 * Example of macro in GNU as
 */
.macro delay_ms ms
  mov.w #N_CYCLES(\ms), r9
  call delay
.endm

.macro delay_ms_by ms mul
  mov.w #\mul, r10
  mov.w #N_CYCLES_BY(\ms, \mul), r9
  call delay_by_x
.endm
