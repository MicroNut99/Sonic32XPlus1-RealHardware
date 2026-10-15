#!/usr/bin/env python3
# SONIC32 TAILS T1: every Tails mapping frame drawn once on the PC into an 8-bit picture for the master SH2
# (Vic's YATSSD draw_sprite: 8 bits per pixel, 0 = transparent, flips done while drawing).
# Output tails_frames.bin (big-endian):
#   u16 frame count, u16 0, then per frame: s16 ox, s16 oy (top-left corner relative to the object's
#   position), u16 w (even), u16 h, u32 offset of the pixels from the file start; then the pixels
#   (rows of w bytes; values = Sonic 2's palette line 0 index 1-15, +PAL_BASE)
# and tails_pal.bin: 16 x u16 32X colours (5-5-5, Sonic 2's line 0 widened from 3 to 5 bits).
# Usage: tails_frames.py <s2disasm folder> <out folder>
import sys, os, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
s2, out = sys.argv[1:3]
import re
def num(t):
    t = t.strip(); neg = t.startswith('-'); t = t.lstrip('-')
    v = int(t[1:], 16) if t.startswith('$') else int(t)
    return -v if neg else v
def frames(path, kind):
    order, body, cur = [], {}, None
    for line in open(path, encoding='latin-1'):
        line = line.split(';')[0].rstrip()
        m = re.match(r'\s*mappingsTableEntry\.w\s+(\S+)', line)
        if m: order.append(m.group(1)); continue
        m = re.match(r'^(\S+):\s*(spriteHeader|dplcHeader)', line)
        if m: cur = m.group(1); body[cur] = []; continue
        m = re.match(r'\s*(spritePiece|dplcEntry)\s+(.*)', line)
        if m and cur: body[cur].append([num(a) for a in m.group(2).split(',')])
    return [body[n] for n in order]
maps = frames(os.path.join(s2, 'mappings/sprite/Tails.asm'), 'map')
dplcs = frames(os.path.join(s2, 'mappings/spriteDPLC/Tails.asm'), 'dplc')
art = open(os.path.join(s2, "art/uncompressed/Tails's art.bin"), 'rb').read()
PAL_BASE = 0
def tile_px(t, x, y):
    b = art[t * 32 + y * 4 + x // 2]
    return (b >> 4) if x % 2 == 0 else (b & 15)
recs, blobs, seen = [], b'', {}
for f, m in enumerate(maps):
    tiles = []
    for n, first in dplcs[f] if f < len(dplcs) else []:
        tiles += list(range(first, first + n))
    pix = {}
    for x, y, w, h, tile, xf, yf, pal, pri in m:
        for cx in range(w):
            for cy in range(h):
                k = tile + cx * h + cy
                if k >= len(tiles): continue
                for py in range(8):
                    for px in range(8):
                        v = tile_px(tiles[k], px, py)
                        if not v: continue
                        sx = (w - 1 - cx) * 8 + (7 - px) if xf else cx * 8 + px
                        sy = (h - 1 - cy) * 8 + (7 - py) if yf else cy * 8 + py
                        pix[(x + sx, y + sy)] = v + PAL_BASE
    if not pix:
        recs.append((0, 0, 0, 0, b'')); continue
    x0 = min(p[0] for p in pix); x1 = max(p[0] for p in pix) + 1
    y0 = min(p[1] for p in pix); y1 = max(p[1] for p in pix) + 1
    w = (x1 - x0 + 1) & ~1; h = y1 - y0
    data = bytes(pix.get((x0 + i, y0 + j), 0) for j in range(h) for i in range(w))
    recs.append((x0, y0, w, h, data))
head = struct.pack('>HH', len(recs), 0)
off = 4 + 12 * len(recs)
body = b''
for x0, y0, w, h, data in recs:
    if data not in seen:
        seen[data] = off + len(body); body += data
        while len(body) % 4: body += b'\0'
    head += struct.pack('>hhHHI', x0, y0, w, h, seen[data] if data else 0)
os.makedirs(out, exist_ok=True)
open(os.path.join(out, 'tails_frames.bin'), 'wb').write(head + body)
pal = open(os.path.join(s2, 'art/palettes/SonicAndTails.bin'), 'rb').read()[:32]
def c5(v3): return (v3 * 31 + 3) // 7
cols = []
for i in range(16):
    g = int.from_bytes(pal[2 * i:2 * i + 2], 'big')
    r, gg, b = (g >> 1) & 7, (g >> 5) & 7, (g >> 9) & 7
    cols.append(0x8000 if i == 0 else (c5(b) << 10 | c5(gg) << 5 | c5(r)))
open(os.path.join(out, 'tails_pal.bin'), 'wb').write(struct.pack('>16H', *cols))
print('tails_frames.bin: %d frames, %d bytes' % (len(recs), len(head) + len(body)))
