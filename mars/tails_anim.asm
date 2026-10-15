; Tails' animation scripts and his tails' (Sonic 2: Tails_Animate's TailsAniData, Obj05's
; Obj05AniSelection / Obj05AniData), converted from s2disasm

TailsAniData:
		dc.w TailsAni_Walk-TailsAniData
		dc.w TailsAni_Run-TailsAniData
		dc.w TailsAni_Roll-TailsAniData
		dc.w TailsAni_Roll2-TailsAniData
		dc.w TailsAni_Push-TailsAniData
		dc.w TailsAni_Wait-TailsAniData
		dc.w TailsAni_Balance-TailsAniData
		dc.w TailsAni_LookUp-TailsAniData
		dc.w TailsAni_Duck-TailsAniData
		dc.w TailsAni_Spindash-TailsAniData
		dc.w TailsAni_Dummy1-TailsAniData
		dc.w TailsAni_Dummy2-TailsAniData
		dc.w TailsAni_Dummy3-TailsAniData
		dc.w TailsAni_Stop-TailsAniData
		dc.w TailsAni_Float-TailsAniData
		dc.w TailsAni_Float2-TailsAniData
		dc.w TailsAni_Spring-TailsAniData
		dc.w TailsAni_Hang-TailsAniData
		dc.w TailsAni_Blink-TailsAniData
		dc.w TailsAni_Blink2-TailsAniData
		dc.w TailsAni_Hang2-TailsAniData
		dc.w TailsAni_Bubble-TailsAniData
		dc.w TailsAni_DeathBW-TailsAniData
		dc.w TailsAni_Drown-TailsAniData
		dc.w TailsAni_Death-TailsAniData
		dc.w TailsAni_Hurt-TailsAniData
		dc.w TailsAni_Hurt2-TailsAniData
		dc.w TailsAni_Slide-TailsAniData
		dc.w TailsAni_Blank-TailsAniData
		dc.w TailsAni_Dummy4-TailsAniData
		dc.w TailsAni_Dummy5-TailsAniData
TailsAni_HaulAss_ptr:
		dc.w TailsAni_HaulAss-TailsAniData
TailsAni_Fly_ptr:
		dc.w TailsAni_Fly-TailsAniData
TailsAni_Walk:	dc.b $FF,$10,$11,$12,$13,$14,$15, $E, $F,$FF
	even
TailsAni_Run:	dc.b $FF,$2E,$2F,$30,$31,$FF,$FF,$FF,$FF,$FF
	even
TailsAni_Roll:	dc.b   1,$48,$47,$46,$FF
	even
TailsAni_Roll2:	dc.b   1,$48,$47,$46,$FF
	even
TailsAni_Push:	dc.b $FD,$63,$64,$65,$66,$FF,$FF,$FF,$FF,$FF
	even
TailsAni_Wait:	dc.b   7,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  3,  2,  1,  1,  1
		dc.b   1,  1,  1,  1,  1,  3,  2,  1,  1,  1,  1,  1,  1,  1,  1,  1
		dc.b   5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5
		dc.b   6,  7,  8,  7,  8,  7,  8,  7,  8,  7,  8,  6,$FE,$1C
	even
TailsAni_Balance:	dc.b   9,$69,$69,$6A,$6A,$69,$69,$6A,$6A,$69,$69,$6A,$6A,$69,$69,$6A
			dc.b $6A,$69,$69,$6A,$6A,$69,$6A,$FF
	even
TailsAni_LookUp:	dc.b $3F,  4,$FF
	even
TailsAni_Duck:		dc.b $3F,$5B,$FF
	even
TailsAni_Spindash:	dc.b   0,$60,$61,$62,$FF
	even
TailsAni_Dummy1:	dc.b $3F,$82,$FF
	even
TailsAni_Dummy2:	dc.b   7,  8,  8,  9,$FD,  5
	even
TailsAni_Dummy3:	dc.b   7,  9,$FD,  5
	even
TailsAni_Stop:		dc.b   7,$67,$68,$67,$68,$FD,  0
	even
TailsAni_Float:		dc.b   9,$6E,$73,$FF
	even
