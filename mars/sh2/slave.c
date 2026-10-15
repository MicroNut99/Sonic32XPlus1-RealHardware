/* Slave SH2, step 2: plays the "SEGA" voice on the 32X's PWM.
   The 68000 asks by changing COMM8 (a request number), with COMM12-14 = the ROM offset of
   a small table (ROM offset of the sample, its size in bytes) and the PWM cycle for the
   Mega Drive pitch in COMM10 (worked out at build time, see mars/mars68k.asm). The slave reports
   the request number in COMM6 when the voice has finished.
   The PWM takes one value per cycle from a 3-deep FIFO: writing whenever the FIFO
   has room plays the samples at exactly that rate. */
#include "mars.h"


static u16 read_twice(volatile u16 *r)
{
    u16 a, b;
    do { a = *r; b = *r; } while (a != b);
    return a;
}

static void pwm_put(u16 v)
{
    while (MARS_PWM_MONO & 0x8000) {}
    MARS_PWM_MONO = v;
}

void slave_main(void)
{
    u16 last, cycle = 1415;
    /* Touch nothing until the 68000 has finished Sega's start-up code and set up the
       32X ("S32G" in COMM12, Mars_Init68k): the start-up code clears and checks the
       32X registers, the PWM's among them, while the SH2s already run. (Step 2's first
       build set the PWM at once: black screen on a real console.) */
    while (MARS_COMM12L != 0x53333247u) {}
    last = read_twice(&MARS_COMM8);
    MARS_PWM_CYCLE = cycle;
    MARS_PWM_CTRL = 0x0105;                    /* left and right channels on, timer interval 1 */
    pwm_put((u16)(cycle >> 1));                /* start at the middle: the silent level */
    for (;;) {
        u16 req = read_twice(&MARS_COMM8);
        if (req == last) {                     /* idle: keep the output at the middle (no pop) */
            if (!(MARS_PWM_MONO & 0x8000)) MARS_PWM_MONO = (u16)(cycle >> 1);
            continue;
        }
        last = req;
        cycle = read_twice(&MARS_COMM10);
        if (cycle < 256 || cycle > 4095) cycle = 1415;
        MARS_PWM_CYCLE = cycle;
        {
            u32 tab = (u32)read_twice(&MARS_COMM12) << 16 | read_twice(&MARS_COMM14);
            const volatile u32 *t = (const volatile u32 *)(MARS_ROM_CT + (tab & 0x3FFFFC));
            u32 off = t[0] & 0x3FFFFF, n = t[1];
            const volatile unsigned char *p = MARS_ROM_CT + off;
            int mid = cycle >> 1, i;
            for (i = 0; i < (int)n; i++)               /* 8-bit unsigned, 128 = silence; a quarter of the PWM's */
                pwm_put((u16)(mid + (((int)p[i] - 128) * mid) / 512));   /* range: about the Mega Drive's loudness */
        }
        pwm_put((u16)(cycle >> 1));
        MARS_COMM6 = req;
    }
}
