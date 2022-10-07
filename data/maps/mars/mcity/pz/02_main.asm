MarsMapPz_02_main:
		dc.w 226,354
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/02_main_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/02_main_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/02_main_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/02_main_mtrl.asm"
		align 4
