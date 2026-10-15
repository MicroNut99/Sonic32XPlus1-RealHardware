; ---------------------------------------------------------------------------
; The secret menu (Mars = 1): Sonic 1's level select, opened with Mode + Z on a
; 6-button pad from anywhere (title, demos, levels - also paused -, special
; stage ...). Its last line, CREDITS, opens the credits screen: the credits
; roll on the Genesis (plane B) over OpenJazz's menu plasma drawn by the 32X.
; ---------------------------------------------------------------------------

v_mars_pad6:	equ v_mars_tails+$30	; 6-button pad 1, held: bit 0 Z, 1 Y, 2 X, 3 Mode
v_mars_pad6p:	equ v_mars_tails+$31	; ... pressed this frame
v_mars_menu:	equ v_mars_tails+$32	; 1 = open the menu (the title screen does)
v_mars_credits:	equ v_mars_tails+$33	; 1 = the credits screen runs (the 32X draws the plasma)
v_mars_crhide:	equ v_mars_tails+$34	; credits text hidden
v_mars_speed:	equ v_mars_tails+$35	; plasma speed 1-16 (8 = normal)
v_mars_roll:	equ v_mars_tails+$36	; the credits' roll, 1/256 pixels (word)

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
;   Up / Down: plasma faster / slower    A or Y: credits text on / off
;   Start or Z: back to the menu         X: back to the title screen
; ---------------------------------------------------------------------------
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
		move.l	#$40200000,4(a6)			; the credits' tiles -> tile 1 ...
		lea	Mars_CreditsTiles(pc),a1
		move.w	#(Mars_CreditsTilesEnd-Mars_CreditsTiles)/4-1,d1
.tiles:		move.l	(a1)+,(a6)
		dbf	d1,.tiles
		move.l	#$40000002,4(a6)			; the speed line's letters -> tile 1024 ...
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
		move.b	d0,(v_mars_crhide).w
		move.b	d0,(v_mars_menu).w
		move.b	#8,(v_mars_speed).w
		move.b	#1,(v_mars_credits).w			; the 32X: plasma
		bsr.w	Mars_CreditsText
		bsr.w	Mars_SpeedLine
		move	#$2300,sr

.loop:		move.b	#id_VBlank_Title,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		addi.w	#$40,(v_mars_roll).w			; the roll: a quarter pixel a frame
		move.b	(v_mars_roll).w,d0
		move.b	d0,(v_scrposy_vdp+3).w			; plane B's vertical scroll
		move.b	(v_mars_pad6p).w,d2			; 6-button keys
		move.b	(v_jpadpress1).w,d3
		btst	#2,d2					; X: the title screen
		bne.s	.title
		btst	#0,d2					; Z or Start: the menu
		bne.s	.menu
		btst	#bitStart,d3
		bne.s	.menu
		btst	#1,d2					; Y or A: the text on / off
		bne.s	.text
		btst	#bitA,d3
		bne.s	.text
		btst	#bitUp,d3				; Up: faster
		beq.s	.noup
		cmpi.b	#16,(v_mars_speed).w
		bhs.s	.loop
		addq.b	#1,(v_mars_speed).w
		bsr.w	Mars_SpeedLine
		bra.s	.loop
.noup:		btst	#bitDn,d3				; Down: slower
		beq.s	.loop
		cmpi.b	#1,(v_mars_speed).w
		bls.s	.loop
		subq.b	#1,(v_mars_speed).w
		bsr.w	Mars_SpeedLine
		bra.s	.loop
.text:		not.b	(v_mars_crhide).w
		bsr.w	Mars_CreditsText
		bra.s	.loop
.menu:		move.b	#1,(v_mars_menu).w			; the title screen opens the menu again
.title:		clr.b	(v_mars_credits).w
		clr.l	(v_scrposy_vdp).w
		move.b	#id_Title,(v_gamemode).w
		rts

; plane B: the credits (32 rows of 40), or empty
Mars_CreditsText:
		move	sr,-(sp)
		move	#$2700,sr
		lea	(vdp_data_port).l,a6
		lea	Mars_CreditsMap(pc),a1
		move.l	#$60000003,d4				; plane B ($E000)
		moveq	#32-1,d2
.row:		move.l	d4,4(a6)
		moveq	#40-1,d1
.col:		move.w	(a1)+,d0
		tst.b	(v_mars_crhide).w
		beq.s	.put
		moveq	#0,d0
.put:		move.w	d0,(a6)
		dbf	d1,.col
		addi.l	#$800000,d4				; next row ($80 bytes)
		dbf	d2,.row
		move	(sp)+,sr
		rts

; plane A rows 25-26: "SPEED 08", centred, in the credits' letters (2 tiles each)
Mars_SpeedLine:
		move	sr,-(sp)
		move	#$2700,sr
		moveq	#0,d0
		move.b	(v_mars_speed).w,d0
		divu.w	#10,d0
		move.w	d0,d4					; tens
		swap	d0
		move.w	d0,d5					; units
		move.l	#$4C800003+(16<<17),d6			; row 25, column 16 ($C000 + 25*$80 + 16*2)
		moveq	#0,d3					; top halves
		bsr.s	.row
		move.l	#$4D000003+(16<<17),d6			; row 26
		moveq	#1,d3					; bottom halves
		bsr.s	.row
		move	(sp)+,sr
		rts
.row:		move.l	d6,(vdp_control_port).l
		lea	Mars_SpeedText(pc),a1
		moveq	#6-1,d1					; "SPEED "
.char:		moveq	#0,d0
		move.b	(a1)+,d0
		bmi.s	.space
		bsr.s	.put
		bra.s	.nextc
.space:		move.w	#0,(vdp_data_port).l
.nextc:		dbf	d1,.char
		move.w	d4,d0					; the digits
		bsr.s	.put
		move.w	d5,d0
.put:		add.w	d0,d0					; glyph n: tiles 1024 + 2n (+1 bottom)
		add.w	d3,d0
		addi.w	#$2000+1024,d0				; palette line 1
		move.w	d0,(vdp_data_port).l
		rts
Mars_SpeedText:	dc.b 28, 25, 14, 14, 13, -1			; S P E E D (glyphs: 0-9, then A = 10)
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
