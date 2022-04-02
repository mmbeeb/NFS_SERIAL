

	;********************************
	;*             FS               *
	;*   Original ACORN version     *
	;********************************

	;* Assembled using beebasm 1.09 *

	LOADADDR =? &0E23

	OSASCI=?&FFE3
	OSNEWL=?&FFE7
	OSWRCH=?&FFEE
	OSWORD=?&FFF1
	OSBYTE=?&FFF4

	TXTPTR=?&F2

	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.FS_START
{
	VSTR=FALSE;DISPLAY VERSION STRING IF MESSAGES ARE ENABLED USING *OPT1,1

IF VSTR
	LDA &0E06;*OPT1
	BEQ L_0E35
	
	LDX #0
	
.L_0E2A
	LDA D_0E4D,X
	BEQ L_0E35
	
	JSR OSASCI
	INX
	BNE L_0E2A
ENDIF
	
.L_0E35
	LDA #0;READ FS NUMBER
	JSR S_0E41
	
	LDY #0
	JSR S_0E6B
	
	LDA #1;WRITE FS NUMBER
	
.S_0E41
	STA OWBLK
	LDX #LO(OWBLK)
	LDY #HI(OWBLK)
	LDA #&13
	JMP OSWORD
	
.D_0E4D
	EQUS "Set File Server Number. 1.04", 13, 0
	
.S_0E6B
	INY
	LDA (TXTPTR),Y
	CMP #13
	BEQ L_0EBA
	
	CMP #' '
	BNE S_0E6B
	
.L_0E76
	INY
	LDA (TXTPTR),Y
	CMP #' '
	BEQ L_0E76
	
	CMP #13
	BEQ L_0EBA
	
	JSR S_0E93
	BCC L_0E8D
	
	STA OWBLK+2
	INY
	JSR S_0E93
	
.L_0E8D
	BEQ L_0E92
	STA OWBLK+1
	
.L_0E92
	RTS
	
.S_0E93
	LDA #0
	STA &A8
	
.L_0E97
	LDA (TXTPTR),Y
	CMP #'@'
	BCS L_0EB6
	
	CMP #'.'
	BEQ L_0EB7
	BMI L_0EB6
	
	AND #&0F
	STA &A9
	ASL &A8
	LDA &A8
	ASL A
	ASL A
	ADC &A8
	ADC &A9
	STA &A8
	INY
	BNE L_0E97
	
.L_0EB6
	CLC
	
.L_0EB7
	LDA &A8
	RTS
	
.L_0EBA
	PLA
	PLA
	JSR S_0F3B_PRINT
	EQUS "File server is "
	
	LDY OWBLK+2
	BEQ L_0EDA
	
	JSR S_0F10_PRINTNUM
	JSR S_0F3B_PRINT
	EQUS "."
	
.L_0EDA
	LDY OWBLK+1
	JSR S_0F10_PRINTNUM
	JSR OSNEWL
	JMP OSNEWL
	
IF LOADADDR=&0E23
	ORG &0F09
	
	EQUD &FFFF0E23

	ORG &0F10
ENDIF
	
.S_0F10_PRINTNUM
{
	;SMALL CHANGE, IT WAS BIT &0F85 ?
	BIT L_0F3A;SET V
	
	LDA #100
	JSR S_0F20
	LDA #10
	JSR S_0F20
	LDA #1
	
	CLV;PRINT ZERO
	
.S_0F20
	STA &AA
	TYA
	LDX #&2F
	SEC
	PHP
	
.L_0F27
	INX
	SBC &AA
	BCS L_0F27
	
	ADC &AA
	TAY
	TXA
	PLP
	BVC L_0F37
	
	CMP #'0'
	BEQ L_0F3A
	
.L_0F37
	JMP OSASCI
	
.L_0F3A
	RTS
}
	
.S_0F3B_PRINT
{
	PLA
	STA &A8
	PLA
	STA &A9
	
	LDY #0
	BEQ L_0F48;ALWAYS
	
.L_0F45
	JSR OSASCI
	
.L_0F48
	INC &A8
	BNE L_0F4E
	
	INC &A9
	
.L_0F4E
	LDA (&A8),Y
	BPL L_0F45
	
	JMP (&00A8)
}
	
.OWBLK



}
.FS_END

	SAVE "$.FS", FS_START, FS_END
