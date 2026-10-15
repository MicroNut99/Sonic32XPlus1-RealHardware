; ---------------------------------------------------------------------------
; The secret menu (Mars = 1): Sonic 1's level select, opened with Mode + Z on a
; 6-button pad from anywhere (title, demos, levels - also paused -, special
; stage ...). Its last line, CREDITS, opens the credits screen: the credits
; roll on the Genesis (plane B) over OpenJazz's menu plasma drawn by the 32X,
; with the CD player (Sega CD, audio CD) underneath. In the menu, B goes back to
; the title screen.
; ---------------------------------------------------------------------------

v_mars_pad6:	equ v_mars_tails+$30	; 6-button pad 1, held: bit 0 Z, 1 Y, 2 X, 3 Mode
v_mars_pad6p:	equ v_mars_tails+$31	; ... pressed this frame
v_mars_menu:	equ v_mars_tails+$32	; 1 = open the menu (the title screen does)
v_mars_credits:	equ v_mars_tails+$33	; 1 = the credits screen runs (the 32X draws the plasma)
v_mars_crhide:	equ v_mars_tails+$34	; credits text hidden
v_mars_speed:	equ v_mars_tails+$35	; plasma speed 1-16 (8 = normal)
v_mars_roll:	equ v_mars_tails+$36	; the credits' roll, 1/256 pixels (word)

