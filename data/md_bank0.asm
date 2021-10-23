; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than MD's DMA data
; 
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align $8000
; PCM_START:	binclude "sound/test_md.wav",$2C,$05FFFF
; PCM_END:
