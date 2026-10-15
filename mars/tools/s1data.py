#!/usr/bin/env python3
# SONIC32 R1: Sonic 1 data readers - Nemesis, Kosinski, Enigma decompression (the formats Sonic 1 / Sonic32
# use for art, 256x256 chunks and 16x16 blocks), the level layout, and a renderer.
import struct

class Bits:
    def __init__(s, d, p): s.d, s.p, s.n, s.v = d, p, 0, 0
    def bit(s):
        if s.n == 0:
            s.v = s.d[s.p]; s.p += 1; s.n = 8
        s.n -= 1
        return (s.v >> s.n) & 1
    def bits(s, k):
        r = 0
        for _ in range(k): r = r << 1 | s.bit()
        return r

def nemesis(d):
    hdr = d[0] << 8 | d[1]
    xor, ntiles = hdr & 0x8000, hdr & 0x7FFF
    p, codes, nyb = 2, {}, 0
    while True:
        b = d[p]; p += 1
        if b == 0xFF: break
        if b & 0x80:
            nyb = b & 0x0F
            b = d[p]; p += 1
        codes[(b & 0x0F, d[p])] = (nyb, ((b >> 4) & 7) + 1); p += 1
    bs, out, row, nrow, prev = Bits(d, p), bytearray(), 0, 0, 0
    total = ntiles * 8 * 8
    nyb_out = []
    while len(nyb_out) < total:
        code, ln = 0, 0
        while True:
            code = code << 1 | bs.bit(); ln += 1
            if ln == 6 and code == 0x3F:
                cnt = bs.bits(3) + 1; v = bs.bits(4); break
            if (ln, code) in codes:
                v, cnt = codes[(ln, code)]; break
            if ln > 8: raise ValueError('bad nemesis code')
        nyb_out += [v] * cnt
    nyb_out = nyb_out[:total]
    for i in range(0, total, 8):
        r = 0
        for k in range(8): r = r << 4 | nyb_out[i + k]
        if xor: r ^= prev; prev = r
        out += struct.pack('>I', r)
    return bytes(out)

def kosinski(d):
    p = 0
    out = bytearray()
    desc = d[0] | d[1] << 8; p = 2; n = 16
    def bit():
        nonlocal desc, n, p
        b = desc & 1; desc >>= 1; n -= 1
        if n == 0:
            desc = d[p] | d[p + 1] << 8; p += 2; n = 16
        return b
    while True:
        if bit():
            out.append(d[p]); p += 1; continue
        if bit():
            lo, hi = d[p], d[p + 1]; p += 2
            off = (((hi & 0xF8) << 5) | lo) - 0x2000
            cnt = hi & 7
            if cnt == 0:
                cnt = d[p]; p += 1
                if cnt == 0: break
                if cnt == 1: continue
                cnt += 1
            else:
                cnt += 2
        else:
            cnt = (bit() << 1 | bit()) + 2
            off = d[p] - 0x100; p += 1
        for _ in range(cnt): out.append(out[len(out) + off])
    return bytes(out)

def enigma(d, startoff=0):
    nbits, mask = d[0], d[1]
    inc = d[2] << 8 | d[3]
    com = d[4] << 8 | d[5]
    bs, out = Bits(d, 6), []
    def inline():
        v = 0
        for k, b in ((4, 15), (3, 14), (2, 13), (1, 12), (0, 11)):
            if mask & (1 << k) and bs.bit(): v |= 1 << b
        return v | bs.bits(nbits)
    while True:
        if bs.bit() == 0:
            mode = bs.bit(); cnt = bs.bits(4) + 1
            if mode == 0:
                for _ in range(cnt): out.append(inc); inc += 1
            else:
                out += [com] * cnt
        else:
            mode = bs.bits(2); cnt = bs.bits(4)
            if mode == 3:
                if cnt == 0xF: break
                for _ in range(cnt + 1): out.append(inline())
            else:
                v = inline()
                for _ in range(cnt + 1):
                    out.append(v & 0xFFFF)
                    if mode == 1: v += 1
                    elif mode == 2: v -= 1
    return [(w + startoff) & 0xFFFF for w in out]

def asm_dcb(asm_lines, label, nbytes):
    """the bytes of 'label: dc.b ...' (and following dc.b lines) from Sonic32.asm"""
    import re
    out, on = [], False
    for l in asm_lines:
        if l.startswith(label + ':'): on = True; l = l[len(label) + 1:]
        elif on and re.match(r'^[A-Za-z_]', l): break
        if on:
            m = re.search(r'dc\.b\s+([^;]*)', l)
            if m:
                for t in m.group(1).split(','):
                    t = t.strip()
                    if t: out.append(int(t[1:], 16) if t.startswith('$') else int(t))
            if len(out) >= nbytes: break
    return bytes(out[:nbytes])

def render_layout(layout, chunks, blocks, art, x0=0, w=None, wrap=True):
    """pixels (palette line*16+index, 0 = see-through) of a Sonic 1 layout, list of rows"""
    lw, lh = layout[0] + 1, layout[1] + 1
    W = lw * 256 if w is None else w
    H = lh * 256
    img = [[0] * W for _ in range(H)]
    for cy in range(lh):
        for cxw in range((x0 // 256), (x0 + W + 255) // 256):
            cid = layout[2 + cy * lw + (cxw % lw)] & 0x7F
            if not cid: continue
            ch = chunks[(cid - 1) * 512:cid * 512]
            for by in range(16):
                for bx in range(16):
                    cw = ch[(by * 16 + bx) * 2] << 8 | ch[(by * 16 + bx) * 2 + 1]
                    bi, bh, bv = cw & 0x3FF, (cw >> 11) & 1, (cw >> 12) & 1
                    for ty in range(2):
                        for tx in range(2):
                            sx_, sy_ = (1 - tx if bh else tx), (1 - ty if bv else ty)
                            pw = blocks[bi * 4 + sy_ * 2 + sx_]
                            t, ph, pv, pal = pw & 0x7FF, (pw >> 11) & 1, (pw >> 12) & 1, (pw >> 13) & 3
                            ph ^= bh; pv ^= bv
                            for py in range(8):
                                for px in range(8):
                                    qx, qy = (7 - px if ph else px), (7 - py if pv else py)
                                    b = art[t * 32 + qy * 4 + qx // 2] if t * 32 < len(art) else 0
                                    v = (b >> 4) if qx % 2 == 0 else b & 15
                                    X = cxw * 256 + bx * 16 + tx * 8 + px - x0
                                    Y = cy * 256 + by * 16 + ty * 8 + py
                                    if 0 <= X < W and v: img[Y][X] = pal * 16 + v
    return img
