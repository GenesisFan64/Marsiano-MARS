MarsMapPz_07_multi:
		dc.w 30,2075
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/07_multi_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/07_multi_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/07_multi_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/07_multi_mtrl.asm"
		align 4
