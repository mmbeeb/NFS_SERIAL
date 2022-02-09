	\\ netsys_sp_L1.asm
	\\ Compiler: BeebAsm V1.09
	\\ By Martin Mather

	\\ Serial system hardware
	ACIA_TDR = &FE09			;Write
	ACIA_RDR = &FE09			;Read
	ACIA_CONTROL = &FE08		;Write
	ACIA_STATUS = &FE08			;Read
	SERIAL_ULA = &FE10

	;50ths of a second
	SP_TIMEOUT1	= 125			;Until first interrupt
	SP_TIMEOUT2 = 25			;After interrupt
	
	SP_DEFAULT_BAUDRATE	= 8		;Default baud rate
	

.NFS_SERVICE_05					;Unrecognised Interrupt
{
	LDA ACIA_STATUS
	BMI L1						;If ACIA interrupt!
	
	LDA #5
	RTS

.L1	JSR sp_interrupt_handler
	LDA #0						;We handled the service call.
	RTS
}
	
	\\ Claim the NMI so we can use the associated memory in zero page and page &D.
	
.NFS_SERVICE_0C
.NFS_NMI_CLAIM					;Another ROM is claiming NMI
{
	BIT I_Own_NMI_D66
	BPL L1

IF _SPDBG_
	;lda #'/'
	;jsr DBGWRCH
	;lda #'R'
	;jsr DBGWRCH
ENDIF
	
	LDA #0
	STA Line_Not_Busy_D62
	STA I_Own_NMI_D66

	LDA #&43
	STA ACIA_CONTROL			;Reset ACIA, nRTS=1

.L1	RTS
}


.NFS_SERVICE_0B
.NFS_NMI_RELEASED				;NMI has been released by another ROM
{
IF _SPDBG_
	;lda #'/'
	;jsr DBGWRCH
	;lda #'C'
	;jsr DBGWRCH
ENDIF

	LDA #&80
	STA Line_Not_Busy_D62
	STA I_Own_NMI_D66
	
	ASL A	;A=0
	STA SP_TUBEEN
	
	LDA #&40
	STA &0D00					;RTI just in case

	;JMP sp_reset_and_listen
}


	\\ See AUG page 300 "13.8.2 The RS423 serial system"

	\\ Listen
	\\ Exit: Z=0
.sp_reset_and_listen
{
	\\ OSBYTE &E8 -> ?&278 = 6850 interrupt mask, default value = &FF
	LDA #0
	STA &278					;ACIA interrupt mask, stop the OS intercepting the ACIA interrupt.
	
	;ACIA MASTER RESET
	;Note: If first MASTER RESET then nRTS=1,
	;else CR5 & CR6 cotrol the state of nRTS.
	LDA #&03
	STA ACIA_CONTROL			;nRTS=0
	
	;;SERIAL ULA SEE AUG 392
	;;Y = TX&RX BAUD RATE, 1=75, 2=150, 3=300, 4=1200, 5=2400, 6=4800, 7=9600, 8=19200
	
	LDY SP_BAUDRATE
	DEY
	BPL L1
	
	CPY #8
	BCC L2
	
.L1	LDY #SP_DEFAULT_BAUDRATE-1

.L2	LDA bauds,Y
	STA &0282					;OS copy of the Serial ULA register.
	STA SERIAL_ULA
	
	;LISTEN
	;Y=Frame Flag
	
.*sp_listen4scout
	LDA #&80
	STA Line_Not_Busy_D62		;Line not busy
	
	LDA #SP_FLAG_SCOUT
	
.*sp_listen4flag
	STA SP_RX_STATE2

IF _SPDBG_
	pha
	lda #'?'
	jsr DBGWRCH
	pla
	jsr PRINT_HEX_SPC
ENDIF

	;RIE = 1, TIE = 0, nRTS = 0
	;Word Select = 8N1, Clk Div = 64
	LDA #&96
	CLC
	
.L3	PHP
	SEI
	STA &0250
	STA ACIA_CONTROL

	LDA #0
	STA SP_ESCFLAG
	STA SP_RX_STATE
	ROL A
	STA SP_TX_STATE				;SP_TX_STATE = C
	
	LDA #(&100-SP_TIMEOUT1)
	STA &EA						;Set timer
	PLP
	RTS

	;Transmit A bytes	
.*sp_transmit
	STA SP_TX_SIZE				;Control buffer size

IF _SPDBG_
	lda #'#'
	jsr DBGWRCH
ENDIF
	
	;RIE = 0, TIE = 1
	;0 01 101 10
	LDA #&36
	SEC
	BCS L3						;Always
	
.bauds
	EQUB &7F, &5B, &6D, &49, &76, &52, &64, &40
}

	;Check things are ok
