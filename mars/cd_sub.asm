; ===========================================================================
; The Sega CD Sub-CPU program for CD audio in Mode 1 (cartridge + Sega CD) -
; Chilly Willy's, from Victor Luchits' YATSSD (src-md/cd.s), as in the earlier
; Sonic32 build. Copied to the Sub-CPU's program RAM at $6000 by CD_Init (mars/cd.asm).
; Commands in the main comm port (main $A1200E = sub $800E): D disc info,
; T track info, P play (track in $8010, flag byte $8012: -1 from it on, 0 once,
; else repeat), S stop, Z pause / go on, C check disc. (Short addresses
; $8000-$80FF are written $FFFF80xx: the assembler wants the sign-extended value.) Result in the sub comm
; port ($800F): D done, E error; the main CPU then clears its port.
; ===========================================================================
CD_Sub:
SPHeader:	dc.b	'MAIN-SUBCPU',0
		dc.w	$0001,$0000
		dc.l	$00000000
		dc.l	$00000000
		dc.l	SPHeaderOffsets-SPHeader
		dc.l	$00000000
SPHeaderOffsets:
		dc.w	SPInit-SPHeaderOffsets
		dc.w	SPMain-SPHeaderOffsets
		dc.w	SPInt2-SPHeaderOffsets
		dc.w	SPNull-SPHeaderOffsets
		dc.w	$0000

SPInit:
		move.b	#'I',($FFFF800F).w		; sub comm port = INITIALIZING
		andi.b	#$E2,($FFFF8003).w		; priority mode off, 2M, Sub-CPU has Word RAM
		rts

SPMain:
		move.w	#$0081,d0		; CDBSTAT
		jsr	($5F22).w
		move.w	(a0),d0			; BIOS status word
		bmi.s	SPMain_Init		; not ready
		lsr.w	#8,d0
		cmpi.b	#$40,d0
		beq.s	SPMain_Ready		; tray open
		cmpi.b	#$10,d0
		beq.s	SPMain_Ready		; no disc
SPMain_Init:
		lea	drive_init_parms(pc),a0
		move.w	#$0010,d0		; DRVINIT
		jsr	($5F22).w
		move.w	#$0089,d0		; CDCSTOP
		jsr	($5F22).w
SPMain_Ready:
		move.b	#0,($FFFF800F).w		; sub comm port = READY

WaitCmd:
		tst.b	($FFFF800E).w
		beq.s	WaitCmd
		cmpi.b	#'D',($FFFF800E).w
		beq.w	GetDiscInfo
		cmpi.b	#'T',($FFFF800E).w
		beq.w	GetTrackInfo
		cmpi.b	#'P',($FFFF800E).w
		beq.w	PlayTrack
		cmpi.b	#'S',($FFFF800E).w
		beq.w	StopPlaying
		cmpi.b	#'Z',($FFFF800E).w
		beq.w	PauseResume
		cmpi.b	#'C',($FFFF800E).w
		beq.w	CheckDisc
		move.b	#'E',($FFFF800F).w		; ERROR
WaitAck:
		tst.b	($FFFF800E).w
		bne.s	WaitAck			; until the main CPU has seen the result
		move.b	#0,($FFFF800F).w		; READY
		bra.s	WaitCmd

GetDiscInfo:
		move.w	#$0081,d0		; CDBSTAT
		jsr	($5F22).w
		move.w	(a0),($FFFF8020).w		; BIOS status word
		move.w	16(a0),($FFFF8022).w	; first track, last track
		move.w	18(a0),($FFFF8024).w	; drive version, flag
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck

GetTrackInfo:
		move.w	($FFFF8010).w,d1		; track number
		move.w	#$0083,d0		; CDBTOCREAD
		jsr	($5F22).w
		move.l	d0,($FFFF8020).w		; MMSSFFTN
		move.b	d1,($FFFF8024).w		; track type
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck

PlayTrack:
		move.w	#$0002,d0		; MSCSTOP
		jsr	($5F22).w
		move.w	($FFFF8010).w,d1		; track number
		move.w	#$0011,d0		; MSCPLAY - from this track on
		move.b	($FFFF8012).w,d2		; flag
		bmi.s	PlayTrack_Go
		beq.s	PlayTrack_Once
		move.w	#$0013,d0		; MSCPLAYR - repeat
		bra.s	PlayTrack_Go
PlayTrack_Once:
		move.w	#$0012,d0		; MSCPLAY1 - once
PlayTrack_Go:
		lea	track_number(pc),a0
		move.w	d1,(a0)
		jsr	($5F22).w
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck

StopPlaying:
		move.w	#$0002,d0		; MSCSTOP
		jsr	($5F22).w
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck

PauseResume:
		move.w	#$0081,d0		; CDBSTAT
		jsr	($5F22).w
		move.b	(a0),d0
		cmpi.b	#1,d0
		beq.s	PauseResume_On		; playing: pause
		cmpi.b	#5,d0
		beq.s	PauseResume_Off		; paused: go on
		move.b	#'E',($FFFF800F).w
		bra.w	WaitAck
PauseResume_On:
		move.w	#$0003,d0		; MSCPAUSEON
		jsr	($5F22).w
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck
PauseResume_Off:
		move.w	#$0004,d0		; MSCPAUSEOFF
		jsr	($5F22).w
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck

CheckDisc:
		lea	drive_init_parms(pc),a0
		move.w	#$0010,d0		; DRVINIT
		jsr	($5F22).w
		move.w	#$0089,d0		; CDCSTOP
		jsr	($5F22).w
		move.b	#'D',($FFFF800F).w
		bra.w	WaitAck

SPInt2:
		rts
SPNull:
		rts

		even
drive_init_parms:
		dc.b	$01, $FF		; first track 1, last track: all
track_number:
		dc.w	0
		even
CD_SubEnd:
