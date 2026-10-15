/* 32X registers as the SH2s see them (cache-through addresses) */
#ifndef MARS_H
#define MARS_H
typedef unsigned short u16;
typedef unsigned int u32;
#define MARS_ADAPTER  (*(volatile u16 *)0x20004000)   /* bit 15 FM: 1 = the SH2s have the 32X VDP */
#define MARS_COMM0    (*(volatile u16 *)0x20004020)
#define MARS_COMM12L  (*(volatile u32 *)0x2000402C)
#define MARS_COMM12   (*(volatile u16 *)0x2000402C)
#define MARS_COMM14   (*(volatile u16 *)0x2000402E)
#define MARS_DISPMODE (*(volatile u16 *)0x20004100)
#define MARS_FILLEN   (*(volatile u16 *)0x20004104)
#define MARS_FILADR   (*(volatile u16 *)0x20004106)
#define MARS_FILDAT   (*(volatile u16 *)0x20004108)
#define MARS_FBCTL    (*(volatile u16 *)0x2000410A)   /* bit 0 FS, bit 1 FEN (fill busy), bit 15 VBLK */
#define MARS_CRAM     ((volatile u16 *)0x20004200)
#define MARS_FB       ((volatile u16 *)0x24000000)    /* frame buffer: words; line table first */
#define MARS_FB_BYTES ((volatile unsigned char *)0x24000000)
#define LINE_WORDS 160                                 /* 320 pixels per line (the 68000 wrote the line tables) */
#endif
#define MARS_COMM6    (*(volatile u16 *)0x20004026)   /* slave -> 68000: number of the last sound finished */
#define MARS_COMM8    (*(volatile u16 *)0x20004028)   /* 68000 -> slave: sound request number (changes = play) */
#define MARS_COMM10   (*(volatile u16 *)0x2000402A)   /* 68000 -> slave: PWM cycle for that sound */
#define MARS_PWM_CTRL  (*(volatile u16 *)0x20004030)
#define MARS_PWM_CYCLE (*(volatile u16 *)0x20004032)
#define MARS_PWM_MONO  (*(volatile u16 *)0x20004038)  /* write: both channels; read bit 15: FIFO full */
#define MARS_ROM_CT    ((volatile unsigned char *)0x22000000)  /* cartridge ROM, cache-through */
