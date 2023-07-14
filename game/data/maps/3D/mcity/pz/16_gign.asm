MarsMapPz_16_gign:
		dc.w 72,7850
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "game/data/maps/3D/mcity/pz/16_gign_vert.bin"
.face:		binclude "game/data/maps/3D/mcity/pz/16_gign_face.bin"
.vrtx:		binclude "game/data/maps/3D/mcity/pz/16_gign_vrtx.bin"
.mtrl:		include "game/data/maps/3D/mcity/pz/16_gign_mtrl.asm"
		align 4