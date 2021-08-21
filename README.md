# Marsiano-MARS
A video "driver" for the Sega 32X (audio too.) for easily doing visual and audio tasks like drawing a third background, sprites, polygons...

Things working:
- Draw an extra background in 256-color mode of any size in either ROM or RAM (but the map's WIDTH and HEIGHT must be aligned depending of specific setting)
- Polygons system from Shinrinx-MARS

Notes/Issues:
- SVDP FILL can't be used anymore because of the new internal width (384, only works if 512 is used), solidcolor polygons need reworking
- Code that Draws polygons with texture skips hidden copy of line 0
- Communication with MD and 32X is minimal (and temporal)

(Copypaste from Shinrinx-MARS)
Please note that current 32X emulators ignore some hardware restrictions and bugs of the system:
- RV bit: This bit reverts the ROM map back to normal temporary, meant as a workaround for the Genesis DMA's ROM-to-VDP transfers, If you do any transfer without setting this bit, the DMA will transfer trash data, And your DMA transfer routines MUST be located on RAM otherwise after setting RV=1 the next instruction will be trash becuase the ROM changed its location (from $880000 to $000000), for the SH2 side: if RV is set, any read from SH2's ROM area will return trash data
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), if a CPU with no permission touches the Super VDP, it will freeze the entire system (32X add-on or Genesis)
- BUS fighting on SH2: If any of the SH2 CPUs read/write the same location you will get bad results, mostly a freeze. (Note: Only encountered this on SDRAM area, other locations like the registers should be fine)
- SH2's DMA locks Palette (HW bug I found, or probably did something wrong): If transfering indexed-palette data to SuperVDP's Palette using DMA, the first transfer will work, then the DMA will get locked, both Source and Destination areas can't be rewritten
- PWM's sound limit (for each channel: Left and Right) is $3FF, not $FFF mentioned in the docs

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X already inserted, If it doesn't boot: it probably broke during coding, ROM is for NTSC systems, can be played on PAL but with slowdown.

For more info check the official hardware manual (32X Hardware Manual.pdf)
