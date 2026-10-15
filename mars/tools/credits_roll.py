#!/usr/bin/env python3
# Sonic 1 32X: the credits as a rolling picture on the Genesis plane B, in Jazz Jackrabbit's FONTBIG.0FN
# (the font of the CD32X credits picture), drawn the way that picture shows it: every pixel of a
# letter shaded by its row from white (top) to blue (bottom) - the letter's inner line a little
# lighter than its outer line - and a dark shadow one pixel right / down. 320 x 256 = plane B's
# height, so scrolling it vertically rolls the credits round and round.
# .0FN: "Digital Dimensions" + 0x1A, space width, line height, then per character a size word and an
# RLE block (OpenJazz src/io/gfx/font.cpp, file.cpp loadRLE); ASCII map as OpenJazz's Font(fileName).
# Output: credits_tiles.bin (unique 8x8 tiles, 4 bits), credits_map.bin (32 rows x 40 name-table
# words: palette line 1, tiles from 1), credits_pal.bin (16 Genesis colours for line 1)
# Usage: credits_roll.py <FONTBIG.0FN> <out folder> [preview.png]   (out folder: mars/credits)
# FONTBIG.0FN comes with Jazz Jackrabbit (not in this repository).
import sys, os
path, out = sys.argv[1], sys.argv[2]
d = open(path, 'rb').read()
assert d[:18] == b'Digital Dimensions', 'not a .0FN font'
p = 19; space = d[p]; p += 2
chars = []
while p < len(d) and len(chars) < 128:
    size = d[p] | d[p + 1] << 8; p += 2
    if size <= 4: chars.append(None); continue
    bsz = d[p] | d[p + 1] << 8; p += 2; start = p
    buf = bytearray(size); pos = 0
    while pos < size:
        code = d[p]; p += 1; amt = code & 127
        if code & 128:
            v = d[p]; p += 1
            if pos + amt >= size: break
            buf[pos:pos + amt] = bytes([v]) * amt; pos += amt
        elif amt:
            if pos + amt >= size: break
            buf[pos:pos + amt] = d[p:p + amt]; p += amt; pos += amt
        else:
            buf[pos] = d[p]; p += 1; pos += 1; break
    p = start + bsz
    w = buf[0] | buf[1] << 8; h = buf[2] | buf[3] << 8
    chars.append((w, h, bytes(buf[4:4 + w * h])) if size - 4 >= w * h else None)
def idx(c):
    m = {'!': 107, '.': 102, '-': 104, ':': 114, '/': 108, "'": 115, ',': 101}
    if c in m: return m[c]
    if '0' <= c <= '9': return ord(c) + 5
    if 'A' <= c <= 'Z': return ord(c) - 38
    raise ValueError(c)
groups = [['SONIC THE HEDGEHOG', 'SONIC TEAM  SEGA 1991'], ['DISASSEMBLY', 'SONIC RETRO  S1DISASM'],
          ['TAILS', 'SONIC 2  SEGA 1992'], ['PLASMA', 'OPENJAZZ  ALIREZA NEJATI'],
          ['32X PORT', 'MICRONUT99'], ['THANK YOU FOR PLAYING!']]
