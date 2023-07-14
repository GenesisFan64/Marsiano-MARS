MarsMapPz_01_main:
		dc.w 220,302
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "game/data/maps/3D/mcity/pz/01_main_vert.bin"
.face:		binclude "game/data/maps/3D/mcity/pz/01_main_face.bin"
.vrtx:		binclude "game/data/maps/3D/mcity/pz/01_main_vrtx.bin"
.mtrl:		include "game/data/maps/3D/mcity/pz/01_main_mtrl.asm"
