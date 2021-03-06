    SUBROUTINE JSL.TOPS.XTR.CRF.M

    $INSERT I_COMMON
    $INSERT I_EQUATE
    $INSERT I_F.DATES
    $INSERT I_F.COMPANY
    $INSERT I_F.RE.STAT.LINE.CONT
    $INSERT I_F.CONSOLIDATE.ASST.LIAB
    $INSERT I_F.CONSOLIDATE.PRFT.LOSS

    GOSUB INIT
    GOSUB PROCESS
    GOSUB WRITE.TO.FILE
    RETURN 
	
*----*	
INIT:
*----*


    FN.RE.STAT.LINE.CONT = 'F.RE.STAT.LINE.CONT'
	F.RE.STAT.LINE.CONT = ''
    CALL OPF(FN.RE.STAT.LINE.CONT, F.RE.STAT.LINE.CONT)

    FN.CONSOLIDATE.PRFT.LOSS = 'F.CONSOLIDATE.PRFT.LOSS'
	F.CONSOLIDATE.PRFT.LOSS= ''
    CALL OPF(FN.CONSOLIDATE.PRFT.LOSS, F.CONSOLIDATE.PRFT.LOSS)

    FN.CONSOLIDATE.ASST.LIAB = 'F.CONSOLIDATE.ASST.LIAB'
	F.CONSOLIDATE.ASST.LIAB = ''
    CALL OPF(FN.CONSOLIDATE.ASST.LIAB, F.CONSOLIDATE.ASST.LIAB)
	OPEN "","/u01/tafj/TAFJ/UD/TOPS.BP" TO F.ACL.CONTIF ELSE PRINT "CAN NOT OPEN DIRECTORY"
    DLM='|'
	REPORT.DATE=R.DATES(EB.DAT.LAST.WORKING.DAY)[1,4]:'-':R.DATES(EB.DAT.LAST.WORKING.DAY)[5,2]:'-':R.DATES(EB.DAT.LAST.WORKING.DAY)[7,2]
    DB.DATE=TODAY[1,4]:'-':TODAY[5,2]:'-':TODAY[7,2]
	
    RETURN

*------*
PROCESS:
*------*

    LINE.LIST = ''
    SE.LIST = ''
    DR.TOTAL = 0
    CR.TOTAL = 0
    OUT.ARR = ''
    CRF.FCY.DR.BAL=0 ; CRF.FCY.CR.BAL=0 ; CRF.FCY.BAL=0
	YR.COMPANY = ID.COMPANY ;*'MW0010001'
	YR.MNE=R.COMPANY(EB.COM.MNEMONIC)
	YR.LCY = R.COMPANY(EB.COM.LOCAL.CURRENCY)
    YR.TDY =R.DATES(EB.DAT.LAST.WORKING.DAY)
	GOSUB PROCESS.CAL
	GOSUB PROCESS.CPL
    RETURN
 
