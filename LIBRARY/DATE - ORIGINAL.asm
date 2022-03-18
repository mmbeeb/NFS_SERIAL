

	;********************************
	;*            DATE              *
	;*   Original ACORN version     *
	;********************************

	;* Assembled using beebasm 1.09 *

	OSNEWL=&FFE7
	OSWRCH=&FFEE
	OSWORD=&FFF1

	CLEAR &0E00, &0FFF
	ORG &0E23

.DATE_START
{
	LDA #9
	STA D_0FDC
	LDA #16
	STA D_0FDE

	LDA #&14
	LDX #LO(D_0FDB)
	LDY #HI(D_0FDB)
	JSR OSWORD
	
	; PRINT DATE

	; DAY OF WEEK
	LDA #9
	JSR S_0F17
	JSR S_0E65
	
	; DAY OF MONTH
	LDA #17
	JSR S_0F17
	JSR S_0EA8
	
	LDA #21
	JSR S_0F17
	
	;MONTH
	LDA D_0FE0
	AND #&0F
	ADC #6
	JSR S_0F2E
	
	;YEAR
	LDA #25
	JSR S_0F17
	
	LDA D_0FF7
	
	ADC #&31
	JSR OSWRCH
	JMP OSNEWL
	
	;PRINT DAY OF WEEK
.S_0E65
	LDA D_0FE0
	LSR A
	LSR A
	LSR A
	LSR A
	STA D_0FF7
	LDA D_0FE0
	AND #&0F
	PHA 
	TAX 
	CMP #3
	BCC L_0E7B
	
	DEX 
	
.L_0E7B
	DEX 
	TXA 
	ASL A
	STA D_0FF8
	PLA 
	TAX 
	CMP #9
	BCC L_0E88
	
	INX 
	
.L_0E88
	TXA 
	LSR A
	CLC 
	ADC D_0FF8
	ADC D_0FDF
	ADC D_0FF7
	SEC 
	SBC #3
	
.L_0E97
	CMP #7
	BCC L_0EA0
	
	SEC 
	SBC #7
	BPL L_0E97
	
.L_0EA0
	JSR S_0F2E
	
	LDA #14
	JMP S_0F17
	
	;DAY OF MONTH
.S_0EA8
	LDA #&FF
	STA D_0FF8
	
	LDA D_0FDF
	
	;PRINT DECIMAL
	SEC 
	
.L_0EB1
	INC D_0FF8
	SBC #10
	BCS L_0EB1
	
	ADC #10
	STA D_0FFA
	LDA D_0FF8
	BEQ L_0EC7
	
	ORA #'0'
	JSR OSWRCH
	
.L_0EC7
	LDA D_0FFA
	ORA #'0'
	JSR OSWRCH
	
	LDX D_0FF8
	CPX #1
	BEQ L_0EE2;th
	
	CMP #'1'
	BEQ L_0EEC;st
	
	CMP #'2'
	BEQ L_0EF6;nd
	
	CMP #'3'
	BEQ L_0F0D;rd
	
.L_0EE2
	LDA #'t'
	JSR OSWRCH
	LDA #'h'
	JMP OSWRCH
	
.L_0EEC
	LDA #'s'
	JSR OSWRCH
	LDA #'t'
	JMP OSWRCH
	
.L_0EF6
	LDA #'n'
	JSR OSWRCH
	LDA #'d'
	JMP OSWRCH
	
	ORG &0F0D
	
.L_0F0D
	LDA #'r'
	JSR OSWRCH
	LDA #'d'
	JMP OSWRCH
	
.S_0F17
	STA D_0FF8
	LDY D_0FF9
	
.L_0F1D
	LDA D_0FC2,Y
	JSR OSWRCH
	INY 
	CPY D_0FF8
	BNE L_0F1D

	STY D_0FF9
	CLC 
	RTS 

.S_0F2E
	TAX 
	LDA D_0F48,X
	TAX 
	LDA D_0F5B,X
	JSR OSWRCH
	INX 

.L_0F3A
	LDA D_0F5B,X
	CMP #'['
	BCC L_0F47

	JSR OSWRCH
	INX 
	BNE L_0F3A
	
.L_0F47
	RTS 

.D_0F48
	EQUB &00, &03, &06, &0A, &10, &15, &18
	EQUB &1D, &24, &2C, &31, &36, &39, &3D, &41, &47, &50, &57, &5F
	
.D_0F5B
	EQUS "Sun", "Mon", "Tues", "Wednes", "Thurs", "Fri", "Satur"
	
	EQUS "January", "February", "March"
	EQUS "April", "May", "June"
	EQUS "July", "August", "September"
	EQUS "October", "November", "December"

.D_0FC2
	EQUS "Today is ", "day the ", " of ", " 198"

	;OSWORD &14 BLOCK
.D_0FDB
	EQUB 0
.D_0FDC
	EQUB 0;BLOCK SIZE
	EQUB 0;
.D_0FDE
	EQUB 0;FUNCTION CODE 16 = READ TIME & DATE
.D_0FDF
	EQUB 0;/DATE1
.D_0FE0
	EQUB 0;/DATE2
	EQUB 0;/HOURS
	EQUB 0;/MINUTES
	EQUB 0;/SECONDS
	
	ORG &0FF7
	
.D_0FF7
	EQUB 0
.D_0FF8
	EQUB 0
.D_0FF9
	EQUB 0
.D_0FFA
	EQUW 0
}
.DATE_END

	SAVE "O.DATE", DATE_START, DATE_END

