/* Master SH2: the 32X skies (step 4) and Tails (step 3) on the 32X screen; 32X colour 0 =
   the Mega Drive's backdrop colour. COMM0 (68000, every frame): backdrop colour (bits 0-11),
   sky code (12-14: zone + 1, 0 = none, 7 = the credits screen: OpenJazz's plasma, speed in
   COMM2 bits 8-12), fading (15). The 68000 set the 32X
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

static void fill_line(unsigned y, unsigned c)  /* line y of the back buffer in colour c */
{
    unsigned w = 0x100 + y * LINE_WORDS, first = 256 - (w & 0xFF);     /* a fill stays in one 256-word page */
    u16 v = (u16)(c << 8 | c);
    if (first >= LINE_WORDS) fill(w, LINE_WORDS, v);
    else { fill(w, first, v); fill(w + first, LINE_WORDS - first, v); }
}

/* The 32X skies: colours 16-79 (sky) and 80-143 (Green Hill's water), WITHOUT bit 15, so they
   show only where the Genesis picture is see-through (its backdrop, and Green Hill's sky made
   see-through by the 68000 - the Genesis clouds stay in front). */
static u16 rgb15(int r, int g, int b) { return (u16)((b >> 3) << 10 | (g >> 3) << 5 | (r >> 3)); }
static u16 ghz_grad[128];
static u16 zone_grad[7][64];
static const unsigned char zone_cols[7][3][3] = {   /* by sky code (zone + 1): top, middle, bottom */
    { {0, 0, 0}, {0, 0, 0}, {0, 0, 0} },
    { {0, 0, 0}, {0, 0, 0}, {0, 0, 0} },              /* 1 Green Hill: ghz_grad */
    { {0, 0, 0}, {0, 0, 0}, {0, 0, 0} },              /* 2 Labyrinth: none */
    { {8, 10, 80}, {50, 40, 150}, {150, 100, 200} },  /* 3 Marble: deep blue to lilac haze */
    { {0, 0, 24}, {24, 12, 80}, {90, 40, 130} },      /* 4 Star Light: night, violet at the horizon */
    { {40, 0, 80}, {150, 40, 140}, {255, 150, 90} },  /* 5 Spring Yard: twilight, purple to orange */
    { {24, 12, 0}, {110, 60, 10}, {200, 130, 50} },   /* 6 Scrap Brain: smog, brown to amber */
};
static void make_gradients(void)
{
    int i, z;
    for (i = 0; i < 64; i++) {   /* Green Hill sky: deep blue at the top, light near the horizon */
        int t = i * 256 / 63, t2 = t * t / 256;
        ghz_grad[i] = rgb15(8 + (120 - 8) * t2 / 256, 24 + (190 - 24) * t2 / 256, 140 + (255 - 140) * t2 / 256);
    }
    for (i = 0; i < 64; i++) {   /* Green Hill water: bright at the horizon, deeper below */
        int t = i * 256 / 63;
        ghz_grad[64 + i] = rgb15(80 - 70 * t / 256, 180 - 120 * t / 256, 245 - 75 * t / 256);
    }
    for (z = 3; z < 7; z++)
        for (i = 0; i < 64; i++) {
            const unsigned char *a = i < 32 ? zone_cols[z][0] : zone_cols[z][1];
            const unsigned char *b = i < 32 ? zone_cols[z][1] : zone_cols[z][2];
            int f = (i & 31) * 256 / 31;
            zone_grad[z][i] = rgb15(a[0] + (b[0] - a[0]) * f / 256, a[1] + (b[1] - a[1]) * f / 256, a[2] + (b[2] - a[2]) * f / 256);
        }
}
static unsigned line_colour(int sky, int y, int bg)
{
    int l;
    if (sky == 0) return 0;                        /* colour 0: the Genesis backdrop colour */
    if (sky != 1) return 16 + y * 64 / 224;        /* other zones: top to bottom of the screen */
    l = (y + bg) & 255;                            /* Green Hill: follows the background */
    if (l < 150) return 16 + l * 64 / 150;
    return 80 + (l - 150) * 64 / 106;
}

extern const unsigned char tails_frames[];
extern const unsigned char oj_pal[16][3];
void plasma_step(int speed);
void plasma_draw(unsigned base);
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
    u16 cur, back;
    int i, y;
    make_gradients();
    while (MARS_COMM12L != 0x53333247u) {}         /* "S32G" */
    while (!(MARS_ADAPTER & 0x8000)) {}
    cur = MARS_FBCTL & 1;
    for (;;) {
        u16 c0 = comm(&MARS_COMM0), c2 = comm(&MARS_COMM2), c4 = comm(&MARS_COMM4), c6 = comm(&MARS_COMM6);
        int sky = (c0 >> 12) & 7, plasma = sky == 7;
        if (c0 & 0x8000 || sky == 2 || sky == 7) sky = 0;   /* fading: the backdrop colour fades with the Genesis */
        back = cur ^ 1;
        if (plasma) {                              /* the credits screen: OpenJazz's plasma behind the credits */
            int speed = (c2 >> 8) & 31;
            if (speed < 1 || speed > 16) speed = 8;
            plasma_draw(160);
            plasma_step(speed);
        } else {
            for (y = 0; y < 224; y++) fill_line((unsigned)y, line_colour(sky, y, (int)(c2 & 0xFF)));
            while (MARS_FBCTL & 2) {}              /* the fills are done */
        }
        if (!plasma && (c2 & 0x1000)) {
            int x = (int)((c6 >> 8) | ((c2 >> 14) & 1) << 8) - 64;
            int yy = (int)((c6 & 0xFF) | ((c2 >> 15) & 1) << 8) - 64;
            int hf = (c2 >> 10) & 1;
            draw_frame(c4 & 0xFF, x, yy, hf);      /* his tails behind ... */
            draw_frame(c4 >> 8, x, yy, hf);        /* ... Tails in front */
        }
        MARS_FBCTL = back;                         /* show it from the next vertical blank */
        while ((MARS_FBCTL & 1) != back) {}
        cur = back;
        /* in the vertical blank: the colours */
        MARS_CRAM[0] = md_to_32x(c0 & 0x0EEE);     /* no bit 15: behind the Genesis picture */
        for (i = 1; i < 16; i++)
            MARS_CRAM[i] = (u16)(tails_pal[i] | 0x8000);   /* Tails: bit 15, in front */
        if (plasma) for (i = 0; i < 16; i++) MARS_CRAM[160 + i] = rgb15(oj_pal[i][0], oj_pal[i][1], oj_pal[i][2]);
        if (sky == 1) for (i = 0; i < 128; i++) MARS_CRAM[16 + i] = ghz_grad[i];
        else if (sky) for (i = 0; i < 64; i++) MARS_CRAM[16 + i] = zone_grad[sky][i];
    }
}