*----------*   
PROCESS.CAL:
*----------*

	SEL.CONT = "SSELECT ":FN.RE.STAT.LINE.CONT:" WITH @ID LIKE FDHGL...  AND ASST.CONSOL.KEY NE ''"
	CALL EB.READLIST(SEL.CONT,LINE.LIST,'','','')

	LOOP
		REMOVE LINE.ID FROM LINE.LIST SETTING LINEPOS
	WHILE LINE.ID:LINEPOS

		CALL F.READ(FN.RE.STAT.LINE.CONT, LINE.ID, R.LINE.CONT.REC, F.RE.STAT.LINE.CONT, LINERR)
		CAL.IDS = R.LINE.CONT.REC<RE.SLC.ASST.CONSOL.KEY>
		CAL.TYPES = R.LINE.CONT.REC<RE.SLC.ASSET.TYPE>
		CRF.LDS = R.LINE.CONT.REC<RE.SLC.DESC,2>
		CAL.CNT = DCOUNT(R.LINE.CONT.REC<RE.SLC.ASST.CONSOL.KEY>, @VM)
		FOR YY = 1 TO CAL.CNT
			SE.ID = R.LINE.CONT.REC<RE.SLC.ASST.CONSOL.KEY><1,YY>
			CAL.TYPE.CNT = DCOUNT(R.LINE.CONT.REC<RE.SLC.ASSET.TYPE,YY>, @SM)
			FOR YX = 1 TO CAL.TYPE.CNT
				CAL.TYPE = R.LINE.CONT.REC<RE.SLC.ASSET.TYPE><1,YY,YX>
				CALL F.READ(FN.CONSOLIDATE.ASST.LIAB,SE.ID,TRI.REC,F.CONSOLIDATE.ASST.LIAB ,RERR)
				CRF.ID = SE.ID
				CRF.CCY = TRI.REC<RE.ASL.CURRENCY>
				CRF.CAT=TRI.REC<RE.ASL.VARIABLE.1>
				CRF.SEC=TRI.REC<RE.ASL.VARIABLE.2>
				CRF.RES=TRI.REC<RE.ASL.VARIABLE.3>
				CRF.IND=TRI.REC<RE.ASL.VARIABLE.8>
				CRF.TYPE = TRI.REC<RE.ASL.TYPE> ; CONVERT VM TO FM IN CRF.TYPE
				LOCATE CAL.TYPE IN CRF.TYPE SETTING CALPOS THEN
					IF CRF.CCY = YR.LCY THEN
						CRF.BAL = TRI.REC<RE.ASL.BALANCE><1,CALPOS>
                        IF TRI.REC<RE.ASL.DATE.LAST.UPDATE> NE YR.TDY THEN
                            CRF.BAL += TRI.REC<RE.ASL.DEBIT.MOVEMENT><1,CALPOS>
                            CRF.BAL += TRI.REC<RE.ASL.CREDIT.MOVEMENT><1,CALPOS>
                        END
					END ELSE
						CRF.BAL = TRI.REC<RE.ASL.LOCAL.BALANCE><1,CALPOS>
						CRF.FCY.BAL=TRI.REC<RE.ASL.BALANCE><1,CALPOS>
                        IF TRI.REC<RE.ASL.DATE.LAST.UPDATE> NE YR.TDY THEN
                            CRF.BAL += TRI.REC<RE.ASL.LOCAL.DEBIT.MVE><1,CALPOS>
                            CRF.BAL += TRI.REC<RE.ASL.LOCAL.CREDT.MVE><1,CALPOS>
							CRF.FCY.BAL+=TRI.REC<RE.ASL.DEBIT.MOVEMENT><1,CALPOS>
							CRF.FCY.BAL+=TRI.REC<RE.ASL.CREDIT.MOVEMENT><1,CALPOS>
                        END
			END
					CRF.TYPE = TRI.REC<RE.ASL.TYPE><1,CALPOS>
					CRF.REF = FIELDS(LINE.ID,'.',1,2)
                    IF CRF.BAL THEN
                        IF CRF.BAL < 0 THEN
                            CRF.DR.BAL = CRF.BAL
                            *DR.TOTAL += CRF.BAL
							CRF.FCY.DR.BAL=CRF.FCY.BAL
                        END 
                        IF CRF.BAL > 0 THEN
                            CRF.CR.BAL = CRF.BAL
                            *CR.TOTAL += CRF.BAL
							CRF.FCY.CR.BAL=CRF.FCY.BAL
                        END
					    GOSUB WRITE.TO.CRF
                    END
				END
			NEXT YX
			R.CPL.REC=''
		NEXT YY
		R.LINE.CONT.REC=''
	REPEAT
	RETURN
	
