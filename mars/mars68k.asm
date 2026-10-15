; ---------------------------------------------------------------------------
; 32X support code for the 68000 (Mars = 1)
; ---------------------------------------------------------------------------

mars_adapter:	equ $A15100	; adapter control: bit 15 FM (1 = the SH2s have the 32X VDP), bits 0-1 ADEN/RES
mars_bank:	equ $A15104	; ROM bank shown at $900000-$9FFFFF
mars_comm0:	equ $A15120	; COMM0-COMM14: shared with the SH2s
mars_comm12:	equ $A1512C
mars_vdpmode:	equ $A15180	; 32X VDP: bitmap mode
mars_fbctl:	equ $A1518A	; 32X VDP: frame buffer control (bit 0 FS)
mars_cram:	equ $A15200	; 32X palette (256 colours)
mars_fb:	equ $840000	; 32X frame buffer (68000 side, the buffer not shown)

; ---------------------------------------------------------------------------
; After Sega's start-up code: wait until both SH2s have booted ("M_OK" and
; "S_OK" in COMM0 / COMM4, written by the 32X boot ROM), then start the game.
; ---------------------------------------------------------------------------
Init32X:
		move	#$2700,sr
		lea	(v_systemstack).w,sp			; the 32X ignores vector 0: set the stack here
		lea	(mars_adapter).l,a0
.master:	cmpi.l	#'M_OK',$20(a0)
		bne.s	.master
.slave:		cmpi.l	#'S_OK',$24(a0)
		bne.s	.slave
		moveq	#0,d0
		move.l	d0,$20(a0)				; tell the SH2s the 68000 runs
		move.l	d0,$24(a0)
		move.w	d0,mars_bank-mars_adapter(a0)		; bank 0: ROM $000000-$0FFFFF at $900000
		jmp	(EntryPoint).l

; ---------------------------------------------------------------------------
; Set up the 32X screen from the 68000, then hand it to the SH2s - the way
; Virtua Racing Deluxe does it (it runs on the same console):
; FM = 0 ($0083), 256-colour mode with PRI clear, palette 0, both frame
; buffers: line table (line n at word $100 + n*160) and every pixel colour 0;
; then FM = 1 ($8083) and "S32G" in COMM12: the master SH2 may draw.
; Called from GameInit (interrupts off).
; ---------------------------------------------------------------------------
Mars_Init68k:
		move.w	#$0083,(mars_adapter).l			; the 68000 takes the 32X VDP
		move.w	#$0001,(mars_vdpmode).l			; 256 colours, PRI clear
		lea	(mars_cram).l,a0
		moveq	#0,d0
		move.w	#256/2-1,d1
.pal:		move.l	d0,(a0)+
		dbf	d1,.pal
		moveq	#2-1,d3					; both frame buffers
.buffer:	lea	(mars_fb).l,a0
		move.w	#$100,d0
		move.w	#256-1,d1
.linetable:	move.w	d0,(a0)+
		addi.w	#160,d0
		dbf	d1,.linetable
		moveq	#0,d0
		move.w	#($10000-$100)/2-1,d1
.clear:		move.l	d0,(a0)+
		dbf	d1,.clear
		move.w	(mars_fbctl).l,d2			; show the other buffer: wait for the swap
		andi.w	#1,d2
		eori.w	#1,d2
		move.w	d2,(mars_fbctl).l
		move.l	#$200000,d4				; (never forever)
.swap:		move.w	(mars_fbctl).l,d0
		andi.w	#1,d0
		cmp.w	d2,d0
		beq.s	.swapped
		subq.l	#1,d4
		bne.s	.swap
.swapped:	dbf	d3,.buffer
		move.w	#$8083,(mars_adapter).l			; the SH2s take the 32X VDP
		move.l	#'S32G',(mars_comm12).l			; the master SH2 may start
		rts