.sp_poll
{
	BIT I_Own_NMI_D66
	BPL L1						;I don't own NMI!

	LDA &EA
	BMI L1						;Not timed out
	BNE L1						;CFS owns ACIA
	
	LDA SP_TX_STATE
	BNE L2						;TX busy
	
	LDA SP_RX_STATE
	BNE L3						;RX busy
	
	LDA SP_RX_STATE2
	CMP #SP_FLAG_SCOUT
	BNE L3						;We were expecting a reply!
	
.L1	RTS

	;TX timed out
.L2

IF _SPDBG_
	lda #'.'
	jsr DBGWRCH
	lda #'T'
	jsr DBGWRCH
ENDIF
	
	JMP sp_transmit_error
	
	;RX timed out
.L3

IF _SPDBG_
	lda #'.'
	jsr DBGWRCH
	lda #'R'
	jsr DBGWRCH
ENDIF

	JMP sp_receive_error
}


	;ACIA interrupt flag set.
	;Entry: A = ACIA status byte
	;Exit : A,X,Y undefined
.sp_interrupt_handler
{
	LDY #(&100-SP_TIMEOUT2)
	STY &EA						;Reset timer

	LSR A
	BCS sp_rx_interrupt			;If RDRF=1
	
	LSR A
	BCS L1						;If TDRE=1
	
	RTS
	
.L1	JMP sp_tx_interrupt
}
	
	;***************** RECEIVED BYTE!
.sp_rx_interrupt
{
	LDY ACIA_RDR

IF _SPDBG_
	tya
	jsr PRINT_HEX
ENDIF
	
	CPY #SP_ESC_CHR
	BEQ L3
	
	BIT SP_ESCFLAG
	BMI L4
	
	TYA
	
	;A=BYTE
.L1	JSR CRC_CALC
	
	LDY SP_FIFO+1				;FIFO
	LDX SP_FIFO
	STX SP_FIFO+1
	STA SP_FIFO
	
	BIT SP_FIFO_STATE
	BPL L8						;If FIFO wasn't full
	
	;Y=BYTE OUT OF FIFO

IF _SPDBG_
	;lda #'!'
	;jsr DBGWRCH
	;tya
	;;jsr PRINT_HEX_SPC
ENDIF
	
	LDA SP_RX_STATE
	BEQ L2						;NOT EXPECTING ANYTHING!
	BPL L6						;RXING DATA
	
	;READ TO BUFFER (MAX 12 BYTES)
	
	TYA							;A=DATA
	LDY SP_RX_COUNT				;COUNTER
	CPY #12
	BCS L7						;CONTROL BUFFER OVERFLOW, C=1
	
	STA SP_RX_BUF,Y
	INC SP_RX_COUNT
	DEY
	BEQ L5						;If Y was == 1, then ?&80 == 2

.L2	RTS

.L8	DEC SP_FIFO_STATE			;FIFO state
	RTS
	
	;ESC CHR received, C=1
.L3	ROR SP_ESCFLAG				;Set bit 7
	RTS
	
	;ESC byte
.L4	LSR SP_ESCFLAG				;Reset bit 7
	TYA
	BNE L4A						;FLAG BYTE!
	
	LDA #SP_ESC_CHR
	BNE L1						;always
	
.L4A
	JMP sp_rx_newframe

	;2 bytes read, are the rest data?
.L5	;lda #'+'
	;jsr OSWRCH
	
	ROL SP_RX_STATE				;/DATA (now in bit 7), so if +VE rest of frame contains data.
	RTS
	
	;Y=DATA BYTE : STORE IN BUFFER?
.L6	BIT SP_RX_OVERFLOW
	BMI L2						;If buffer has already overflowed

	LDA #&02
	BIT RXTX_Flags_D4A
	BNE TU1						;OVER TUBE

	INC &A2
	BEQ H5
	
.H2	TYA
	LDY &A2
	STA (ptrA4L),Y
	
	;lda #'>'
	;jsr OSWRCH

	RTS

.H5	INC &A5
	DEC &A3
	BNE H2
	
.H3	;BUF OVERFLOW

.L7
IF _SPDBG_
	;lda #'?'
	;jsr DBGWRCH
ENDIF

	SEC
	ROR SP_RX_OVERFLOW			;Set buffer overflow flag
	RTS
	
.TU1
	JSR Sub_9A37_IncCounter		;!&A2 += 1
	BEQ L7						;If !&A2 == 0, buffer is already full
	
	STY TUBE_R3_DATA

IF _SPDBG_
	;lda #'T'
	;jmp DBGWRCH
ENDIF
	RTS

}

	;***************** TRANSMIT BYTE?
	
