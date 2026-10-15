# Sonic the Hedgehog 32X – with Tails, 32X skies (real hardware)

**Sonic the Hedgehog** (REV01) rebuilt as a **Sega 32X** cartridge game from Sonic Retro's
**s1disasm** source, one step at a time, every step tested on a real Genesis + 32X. It adds
**Tails** (from Sonic 2) drawn by the 32X, **32X color skies**, the **SEGA voice** on the 32X's PWM,
and a hidden **menu** with a **credits screen** (OpenJazz's plasma, Sega CD audio player).

---

## What it is

- A **32X cartridge game** (`s1built.32x`). It runs on a Genesis / Mega Drive with a 32X (tested on
  a real console from a Mega EverDrive) and in emulators with 32X support (PicoDrive).
- Sonic 1, unchanged in its levels, physics, bosses and special stages – the 68000 runs Sonic 1 as
  before. Everything new is **added around it**: the 32X start-up, Tails, the 32X picture layer, the
  menu, the credits.
- Optionally a **32XCD** game: with a **Sega CD** attached underneath and an **audio CD** in the drive,
  the credits screen plays the CD's tracks ("Mode 1").
- Built from source: with `Mars = 0` in `sonic.asm` the same tree still builds the original Mega
  Drive ROM, byte for byte.

## What it is not

- **Not Sonic 2 or Sonic 3.** Only Tails and his animations come from Sonic 2; the levels are Sonic 1's.
- **Not a second character.** Tails follows Sonic's path; he has no physics of his own, cannot be
  hurt, cannot die, and does not touch rings, monitors or badniks. The camera always follows Sonic.
- **Not a Sega CD game** (it does not boot from a disc). Without a Sega CD it works the same; the
  credits screen then says why there is no CD player.
- **Not a full 32X remake.** The Genesis still draws Sonic 1's levels; the 32X adds a layer *behind*
  them (skies) and draws Tails in front. The level graphics are not redrawn in 256 colors.

---

## Controls

| Where | Button | Does |
|---|---|---|
| Title screen | Start | Play (as Sonic 1) |
| Anywhere (title, demos, levels – also paused –, special stage) | **Mode + Z** (6-button pad 1) | Open the **menu** |
| Menu | Up / Down, A / C / Start | Choose a zone / act / special stage / sound select / **CREDITS** |
| Menu | **B** | Back to the title screen |
| Credits | Up / Down | Plasma faster / slower |
| Credits | **X** | All text except the CD line off / on |
| Credits | **B** (or Z) | Back to the menu |
| Credits, with an audio CD | Left / Right, A, C, Start | Choose a track, play, stop, pause / go on |

Mode, X, Y and Z need a **6-button pad**. Sonic 1's own level select cheat still works too.

### Tails

Tails runs behind Sonic, about a quarter of a second behind, along exactly Sonic's path – he never
falls behind or gets stuck. He copies what Sonic did then with his own Sonic 2 animations (walk,
run, roll, push, wait, spring, hurt ...), his tails included, facing the way Sonic faced. He is
shown in levels and demos, hidden on title cards and everywhere else.

### The credits screen

The credits roll up from the bottom of the screen over OpenJazz's menu plasma, with the CD player
line underneath: `TRACK 05 OF 12  PLAYING`, or why there is none (`NO SEGA CD FOUND`,
`SEGA CD DOES NOT ANSWER`, `NO AUDIO CD`).

---

## How the 32X is used

The Genesis (68000 + VDP) still runs and draws Sonic 1. The 32X adds a **second picture layer**
(320 x 224, 256 colors from 32,768) mixed with the Genesis picture, and two SH2 processors:

| Part | Job |
|---|---|
| **Master SH2** (`mars/sh2/master.c`, `plasma.c`) | Draws the skies, Tails and his tails, the credits plasma; double-buffered, one frame per vertical blank |
| **Slave SH2** (`mars/sh2/slave.c`) | The SEGA voice on the PWM |
| **68000** (`sonic.asm` + `mars/`) | Sonic 1, plus: the 32X start-up and hand-over, Tails, the 6-button pad, the menu, the credits, CD audio, telling the SH2s what to do |

**The 32X enhancements:**

- **Tails in 32X colors.** His 139 animation frames (from Sonic 2) are pre-drawn into 8-bit pictures
  with his own 15-color 32X palette (`mars/tools/tails_frames.py`) – no Genesis palette line, no
  sprites, no VRAM: Sonic 1's graphics are untouched. His colors carry the 32X "through" bit, so he
  is in front of the Genesis picture.
- **Skies in 15-bit color.** 64-shade gradients, *behind* the Genesis picture, where Sonic 1 shows
  its backdrop color. Green Hill: sky and water; its sky is made see-through at the level start
  (`mars/tools/ghz_sky.py`, `Mars_GHZSky`), **the Genesis keeps drawing the clouds in front**, and
  the gradient follows the background's scrolling. The **title screen** gets the same Green Hill sky
  and water behind its clouds (its blocks and tiles patched as it loads them). Marble, Star Light, Spring Yard and Scrap Brain:
  a gradient per zone (deep blue to lilac, night to violet, purple to orange twilight, smog brown to
  amber). While Sonic 1 fades its palette, the backdrop color is shown instead, so it fades too.
  Labyrinth has no sky.
- **The SEGA voice on the PWM**, at its Mega Drive pitch: the PWM cycle is the 32X clock divided by
  the rate the Z80 really plays it at (sega.wav's 16,500 Hz through the Z80 driver's loop timing,
  plus its 68000-bus reads: about 16,030 Hz), worked out at build time, NTSC and PAL. Music and
  sound effects stay on the Genesis as in Sonic 1.
- **The credits plasma:** OpenJazz's main menu plasma – its formula, sine table and colors
  unaltered; only its pace is set by the speed (Up / Down).
- **Hardware features used:** 256-color packed-pixel mode, double frame buffers, **Auto Fill** (the
  32X VDP fills lines itself), the through bit (32X in front of or behind the Genesis), per-frame
  palette changes in vertical blank, PWM sound.

### Start-up (what a real console needs)

1. Sega's 32X start-up code (`mars/icd.bin`, at `$3F0`) runs on the 68000, then `Init32X` waits for
   both SH2s (`M_OK`, `S_OK`) and sets the stack (the 32X ignores vector 0).
2. Sonic 1 starts; in `GameInit` the **68000 sets up the 32X screen** (`Mars_Init68k`: FM = 0 with
   `$0083`, 256 colors, line tables, both buffers cleared, palette) and **hands it to the SH2s**
   (`$8083`) – the way Virtua Racing Deluxe does it – then writes `S32G` to COMM12.
3. Both SH2s touch nothing until they see `S32G` (Sega's start-up code clears and checks the 32X
   registers while the SH2s already run).

The SH2 program's size in the 32X header must be a multiple of 4 (the boot ROM copies it a long at
a time) – it is padded to 16 and checked at build time. Data the SH2s read as longs must be 4-byte
aligned.