v_mars_titlesky:	equ v_mars_tails+$3F	; 1 = the title screen shows (32X: Green Hill's sky behind it)
levsel_credits_row:	equ 21		; the level select's CREDITS line

; ---------------------------------------------------------------------------
; 6-button pad (port 1), straight after ReadJoypads read it (a1 = port 1 data):
; two more TH pulses; on the third low phase a 6-button pad answers with 0000,
; on the third high phase it gives Mode, X, Y, Z.
; ---------------------------------------------------------------------------
Mars_Read6:
		move.b	#0,(a1)
		nop
		nop
		move.b	#$40,(a1)
		nop
		nop
		move.b	#0,(a1)
		nop
		nop
		move.b	(a1),d0					; third low phase
		move.b	#$40,(a1)
		nop
		nop
		move.b	(a1),d1					; third high phase: Mode X Y Z
		move.b	#0,(a1)
		nop
		nop
		move.b	#$40,(a1)
		andi.b	#$F,d0
		beq.s	.six
		moveq	#0,d1					; a 3-button pad: nothing
		bra.s	.store
.six:		not.b	d1
		andi.b	#$F,d1					; pressed = 1
.store:		move.b	(v_mars_pad6).w,d0
		eor.b	d1,d0
		and.b	d1,d0					; pressed this frame
		move.b	d1,(v_mars_pad6).w
		move.b	d0,(v_mars_pad6p).w
		; Mode + Z together (either pressed last): the menu
		andi.b	#%1001,d1
		cmpi.b	#%1001,d1
		bne.s	.done
		andi.b	#%1001,d0
		beq.s	.done
		tst.b	(v_mars_credits).w			; (the credits screen handles its own keys)
		bne.s	.done
		move.b	#1,(v_mars_menu).w
		cmpi.b	#id_Title,(v_gamemode).w		; the title screen opens it itself
		beq.s	.done
		move.b	#id_Title,(v_gamemode).w		; anywhere else: back to the title screen first
.done:		rts

; ---------------------------------------------------------------------------
; The credits screen (from the level select's CREDITS line; game mode: title)
;   the credits roll up from the bottom of the screen (plane B), OpenJazz's
;   plasma behind (32X); the CD player line (plane A rows 25-26)
;   Up / Down: plasma faster / slower   X: all text but the CD line on / off
;   B (or Z): back to the menu
;   with an audio CD: Left / Right choose a track, A play, C stop, Start pause
; ---------------------------------------------------------------------------
v_mars_track:	equ v_mars_tails+$3B	; the chosen CD track (1 ...)
v_mars_tracks:	equ v_mars_tails+$3C	; the CD's track count (0 = none)
v_mars_player:	equ v_mars_tails+$3D	; 0 stopped, 1 playing, 2 paused
v_mars_rows:	equ v_mars_tails+$3E	; credits rows shown so far (0-32)
mars_textbuf:	equ v_tracksonic	; (Sonic's position record: a text buffer here)

Mars_Credits:
		move	#$2700,sr
		lea	(v_spritetablebuffer).w,a1		; no sprites
		moveq	#0,d0
		move.w	#$280/4-1,d1
.spr:		move.l	d0,(a1)+
		dbf	d1,.spr
		lea	(vdp_data_port).l,a6
		move.l	#$40000003,4(a6)			; plane A ($C000): empty
		move.w	#$1000/2-1,d1
.planea:	move.w	d0,(a6)
		dbf	d1,.planea
		move.l	#$60000003,4(a6)			; plane B ($E000): empty (the credits roll in)
		move.w	#$1000/2-1,d1
.planeb:	move.w	d0,(a6)
		dbf	d1,.planeb
		move.l	#$40200000,4(a6)			; the credits' tiles -> tile 1 ...
		lea	Mars_CreditsTiles(pc),a1
		move.w	#(Mars_CreditsTilesEnd-Mars_CreditsTiles)/4-1,d1
.tiles:		move.l	(a1)+,(a6)
		dbf	d1,.tiles
		move.l	#$40000002,4(a6)			; the CD line's letters -> tile 1024 ...
		lea	Mars_CreditsGlyphs(pc),a1
		move.w	#(Mars_CreditsGlyphsEnd-Mars_CreditsGlyphs)/4-1,d1
.glyphs:	move.l	(a1)+,(a6)
		dbf	d1,.glyphs
		lea	Mars_CreditsPal(pc),a1			; their colours: palette line 1
		lea	(v_palette+$20).w,a2
		moveq	#$10-1,d1
.pal:		move.w	(a1)+,(a2)+
		dbf	d1,.pal
		moveq	#0,d0
		move.l	d0,(v_scrposy_vdp).w
		move.w	d0,(v_mars_roll).w
		move.b	d0,(v_mars_rows).w
		move.b	d0,(v_mars_crhide).w
		move.b	d0,(v_mars_menu).w
		move.b	d0,(v_mars_player).w
		move.b	#8,(v_mars_speed).w
		move.b	#1,(v_mars_track).w
		move.b	#1,(v_mars_credits).w			; the 32X: plasma
		move	#$2300,sr
		tst.b	(CD_Ok).w				; the Sega CD (once)
		bne.s	.cdup
		bsr.w	CD_Init
.cdup:		bsr.w	CD_TrackCount
		move.b	d0,(v_mars_tracks).w
		bsr.w	Mars_TrackLine

.loop:		move.b	#id_VBlank_Title,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		addi.w	#$40,(v_mars_roll).w			; the roll: a quarter pixel a frame, upwards
		move.b	(v_mars_roll).w,d0
		move.b	d0,(v_scrposy_vdp+3).w			; plane B's vertical scroll
		bsr.w	Mars_CreditsReveal
		move.b	(v_mars_pad6p).w,d2			; 6-button keys
		move.b	(v_jpadpress1).w,d3
		btst	#bitB,d3				; B or Z: back to the menu
		bne.w	.menu
		btst	#0,d2
		bne.w	.menu
		btst	#2,d2					; X: the text (all but the CD line) on / off
		beq.s	.nox
		not.b	(v_mars_crhide).w
		bsr.w	Mars_CreditsRedraw
		bra.s	.loop
.nox:		btst	#bitUp,d3				; Up: the plasma faster
		beq.s	.noup
		cmpi.b	#16,(v_mars_speed).w
		bhs.s	.loop
		addq.b	#1,(v_mars_speed).w
		bra.s	.loop
.noup:		btst	#bitDn,d3				; Down: slower
		beq.s	.nodown
		cmpi.b	#1,(v_mars_speed).w
		bls.s	.loop
		subq.b	#1,(v_mars_speed).w
		bra.s	.loop
.nodown:	tst.b	(v_mars_tracks).w			; the player: only with CD tracks
		beq.s	.loop
		btst	#bitStart,d3				; Start: pause / go on
		beq.s	.nopause
		tst.b	(v_mars_player).w
		beq.s	.loop					; (nothing playing)
		bsr.w	CD_PauseResume
		eori.b	#3,(v_mars_player).w			; playing (1) <-> paused (2)
		bra.s	.chosen
.nopause:	btst	#bitL,d3				; Left: the track before
		beq.s	.noleft
		subq.b	#1,(v_mars_track).w
		bne.s	.chosen
		move.b	(v_mars_tracks).w,(v_mars_track).w	; (wrap to the last)
		bra.s	.chosen
.noleft:	btst	#bitR,d3				; Right: the next track
		beq.s	.noright
		addq.b	#1,(v_mars_track).w
		move.b	(v_mars_tracks).w,d0
		cmp.b	(v_mars_track).w,d0
		bhs.s	.chosen
		move.b	#1,(v_mars_track).w			; (wrap to the first)
		bra.s	.chosen
.noright:	btst	#bitA,d3				; A: play
		beq.s	.noplay
		moveq	#0,d0
		move.b	(v_mars_track).w,d0
		bsr.w	CD_PlayTrack
		move.b	#1,(v_mars_player).w
		bra.s	.chosen
.noplay:	btst	#bitC,d3				; C: stop
		beq.w	.loop
		bsr.w	CD_Stop
		clr.b	(v_mars_player).w
.chosen:	bsr.w	Mars_TrackLine
		bra.w	.loop
.menu:		move.b	#1,(v_mars_menu).w			; the title screen opens the menu again
		clr.b	(v_mars_credits).w
		clr.l	(v_scrposy_vdp).w
		move.b	#id_Title,(v_gamemode).w
		rts

; The credits roll in from the bottom: picture row r (8 pixels) goes into plane B's row
; r + 28 just before it scrolls into view; after all 32 the picture just loops.
Mars_CreditsReveal:
		moveq	#0,d1
		move.b	(v_mars_rows).w,d1
		cmpi.b	#32,d1
		bhs.s	.done
		moveq	#0,d0
		move.b	(v_mars_roll).w,d0			; scrolled so far (pixels)
		addq.w	#8,d0
		move.w	d1,d2
		lsl.w	#3,d2
		cmp.w	d0,d2					; row r due when r*8 <= scroll + 8
		bhi.s	.done
		bsr.s	Mars_CreditsRow
		addq.b	#1,(v_mars_rows).w
.done:		rts

; picture row d1 (0-31) into plane B (or empty when the text is hidden)
Mars_CreditsRow:
		move	sr,-(sp)
		move	#$2700,sr
		move.w	d1,d0
		addi.w	#28,d0
		andi.w	#31,d0
		lsl.w	#7,d0					; plane row * $80
		swap	d0
		clr.w	d0
		addi.l	#$60000003,d0				; VRAM write $E000 + row * $80
		move.l	d0,(vdp_control_port).l
		lea	Mars_CreditsMap(pc),a1
		move.w	d1,d0
		mulu.w	#40*2,d0
		adda.w	d0,a1
		moveq	#40-1,d2
.col:		move.w	(a1)+,d0
		tst.b	(v_mars_crhide).w
		beq.s	.put
		moveq	#0,d0
.put:		move.w	d0,(vdp_data_port).l
		dbf	d2,.col
		move	(sp)+,sr
		rts

; all rows shown so far again (text on / off)
Mars_CreditsRedraw:
		moveq	#0,d1
.row:		cmp.b	(v_mars_rows).w,d1
		bhs.s	.done
		move.w	d1,-(sp)
		bsr.s	Mars_CreditsRow
		move.w	(sp)+,d1
		addq.w	#1,d1
		bra.s	.row
.done:		rts

; ---------------------------------------------------------------------------
; The CD line on plane A rows 25-26: "TRACK 05 OF 12  PLAYING", or why there is no player
; ---------------------------------------------------------------------------
Mars_TrackLine:
		lea	Mars_NoSegaCD(pc),a2
		move.b	(CD_State).w,d0
		cmpi.b	#2,d0
		blo.s	.why
		lea	Mars_NoAnswer(pc),a2
		beq.s	.why
		lea	Mars_NoTracks(pc),a2
		tst.b	(v_mars_tracks).w
		bne.s	.tracks
.why:		lea	(mars_textbuf).w,a1
.copy:		move.b	(a2)+,(a1)+
		bne.s	.copy
		bra.s	.show
.tracks:	lea	(mars_textbuf).w,a1
		move.l	#'TRAC',(a1)+
		move.w	#'K ',(a1)+
		moveq	#0,d0
		move.b	(v_mars_track).w,d0
		bsr.w	Mars_Dec2
		move.l	#' OF ',(a1)+
		moveq	#0,d0
		move.b	(v_mars_tracks).w,d0
		bsr.w	Mars_Dec2
		move.w	#'  ',(a1)+
		lea	Mars_Stopped(pc),a2
		move.b	(v_mars_player).w,d0
		beq.s	.state
		lea	Mars_Playing(pc),a2
		subq.b	#1,d0
		beq.s	.state
		lea	Mars_Paused(pc),a2
.state:		move.b	(a2)+,(a1)+
		bne.s	.state
.show:		move	sr,-(sp)
		move	#$2700,sr
		move.l	#$4C800003,d4				; row 25: top halves
		moveq	#0,d5
		bsr.s	.row
		move.l	#$4D000003,d4				; row 26: bottom halves
		moveq	#1,d5
		bsr.s	.row
		move	(sp)+,sr
		rts
.row:		move.l	d4,(vdp_control_port).l			; 40 cells: the text centred
		lea	(mars_textbuf).w,a1
		movea.l	a1,a3
		moveq	#0,d3
.len:		tst.b	(a3)+
		beq.s	.lenok
		addq.w	#1,d3
		bra.s	.len
.lenok:		moveq	#40,d1
		sub.w	d3,d1
		lsr.w	#1,d1					; spaces before
		move.w	d1,d2
		subq.w	#1,d2
		bmi.s	.text
.pre:		move.w	#0,(vdp_data_port).l
		dbf	d2,.pre
.text:		moveq	#0,d0
		move.b	(a1)+,d0
		beq.s	.post
		addq.w	#1,d1
		moveq	#0,d2					; space
		cmpi.b	#'A',d0
		bhs.s	.letter
		cmpi.b	#'0',d0
		blo.s	.put
		subi.b	#'0',d0					; 0-9: glyph 0-9
		bra.s	.glyph
.letter:	subi.b	#'A'-10,d0				; A-Z: glyph 10-35
.glyph:		add.w	d0,d0
		add.w	d5,d0
		addi.w	#$2000+1024,d0				; palette line 1, tile 1024 + 2 * glyph (+1)
		move.w	d0,d2
.put:		move.w	d2,(vdp_data_port).l
		bra.s	.text
.post:		moveq	#40,d2					; spaces after
		sub.w	d1,d2
		subq.w	#1,d2
		bmi.s	.end
.sp:		move.w	#0,(vdp_data_port).l
		dbf	d2,.sp
.end:		rts

Mars_Dec2:					; d0 (0-99) as two digits to (a1)+
		andi.l	#$FF,d0
		divu.w	#10,d0
		addi.b	#'0',d0
		move.b	d0,(a1)+
		swap	d0
		addi.b	#'0',d0
		move.b	d0,(a1)+
		rts
Mars_Stopped:	dc.b	"STOPPED",0
Mars_Playing:	dc.b	"PLAYING",0
Mars_Paused:	dc.b	"PAUSED",0
Mars_NoSegaCD:	dc.b	"CD AUDIO  NO SEGA CD FOUND",0
Mars_NoAnswer:	dc.b	"CD AUDIO  SEGA CD DOES NOT ANSWER",0
Mars_NoTracks:	dc.b	"CD AUDIO  NO AUDIO CD",0
		even

		include	"mars/cd.asm"
		even

Mars_CreditsTiles:	binclude "mars/credits/credits_tiles.bin"	; mars/tools/credits_roll.py
Mars_CreditsTilesEnd:
		even
Mars_CreditsMap:	binclude "mars/credits/credits_map.bin"
		even
Mars_CreditsPal:	binclude "mars/credits/credits_pal.bin"
		even
Mars_CreditsGlyphs:	binclude "mars/credits/player_glyphs.bin"
Mars_CreditsGlyphsEnd:
		even