.sp_tx_interrupt
{
	LDY SP_TX_STATE
	BEQ J1						;Not doing anything, reset.

	;**** TRANSMIT OPENING FLAG

	DEY
	BNE J2						;If TX_STATE != 1
	
	;TX_STATE == 1 : Begin transmission
	
IF _SPDBG_
	;lda #'&'
	;jsr DBGWRCH
	;lda RXTX_Flags_D4A
	;jsr PRINT_HEX_SPC
ENDIF
	
	;Y=0
	STY SP_TX_COUNT				;Counter
	STY SP_CRC					;CRC reset
	STY SP_CRC+1

	;Send ESC character
	LDA #SP_ESC_CHR
	STA ACIA_TDR
	
	LSR SP_ESCFLAG				;CLEAR FLAG
	BPL J2A						;ALWAYS, TX_STATE = 2
	
.J1	JMP Sub_99DB_ListenForScout

.J2	DEY
	BNE J5						;If TX_STATE != 2
	
	;TX_STATE == 2 : Send flag
	
	LDA SP_TX_FLAG				;SEND FLAG BYTE (Should never == SP_ESC_CHR!!!)
	STA ACIA_TDR
	JSR CRC_CALC				;INCLUDE FLAGS IN CRC

.J2A
	INC SP_TX_STATE				;TX_STATE = 3
	RTS
	
	;**** TRANSMIT TX_BUF

.J3	ROR SP_ESCFLAG				;Set ESC flag
	RTS
	
.J4	STY ACIA_TDR				;Y=0
	STY SP_ESCFLAG				;Clear ESC flag
	BMI J6						;always
	
.J5	DEY
	BNE J9						;If TX_STATE != 3
	
	;TX_STATE == 3 : Transmit SP_TX_BUF contents
	
	BIT SP_ESCFLAG
	BMI J4

	LDY SP_TX_COUNT
	INC SP_TX_COUNT
	LDA SP_TX_BUF,Y
	STA ACIA_TDR
	
	JSR CRC_CALC
	
	CMP #SP_ESC_CHR
	BEQ J3						;If Z, then C set

.J6	DEC SP_TX_SIZE
	BNE J7
	
IF _SPDBG_
	;TX_BUF now empty
	;lda #'('
	;jsr DBGWRCH
ENDIF
	
	INC SP_TX_STATE				;TX_STATE = 4

.J7	RTS
	
	;**** TRANSMIT DATA
	
.J8	STY ACIA_TDR				;Y=0
	STY SP_ESCFLAG				;CLEAR FLAG
	RTS
		
.J9	DEY
	BNE J17						;If TX_STATE != 4
	
	;TX_STATE == 4 : Transmit data (if any)
	
	LDA RXTX_Flags_D4A
	ROR A						;C = Flags bit 0
	BCS J13						;No sata to send

	BIT SP_ESCFLAG
	BMI J8

	ROR A						;C = Flags bit 1
	BCS J14						;OVER TUBE
	
	;HOST DATA

	INC &A2
	BEQ J12

.J10
	LDY &A2
	LDA (ptrA4L),Y
	
	;GOT BYTE FROM BUFFER
.J11
	STA ACIA_TDR
	
	JSR CRC_CALC

	CMP #SP_ESC_CHR
	BEQ J15						;C=1

IF _SPDBG_
	;pha
	;lda #'<'
	;jsr DBGWRCH
	;pla
	;jsr PRINT_HEX_SPC
ENDIF

	RTS

.J12
	INC &A5
	DEC &A3
	BNE J10
	
	;BUF EMPTY
.J13

IF _SPDBG_
	;lda #')'
	;jsr DBGWRCH
ENDIF

	INC SP_TX_STATE				;TX_STATE = 5
	BNE J18						;Always.  No more data, send CRC.
	
	;TUBE DATA
	
.J14
	JSR Sub_9A37_IncCounter		;!&A2 += 1
	BEQ J13						;If !&A2 == 0
	
	LDA TUBE_R3_DATA
	JMP J11
	
	;**** TRANSMIT CRC

.J15
	ROR SP_ESCFLAG				;SET FLAG
	RTS

.J16
	STY ACIA_TDR				;Y=0
	STY SP_ESCFLAG				;RESET FLAG
	BEQ J20						;ALWAYS
	
.J17
	DEY
	BNE J21						;If TX_STATE != 5
	
	;TX_STATE == 5 : Send high byte of CRC
	
.J18
	LDA SP_CRC+1
	
.J19
	BIT SP_ESCFLAG
	BMI J16						;Y=0

	STA ACIA_TDR
	
	CMP #SP_ESC_CHR
	BEQ J15						;C=1

.J20
	INC SP_TX_STATE				;TX_STATE = 6 (or 7)
	RTS
	
.J21
	DEY
	BNE J22						;If TX_STATE != 6
	
	;TX_STATE == 6 : Send low byte of CRC
	
	LDA SP_CRC
	JMP J19						;Y=0

	;**** TRANSMIT CLOSING FLAG

.J22
	DEY
	BNE J23						;If TX_STATE != 7
	
	;TX_STATE == 7 : SEND ESC FLAG
	
	LDA #SP_ESC_CHR
	STA ACIA_TDR
	BNE J20						;Always, TX_STATE = 8
	
.J23
	DEY
	BNE J24						;If TX_STATE != 8
	
	;TX_STATE == 8 : SEND VOID FLAG
	
	LDA #&7E
	STA ACIA_TDR
	BNE J20						;Always, TX_STATE = 9
	
.J24
	DEY
	BNE J25						;If TX_STATE != 9
	
	;TX_STATE == 9 : TX COMPLETE
	
	JMP Sub_9D14_Frame_Sent

	;Unknown state	
.J25
	JMP Sub_99DB_ListenForScout
}



