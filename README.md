# Marsiano-MARS
A GameBase/Engine/Library for making Sega 32X Games, in assembly.
*WORK IN PROGRESS*

Graphics:
- Working scrolling background in 256-color mode: Source data can be either a static image in ROM or a buffer section in RAM, in any WIDTH and HEIGHT BUT aligned in "blocks" (Ex. 4x4, 8x8, 16x16, 32x32)

Sound, Genesis and 32X:
- Runs on Z80, with DMA protection (Genesis side)
- Music can be composed in any tracker that supports ImpulseTracker (.IT), then imported with a simple python3 script
- Supports Ticks and Global tempo (default tempos 150 for NTSC and 120 for PAL)
- It uses the channel-link system, It automaticly picks the available soundchip channel to play. Can autodetect special features (DAC and FM3 special) and swap sound chips in the same Impulse-channel
- Two playback slots: Second slot has priority for SFX sound effects, it can temporally override channels used by the first slot
- PSG soundchip: supports effects like Attack and Release, can autodetect if the NOISE channel uses Tone3(frequency-steal) mode
- YM2612 soundchip: DAC sample playback at 18000hz aprox. with pitch changes, supports FM3 special mode for extra frequencies
- 32X: Supports PWM at 22050hz, 7 psuedo channels are available to use with Pitch, Volume and Panning, Controlled by the sound driver in the Genesis side. Has overflow protection.

Notes/Issues:
- Genesis: DAC Wave sound (Genesis side) might play slow if track is using too much channels
- 32X: background breaks on SOFT Reset
- SOFT-Reset MIGHT crash everything. (very low chance)

Planned/TODO:
- Implement NORMAL sprites on 32X side and make a new Polygons(DDA) system (separate from sprites)
- Add optional mode to make the scrolling use Direct-Color mode, it is posible but the view area will be smaller vertically.

Do note that current 32X emulators ignore some hardware restrictions and bugs of the system:
- ALL Emulators doesn't trigger the SH2's Error handlers (Address Error, Zero Divide, etc.)
- RV bit: This bit sets the ROM map temporally to it's original location on the Genesis side, as a workaround for the Genesis DMA's ROM-to-VDP transfers, If you do any DMA-transfer without setting this bit: it will transfer trash data, Your Genesis-DMA transfer routines MUST be located on RAM (or just the last instruction for the last VDP write), on the SH2 side: If RV is set, any read from SH2's ROM area will return trash data.
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with NO permission touches the Super VDP, it will freeze the entire system (32X add-on or Genesis), on emulation nothing happens.
- BUS fighting on SH2: If any of the SH2 CPUs WRITE the same location at the same time it will crash the add-on. (Only checked SDRAM area, and the comm ports)
- PWM's sound limit for each channel (Left and Right) is $3FF, NOT $FFF mentioned in the docs
- SDRAM is a little slower for code (Found this while checking the PWM playback): On SDRAM the PWM playback code struggled to play while on Cache it worked as it supposed to. ANY code that requires to process things fast MUST be done on the current SH2's cache (at $C0000000, $800 bytes max) (TODO: Maybe check this again)
- If the SH2 peforms DMA (Channel 0) on the background and the DESTINATION gets poked (READ or WRITE) it will abort the DMA transfer entirely.

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X inserted.
If it doesn't boot or freezes: I probably broke something without testing on HW
ROM is for NTSC systems, can be played on PAL but with slowdown.

For more info check the official hardware manual (32X Hardware Manual.pdf)
