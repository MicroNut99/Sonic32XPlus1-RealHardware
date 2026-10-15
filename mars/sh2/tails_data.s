! Tails' pictures for the master SH2 (made from Sonic 2's Tails art by mars/tools/tails_frames.py):
! tails_frames: u16 count, u16 0, per frame s16 ox, s16 oy, u16 w, u16 h, u32 offset of the pixels
! (8 bits, 0 = see-through, 1-15 = colours); tails_pal: 16 32X colours
	.section .rodata
	.align	2
	.global	_tails_frames
_tails_frames:
	.incbin	"tails_frames.bin"
	.align	2
	.global	_tails_pal
_tails_pal:
	.incbin	"tails_pal.bin"
	.align	2
