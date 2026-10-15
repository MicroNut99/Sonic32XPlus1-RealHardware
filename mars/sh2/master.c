/* Master SH2, step 1: a small white test box on the 32X screen; 32X colour 0 =
   the Mega Drive's backdrop colour (sent by the 68000 in COMM0 every frame).
   The 68000 set the 32X screen up and handed it over (FM = 1), then wrote
   "S32G" to COMM12. */
#include "mars.h"

static void fill(unsigned waddr, unsigned len, u16 data)   /* the 32X VDP's own fill */
{
    while (MARS_FBCTL & 2) {}
    MARS_FILLEN = (u16)(len - 1);
    MARS_FILADR = (u16)waddr;
    MARS_FILDAT = data;
}

static void clear_back_buffer(void)
{
    unsigned y;
    for (y = 0; y < 224; y++) {
        unsigned w = 0x100 + y * LINE_WORDS, first = 256 - (w & 0xFF);   /* a fill stays in one 256-word page */
        if (first >= LINE_WORDS) fill(w, LINE_WORDS, 0);
        else { fill(w, first, 0); fill(w + first, LINE_WORDS - first, 0); }
    }
    while (MARS_FBCTL & 2) {}
}

static void draw_box(void)
{
    unsigned y, x;
    for (y = 8; y < 24; y++)
        for (x = 280; x < 312; x += 2)
            MARS_FB[0x100 + y * LINE_WORDS + x / 2] = 0x0101;           /* colour 1 */
}

static u16 md_to_32x(u16 c)        /* Mega Drive 0000BBB0GGG0RRR0 -> 32X 0BBBBBGGGGGRRRRR */
{
    u16 r = (c >> 1) & 7, g = (c >> 5) & 7, b = (c >> 9) & 7;
    return (u16)(((b * 31 + 3) / 7) << 10 | ((g * 31 + 3) / 7) << 5 | ((r * 31 + 3) / 7));
}

void master_main(void)
{
    u16 cur, back, c, c2;
    while (MARS_COMM12L != 0x53333247u) {}         /* "S32G" */
    while (!(MARS_ADAPTER & 0x8000)) {}
    cur = MARS_FBCTL & 1;
    for (;;) {
        back = cur ^ 1;
        clear_back_buffer();
        draw_box();
        MARS_FBCTL = back;                         /* show it from the next vertical blank */
        while ((MARS_FBCTL & 1) != back) {}
        cur = back;
        do { c = MARS_COMM0; c2 = MARS_COMM0; } while (c != c2);
        MARS_CRAM[0] = md_to_32x(c);               /* no bit 15: behind the Mega Drive picture */
        MARS_CRAM[1] = 0xFFFF;                     /* white, bit 15: in front */
    }
}
