; ====================================================================
; PWM samples
;
; For SH2's visible areas: ROM ($02000000) or SDRAM ($06000000)
;
; - SDRAM is safest but it has very LOW storage
; - ROM area can use all the 4 Megabytes of storage, BUT when the
; RV bit is set: the sample data will be lost. Luckily
; a "Wave-backup" feature is implemented to copy a small
; amount of bytes of the sample data into a safe place for playback
; while RV bit is active.
;
; Do note that if the RV bit stays active too long it will ran out of
; backup data and the sample will play trash bytes.
;
; SAMPLE DATA IS 8-BIT WAV, THIS INCLUDES STEREO SAMPLES
; ====================================================================

	align 4		; First align
SmpIns_Bell_Ice:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/bell_ice.wav",$2C
	align 4
.end:

SmpIns_Brass1_Hi:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/brass1_hi.wav",$2C
	align 4
.end:

SmpIns_Brass1_Low:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/brass1_low.wav",$2C
	align 4
.end:

SmpIns_Forest_1:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/forest1.wav",$2C
	align 4
.end:

SmpIns_Kick_jam:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/kick_jam.wav",$2C
	align 4
.end:

SmpIns_Snare_jam:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_jam.wav",$2C
	align 4
.end:

SmpIns_SnrTom_1:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snrtom_1.wav",$2C
	align 4
.end:

SmpIns_PIANO_1:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/PIANO__1.wav",$2C
	align 4
.end:

SmpIns_SSTR162A:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/SSTR162A.wav",$2C
	align 4
.end:

SmpIns_Nadie:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie_st.wav",$2C
	align 4
.end:

SmpIns_PKick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/wegot_kick.wav",$2C
	align 4
.end:

SmpIns_PTom:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/sauron_tom.wav",$2C
	align 4
.end:

SmpIns_Piano:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/piano_1.wav",$2C
	align 4
.end:


; MOVEME
SmpIns_MoveMe_Hit:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/moveme_hit.wav",$2C
	align 4
.end:
SmpIns_MoveMe_Brass:
	gSmpHead .end-.start,6478
.start:	binclude "sound/instr/smpl/brass_moveme.wav",$2C
	align 4
.end:
SmpIns_Kick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/kick_moveme.wav",$2C
	align 4
.end:
SmpIns_Snare:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_moveme.wav",$2C
	align 4
.end:

SmpIns_MyTime:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/mytime.wav",$2C
	align 4
.end:
