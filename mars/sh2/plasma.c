/* OpenJazz's main menu plasma, unaltered (src/menu/plasma.cpp, Plasma::draw, as in OpenJazzCD32X):
 *   pixel colour = ((row term + column term) >> 10) & 15
 *   row term    = fCos(t1 * 4) << 3 + fCos(t2 * 4) << 3 + (32 << 10), t1 = p0 + 2y, t2 = p1 + y
 *   column term = fCos(t3 * 4) << 3 + fCos(t4 * 4) << 3,               t3 = p2 + 3x, t4 = p3 + 2x
 *   each step: p0 += 1, p1 += 2, p2 += 3, p3 += 4 (back to 1, 2, 3, 4 past 256)
 * colours: MENU.000's main menu palette, colours 0-15.
 * Here only the pace differs: steps per frame set by the 68000's speed (Up / Down on the credits
 * screen), slower than before.
 * Plasma: Copyright (c) 2010 Alireza Nejati; OpenJazz is distributed under the terms of the GNU
 * General Public License, version 2.0. */
#include "mars.h"
#include "oj_sin.h"

#define FCOS(a) ((int)oj_sin[((a) + 256) & 1023])

const unsigned char oj_pal[16][3] = {   /* MENU.000, main menu palette, colours 0-15 (8-bit RGB) */
    {0, 0, 56}, {4, 0, 60}, {8, 0, 65}, {12, 0, 69}, {16, 0, 73}, {20, 0, 77}, {24, 0, 81}, {28, 0, 85},
    {32, 0, 89}, {28, 0, 85}, {24, 0, 81}, {20, 0, 77}, {16, 0, 73}, {12, 0, 69}, {8, 0, 65}, {4, 0, 60}
};

static int p0, p1, p2, p3;
static int col[320];
static unsigned acc;

void plasma_step(int speed)    /* speed 1-16, 8 = normal: 150/256 of OpenJazz's step a frame */
{
    int n;
    acc += 150u * (unsigned)speed / 8u;
    n = (int)(acc >> 8);
    acc &= 255;
    while (n-- > 0) {
        p0 = p0 < 256 ? p0 + 1 : 1;
        p1 = p1 < 256 ? p1 + 2 : 2;
        p2 = p2 < 256 ? p2 + 3 : 3;
        p3 = p3 < 256 ? p3 + 4 : 4;
    }
}

/* into the back buffer (line n at word $100 + n*160), colours base + 0 .. base + 15 */
void plasma_draw(unsigned base)
{
    int x, y, t1 = p0, t2 = p1, t3 = p2, t4 = p3;
    u32 b4 = base * 0x01010101u;
    for (x = 0; x < 320; x++, t3 += 3, t4 += 2)
        col[x] = (FCOS(t3 * 4) << 3) + (FCOS(t4 * 4) << 3);
    for (y = 0; y < 224; y++, t1 += 2, t2 += 1) {
        const int colb = (FCOS(t1 * 4) << 3) + (FCOS(t2 * 4) << 3) + (32 << 10);
        volatile u32 *p = (volatile u32 *)(MARS_FB_BYTES + 2 * (0x100 + y * LINE_WORDS));
        const int *c = col;
        for (x = 0; x < 320; x += 4, c += 4)
            *p++ = b4 + ((u32)(((colb + c[0]) >> 10) & 15) << 24 | (u32)(((colb + c[1]) >> 10) & 15) << 16
                       | (u32)(((colb + c[2]) >> 10) & 15) << 8 | (u32)(((colb + c[3]) >> 10) & 15));
    }
}
