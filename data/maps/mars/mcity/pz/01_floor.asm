MarsMapPz_01_floor:
		dc.w 36,49
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/01_floor_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/01_floor_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/01_floor_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/01_floor_mtrl.asm"
		align 4
