MarsMapPz_04_inters:
		dc.w 16,1124
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/04_inters_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/04_inters_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/04_inters_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/04_inters_mtrl.asm"
		align 4
