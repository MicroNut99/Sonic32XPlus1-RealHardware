; ===========================================================================
; CD audio from the Sega CD in Mode 1 (this ROM in the cartridge slot, a Sega
; CD attached, an audio CD in the drive) - after Chilly Willy's InitCD in Victor
; Luchits' YATSSD (src-md/main.c), as in the earlier Sonic32 build.
; In Mode 1 the Sega CD sits at $400000: BIOS ROM $400000, program RAM window
; $420000, Word RAM $600000. CD_Init finds the BIOS, unpacks the Sub-CPU BIOS
; into program RAM (Sonic 1's KosDec: the BIOS is Kosinski-packed), copies our
; Sub-CPU program (mars/cd_sub.asm) to $6000 and starts the Sub-CPU. From then
; on every vertical blank raises the Sub-CPU's level 2 interrupt (Mars_SendBG).
; ===========================================================================

CD_Ok:		equ	v_mars_tails+$38	; 1 = CD ready
CD_Lvl2:	equ	v_mars_tails+$39	; 1 = send the Sub-CPU level 2 interrupts
CD_State:	equ	v_mars_tails+$3A	; 0 not tried, 1 no Sega CD (no BIOS), 2 no answer from the Sub-CPU, 3 ready

CD_Init:
		clr.b	(CD_Ok).w
		clr.b	(CD_Lvl2).w
		lea	($415800).l,a0		; where the Sega CD BIOS can be (by model)
		move.l	#'SEGA',d2
		bsr.s	CD_IdIs
		beq.s	CD_BiosFound
		lea	($416000).l,a0
		bsr.s	CD_IdIs
		beq.s	CD_BiosFound
		move.l	#'WOND',d2		; WonderMega / X'Eye
		bsr.s	CD_IdIs
		beq.s	CD_BiosFound
		lea	($41AD00).l,a0		; LaserActive
		move.l	#'SEGA',d2
		bsr.s	CD_IdIs
		beq.s	CD_BiosFound
		move.b	#1,(CD_State).w		; no Sega CD
		rts

; is the BIOS name at $6D(a0) the 4 letters in d2? (Z set if so) - byte by byte: $6D is
; odd, and a word / long read there is an address error on a real 68000 (the earlier
; build's cmpi.l #'SEGA',$6D(a0) stopped the console with ADDRESS ERROR at $41586D)
CD_IdIs:
		move.b	$6D(a0),d1
		lsl.l	#8,d1
		move.b	$6E(a0),d1
		lsl.l	#8,d1
		move.b	$6F(a0),d1
		lsl.l	#8,d1
		move.b	$70(a0),d1
		cmp.l	d2,d1
		rts
CD_BiosFound:
		move.l	a0,-(sp)
		move.w	#$FF00,($A12002).l	; reset the gate array (this exact order)
		move.b	#3,($A12001).l
		move.b	#2,($A12001).l
		move.b	#0,($A12001).l
CD_BusReq:	move.b	#2,($A12001).l		; reset the Sub-CPU, request its bus
		btst	#1,($A12001).l
		beq.s	CD_BusReq
		move.w	#2,($A12002).l		; no write protection, bank 0, 2M
		lea	($420000).l,a1		; clear program RAM bank 0
		move.w	#$20000/4-1,d1
CD_ClrPrg:	clr.l	(a1)+
		dbf	d1,CD_ClrPrg
		movea.l	(sp)+,a0		; unpack the Sub-CPU BIOS to $0000
		lea	($420000).l,a1
		jsr	(KosDec).l
		lea	CD_Sub(pc),a0		; our Sub-CPU program to $6000
		lea	($426000).l,a1
		move.w	#(CD_SubEnd-CD_Sub)/2-1,d1
CD_CopySub:	move.w	(a0)+,(a1)+
		dbf	d1,CD_CopySub
		move.b	#0,($A1200E).l		; main comm port clear
		move.b	#$2A,($A12002).l	; write-protect up to $5400
CD_Run:		move.b	#1,($A12001).l		; let the Sub-CPU run
		btst	#0,($A12001).l
		beq.s	CD_Run
		move.b	#1,(CD_Lvl2).w		; the BIOS needs level 2 interrupts
		move.l	#2000000,d1
CD_WaitI:	cmpi.b	#'I',($A1200F).l	; our program is running
		beq.s	CD_GotI
		subq.l	#1,d1
		bne.s	CD_WaitI
		clr.b	(CD_Lvl2).w		; no answer
		move.b	#2,(CD_State).w
		rts
CD_GotI:	move.l	#4000000,d1
CD_WaitR:	tst.b	($A1200F).l		; ... and ready for commands
		beq.s	CD_Ready
		subq.l	#1,d1
		bne.s	CD_WaitR
		move.b	#2,(CD_State).w
		rts
CD_Ready:	move.b	#1,(CD_Ok).w
		move.b	#3,(CD_State).w
		rts

; ---------------------------------------------------------------------------
; d0.b = command (D T P S Z C) -> d0.b = 'D' done, 'E' error, 0 no CD / no answer
; ---------------------------------------------------------------------------
CD_Cmd:
		tst.b	(CD_Ok).w
		beq.s	CD_CmdNone
		move.l	#300000,d1
CD_CmdIdle:	tst.b	($A1200F).l		; the Sub-CPU is ready
		beq.s	CD_CmdSend
		subq.l	#1,d1
		bne.s	CD_CmdIdle
		bra.s	CD_CmdNone
CD_CmdSend:	move.b	d0,($A1200E).l
		move.l	#3000000,d1
CD_CmdWait:	move.b	($A1200F).l,d0		; its answer
		bne.s	CD_CmdDone
		subq.l	#1,d1
		bne.s	CD_CmdWait
		move.b	#0,($A1200E).l
CD_CmdNone:	moveq	#0,d0
		rts
CD_CmdDone:	move.b	#0,($A1200E).l		; seen
		rts

CD_TrackCount:					; d0 = the last track's number (0 = no CD)
		moveq	#'D',d0
		bsr.s	CD_Cmd
		cmpi.b	#'D',d0
		bne.s	CD_CmdNone
		moveq	#0,d0
		move.b	($A12023).l,d0		; last track (sub status word $8022: first, last)
		rts

CD_PlayTrack:					; d0.w = track number (1 ...): from it on
		move.w	d0,($A12010).l
		move.b	#$FF,($A12012).l	; flag: -1 = play on from this track
		moveq	#'P',d0
		bra.s	CD_Cmd

CD_Stop:	moveq	#'S',d0
		bra.s	CD_Cmd

CD_PauseResume:	moveq	#'Z',d0
		bra.w	CD_Cmd

		include	"mars/cd_sub.asm"
		even
