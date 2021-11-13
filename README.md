# Marsiano-MARS
A Video+Sound "driver"/handler for the 32X.

Sound driver, both Genesis and 32X:
- Runs on Z80, DMA safe... supposedly (needs testing)
- Music can be composed in any tracker that supports ImpulseTracker (.IT) then imported with a simple python3 script
- Supports Ticks and Global tempo
- It uses the channel-link system, It automaticly picks the available soundchip channel to play. Can autodetect special features (DAC and FM3 special) and swap sound chips in the same Impulse-channel
- Two playback tracks: second slot has priority (for SFX sound effects) and can temporally override channels used by the first slot
- PSG soundchip: supports effects like Attack and Release, can autodetect if the NOISE channel uses Tone3 mode
- YM2616 soundchip: DAC sample playback at 16000hz aprox. supports FM3 special mode for extra frequencies
- Supports PWM, 7 psuedo channels are available to use with Volume and other effects

Video "driver" (on the 32X side):
- Draws an extra background in 256-color mode of any size in either ROM or RAM (but the map's WIDTH and HEIGHT must be aligned depending of specific setting)

Notes/Issues:
- Polygon rendering broken. Will have to rewrite it entirely
- DAC Sound playback may probably slowdown if track is using too much channels

Please note that current 32X emulators ignore some hardware restrictions and bugs of the system:
- ALL Emulators doesn't trigger the error handlers
- RV bit: This bit set the ROM map temporary to normal, meant as a workaround for the Genesis DMA's ROM-to-VDP transfers, If you do any transfer without setting this bit, the DMA will transfer trash data, Your DMA transfer routines MUST be located on RAM otherwise after setting RV=1 the next instruction will be trash because the ROM changed its location (from $880000 to $000000), for the SH2 side: if RV is set, any read from SH2's ROM area will return trash data.
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with no permission touches the Super VDP, it will freeze the entire system (32X add-on or Genesis)
- BUS fighting on SH2 (TODO: keep testing this): If any of the SH2 CPUs WRITE the same location at the same time it will crash the add-on. (Note: Only encountered this on SDRAM area, other locations like the registers should be fine)
- SH2's DMA locks Palette (HW bug I found, or probably did something wrong): If transfering indexed-palette data to SuperVDP's Palette using DMA, the first transfer will work, then the DMA will get stuck, both Source and Destination areas can't be rewritten
- PWM's sound limit for each channel (Left and Right) is $3FF, NOT $FFF mentioned in the docs

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X inserted.
If it doesn't boot or freezes: I probably broke something without testing on HW
ROM is for NTSC systems, can be played on PAL but with slowdown.

For more info check the official hardware manual (32X Hardware Manual.pdf)
