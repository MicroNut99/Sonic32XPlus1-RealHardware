#!/usr/bin/env python3
# Green Hill's sky made see-through on the Genesis (Mars = 1), so the 32X sky shows behind it while the
# Genesis still draws the clouds in front: the sky is palette line 3 colour 1 in the background; every
# background tile drawn with line 3 that holds colour 1 gets that colour changed to 0 (see-through) -
# except tiles the foreground or other palette lines also use (left as they are).
# Output mars/ghz_sky.bin (big-endian): u16 count, then per tile u16 VRAM tile number + 32 bytes.
# Usage (from the repository folder): python3 mars/tools/ghz_sky.py
import sys, os, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from s1data import nemesis, kosinski, enigma
rd = lambda f: open(f, 'rb').read()
art = nemesis(rd('artnem/8x8 - GHZ1.nem')) + nemesis(rd('artnem/8x8 - GHZ2.nem'))
blocks = enigma(rd('map16/GHZ.eni'))
chunks = kosinski(rd('map256/GHZ.kos'))
def tiles_of(layout):
    lw, lh = layout[0] + 1, layout[1] + 1
    s = set()
    for i in range(lw * lh):
        cid = layout[2 + i] & 0x7F
        if not cid: continue
        ch = chunks[(cid - 1) * 512:cid * 512]
        for k in range(256):
            bi = (ch[2 * k] << 8 | ch[2 * k + 1]) & 0x3FF
            for t in range(4):
                pw = blocks[bi * 4 + t]
                s.add((pw & 0x7FF, (pw >> 13) & 3))
    return s
bg = tiles_of(rd('levels/ghzbg.bin'))
fg = set()
for f in ('ghz1', 'ghz2', 'ghz3'): fg |= tiles_of(rd('levels/%s.bin' % f))
fgt = {t for t, p in fg}
bg_other = {t for t, p in bg if p != 3}
def has1(t): return any((b >> 4) == 1 or (b & 15) == 1 for b in art[t * 32:t * 32 + 32])
pick = sorted(t for t, p in bg if p == 3 and has1(t) and t not in fgt and t not in bg_other)
res = struct.pack('>H', len(pick))
for t in pick:
    d = bytes(((0 if (b >> 4) == 1 else b >> 4) << 4) | (0 if (b & 15) == 1 else b & 15) for b in art[t * 32:t * 32 + 32])
    res += struct.pack('>H', t) + d
open('mars/ghz_sky.bin', 'wb').write(res)
print('mars/ghz_sky.bin: %d tiles made see-through where the sky is' % len(pick))
