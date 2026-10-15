# Sonic 1 32X (real hardware)

Sonic the Hedgehog (REV01) rebuilt as a Sega 32X ROM from the s1disasm source, one step at a
time, each step tested on a real Genesis + 32X.

## Build

1. `make -C mars/sh2` (needs the SH2 GCC toolchain, `sh-elf-*`; `sh2.bin` is committed, so this is
   only needed after changing `mars/sh2`)
2. `lua build.lua`
3. Output: `s1built.32x` (the same bytes as `s1built.bin`)

`Mars = 0` in `sonic.asm` builds the original Mega Drive ROM.

## Steps

| Step | What | Status |
|---|---|---|
| 1 | 32X ROM: 32X header and start-up; the 68000 sets up the 32X screen and hands it to the SH2s (as Virtua Racing Deluxe does); the master SH2 draws a white test box (top right) and sets 32X colour 0 to the Genesis backdrop colour | works on a real Genesis + 32X |
| 2 | The "SEGA" voice on the 32X's PWM (slave SH2), at its Mega Drive pitch: PWM cycle = 32X clock / the rate the Z80 plays it at (from sega.wav's rate and the Z80 loop timing), NTSC and PAL; music and effects stay on the Z80 / FM as in the original. The slave waits for the 68000's "S32G" before touching the PWM (first build: black screen on hardware) | works on a real Genesis + 32X |
| 3 | Tails, drawn by the master SH2 in front of the Genesis picture; he follows Sonic's path 16 frames behind with Sonic 2's animations (mars/tails.asm; pictures from Sonic 2's art, mars/tools/tails_frames.py) | works on a real Genesis + 32X |
| 4 | 32X skies: colour gradients drawn by the master SH2 behind the Genesis picture (no bit 15), so they show where Sonic 1 shows its backdrop: Green Hill's sky (made see-through at level start, mars/tools/ghz_sky.py - the Genesis clouds stay in front) and water, the skies of Marble, Spring Yard, Star Light and Scrap Brain; none in Labyrinth; while the palette fades, the backdrop colour instead | built, to be tested on hardware |
| 5 | The secret menu: Sonic 1's level select, opened with Mode + Z on a 6-button pad from anywhere (also paused); its CREDITS line: the credits roll on the Genesis (Jazz Jackrabbit's FONTBIG.0FN, mars/tools/credits_roll.py) over OpenJazz's menu plasma, unaltered except its pace (mars/sh2/plasma.c). Up / Down plasma speed, A or Y text on / off, Start or Z back to the menu, X to the title screen | built, to be tested on hardware |

## Licences of parts not from Sonic 1

- `mars/sh2/plasma.c`, `mars/sh2/oj_sin.h`: OpenJazz's menu plasma (Copyright (c) 2010 Alireza
  Nejati; OpenJazz: GNU General Public License, version 2.0).
- `mars/credits/*`: drawn from Jazz Jackrabbit's FONTBIG.0FN (not included) by `mars/tools/credits_roll.py`.
- `mars/sh2/tails_frames.bin`, `mars/tails_anim.asm`: Sonic 2's Tails art and animation scripts (from s2disasm).

## How the 32X version is put together

- `mars/header.asm` replaces the Mega Drive vectors and header: 32X header, jump table for the
  68000's interrupts at $200, the SH2 program's location at $3C0, Sega's start-up code at $3F0.
- From $800 on, the 68000 code runs at $900000 + ROM offset (the 32X shows the first 1 MB of the
  cartridge there). The Z80 driver keeps its own addresses.
- `mars/mars68k.asm`: waiting for the SH2s, setting up the 32X screen, sending the backdrop colour.
- `mars/sh2`: the SH2 program (master: picture, slave: PWM sound). Its size must be a multiple
  of 4 for the 32X boot ROM (checked at build time, padded to 16).
- COMM registers: COMM0 backdrop colour + sky (bits 12-14) + fading (15), COMM2-6 Tails and the
  background's y (68000 -> master); COMM8 sound request,
  COMM10 PWM cycle / 0 = done, COMM12-14 "S32G" at start, then the sound's table (68000 <-> slave).

---

# Sonic the Hedgehog (16-bit) Disassembly

For an overview of the folder structure, [refer to this page](https://info.sonicretro.org/SCHG_How-to:Disassembly_Folder_Structure#Sonic_1).

Also See: http://info.sonicretro.org/Disassemblies

# DISCLAIMER
Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
