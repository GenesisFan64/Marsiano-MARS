MarsMapPz_01_main:
		dc.w 220,302
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/01_main_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/01_main_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/01_main_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/01_main_mtrl.asm"
