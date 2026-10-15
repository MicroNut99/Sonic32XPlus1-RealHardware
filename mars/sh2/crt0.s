! 32X SH2 start-up for Sonic 1 32X (Mars = 1).
! The 32X boot ROM copies this program to SDRAM $06000000 and starts the
! master at $06000400 (VBR $06000000) and the slave at $06000420 (VBR $06000200).
! Interrupts stay masked (SR = $F0): both SH2s poll.

	.section .vectors,"ax"
	.global _start
_start:
master_vbr:				! $06000000
	.long	master_start		! power-on PC
	.long	0x0603F800		! power-on SP
	.rept	126
	.long	master_trap
	.endr
slave_vbr:				! $06000200
	.long	slave_start
	.long	0x0603FC00
	.rept	126
	.long	slave_trap
	.endr

	.org	0x400
master_start:				! $06000400
	mov.l	m_sp,r15
	mov	#0xF0,r0
	extu.b	r0,r0
	ldc	r0,sr			! interrupts masked
	mov.l	m_main,r0
	jmp	@r0
	nop
	.align	2
m_sp:	.long	0x0603F800
m_main:	.long	_master_main
	.org	0x420
slave_start:				! $06000420
	mov.l	s_sp,r15
	mov	#0xF0,r0
	extu.b	r0,r0
	ldc	r0,sr
	mov.l	s_main,r0
	jmp	@r0
	nop
	.align	2
s_sp:	.long	0x0603FC00
s_main:	.long	_slave_main

master_trap:
	bra	master_trap
	nop
slave_trap:
	bra	slave_trap
	nop