\\*************************************************************************************


.CRC_CALC
{
	L=SP_CRC
	H=SP_CRC+1
	T=SP_CRC_TEMP
	
	PHA
	
	SEC
	ROR T
	
	EOR H
	STA H
	
.L1	LDA H
	ROL A
	BCC L2
	
	ROR A
	EOR #&08
	STA H
	LDA L
	EOR #&10
	STA L
	SEC
	
.L2	ROL L
	ROL H
	
	LSR T
	BNE L1

	PLA
	RTS
}



\\*************************************************************************************

IF _SPDBG_
	\ Print hex followed by space
	\ Exit: A, X & Y preserved
.PRINT_HEX_SPC
	JSR PRINT_HEX
	PHA
	LDA #&20
	JSR DBGWRCH
	PLA
	RTS

	\ Print hex
	\ Exit: A, X & Y preserved
.PRINT_HEX
{
	PHA
	LSR A
	LSR A
	LSR A
	LSR A
	JSR L1
	PLA
	PHA
	JSR L1
	PLA
	RTS
	
.L1	CLC
	AND #&0F
	ADC #&30
	CMP #&3A
	BCC L2
	
	ADC #&06
	
.L2	JMP DBGWRCH
}

.DBGWRCH
{
	bit SP_DBGFLAG
	bmi x1
	rts
.x1
	jmp OSWRCH
}
ENDIF

\\\ END OF FILE
