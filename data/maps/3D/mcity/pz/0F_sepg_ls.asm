MarsMapPz_0F_sepg_ls:
		dc.w 36,3751
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "data/maps/3D/mcity/pz/0F_sepg_ls_vert.bin"
.face:		binclude "data/maps/3D/mcity/pz/0F_sepg_ls_face.bin"
.vrtx:		binclude "data/maps/3D/mcity/pz/0F_sepg_ls_vrtx.bin"
.mtrl:		include "data/maps/3D/mcity/pz/0F_sepg_ls_mtrl.asm"
		align 4