*-----------*	
PROCESS.CPL:
*-----------*

	SEL.CONT = "SSELECT ":FN.RE.STAT.LINE.CONT:" WITH @ID LIKE FDHPL...  AND PRFT.CONSOL.KEY NE ''"
	CALL EB.READLIST(SEL.CONT,LINE.LIST,'','','')

	LOOP
		REMOVE LINE.ID FROM LINE.LIST SETTING LINEPOS
	WHILE LINE.ID:LINEPOS

	CALL F.READ(FN.RE.STAT.LINE.CONT, LINE.ID, R.LINE.CONT.REC,F.RE.STAT.LINE.CONT, LINERR)
	CPL.IDS = R.LINE.CONT.REC<RE.SLC.PRFT.CONSOL.KEY>
	CRF.LDS = R.LINE.CONT.REC<RE.SLC.DESC,2>
	CPL.CNT = DCOUNT(R.LINE.CONT.REC<RE.SLC.PRFT.CONSOL.KEY>, @VM)
	FOR YYP = 1 TO CPL.CNT
		CPL.ID = R.LINE.CONT.REC<RE.SLC.PRFT.CONSOL.KEY><1,YYP>
		CALL F.READ(FN.CONSOLIDATE.PRFT.LOSS,CPL.ID,R.CPL.REC,F.CONSOLIDATE.PRFT.LOSS ,CPLERR)
		CRF.ID = CPL.ID
                CRF.CAT=R.CPL.REC<RE.PTL.VARIABLE.1>
	        CRF.PROD=R.CPL.REC<RE.PTL.VARIABLE.2>
	        CRF.SEC=R.CPL.REC<RE.PTL.VARIABLE.3>
	        CRF.DEPT=R.CPL.REC<RE.PTL.VARIABLE.4>
	        CRF.RES=R.CPL.REC<RE.PTL.VARIABLE.5>
        IF R.CPL.REC<RE.PTL.DATE.LAST.UPDATE> # YR.TDY THEN
                CCY.CNT = DCOUNT(R.CPL.REC<RE.PTL.CURRENCY>, @VM)
            FOR IX = 1 TO CCY.CNT
            *--Check for balances before last working day - Add to Opening balance ---*
                CRF.BALMVT = 0 ; CRF.FCYBALMVT=0
                CRF.CCY = R.CPL.REC<RE.PTL.CURRENCY><1,IX>
                CRF.BALDAY = R.CPL.REC<RE.PTL.BALANCE><1,IX>
                CRF.BALYTD = R.CPL.REC<RE.PTL.BALANCE.YTD><1,IX>
                CRF.BALMVT = R.CPL.REC<RE.PTL.DEBIT.MOVEMENT><1,IX>
                CRF.BALMVT += R.CPL.REC<RE.PTL.CREDIT.MOVEMENT><1,IX>
		CRF.FCYBALDAY =R.CPL.REC<RE.PTL.CCY.BALANCE><1,IX>
		CRF.FCYBALYTD = R.CPL.REC<RE.PTL.CCY.BALANCE.YTD><1,IX>
		CRF.FCYBALMVT = R.CPL.REC<RE.PTL.CCY.CREDT.MVE><1,IX>
		CRF.FCYBALMVT += R.CPL.REC<RE.PTL.CCY.DEBIT.MVE><1,IX>
                CRF.BAL = CRF.BALDAY + CRF.BALYTD + CRF.BALMVT
		CRF.FCY.BAL=CRF.FCYBALDAY + CRF.FCYBALYTD + CRF.FCYBALMVT
                CRF.TYPE = FIELD(CPL.ID,'.',2,1)
                CRF.REF = FIELDS(LINE.ID,'.',1,2)
                IF CRF.BAL THEN
                    IF CRF.BAL < 0 THEN
                        CRF.DR.BAL = CRF.BAL
                        *DR.TOTAL += CRF.BAL
			CRF.FCY.DR.BAL=CRF.FCY.BAL
                    END 
                    IF CRF.BAL > 0 THEN
                        CRF.CR.BAL = CRF.BAL
                        *CR.TOTAL += CRF.BAL
			CRF.FCY.CR.BAL=CRF.FCY.BAL
                    END
                    GOSUB WRITE.TO.CRF
                END
            NEXT IX
        END
		R.CPL.REC=''
	NEXT YYP
	R.LINE.CONT.REC=''
	REPEAT
        CHANGE '"' TO '' IN PY.LIST
        WRITE PY.LIST TO F.ACL.CONTIF,'CRF.REP.-':DB.DATE:'-.csv'
        PY.LIST=''
	RETURN
	
WRITE.TO.CRF:
*---------------
*- Append asset type 
        CHANGE ',' TO ' ' IN CRF.LDS
        BRANCH=RIGHT(CRF.ID,9)
        CALL DBR('COMPANY':FM:EB.COM.COMAPNY.NAME,BRANCH,BRANCH.NAME)
        CHANGE ',' TO ' ' IN BRANCH.NAME
	OUT.ARR =CRF.ID:DLM:CRF.REF:DLM:DQUOTE(CRF.LDS):DLM:CRF.CCY:DLM:ABS(CRF.DR.BAL):DLM:ABS(CRF.CR.BAL):DLM:ABS(CRF.FCY.DR.BAL):DLM:ABS(CRF.FCY.CR.BAL):DLM:YR.MNE:DLM:CRF.TYPE
	OUT.ARR:=DLM:CRF.CAT:DLM:CRF.SEC:DLM:CRF.RES:DLM:CRF.PROD:DLM:CRF.DEPT:DLM:CRF.IND:DLM:BRANCH:DLM:BRANCH.NAME:DLM:REPORT.DATE:DLM:DB.DATE
	PY.LIST<-1>=OUT.ARR
	OUT.ARR='' ; CRF.DR.BAL= 0 ; CRF.CR.BAL= 0 ; CRF.BAL=0 ; TRI.REC='' ; CRF.FCY.DR.BAL=0 ; CRF.FCY.CR.BAL=0 ; CRF.FCY.BAL=0
        CRF.BALDAY=0 ; CRF.BALYTD=0 ; CRF.BALMVT=0 ; CRF.FCYBALDAY=0 ; CRF.FCYBALYTD=0 ; CRF.FCYBALMVT=0 ; BRANCH='' ; BRANCH.NAME=''
    RETURN

WRITE.TO.FILE:
    CHANGE '"' TO '' IN PY.LIST
    WRITE PY.LIST TO F.ACL.CONTIF,'CRF.REP-':DB.DATE:"-.csv"
    PY.LIST=''
    RETURN
END