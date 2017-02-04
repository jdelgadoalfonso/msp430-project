.macro  delay_ms ms
  mov.w #\ms, r9
1:
  dec.w r9
  jnz 1b
.endm
