	\\ netsys_sp_eq.asm
	\\ Compiler: BeebAsm V1.09
	\\ By Martin Mather
	
	\\ SP constants
	
	SP_ESC_CHR = &E5
		
	SP_FLAG_VOID = &7e
	SP_FLAG_DATA = &be
	SP_FLAG_SCOUT = &ce
	SP_FLAG_BROADCAST = &de
	SP_FLAG_RESET = &d6
	SP_FLAG_ACK = &ee
	SP_FLAG_NAK = &fe
	
	\\ TUBE constants
	
	TUBEOP0 = 0	; Multi byte transfer, parasite to host
	TUBEOP1 = 1	; Multi byte transfer, host to parasite
	;TUBEOP2 = 2 ; Multi pairs transfer Parasite->Host
	;TUBEOP3 = 3 ; Multi pairs of bytes Host->Parasite
	
	\\ Data addresses
	
	SP_DBGFLAG = &8F

	ORG &0D10					;RECEIVE BUFFER
.SP_RX_BUF
.SP_RX_STN
	EQUB 0
.SP_RX_NET
	EQUB 0
.SP_RX_CTRL
	EQUB 0
.SP_RX_PORT
	EQUB 0

	ORG &0D20					;TRANSMIT BUFFER

.SP_TX_BUF
.SP_TX_STN
	EQUB 0
.SP_TX_NET
	EQUB 0
.SP_TX_CTRL
	EQUB 0
.SP_TX_PORT
	EQUB 0
	
	ORG &0D30
.SP_TX_FLAG
	EQUB 0
.SP_BAUDRATE
	EQUB 0
.SP_CRC
	EQUW 0
.SP_CRC_TEMP
	EQUB 0
.SP_RX_COUNT
.SP_TX_COUNT
	EQUB 0
.SP_TX_SIZE
	EQUB 0
.SP_FIFO
	EQUW 0
.SP_FIFO_STATE
	EQUB 0
.SP_RX_STATE
	EQUB 0
.SP_RX_STATE2
	EQUB 0
.SP_TX_STATE
	EQUB 0
.SP_ESCFLAG						;LAST DATA BYTE = SP_ESC_CHR
	EQUB 0
.SP_RX_OVERFLOW
	EQUB 0

	SP_TUBEEN = &98

	TubeOp_D5C = &0D5C	

	RXTX_Flags_D4A = &0D4A		;Various flags	
	Line_Not_Busy_D62 = &0D62	;If bit 7 set, line not busy
	ProtectionMask_D63 = &0D63
	RXTX_Flags_D64 = &0D64
	ProtectionMaskCopy_D65 = &0D65
	I_Own_NMI_D66 = &0D66
	TubePresent_D67 = &0D67
	
	
	