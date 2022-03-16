	\\ Acorn DNFS (NFS 3.60 & DFS 1.20)
	\\ nfs_rom.asm
	\\ Compiler: BeebAsm V1.08
	\\ Disassembly by Martin Mather


	_DNFS_ = FALSE
	_ADLC_ = FALSE			; Else it's SP

	_SPDBG_ = FALSE

	_SWRAM_ = FALSE			; Sideways RAM Version
	
	DEFAULT_FS_STN = &FE

	INCLUDE "dfs.asm"

	SAVE "NFS360.ROM", &8000, &C000
