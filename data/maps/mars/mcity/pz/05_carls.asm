MarsMapPz_05_carls:
		dc.w 25,1865
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/05_carls_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/05_carls_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/05_carls_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/05_carls_mtrl.asm"
		align 4