**68000 → SH2s:** the 16-bit COMM registers.

| Register | Written by | In a level | In the credits |
|---|---|---|---|
| COMM0 | 68000 (vertical blank) | backdrop color (bits 0-11), sky: zone + 1 (12-14), fading (15) | sky code 7 = plasma |
| COMM2 | 68000 | background y (0-7), Tails on screen / facing left / bit 8 of x, y | plasma speed (bits 8-12) |
| COMM4 | 68000 | Tails' frame, his tails' frame | – |
| COMM6 | 68000 | Tails' screen x + 64, y + 64 | – |
| COMM8 | 68000 | SEGA voice request (number + 1 = play) | – |
| COMM10 | 68000 / slave | PWM cycle / 0 = voice finished | – |
| COMM12-14 | 68000 | `S32G` at start, then the voice's table | – |

COMM2 = 0 outside levels and demos: no Tails.

---

## Sega CD audio

Chilly Willy's **Mode 1** code from Victor Luchits' YATSSD (`src-md`: `main.c` InitCD and the
Sub-CPU program `cd.s`), as in the earlier Sonic32 build: `mars/cd.asm`, `mars/cd_sub.asm`. Find the
Sega CD BIOS at `$400000`, unpack it into the Sub-CPU's memory (with Sonic 1's own Kosinski decoder),
copy the Sub-CPU program to `$6000`, start it, raise its level 2 interrupt every frame; commands D
(disc info: track count), P (play), S (stop), Z (pause / go on). It is started the first time the
credits screen opens. The BIOS name check reads byte by byte: its offset (`$6D`) is odd, and the
earlier build's long read there stopped a real 68000 with an address error.

---

## Building