; ---------------------------------------------------------------------------
; Every vertical interrupt, COMM0 for the master SH2:
;   bits 0-11  the Mega Drive's backdrop colour (palette line 0 colour 0 on the
;              Sega and continue screens, line 2 colour 0 elsewhere): 32X colour 0
;   bits 12-14 the 32X sky: 0 none, 1 Green Hill, 3 Marble, 4 Star Light,
;              5 Spring Yard, 6 Scrap Brain (zone + 1; Labyrinth has none) -
;              only while a level or demo runs
;              7: the credits screen (OpenJazz's plasma; COMM2 bits 8-12 = speed)
;   bit 15     the palette is fading: no sky (the backdrop colour fades with it)
; Outside levels and demos also COMM2 = 0 (no Tails).
; ---------------------------------------------------------------------------
Mars_SendBG:
		tst.b	(v_mars_credits).w			; the credits screen: plasma (code 7), its speed in COMM2
		beq.s	.nocredits
		moveq	#0,d0
		move.b	(v_mars_speed).w,d0
		lsl.w	#8,d0
		move.w	d0,(mars_comm2).l
		move.w	#$7000,d1
		bra.s	.colour
.nocredits:
		moveq	#0,d1					; sky code
		cmpi.b	#id_Level,(v_gamemode).w
		beq.s	.level
		cmpi.b	#id_Demo,(v_gamemode).w
		beq.s	.level
		move.w	#0,(mars_comm2).l			; no Tails
		bra.s	.colour
.level:		move.b	(v_zone).w,d1
		cmpi.b	#id_LZ,d1
		bne.s	.sky
		moveq	#-1,d1					; (Labyrinth: none)
.sky:		addq.w	#1,d1
		andi.w	#7,d1
		ror.w	#4,d1					; -> bits 12-14
		move.w	(v_palette+$40).w,d0
		cmp.w	(v_palette_fading+$40).w,d0		; still fading in or out?
		beq.s	.colour
		ori.w	#$8000,d1
.colour:	move.w	(v_palette+$40).w,d0
		cmpi.b	#id_Sega,(v_gamemode).w
		beq.s	.line0
		cmpi.b	#id_Continue,(v_gamemode).w
		bne.s	.send
.line0:		move.w	(v_palette).w,d0
.send:		andi.w	#$0EEE,d0
		or.w	d1,d0
		move.w	d0,(mars_comm0).l
		rts

; ---------------------------------------------------------------------------
; Green Hill (after its art is loaded): the sky see-through, the clouds kept,
; so the 32X sky shows behind them (tiles from mars/tools/ghz_sky.py; blocks
; of the plain sky tile $F4, palette line 3, become empty)
; ---------------------------------------------------------------------------
Mars_GHZSky:
		tst.b	(v_zone).w				; Green Hill?
		bne.s	.done
		lea	(v_16x16).w,a1
		move.w	#$1800/2-1,d1
.block:		move.w	(a1),d0
		andi.w	#$67FF,d0				; palette line + tile
		cmpi.w	#$60F4,d0
		bne.s	.next
		clr.w	(a1)
.next:		addq.w	#2,a1
		dbf	d1,.block
		lea	Mars_GHZSkyTiles(pc),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	.done
		move	sr,-(sp)
		move	#$2700,sr
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
.tile:		moveq	#0,d0
		move.w	(a1)+,d0				; tile number
		lsl.l	#5,d0					; VRAM address -> VDP write command
		move.l	d0,d2
		andi.w	#$3FFF,d0
		ori.w	#$4000,d0
		swap	d0
		lsr.l	#8,d2
		lsr.l	#6,d2
		andi.w	#3,d2
		move.w	d2,d0
		move.l	d0,(a5)
		moveq	#8-1,d3
.long:		move.l	(a1)+,(a6)
		dbf	d3,.long
		dbf	d1,.tile
		move	(sp)+,sr
.done:		rts
Mars_GHZSkyTiles:
		binclude "mars/ghz_sky.bin"
		even

; ---------------------------------------------------------------------------
; The "SEGA" voice on the 32X's PWM (slave SH2), at the pitch it has on a Mega
; Drive: there the Z80 plays one sample every 90 + 13*(loop count-1) Z80 cycles
; (pcmLoopCounter for the sample's rate from sega.wav, 16,500 Hz: 220 cycles),
; plus about 3.3 cycles for reading each byte through the 68000 bus: 223.3 Z80
; cycles, 16,030 Hz NTSC. The PWM cycle register is the 32X clock divided by
; that rate, plus 1 (the PWM's period is cycle - 1 clocks).
; COMM12-14 = ROM offset of Mars_SegaTable, COMM10 = cycle, COMM8 = request
; number (+1 = play); the slave sets COMM10 to 0 when done.
; Waits (Sega screen's vertical interrupts going on) until then, 3 s at most.
; ---------------------------------------------------------------------------
mars_comm6:	equ $A15126	; (Tails' position for the master)
mars_comm8:	equ $A15128
mars_comm10:	equ $A1512A
; (Mars_SegaCycleNTSC / Mars_SegaCyclePAL: at the end of sonic.asm, after the sound driver)

Mars_SegaTable:
		dc.l SegaPCM-$900000				; ROM offset of the sample (8-bit unsigned)
		dc.l SegaPCM.size				; its size in bytes

Mars_PlaySega:
		move.l	#Mars_SegaTable-$900000,(mars_comm12).l
		move.w	#Mars_SegaCycleNTSC,d0
		btst	#6,(v_megadrive).w			; PAL console?
		beq.s	.ntsc
		move.w	#Mars_SegaCyclePAL,d0
.ntsc:		move.w	d0,(mars_comm10).l
		move.w	(mars_comm8).l,d1
		addq.w	#1,d1
		move.w	d1,(mars_comm8).l			; play
		move.w	#3*60-1,d2
.wait:		move.b	#id_VBlank_Sega,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		move.w	(mars_comm10).l,d0			; finished? (0 twice: the slave may be writing it)
		bne.s	.next
		tst.w	(mars_comm10).l
		beq.s	.done
.next:
		dbf	d2,.wait
.done:		rts

		include	"mars/tails.asm"
		include	"mars/menu.asm"
