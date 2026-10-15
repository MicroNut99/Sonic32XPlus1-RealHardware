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
| 3 | Tails, drawn by the master SH2 in front of the Genesis picture; he follows Sonic's path 16 frames behind with Sonic 2's animations (mars/tails.asm; pictures from Sonic 2's art, mars/tools/tails_frames.py) | built, to be tested on hardware |
| 4 | 32X skies | |

## How the 32X version is put together

- `mars/header.asm` replaces the Mega Drive vectors and header: 32X header, jump table for the
  68000's interrupts at $200, the SH2 program's location at $3C0, Sega's start-up code at $3F0.
- From $800 on, the 68000 code runs at $900000 + ROM offset (the 32X shows the first 1 MB of the
  cartridge there). The Z80 driver keeps its own addresses.
- `mars/mars68k.asm`: waiting for the SH2s, setting up the 32X screen, sending the backdrop colour.
- `mars/sh2`: the SH2 program (master: picture, slave: PWM sound). Its size must be a multiple
  of 4 for the 32X boot ROM (checked at build time, padded to 16).
- COMM registers: COMM0 backdrop colour, COMM2-6 Tails (68000 -> master); COMM8 sound request,
  COMM10 PWM cycle / 0 = done, COMM12-14 "S32G" at start, then the sound's table (68000 <-> slave).

---

# Sonic the Hedgehog (16-bit) Disassembly

For an overview of the folder structure, [refer to this page](https://info.sonicretro.org/SCHG_How-to:Disassembly_Folder_Structure#Sonic_1).

Also See: http://info.sonicretro.org/Disassemblies

# DISCLAIMER
Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
