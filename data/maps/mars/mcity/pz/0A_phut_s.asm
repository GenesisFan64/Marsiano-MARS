MarsMapPz_0A_phut_s:
		dc.w 66,2626
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "data/maps/mars/mcity/pz/0A_phut_s_vert.bin"
.face:		binclude "data/maps/mars/mcity/pz/0A_phut_s_face.bin"
.vrtx:		binclude "data/maps/mars/mcity/pz/0A_phut_s_vrtx.bin"
.mtrl:		include "data/maps/mars/mcity/pz/0A_phut_s_mtrl.asm"
		align 4