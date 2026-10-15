; ---------------------------------------------------------------------------
; 32X ROM header (Mars = 1): replaces the Mega Drive vectors and header.
;
; $000-$0FF  68000 vectors: all point at Sega's start-up code ($3F0). On a 32X the
;            68000 reads its vectors from the 32X's own vector ROM, which jumps
;            into the table at $200 below.
; $100-$1FF  Mega Drive header
; $200-$3BF  jump table for the 68000's exceptions and interrupts (6 bytes each)
; $3C0-$3EF  32X header: where the SH2 program is, its entry points and VBRs
; $3F0-$7FF  Sega's 32X start-up code (ICD_MARS; required, unchanged)
; $800       jump to Init32X; from here on the code runs at $900000 + ROM offset
;            (the 32X shows the first 1 MB of the cartridge there, bank 0)
; ---------------------------------------------------------------------------

Vectors:
		dc.l 0						; initial stack pointer (set later)
	rept 63
		dc.l $3F0					; start-up code
	endr

		dc.b "SEGA MEGA DRIVE "				; hardware system ID
		dc.b "(C)SEGA 1991.APR"				; copyright and date
	rept 2
		dc.b "SONIC THE HEDGEHOG 32X                          "
	endr
		dc.b "GM 00004049-01"				; serial/version
Checksum:	dc.w 0
		dc.b "J               "				; I/O support
		dc.l 0						; start address of ROM
RomEndLoc:	dc.l EndOfRom-$900000-1				; end address of ROM
		dc.l $FF0000					; start address of RAM
		dc.l $FFFFFF					; end address of RAM
		dc.b "    "
		dc.b "    "
		dc.b "    "
		dc.b "                                                    "
		dc.b "JUE             "
	if * <> $200
		fatal "32X header: the jump table must start at $200, not $\{*}"
	endif

; jump table: one entry per 68000 exception vector 1-63 (vector 0 is the stack)
		jmp	(Init32X).l				; reset
		jmp	(BusError).l
		jmp	(AddressError).l
		jmp	(IllegalInstr).l
		jmp	(ZeroDivide).l
		jmp	(ChkInstr).l
		jmp	(TrapvInstr).l
		jmp	(PrivilegeViol).l
		jmp	(Trace).l
		jmp	(Line1010Emu).l
		jmp	(Line1111Emu).l
	rept 12
		jmp	(ErrorExcept).l				; reserved
	endr
		jmp	(ErrorExcept).l				; spurious interrupt
		jmp	(ErrorTrap).l				; IRQ 1
		jmp	(ErrorTrap).l				; IRQ 2
		jmp	(ErrorTrap).l				; IRQ 3
		jmp	(HBlank).l				; IRQ 4: horizontal interrupt
		jmp	(ErrorTrap).l				; IRQ 5
		jmp	(VBlank).l				; IRQ 6: vertical interrupt
		jmp	(ErrorTrap).l				; IRQ 7
	rept 16
		jmp	(ErrorTrap).l				; TRAP #0-15
	endr
	if * > $3C0
		fatal "32X header: the jump table runs past $3C0 (at $\{*})"
	endif
		dcb.b	$3C0-*,0

; 32X header (read by the 32X's boot ROM)
		dc.b "MARS SONIC1     "				; module name
		dc.l 0						; version
		dc.l Mars_SH2-$900000				; SH2 program: ROM offset
		dc.l 0						; destination (SDRAM offset)
		dc.l Mars_SH2_End-Mars_SH2			; size
		dc.l $06000400					; master SH2 entry
		dc.l $06000420					; slave SH2 entry
		dc.l $06000000					; master SH2 vector table (VBR)
		dc.l $06000200					; slave SH2 vector table (VBR)
	if * <> $3F0
		fatal "32X header: the start-up code must be at $3F0, not $\{*}"
	endif

; Sega's 32X start-up code (security check, adapter enable); ends at $800
		binclude "mars/icd.bin"
	if * <> $800
		fatal "32X header: the start-up code must end at $800, not $\{*}"
	endif
		jmp	(Init32X).l				; continue in the game's code

		phase $900000+*
