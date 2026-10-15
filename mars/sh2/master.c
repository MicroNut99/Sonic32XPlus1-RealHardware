/* Master SH2: draws Tails on the 32X screen (step 3); 32X colour 0 = the Mega Drive's
   backdrop colour (sent by the 68000 in COMM0 every frame). The 68000 set the 32X
   screen up and handed it over (FM = 1), then wrote "S32G" to COMM12.
   Tails (mars/tails.asm): COMM4 = his frame << 8 | his tails' frame, COMM6 = (x+64) << 8
   | (y+64), COMM2 = $1000 shown | $400 facing left | $4000 / $8000 bit 8 of x+64 / y+64.
   His colours (1-15) carry bit 15: in front of the Genesis picture. */
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

extern const unsigned char tails_frames[];
extern const u16 tails_pal[];

static unsigned rd16(const unsigned char *p) { return (unsigned)p[0] << 8 | p[1]; }

/* one of Tails' pictures, its origin at screen (x, y); flipped when facing left */
static void draw_frame(unsigned frame, int x, int y, int hflip)
{
    const unsigned char *e, *pix;
    volatile unsigned char *fb = MARS_FB_BYTES;
    int ox, oy, w, h, sx, sy, i, j;
    if (frame == 0 || frame >= rd16(tails_frames)) return;
    e = tails_frames + 4 + 12 * frame;
    ox = (short)rd16(e); oy = (short)rd16(e + 2); w = (int)rd16(e + 4); h = (int)rd16(e + 6);
    pix = tails_frames + ((u32)rd16(e + 8) << 16 | rd16(e + 10));
    if (w == 0 || h == 0) return;
    sx = hflip ? x - (ox + w) : x + ox;
    sy = y + oy;
    for (j = 0; j < h; j++) {
        int yy = sy + j;
        const unsigned char *row = pix + j * w;
        volatile unsigned char *line;
        if (yy < 0 || yy >= 224) continue;
        line = fb + 2 * (0x100 + yy * LINE_WORDS);
        for (i = 0; i < w; i++) {
            int xx = sx + i;
            unsigned char v = row[hflip ? w - 1 - i : i];
            if (v && xx >= 0 && xx < 320) line[xx] = v;
        }
    }
}

static u16 comm(volatile u16 *r)     /* read until two reads agree (the 68000 may be writing it) */
{
    u16 a, b;
    do { a = *r; b = *r; } while (a != b);
    return a;
}

static u16 md_to_32x(u16 c)        /* Mega Drive 0000BBB0GGG0RRR0 -> 32X 0BBBBBGGGGGRRRRR */
{
    u16 r = (c >> 1) & 7, g = (c >> 5) & 7, b = (c >> 9) & 7;
    return (u16)(((b * 31 + 3) / 7) << 10 | ((g * 31 + 3) / 7) << 5 | ((r * 31 + 3) / 7));
}

void master_main(void)
{
    u16 cur, back, c;
    int i;
    while (MARS_COMM12L != 0x53333247u) {}         /* "S32G" */
    while (!(MARS_ADAPTER & 0x8000)) {}
    cur = MARS_FBCTL & 1;
    for (;;) {
        u16 c2 = comm(&MARS_COMM2), c4 = comm(&MARS_COMM4), c6 = comm(&MARS_COMM6);
        back = cur ^ 1;
        clear_back_buffer();
        if (c2 & 0x1000) {
            int x = (int)((c6 >> 8) | ((c2 >> 14) & 1) << 8) - 64;
            int y = (int)((c6 & 0xFF) | ((c2 >> 15) & 1) << 8) - 64;
            int hf = (c2 >> 10) & 1;
            draw_frame(c4 & 0xFF, x, y, hf);       /* his tails behind ... */
            draw_frame(c4 >> 8, x, y, hf);         /* ... Tails in front */
        }
        MARS_FBCTL = back;                         /* show it from the next vertical blank */
        while ((MARS_FBCTL & 1) != back) {}
        cur = back;
        c = comm(&MARS_COMM0);
        MARS_CRAM[0] = md_to_32x(c);               /* no bit 15: behind the Mega Drive picture */
        for (i = 1; i < 16; i++)
            MARS_CRAM[i] = (u16)(tails_pal[i] | 0x8000);   /* Tails: bit 15, in front */
    }
}
