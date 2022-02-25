; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM data
;
; If your data is too much for SDRAM, place it here.
; BUT keep in mind that this entire section will be gone
; if the Genesis performs DMA-to-VDP Transfers
; which requires RV=1 (Revert ROM to original position)
; ***EMULATORS IGNORE THIS LIMITATION***
;
; Only access here on these conditions:
; - Stop all tracks that use PWM samples
; - If you wanna keep any tracks active: set 1 to marsBlock
;   in the Z80 driver, all tracks will continue playing
;   only with PSG and FM instruments
;   (TODO: check how it peforms)
;
; The PWM samples are safe to use with the implementation
; of a sample-backup routine that the 68K requests before
; doing DMA
; ----------------------------------------------------------------

	align 4

; --------------------------------------------------------
; PWM samples
; --------------------------------------------------------

SmpIns_Vctr01:
	gSmpl "sound/instr/smpl/vctr01.wav",58
SmpIns_Vctr04:
	gSmpl "sound/instr/smpl/vctr04.wav",124
SmpIns_VctrSnare:
	gSmpl "sound/instr/smpl/vctrSnare.wav",0
SmpIns_VctrKick:
	gSmpl "sound/instr/smpl/vctrKick.wav",0
SmpIns_VctrTimpani:
	gSmpl "sound/instr/smpl/vctrTimpani.wav",0
SmpIns_VctrCrash:
	gSmpl "sound/instr/smpl/vctrCrash.wav",0
SmpIns_VctrBrass:
	gSmpl "sound/instr/smpl/vctrBrass.wav",1004
SmpIns_VctrAmbient:
	gSmpl "sound/instr/smpl/vctrBrass.wav",124

SmpIns_Bell_Ice:
	gSmpl "sound/instr/smpl/bell_ice.wav",0
SmpIns_Brass1_Hi:
	gSmpl "sound/instr/smpl/brass1_hi.wav",0
SmpIns_Brass1_Low:
	gSmpl "sound/instr/smpl/brass1_low.wav",0
SmpIns_Forest_1:
	gSmpl "sound/instr/smpl/forest1.wav",0
SmpIns_Kick_jam:
	gSmpl "sound/instr/smpl/kick_jam.wav",0
SmpIns_Snare_jam:
	gSmpl "sound/instr/smpl/snare_jam.wav",0
SmpIns_SnrTom_1:
	gSmpl "sound/instr/smpl/snrtom_1.wav",0
SmpIns_PIANO_1:
	gSmpl "sound/instr/smpl/PIANO__1.wav",0
SmpIns_SSTR162A:
	gSmpl "sound/instr/smpl/SSTR162A.wav",0

; --------------------------------------------------------
; Graphics
; --------------------------------------------------------

TESTMARS_BG:
	binclude "data/mars/test_art.bin"
	align 4
Textr_smoke:
	binclude "data/mars/objects/mtrl/smoke_art.bin"
	align 4

; --------------------------------------------------------
; Models
; --------------------------------------------------------

	include "data/mars/objects/mdl/test/head.asm"