Needs **Lua 5.4**, the SH2 GCC toolchain (`sh-elf-gcc`, SGDK-style under `/opt/toolchains/sega`),
and Linux / WSL / macOS (s1disasm's assembler `asl` and `p2bin` are in `build_tools/`).

1. `make -C mars/sh2` – the SH2 program, `mars/sh2/sh2.bin` (committed; only needed after changing
   `mars/sh2`).
2. `lua build.lua` – Sonic 1 with the 32X parts.
3. Output: **`s1built.32x`** (the same bytes as `s1built.bin`).

`Mars = 0` in `sonic.asm` builds the original Mega Drive ROM (MD5 `09dadb5071eb35050067a32462e39c5f`).

**Generated data** (included; rebuild only to change it – Python 3):

| File | Made by | From |
|---|---|---|
| `mars/sh2/tails_frames.bin`, `tails_pal.bin` | `mars/tools/tails_frames.py` | Sonic 2's Tails art and mappings (s2disasm) |
| `mars/tails_anim.asm` | (converted) | Sonic 2's Tails animation scripts |
| `mars/ghz_sky.bin` | `mars/tools/ghz_sky.py` | Sonic 1's Green Hill art (this tree) |
| `mars/credits/*.bin` | `mars/tools/credits_roll.py` | Jazz Jackrabbit's `FONTBIG.0FN` (not included) |
| `mars/sh2/oj_sin.h` | (Python, see the file) | OpenJazz's sine table |

`mars/tools/s1data.py` reads Sonic 1's Nemesis, Kosinski and Enigma data.

---

## Files

| Path | What |
|---|---|
| `sonic.asm` | s1disasm's Sonic 1; every 32X change inside `if Mars=1` |
| `mars/header.asm` | the 32X header, interrupt jump table, Sega's start-up code; the code then runs at `$900000` + ROM offset |
| `mars/mars68k.asm` | 68000: waiting for the SH2s, the 32X set-up and hand-over, the backdrop / sky code, Green Hill's sky patch, the SEGA voice request |
| `mars/tails.asm`, `tails_anim.asm` | 68000: Tails (following, animations, sending to the master) |
| `mars/menu.asm` | 68000: the 6-button pad, the menu, the credits screen, the CD line |
| `mars/cd.asm`, `cd_sub.asm` | Sega CD Mode 1 CD audio (main side, Sub-CPU program) |
| `mars/sh2/` | the SH2 program: `crt0.s` (start-up), `master.c`, `plasma.c`, `slave.c`, `sh2.ld`, `Makefile` |
| `mars/tools/` | the converters (Python) |

---

## RAM used (68000)

`v_mars_tails` (`$40` bytes after the sound driver's RAM, unused by Sonic 1): Tails' animation
record and state, the 6-button pad, the menu and credits state, the CD state. Sonic 1's own position
record (`v_tracksonic`) gives Tails his path; on the credits screen it is a text buffer.

## Known limits

- Tails is drawn in front of foreground scenery (loops, tunnels).
- In Labyrinth, Tails' colors do not change underwater; no 32X sky there.
- On the menu, Sonic 1's title emblem shows dimmed behind the text (as in Sonic 1's own level select).
- The CD audio code is the earlier build's; it needs a Sega CD and an audio CD.

---

## Credits

- **Sonic the Hedgehog** – Sonic Team / SEGA 1991. Tails and his art and animations from Sonic 2
  (SEGA 1992).
- **s1disasm** – Sonic Retro and contributors.
- **Sega CD and 32X framework, Mode 1 CD code** – Chilly Willy; **YATSSD** – Victor Luchits (viciious).
- **Plasma** – OpenJazz (Alireza Nejati, Alister Thomson and contributors).
- **Credits font** – Jazz Jackrabbit, Epic MegaGames 1994 (`FONTBIG.0FN`).
- **32X start-up approach** – Virtua Racing Deluxe's (studied in VirtuaRacing32X).
- **This port** – Micronut99.

## Licences – read before publishing

- The plasma follows OpenJazz's: **GPL-2.0** (`mars/sh2/plasma.c`, `oj_sin.h`) – a published ROM
  containing it falls under GPL-2.0.
- Sonic 1, Sonic 2's Tails art, and Jazz Jackrabbit's font are **copyrighted game data** (SEGA, Epic).
  This source tree contains them (as s1disasm does for Sonic 1); the Tails frames and the credits
  font would need replacing or permission for a public release.
- Chilly Willy's Mode 1 code: check its terms (it comes with YATSSD).
- s1disasm: see its own notes (Sonic Retro).