PITCH = 19                                    # line to line, as in the picture
nlines = sum(len(g) for g in groups)
gap = (256 - nlines * PITCH) // len(groups)   # the extra space after each group
W, H = 320, 256
img = [[0] * W for _ in range(H)]             # 0 see-through, 1 shadow, 2-7 inner by row, 8-13 outer by row
GH = max(c[1] for c in chars if c)
def width(t): return sum(space if c == ' ' else chars[idx(c)][0] + 1 for c in t) - 1
y = gap // 2
for g in groups:
    for line in g:
        tw = width(line); assert tw <= 316, (line, tw)
        x = (W - tw) // 2
        for c in line:
            if c == ' ': x += space; continue
            w, h, px = chars[idx(c)]
            for yy in range(h):
                shade = min(5, yy * 6 // GH)
                for xx in range(w):
                    v = px[yy * w + xx]
                    if not v: continue
                    inner = v >= 45                   # FONTBIG: the core line uses the high colours
                    img[y + yy][x + xx] = (2 if inner else 8) + shade
            x += w + 1
        y += PITCH
    y += gap
for yy in range(H - 1, 0, -1):                 # the shadow: one right and one down, where empty
    for xx in range(W - 1, 0, -1):
        if img[yy][xx] == 0 and img[yy - 1][xx - 1] >= 2: img[yy][xx] = 1
inner = [(255, 255, 255), (226, 234, 255), (196, 210, 255), (164, 184, 250), (134, 156, 240), (106, 128, 228)]
outer = [(206, 216, 250), (176, 192, 246), (146, 166, 238), (118, 140, 226), (92, 114, 212), (70, 90, 196)]
def gen(c): return ((c[2] * 7 + 127) // 255) << 9 | ((c[1] * 7 + 127) // 255) << 5 | ((c[0] * 7 + 127) // 255) << 1
pal = [0, gen((14, 16, 48))] + [gen(c) for c in inner] + [gen(c) for c in outer] + [0, 0]
tiles, index, nt = [bytes(32)], {bytes(32): 0}, []
for ty in range(32):
    for tx in range(40):
        t = bytes((img[ty * 8 + r][tx * 8 + c] << 4) | img[ty * 8 + r][tx * 8 + c + 1] for r in range(8) for c in range(0, 8, 2))
        if t not in index: index[t] = len(tiles); tiles.append(t)
        nt.append(index[t])
os.makedirs(out, exist_ok=True)
open(os.path.join(out, 'credits_tiles.bin'), 'wb').write(b''.join(tiles[1:]))
open(os.path.join(out, 'credits_map.bin'), 'wb').write(b''.join(((0x2000 | t) if t else 0).to_bytes(2, 'big') for t in nt))
open(os.path.join(out, 'credits_pal.bin'), 'wb').write(b''.join(v.to_bytes(2, 'big') for v in pal))
print('credits: %d lines, %d tiles (%d bytes)' % (nlines, len(tiles) - 1, (len(tiles) - 1) * 32))
# C1: the same letters one by one for the CD player line (plane A): 0-9, A-Z, two tiles each
# (top 8 rows, bottom 8 rows of a 16-row cell, the 10-row letter from row 3), the same shading
glyphs = bytearray()
for c in '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ':
    w, h, px = chars[idx(c)]
    cell = [[0] * 8 for _ in range(16)]
    for yy in range(h):
        shade = min(5, yy * 6 // GH)
        for xx in range(min(w, 8)):
            v = px[yy * w + xx]
            if v: cell[yy + 3][xx] = (2 if v >= 45 else 8) + shade
    for yy in range(15, 0, -1):
        for xx in range(7, 0, -1):
            if cell[yy][xx] == 0 and cell[yy - 1][xx - 1] >= 2: cell[yy][xx] = 1
    for t in range(2):
        for r in range(8):
            row = cell[t * 8 + r]
            glyphs += bytes(row[x] << 4 | row[x + 1] for x in range(0, 8, 2))
open(os.path.join(out, 'player_glyphs.bin'), 'wb').write(glyphs)
print('player_glyphs.bin: 36 letters, %d bytes' % len(glyphs))
if len(sys.argv) > 3:
    from PIL import Image
    def rgb(v): return (((v >> 1) & 7) * 36, ((v >> 5) & 7) * 36, ((v >> 9) & 7) * 36)
    im = Image.new('RGB', (W, H), (6, 8, 22))
    for yy in range(H):
        for xx in range(W):
            if img[yy][xx]: im.putpixel((xx, yy), rgb(pal[img[yy][xx]]))
    im.resize((W * 3, H * 3), Image.NEAREST).save(sys.argv[3])
