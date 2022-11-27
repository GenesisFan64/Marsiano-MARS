MarsMapPz_17_gign:
		dc.w 36,5360
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "data/maps/3D/mcity/pz/17_gign_vert.bin"
.face:		binclude "data/maps/3D/mcity/pz/17_gign_face.bin"
.vrtx:		binclude "data/maps/3D/mcity/pz/17_gign_vrtx.bin"
.mtrl:		include "data/maps/3D/mcity/pz/17_gign_mtrl.asm"
		align 4