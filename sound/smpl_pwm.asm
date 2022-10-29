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

SmpIns_Nadie:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie_st.wav",$2C
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

SmpIns_snare_2:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_2.wav",$2C
.end:

SmpIns_MyTime:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/mytime.wav",$2C
	align 4
.end:
