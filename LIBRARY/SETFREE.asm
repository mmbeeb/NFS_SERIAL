

	;********************************
	;*          SETFREE             *
	;*   Original ACORN version     *
	;********************************

	;* Assembled using beebasm 1.09 *

	;THIS IS THE MASTER VERSION.

	LOADADDR =?&0E23

	OSASCI=?&FFE3
	OSNEWL=?&FFE7
	OSWRCH=?&FFEE
	OSWORD=?&FFF1
	OSBYTE=?&FFF4

	TXTPTR=?&F2

	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.SETFREE_START
{
	JSR S_DE20
	BNE L_DD08
	
.L_DD05
	JMP L_DE5E_SYNTAX
	
.L_DD08
	LDX #&00
	
.L_DD0A
	JSR GSREAD
	STA OW_BLK+11,X
	INX 
	BCC L_DD0A
	
	DEX 
	LDA #&0D
	STA OW_BLK+11,X
	CLC 
	TXA 
	ADC #&0C
	STA OW_BLK+1
	
	JSR GSINIT
	BEQ L_DD05
	
	JSR S_DD91
	
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&14
	JSR OSWORD
	
	LDA OW_BLK+3;A=ERR NO.
	BEQ L_DD90

	CMP #&85
	BNE L_DD65
	
	;STA &C009
	
	BRK 
	EQUS &A8, "Not supported : Disc space accounting", 0
	
.L_DD65
	LDA #&00
	STA &0100
	
	LDA OW_BLK+3
	CMP #&A0
	BCS L_DD76
	
.L_DD71
	;STA &C009
	
	LDA #&A8
	
.L_DD76
	CMP #&C0
	BCS L_DD71
	
	STA &0101
	LDX #&01
	
.L_DD7F
	LDA OW_BLK+3,X
	STA &0101,X
	INX 
	EOR #&0D
	BNE L_DD7F
	
	STA &0100,X
	JMP &0100
	
.L_DD90
	RTS 
	
.S_DD91
	LDA #&00
	STA &A9
	STA OW_BLK+7
	STA OW_BLK+8
	STA OW_BLK+9
	STA OW_BLK+10
	
.L_DDA1
	LDX &A9
	JSR GSREAD
	BCS L_DE00
	
	JSR S_DDCA
	PHA 
	LDX #&03
	
.L_DDAE
	ASL OW_BLK+7
	ROL OW_BLK+8
	ROL OW_BLK+9
	ROL OW_BLK+10
	BCS L_DDBE_TOOBIG
	
	DEX 
	BPL L_DDAE
	
	PLA 
	ORA OW_BLK+7
	STA OW_BLK+7
	INC &A9
	BNE L_DDA1;ALWAYS
	
IF LOADADDR=&0E23
	ORG &0F09
	
	EQUD &FFFF0E23
ENDIF
	
.S_DDCA
	CMP #'0'
	BCC L_DDE2_BADHEX
	
	CMP #'9'+1
	BCC L_DDF7
	
	CMP #'f'+1
	BCS L_DDE2_BADHEX
	
	CMP #'a'
	BCS L_DDF5
	
	CMP #'F'+1
	BCS L_DDE2_BADHEX
	
	CMP #'A'
	BCS L_DDF7
	
.L_DDE2_BADHEX
	BRK 
	EQUS &F1, "Bad hex"
	
.L_DDBE_TOOBIG
	BRK
	EQUS &FC, "Too big", 0
	
.L_DDF5
	AND #&5F
	
.L_DDF7
	SEC 
	SBC #&30
	CMP #&0A
	BCC L_DE00
	
	SBC #&07
	
.L_DE00
	RTS 
	
.OW_BLK
	EQUB 0, 7, 0, 31
	
.D_DE05
	EQUS "Set User Free Space. 1.07", 13, 0
	
.S_DE20
IF LOADADDR=&DD00
	LDX #&11
	LDA #&A1
	JSR OSBYTE
	TYA 
	BPL L_DE37
	
	LDX #&00
	
.L_DE2C
	LDA D_DE05,X
	BEQ L_DE37
	
	JSR OSASCI
	INX 
	BNE L_DE2C
ENDIF
	
.L_DE37
	LDY #&00
	LDA #&01
	LDX #&A8
	JSR OSARGS
	
	LDA &A8
	STA TXTPTR
	LDA &A9
	STA TXTPTR+1
	
	LDA #&02
	JSR OSARGS
	CMP #&02
	BNE L_DE5A
	
	CLC 
	JSR GSINIT
	
.L_DE55
	JSR GSREAD
	BCC L_DE55
	
.L_DE5A
	CLC 
	JMP GSINIT
	
.L_DE5E_SYNTAX
	BRK 
	EQUS &DE, "Syntax : *SetFree <Username> <FreeSpace (in hex)>", 0
}
.SETFREE_END

IF HI(SETFREE_START)=&DD;MASTER
	SAVE "M\$.SETFREE", SETFREE_START, SETFREE_END
ELIF HI(SETFREE_START)=&0E
	SAVE "E\$.SETFREE", SETFREE_START, SETFREE_END
ELSE
	SAVE "O\$.SETFREE", SETFREE_START, SETFREE_END
ENDIF

