; ---------------------------------------------------------------------------
; Tails (Mars = 1), step 3: Tails follows Sonic's path 16 frames behind and is
; drawn by the master SH2 on the 32X screen, in front of the Genesis picture.
;
; His position: Sonic's own position record (v_tracksonic, written every frame
; by Sonic_RecordPosition). His animation: Sonic's animation and status from 16
; frames ago (kept here), mapped to Sonic 2's Tails animations and played with
; Sonic 2's scripts (mars/tails_anim.asm); his tails likewise (Sonic 2's object 05).
; No physics of his own: he cannot get stuck, fall behind or get hurt.
;
; Each frame (after the level's objects ran and the screen scrolled) to the master SH2:
;   COMM4 = Tails' frame << 8 | his tails' frame
;   COMM6 = (screen x + 64) << 8 | (screen y + 64)      (low 8 bits each)
;   COMM2 = $1000 on screen | $400 facing left | $4000 bit 8 of x+64 | $8000 bit 8 of y+64
;           (written last; 0 = not shown - Mars_SendBG writes 0 outside levels)
; ---------------------------------------------------------------------------

mars_comm2:	equ $A15122
mars_comm4:	equ $A15124

; v_mars_tails ($40 bytes):
tl_hist:	equ 0		; 16 x (Sonic's animation, status)
tl_hpos:	equ $20		; next entry in tl_hist
tl_body:	equ $21		; animation state of Tails (5 bytes): animation, last animation,
				; script position, timer, frame
tl_tails:	equ $26		; and of his tails (5 bytes)
tl_prevx:	equ $2C		; his x the frame before (for his speed)

; ---------------------------------------------------------------------------
; At the start of a level (Sonic exists): his record filled with where Sonic is
; ---------------------------------------------------------------------------
Mars_TailsInit:
		lea	(v_mars_tails).w,a1
		moveq	#$10-1,d1
.hist:		move.b	(v_player+obAnim).w,(a1)+
		move.b	(v_player+obStatus).w,(a1)+
		dbf	d1,.hist
		moveq	#0,d0
		moveq	#($40-$20)/2-1,d1
.clear:		move.w	d0,(a1)+
		dbf	d1,.clear
		lea	(v_mars_tails).w,a1
		move.b	#$FF,tl_body+1(a1)			; (animations start fresh)
		move.b	#$FF,tl_tails+1(a1)
		move.w	(v_player+obX).w,tl_prevx(a1)
		lea	(v_tracksonic).w,a2
		moveq	#$40-1,d1
.track:		move.w	(v_player+obX).w,(a2)+
		move.w	(v_player+obY).w,(a2)+
		dbf	d1,.track
		rts

; ---------------------------------------------------------------------------
; Every frame of a level
; ---------------------------------------------------------------------------
Mars_Tails:
		lea	(v_mars_tails).w,a3
		; Sonic now into the record; the entry 16 frames old is the one after it
		moveq	#0,d0
		move.b	tl_hpos(a3),d0
		add.w	d0,d0
		move.b	(v_player+obAnim).w,tl_hist(a3,d0.w)
		move.b	(v_player+obStatus).w,tl_hist+1(a3,d0.w)
		move.b	tl_hpos(a3),d0
		addq.b	#1,d0
		andi.b	#$F,d0
		move.b	d0,tl_hpos(a3)
		add.w	d0,d0
		moveq	#0,d5
		move.b	tl_hist(a3,d0.w),d5			; d5 = Sonic's animation 16 frames ago
		move.b	tl_hist+1(a3,d0.w),d6			; d6 = his status then
		; position: Sonic's, 16 frames ago (the newest record is at v_trackbyte - 4)
		moveq	#0,d0
		move.b	(v_trackbyte).w,d0
		subi.b	#4+16*4,d0
		lea	(v_tracksonic).w,a1
		move.w	(a1,d0.w),d2				; d2 = x
		move.w	2(a1,d0.w),d3				; d3 = y
		; speed (pixels per frame) for the walk / run animations
		move.w	d2,d4
		sub.w	tl_prevx(a3),d4
		bpl.s	.abs
		neg.w	d4
.abs:		move.w	d2,tl_prevx(a3)
		; animations
		andi.w	#$1F,d5
		lea	Mars_TailsAnimMap(pc),a1
		move.b	(a1,d5.w),d0
		move.b	d0,tl_body(a3)
		andi.w	#$1F,d0
		lea	Obj05AniSelection(pc),a1
		move.b	(a1,d0.w),tl_tails(a3)
		lea	tl_body(a3),a2
		lea	TailsAniData(pc),a1
		bsr.w	Mars_Animate
		lea	tl_tails(a3),a2
		lea	Obj05AniData(pc),a1
		bsr.w	Mars_Animate
		; to the master SH2
		sub.w	(v_screenposx).w,d2
		addi.w	#64,d2
		sub.w	(v_screenposy).w,d3
		addi.w	#64,d3
		moveq	#0,d1					; COMM2
		cmpi.w	#512,d2
		bhs.s	.send					; (off screen; negative = very large)
		cmpi.w	#512,d3
		bhs.s	.send
		move.w	#$1000,d1
		btst	#0,d6					; facing left?
		beq.s	.right
		bset	#10,d1
.right:		btst	#8,d2
		beq.s	.x8
		bset	#14,d1
.x8:		btst	#8,d3
		beq.s	.y8
		bset	#15,d1
.y8:		move.b	tl_body+4(a3),d0			; frames
		lsl.w	#8,d0
		move.b	tl_tails+4(a3),d0
		move.w	d0,(mars_comm4).l
		move.b	d2,d0					; position
		lsl.w	#8,d0
		move.b	d3,d0
		move.w	d0,(mars_comm6).l
.send:		move.w	d1,(mars_comm2).l
		rts

; Sonic 1 animation -> Sonic 2 Tails animation
Mars_TailsAnimMap:
		dc.b 0, 1, 2, 3, 4, 5, 6, 7			; walk run roll roll2 push wait balance lookup
		dc.b 8, 5, 5, 5, 5, $D, $E, $F			; duck warp1-4 (-> wait) stop float1 float2
		dc.b $10, $11, 5, 5, 5, $15, $18, $17		; spring hang leap1 leap2 surf bubble death1 drown
		dc.b $18, 5, $1A, $1B, $1C, $E, $E, 5		; death2 shrink hurt waterslide null float3 float4
		even

; ---------------------------------------------------------------------------
; Sonic 2's animation scripts: a1 = script table, a2 = state (animation, last
; animation, script position, timer, frame), d4 = speed (pixels per frame).
; First byte of a script = frames per picture; negative = by speed (8 - speed).
; Script end: $FF again, $FE n back n, $FD a: animation a.
; ---------------------------------------------------------------------------
Mars_Animate:
		moveq	#0,d0
		move.b	(a2),d0
		cmp.b	1(a2),d0				; new animation?
		beq.s	.same
		move.b	d0,1(a2)
		clr.b	2(a2)
		clr.b	3(a2)
.same:		add.w	d0,d0
		adda.w	(a1,d0.w),a1				; the script
		move.b	(a1),d0					; frames per picture
		bpl.s	.timer
		moveq	#8,d0					; by speed
		sub.w	d4,d0
		bpl.s	.timer
		moveq	#0,d0
.timer:		subq.b	#1,3(a2)
		bpl.s	.done
		move.b	d0,3(a2)
		moveq	#0,d1
		move.b	2(a2),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#$F0,d0
		bhs.s	.command
.frame:		move.b	d0,4(a2)
		addq.b	#1,2(a2)
.done:		rts
.command:	cmpi.b	#$FF,d0					; $FF: from the start
		bne.s	.back
		clr.b	2(a2)
		move.b	1(a1),d0
		bra.s	.frame
.back:		cmpi.b	#$FE,d0					; $FE n: n back
		bne.s	.other
		move.b	2(a1,d1.w),d0
		sub.b	d0,2(a2)
		sub.w	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	.frame
.other:		cmpi.b	#$FD,d0					; $FD a: animation a
		bne.s	.done
		move.b	2(a1,d1.w),(a2)
		rts

		include	"mars/tails_anim.asm"
		even
