

	;********************************
	;*            TIME              *
	;*   Original ACORN version     *
	;********************************

	;* Assembled using beebasm 1.09 *

	LOADADDR =? &0E23

	OSNEWL=?&FFE7
	OSWRCH=?&FFEE
	OSWORD=?&FFF1

	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.TIME_START
{
.L_0E23
	LDA #&14
	LDX #LO(D_0F54)
	LDY #HI(D_0F54)
	JSR OSWORD
	
	LDA D_0F5A
	CMP #&0C
	BCC L_0E41
	
	PHA
	LDA #&FF
	STA D_0F50
	PLA
	CMP #&0C
	BEQ L_0E41
	
	SEC
	SBC #&0C
	
.L_0E41
	STA D_0F51
	LDA D_0F5B
	STA D_0F5B
	LDA D_0F5C
	STA D_0F5C
	
	LDX #&0D
	LDY #&0F
	LDA D_0F50
	BEQ L_0E68
	
	LDX #&22
	LDY #&0F
	LDA D_0F5A
	CMP #&12
	BCC L_0E68
	
	LDX #&39
	LDY #&0F
	
.L_0E68
	JSR S_0EB4
	LDX #&FF
	LDA D_0F51
	JSR S_0E8A
	JSR S_0EC5
	LDX #&00
	LDA D_0F5B
	JSR S_0E8A
	JSR S_0EC5
	LDA D_0F5C
	JSR S_0E8A
	JMP OSNEWL
	
.S_0E8A
	JSR S_0EA9
	STY D_0F4E
	STA D_0F4F
	CPX #&00
	BEQ L_0E9B
	
	CPY #&00
	BEQ L_0EA1
	
.L_0E9B
	TYA
	ORA #&30
	JSR OSWRCH
	
.L_0EA1
	LDA D_0F4F
	ORA #&30
	JMP OSWRCH
	
.S_0EA9
	LDY #&FF
	SEC
	
.L_0EAC
	SBC #&0A
	INY
	BCS L_0EAC
	
	ADC #&0A
	RTS
	
.S_0EB4
	STX &A8
	STY &A9
	LDY #&00
	
.L_0EBA
	LDA (&A8),Y
	BEQ L_0EC4
	JSR OSWRCH
	INY
	BNE L_0EBA
	
.L_0EC4
	RTS

.S_0EC5
	LDA #&3A
	JMP OSWRCH

IF LOADADDR = &0E23
	ORG &0F09
	EQUD &FFFF0E23;Execution address
ENDIF

.D_0F0D
	EQUS "Good morning ! It's ", 0
	EQUS "Good afternoon ! It's ", 0
	EQUS "Good evening ! It's ", 0

.D_0F4E
	EQUB 0
.D_0F4F
	EQUB 0
.D_0F50
	EQUB 0
.D_0F51
	EQUB 0, 0, 0
	
.D_0F54;OSWORD BLOCK
	EQUB 0
	EQUB 5;BLOCK SIZE
	EQUB 0;
	EQUB 16;FUNCTION CODE 16 = READ TIME & DATE

	EQUB 0;/DATE
	EQUB 0

.D_0F5A
	EQUB 0;/HOURS
.D_0F5B
	EQUB 0;/MINUTES
.D_0F5C
	EQUB 0;/SECONDS
}
.TIME_END

IF HI(TIME_START)=&DD;MASTER
	SAVE "M\$.TIME", TIME_START, TIME_END
ELIF HI(TIME_START)=&0E
	SAVE "E\$.TIME", TIME_START, TIME_END
ELSE
	SAVE "O\$.TIME", TIME_START, TIME_END
ENDIF