TailsAni_Float2:	dc.b   9,$6E,$6F,$70,$71,$72,$FF
	even
TailsAni_Spring:	dc.b   3,$59,$5A,$59,$5A,$59,$5A,$59,$5A,$59,$5A,$59,$5A,$FD,  0
	even
TailsAni_Hang:		dc.b   5,$6C,$6D,$FF
	even
TailsAni_Blink:		dc.b  $F,  1,  2,  3,$FE,  1
	even
TailsAni_Blink2:	dc.b  $F,  1,  2,$FE,  1
	even
TailsAni_Hang2:		dc.b $13,$85,$86,$FF
	even
TailsAni_Bubble:	dc.b  $B,$74,$74,$12,$13,$FD,  0
	even
TailsAni_DeathBW:	dc.b $20,$5D,$FF
	even
TailsAni_Drown:		dc.b $2F,$5D,$FF
	even
TailsAni_Death:		dc.b   3,$5D,$FF
	even
TailsAni_Hurt:		dc.b   3,$5D,$FF
	even
TailsAni_Hurt2:		dc.b   3,$5C,$FF
	even
TailsAni_Slide:		dc.b   9,$6B,$5C,$FF
	even
TailsAni_Blank:		dc.b $77,  0,$FD,  0
	even
TailsAni_Dummy4:	dc.b   3,  1,  2,  3,  4,  5,  6,  7,  8,$FF
	even
TailsAni_Dummy5:	dc.b   3,  1,  2,  3,  4,  5,  6,  7,  8,$FF
	even
TailsAni_HaulAss:	dc.b $FF,$32,$33,$FF
			dc.b $FF,$FF,$FF,$FF,$FF,$FF
	even
TailsAni_Fly:		dc.b   1,$5E,$5F,$FF
	even
Obj05AniSelection:
	dc.b	0,0
	dc.b	3
	dc.b	3
	dc.b	9
	dc.b	1
	dc.b	0
	dc.b	2
	dc.b	1
	dc.b	7
	dc.b	0,0,0
	dc.b	8
	dc.b	0,0
	dc.b	0
	dc.b	0
	dc.b	0,0
	dc.b	$A
	dc.b	0
	dc.b	0,0,0,0
	dc.b	0,0
	dc.b	0
	dc.b	0,0
	dc.b	0
	dc.b	0
	even
Obj05AniData:
		dc.w Obj05Ani_Blank-Obj05AniData
		dc.w Obj05Ani_Swish-Obj05AniData
		dc.w Obj05Ani_Flick-Obj05AniData
		dc.w Obj05Ani_Directional-Obj05AniData
		dc.w Obj05Ani_DownLeft-Obj05AniData
		dc.w Obj05Ani_Down-Obj05AniData
		dc.w Obj05Ani_DownRight-Obj05AniData
		dc.w Obj05Ani_Spindash-Obj05AniData
		dc.w Obj05Ani_Skidding-Obj05AniData
		dc.w Obj05Ani_Pushing-Obj05AniData
		dc.w Obj05Ani_Hanging-Obj05AniData
Obj05Ani_Blank:		dc.b $20,  0,$FF
	even
Obj05Ani_Swish:		dc.b   7,  9, $A, $B, $C, $D,$FF
	even
Obj05Ani_Flick:		dc.b   3,  9, $A, $B, $C, $D,$FD,  1
	even
Obj05Ani_Directional:	dc.b $FC,$49,$4A,$4B,$4C,$FF
	even
Obj05Ani_DownLeft:	dc.b   3,$4D,$4E,$4F,$50,$FF
	even
Obj05Ani_Down:		dc.b   3,$51,$52,$53,$54,$FF
	even
Obj05Ani_DownRight:	dc.b   3,$55,$56,$57,$58,$FF
	even
Obj05Ani_Spindash:	dc.b   2,$81,$82,$83,$84,$FF
	even
Obj05Ani_Skidding:	dc.b   2,$87,$88,$89,$8A,$FF
	even
Obj05Ani_Pushing:	dc.b   9,$87,$88,$89,$8A,$FF
	even
Obj05Ani_Hanging:	dc.b   9,$81,$82,$83,$84,$FF
	even
		even

