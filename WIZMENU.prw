#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "TopConn.ch"

// Textos de interface em ASCII para evitar conflito de encoding no RPO.

/*/{Protheus.doc} UWizMenu
Inicializa o ambiente Protheus e executa o Wizard de Menus.

@type  User Function
@since 26/08/2026
/*/
User Function UWizMenu()
	Private oApp := MsApp():New("SIGACOM")

	oApp:CreateEnv()
	PtSetTheme("OCEAN")

	oApp:cStartProg := "U_WIZMENU"
	__lInternet := .T.

	oApp:Activate()
Return Nil

/*/{Protheus.doc} WIZMENU
Rotina principal do assistente de alteracao de menus.

@type  User Function
@since 26/08/2026
/*/
User Function WIZMENU()
	Local oWizard      := Nil
	Local oStep        := Nil
	Local lReadFile    := .F.
	Local lManual      := .F.
	Local cFilePath    := Space(512)
	Local cProgram     := Space(128)
	Local aMenus       := {}
	Local oMenuBrowse  := Nil

	oWizard := FWWizardControl():New(Nil, {650, 900})
	oWizard:ActiveUISteps()

    // Passo 1 - Apresentacao
    oStep := oWizard:AddStep("INTRO", {|oPanel| WmIntro(oPanel)})
    oStep:SetStepDescription("Apresentacao")
    oStep:SetNextTitle("Avancar")
	oStep:SetNextAction({|| .T.})
	oStep:SetCancelAction({|| .T.})

    // Passo 2 - Definicao da origem da pesquisa
	oStep := oWizard:AddStep("ORIGIN", ;
		{|oPanel| WmOrigin(oPanel, @lReadFile, @lManual, ;
		@cFilePath, @cProgram)})
	oStep:SetStepDescription("Origem da pesquisa")
	oStep:SetNextTitle("Avancar")
	oStep:SetPrevTitle("Voltar")
	oStep:SetNextAction({|| WmNextOrig(lReadFile, lManual, ;
		cFilePath, cProgram, @aMenus, oMenuBrowse)})
	oStep:SetPrevAction({|| .T.})
	oStep:SetCancelAction({|| .T.})

    // Passo 3 - Ocorrencias encontradas nos menus
	oStep := oWizard:AddStep("MENUS", ;
		{|oPanel| WmMenus(oPanel, @aMenus, @oMenuBrowse)})
	oStep:SetStepDescription("Menus encontrados")
	oStep:SetNextTitle("Concluir")
	oStep:SetPrevTitle("Voltar")
	oStep:SetNextAction({|| .T.})
	oStep:SetPrevAction({|| .T.})
	oStep:SetCancelAction({|| .T.})

	oWizard:Activate()
	oWizard:Destroy()
Return Nil

/*/{Protheus.doc} WmIntro
Constroi o passo de apresentacao do assistente.

@type  Static Function
@param oPanel, object, painel disponibilizado pelo FWWizardControl
/*/
Static Function WmIntro(oPanel)
    Local oSay       := Nil
    Local oFontTitle := TFont():New("Arial",, -16, .T.)
    Local oFontBody  := TFont():New("Arial",, -10, .F.)
    Local oFontBold  := TFont():New("Arial",, -10, .T.)

    // O FWWizardControl trabalha com uma escala logica propria. Por isso,
    // sao usadas larguras fixas em vez de oPanel:nClientWidth.
    oSay := TSay():New(6, 12, ;
        {|| "Bem-vindo ao Assistente de Atualizacao de Menus"}, ;
        oPanel,, oFontTitle,,,, .T., CLR_BLUE,, 340, 14)

    oSay := TSay():New(26, 12, ;
        {|| "Localize e altere referencias em varios menus do TOTVS Protheus."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 340, 10)
    oSay := TSay():New(38, 12, ;
        {|| "Origem: arquivo CSV, _contents.txt ou programa informado manualmente."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 340, 10)
    oSay := TSay():New(50, 12, ;
        {|| "As ocorrencias encontradas serao exibidas para selecao antes da alteracao."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 340, 10)

    oSay := TSay():New(68, 12, ;
        {|| "Tabelas de infraestrutura envolvidas:"}, ;
        oPanel,, oFontBold,,,, .T., CLR_BLACK,, 340, 10)
    oSay := TSay():New(80, 22, ;
        {|| "MPMENU_MENU - identificacao e dados gerais dos menus"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 330, 10)
    oSay := TSay():New(91, 22, ;
        {|| "MPMENU_ITEM - estrutura, hierarquia e propriedades dos itens"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 330, 10)
    oSay := TSay():New(102, 22, ;
        {|| "MPMENU_FUNCTION - programas e funcoes associados aos itens"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 330, 10)
    oSay := TSay():New(113, 22, ;
        {|| "MPMENU_I18N - descricoes e traducoes dos menus"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 330, 10)
    oSay := TSay():New(124, 22, ;
        {|| "MPMENU_KEY_WORDS - palavras-chave de pesquisa"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 330, 10)

    oSay := TSay():New(143, 12, ;
        {|| "Antes de processar, voce podera gerar backup completo das tabelas."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 340, 10)
    oSay := TSay():New(155, 12, ;
        {|| "Revise as ocorrencias selecionadas antes de confirmar a atualizacao."}, ;
        oPanel,, oFontBold,,,, .T., CLR_BLACK,, 340, 10)
    oSay := TSay():New(174, 12, ;
        {|| "Korus Consultoria - desenvolvido e distribuido gratuitamente."}, ;
        oPanel,, oFontBold,,,, .T., CLR_BLUE,, 340, 10)
Return Nil

/*/{Protheus.doc} WmOrigin
Constroi o passo de escolha da origem da pesquisa.

@type  Static Function
@param oPanel, object, painel disponibilizado pelo FWWizardControl
@param lReadFile, logical, indica leitura de CSV ou _contents.txt
@param lManual, logical, indica informacao manual do programa
@param cFilePath, character, caminho do arquivo selecionado
@param cProgram, character, nome do programa informado
/*/
Static Function WmOrigin(oPanel, lReadFile, lManual, cFilePath, cProgram)
	Local oCheckFile   := Nil
	Local oCheckManual := Nil
	Local oGetFile     := Nil
	Local oGetProgram  := Nil
	Local oButton      := Nil
	Local oSay         := Nil
    Local oFontTitle   := TFont():New("Arial",, -14, .T.)
    Local oFontBody    := TFont():New("Arial",, -10, .F.)

    oSay := TSay():New(6, 12, ;
        {|| "Selecione a origem das informacoes"}, ;
        oPanel,, oFontTitle,,,, .T., CLR_BLUE,, 340, 12)
    oSay := TSay():New(22, 12, ;
        {|| "Escolha somente uma das opcoes abaixo."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 340, 10)

    // Mesma quantidade de argumentos do exemplo oficial da TCheckBox.
    oCheckFile := TCheckBox():New(38, 12, ;
        "01 Ler arquivo CSV ou _contents.txt", ;
        bSetGet(lReadFile), oPanel, 330, 10,,,,,,,,.T.,,,)

    oSay := TSay():New(54, 22, {|| "Caminho do arquivo:"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 160, 10)

    @ 66, 22 GET oGetFile VAR cFilePath ;
        SIZE 235, 10 OF oPanel PIXEL

    oButton := TButton():New(66, 265, "Selecionar...", ;
        oPanel, ;
        {|| WmSelFile(@cFilePath, oGetFile, @lReadFile, @lManual, ;
        oCheckFile, oCheckManual)}, ;
        80, 10,,,.F.,.T.,.F.,,.F.,,,.F.)

    oCheckManual := TCheckBox():New(92, 12, ;
        "02 Informar programa manualmente", ;
        bSetGet(lManual), oPanel, 330, 10,,,,,,,,.T.,,,)

    oSay := TSay():New(108, 22, {|| "Nome do programa ou funcao:"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 180, 10)

    @ 120, 22 GET oGetProgram VAR cProgram PICTURE "@!" ;
        SIZE 170, 10 OF oPanel PIXEL

	oCheckFile:bLClicked := ;
		{|| WmCheck(1, @lReadFile, @lManual, oCheckFile, oCheckManual)}
	oCheckManual:bLClicked := ;
		{|| WmCheck(2, @lReadFile, @lManual, oCheckFile, oCheckManual)}
Return Nil

/*/{Protheus.doc} WmCheck
Mantem as duas caixas de selecao mutuamente exclusivas.
/*/
Static Function WmCheck(nOption, lReadFile, lManual, ;
		oCheckFile, oCheckManual)

	If nOption == 1 .And. lReadFile
		lManual := .F.
	ElseIf nOption == 2 .And. lManual
		lReadFile := .F.
	EndIf

	oCheckFile:CtrlRefresh()
	oCheckManual:CtrlRefresh()
Return .T.

/*/{Protheus.doc} WmSelFile
Abre o seletor de arquivos do SmartClient.
/*/
Static Function WmSelFile(cFilePath, oGetFile, lReadFile, lManual, ;
		oCheckFile, oCheckManual)

	Local cSelected := ""
	Local cMask     := "Arquivos CSV|*.csv|" + ;
		"Arquivos Contents|*_contents.txt"

	cSelected := cGetFile(cMask, "Selecione o arquivo", 1, "", ;
		.F., nOr(GETF_LOCALHARD, GETF_NETWORKDRIVE), .F., .T.)

	If !Empty(cSelected)
		cFilePath := PadR(cSelected, Len(cFilePath))
		lReadFile := .T.
		lManual := .F.

		oGetFile:CtrlRefresh()
		oCheckFile:CtrlRefresh()
		oCheckManual:CtrlRefresh()
	EndIf
Return Nil

/*/{Protheus.doc} WmMenus
Constroi o passo que apresenta as ocorrencias encontradas nos menus.

@param oPanel, object, painel disponibilizado pelo FWWizardControl
@param aMenus, array, ocorrencias encontradas para exibicao e selecao
@param oBrowse, object, browse utilizado para atualizacao apos a pesquisa
/*/
Static Function WmMenus(oPanel, aMenus, oBrowse)
	Local oGridPanel := Nil
	Local oButton    := Nil
	Local oSay       := Nil
	Local oFontTitle := TFont():New("Arial",, -14, .T.)
	Local oFontBody  := TFont():New("Arial",, -10, .F.)
	Local nGridWidth := Int(oPanel:nClientWidth / 2) - 20

	oSay := TSay():New(6, 10, ;
		{|| "Selecione as ocorrencias que deseja processar"}, ;
		oPanel,, oFontTitle,,,, .T., CLR_BLUE,, 340, 12)

	oSay := TSay():New(22, 10, ;
		{|| cValToChar(Len(aMenus)) + " ocorrencia(s) encontrada(s)."}, ;
		oPanel,, oFontBody,,,, .T., CLR_BLACK,, 340, 10)

    // O painel possui margem lateral de 10 e o browse ocupa toda a sua area.
	oGridPanel := TPanel():New(36, 10, "", oPanel,,,, ;
		CLR_BLACK, CLR_WHITE, nGridWidth, 116, .F., .F.)

	oBrowse := FWBrowse():New()
	oBrowse:SetOwner(oGridPanel)
	oBrowse:SetDataArray()
	oBrowse:SetArray(aMenus)
	oBrowse:DisableFilter()
	oBrowse:DisableConfig()
	oBrowse:DisableReport()
	oBrowse:DisableSeek()
	oBrowse:DisableSaveConfig()

	oBrowse:AddMarkColumns(;
		{|| WmMarkBmp(aMenus, oBrowse)}, ;
		{|| WmToggle(aMenus, oBrowse)})

	oBrowse:AddColumn({"Programa", ;
		{|| WmBrwVal(aMenus, oBrowse, 2)}, ;
		"C", "@!", 1, 18, 0, .F.})
	oBrowse:AddColumn({"Menu", ;
		{|| WmBrwVal(aMenus, oBrowse, 3)}, ;
		"C", "@!", 1, 16, 0, .F.})
	oBrowse:AddColumn({"Localizacao", ;
		{|| WmBrwVal(aMenus, oBrowse, 4)}, ;
		"C", "", 1, 60, 0, .F.})

	oBrowse:Activate()

	oButton := TButton():New(162, 10, "Selecionar todos", ;
		oPanel, {|| WmSetSel(aMenus, oBrowse, 1)}, ;
		100, 12,,,.F.,.T.,.F.,,.F.,,,.F.)
	oButton := TButton():New(162, 120, "Deselecionar todos", ;
		oPanel, {|| WmSetSel(aMenus, oBrowse, 2)}, ;
		100, 12,,,.F.,.T.,.F.,,.F.,,,.F.)
	oButton := TButton():New(162, 230, "Inverter selecao", ;
		oPanel, {|| WmSetSel(aMenus, oBrowse, 3)}, ;
		110, 12,,,.F.,.T.,.F.,,.F.,,,.F.)
Return Nil

/*/{Protheus.doc} WmNextOrig
Valida a origem, pesquisa as ocorrencias e atualiza o terceiro passo.
/*/
Static Function WmNextOrig(lReadFile, lManual, cFilePath, cProgram, ;
		aMenus, oBrowse)

	Local aPrograms := {}
	Local aFound    := {}

	If !WmValOrig(lReadFile, lManual, cFilePath, cProgram)
		Return .F.
	EndIf

	aPrograms := WmPrograms(lReadFile, cFilePath, cProgram)

	If Empty(aPrograms)
		MsgStop("Nao foi possivel identificar programas validos na origem " + ;
			"informada.", "Programas nao encontrados")
		Return .F.
	EndIf

	aFound := WmFindMenus(aPrograms)
	ASize(aMenus, 0)
	AEval(aFound, {|aRow| AAdd(aMenus, aRow)})

	WmRefBrw(aMenus, oBrowse)
Return .T.

/*/{Protheus.doc} WmPrograms
Monta a lista normalizada de programas informados manualmente ou em arquivo.
/*/
Static Function WmPrograms(lReadFile, cFilePath, cProgram)
	Local aPrograms := {}
	Local cNormal   := ""
	Local cResolved := ""

	If lReadFile
		Return WmFileProg(cFilePath)
	EndIf

	cNormal := WmNormProg(cProgram)
	cResolved := WmResolve(cProgram)
	WmAddUnique(@aPrograms, cNormal)
	WmAddUnique(@aPrograms, cResolved)

    // Mantem as duas formas para localizar menus antigos/customizados.
	If Left(cNormal, 2) == "U_"
		WmAddUnique(@aPrograms, SubStr(cNormal, 3))
	EndIf
Return aPrograms

/*/{Protheus.doc} WmFileProg
Extrai nomes de fontes de CSV e de arquivos _contents.txt.

O CSV pode informar o programa na primeira coluna. Em qualquer coluna, nomes
com extensao .PRW ou .TLPP tambem sao reconhecidos.
/*/
Static Function WmFileProg(cFilePath)
	Local aPrograms := {}
	Local aLines    := {}
	Local aFields   := {}
	Local oReader   := Nil
	Local cReadPath := ""
	Local cField    := ""
	Local cProgram  := ""
	Local lCopied   := .F.
	Local nLine     := 0
	Local nField    := 0

	cReadPath := WmSrvFile(cFilePath, @lCopied)
	If Empty(cReadPath)
		Return aPrograms
	EndIf

	oReader := FWFileReader():New(cReadPath)
	If !oReader:Open()
		WmDropSrv(cReadPath, lCopied)
		Return aPrograms
	EndIf

	aLines := oReader:GetAllLines()
	oReader:Close()
	WmDropSrv(cReadPath, lCopied)

	For nLine := 1 To Len(aLines)
		aFields := WmSplitLine(aLines[nLine])

		For nField := 1 To Len(aFields)
			cField := Upper(AllTrim(aFields[nField]))

			If nField == 1 .Or. ".PRW" $ cField .Or. ;
					".TLPP" $ cField
				cProgram := WmNormProg(cField)

				If WmValidProg(cProgram)
					WmAddUnique(@aPrograms, cProgram)

                    // Um fonte GACR010.PRW pode publicar U_GACR010 no RPO.
					If Left(cProgram, 2) == "U_"
						WmAddUnique(@aPrograms, SubStr(cProgram, 3))
					Else
						WmAddUnique(@aPrograms, "U_" + cProgram)
					EndIf
				EndIf
			EndIf
		Next nField
	Next nLine
Return aPrograms

/*/{Protheus.doc} WmSrvFile
Copia o arquivo escolhido no SmartClient para uma pasta temporaria no servidor.
/*/
Static Function WmSrvFile(cClientPath, lCopied)
	Local cRootDir   := "\WIZMENU\"
	Local cThreadDir := cRootDir + AllTrim(Str(ThreadId())) + "\"
	Local cFileName  := WmFileName(cClientPath)
	Local cServer    := ""

	lCopied := .F.
	If Empty(cFileName)
		Return cServer
	EndIf

	If !ExistDir(cRootDir, Nil, .F.)
		MakeDir(cRootDir, Nil, .F.)
	EndIf

	If ExistDir(cRootDir, Nil, .F.) .And. ;
			!ExistDir(cThreadDir, Nil, .F.)
		MakeDir(cThreadDir, Nil, .F.)
	EndIf

	If ExistDir(cThreadDir, Nil, .F.) .And. ;
			CpyT2S(AllTrim(cClientPath), cThreadDir, .T., .F.)
		cServer := cThreadDir + cFileName
		lCopied := .T.
	EndIf
Return cServer

/*/{Protheus.doc} WmDropSrv
Remove o arquivo temporario copiado para o servidor.
/*/
Static Function WmDropSrv(cServerPath, lCopied)
	Local cFolder := ""
	Local nSep    := 0

	If !lCopied .Or. Empty(cServerPath)
		Return Nil
	EndIf

	FErase(cServerPath)
	nSep := Max(Rat("\", cServerPath), Rat("/", cServerPath))
	If nSep > 0
		cFolder := Left(cServerPath, nSep)
		DirRemove(cFolder, Nil, .F.)
	EndIf
Return Nil

/*/{Protheus.doc} WmFileName
Retorna somente o nome de um arquivo informado com caminho completo.
/*/
Static Function WmFileName(cFilePath)
	Local cFile := AllTrim(cFilePath)
	Local nSep  := Max(Rat("\", cFile), Rat("/", cFile))

	If nSep > 0
		cFile := SubStr(cFile, nSep + 1)
	EndIf
Return cFile

/*/{Protheus.doc} WmSplitLine
Separa uma linha de arquivo usando os delimitadores usuais de CSV/contents.
/*/
Static Function WmSplitLine(cLine)
	Local cText := cValToChar(cLine)

	cText := StrTran(cText, Chr(9), ";")
	cText := StrTran(cText, ",", ";")
	cText := StrTran(cText, "|", ";")
Return StrTokArr(cText, ";")

/*/{Protheus.doc} WmNormProg
Normaliza caminho, extensao e chamada vazia de um nome de programa.
/*/
Static Function WmNormProg(cProgram)
	Local cFunction := Upper(AllTrim(cValToChar(cProgram)))
	Local nExtPos   := 0
	Local nExtLen   := 0
	Local nPathPos  := 0
	Local nBlankPos := 0

	cFunction := StrTran(cFunction, '"', "")
	cFunction := StrTran(cFunction, "'", "")

	nExtPos := At(".TLPP", cFunction)
	If nExtPos > 0
		nExtLen := 5
	Else
		nExtPos := At(".PRW", cFunction)
		If nExtPos > 0
			nExtLen := 4
		EndIf
	EndIf

	If nExtPos > 0
		cFunction := Left(cFunction, nExtPos + nExtLen - 1)
		nBlankPos := Max(Rat(" ", cFunction), Rat(Chr(9), cFunction))
		If nBlankPos > 0
			cFunction := SubStr(cFunction, nBlankPos + 1)
		EndIf
	EndIf

	nPathPos := Max(Rat("\", cFunction), Rat("/", cFunction))
	If nPathPos > 0
		cFunction := SubStr(cFunction, nPathPos + 1)
	EndIf

	If Upper(Right(cFunction, 5)) == ".TLPP"
		cFunction := Left(cFunction, Len(cFunction) - 5)
	ElseIf Upper(Right(cFunction, 4)) == ".PRW"
		cFunction := Left(cFunction, Len(cFunction) - 4)
	EndIf

	If Right(cFunction, 2) == "()"
		cFunction := Left(cFunction, Len(cFunction) - 2)
	EndIf
Return AllTrim(cFunction)

/*/{Protheus.doc} WmValidProg
Valida se o texto possui somente caracteres aceitos em um simbolo AdvPL.
/*/
Static Function WmValidProg(cProgram)
	Local cFunction := AllTrim(cProgram)
	Local cChar     := ""
	Local nChar     := 0

	If Empty(cFunction) .Or. Len(cFunction) > 128
		Return .F.
	EndIf

	If !(Left(cFunction, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ_")
		Return .F.
	EndIf

	For nChar := 1 To Len(cFunction)
		cChar := SubStr(cFunction, nChar, 1)
		If !(cChar $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
			Return .F.
		EndIf
	Next nChar
Return .T.

/*/{Protheus.doc} WmFindMenus
Pesquisa as ocorrencias e monta a localizacao hierarquica de cada item.
/*/
Static Function WmFindMenus(aPrograms)
	Local aRows := WmQryMenus(aPrograms)

	WmBuildPath(@aRows)

	ASort(aRows,,, {|x, y| ;
		Upper(x[2] + "|" + x[3] + "|" + x[4]) < ;
		Upper(y[2] + "|" + y[3] + "|" + y[4])})
Return aRows

/*/{Protheus.doc} WmQryMenus
Executa a consulta somente-leitura das ocorrencias dos programas nos menus.
/*/
Static Function WmQryMenus(aPrograms)
	Local aArea     := GetArea()
	Local aRows     := {}
	Local cAlias    := ""
	Local cQuery    := ""
	Local cKey      := ""
	Local cFunction := ""
	Local cMenu     := ""
	Local cFuncId   := ""
	Local cMenuId   := ""
	Local cItemId   := ""
	Local cFather   := ""
	Local cDesc     := ""
	Local nStart    := 1
	Local nEnd      := 0

    // Blocos de 500 evitam o limite de itens do IN em diferentes SGBDs.
	While nStart <= Len(aPrograms)
		nEnd := Min(nStart + 499, Len(aPrograms))

		cQuery := " SELECT DISTINCT " + ;
			" RTRIM(F.F_FUNCTION) WM_PROG, " + ;
			" M.M_NAME WM_MENU, F.F_ID WM_FID, " + ;
			" M.M_ID WM_MID, I.I_ID WM_IID, " + ;
			" I.I_FATHER WM_FATHER, N.N_DESC WM_DESC " + ;
			" FROM MPMENU_FUNCTION F " + ;
			" INNER JOIN MPMENU_ITEM I ON " + ;
			" I.I_ID_FUNC = F.F_ID AND I.D_E_L_E_T_ <> '*' " + ;
			" INNER JOIN MPMENU_MENU M ON " + ;
			" M.M_ID = I.I_ID_MENU AND M.D_E_L_E_T_ <> '*' " + ;
			" LEFT JOIN MPMENU_I18N N ON " + ;
			" N.N_PAREN_TP = '2' AND N.N_PAREN_ID = I.I_ID " + ;
			" AND N.N_LANG = '1' AND N.D_E_L_E_T_ <> '*' " + ;
			" WHERE F.D_E_L_E_T_ <> '*' " + ;
			" AND UPPER(RTRIM(M.M_NAME)) NOT LIKE '#BKP_%' " + ;
			" AND UPPER(RTRIM(F.F_FUNCTION)) IN (" + ;
			WmSqlList(aPrograms, nStart, nEnd) + ") " + ;
			" ORDER BY WM_PROG, WM_MENU, WM_IID "

		cQuery := ChangeQuery(cQuery)
		cAlias := GetNextAlias()
		DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAlias, .T., .T.)

		While !(cAlias)->(EoF())
			cFunction := WmDbChar((cAlias)->WM_PROG)
			cMenu := WmDbChar((cAlias)->WM_MENU)
			cFuncId := WmDbChar((cAlias)->WM_FID)
			cMenuId := WmDbChar((cAlias)->WM_MID)
			cItemId := WmDbChar((cAlias)->WM_IID)
			cFather := WmDbChar((cAlias)->WM_FATHER)
			cDesc := WmDbChar((cAlias)->WM_DESC)
			cKey := Upper(cFuncId + "|" + cMenuId + "|" + cItemId)

			If AScan(aRows, {|x| ;
					Upper(x[5] + "|" + x[6] + "|" + x[7]) == cKey}) == 0
				AAdd(aRows, {.F., cFunction, cMenu, "", ;
					cFuncId, cMenuId, cItemId, cFather, cDesc})
			EndIf

			(cAlias)->(DbSkip())
		EndDo

		(cAlias)->(DbCloseArea())
		nStart := nEnd + 1
	EndDo

	RestArea(aArea)
Return aRows

/*/{Protheus.doc} WmBuildPath
Carrega os ancestrais em lotes e monta os caminhos com profundidade livre.
/*/
Static Function WmBuildPath(aRows)
	Local aCache   := {}
	Local aPending := {}
	Local aLoaded  := {}
	Local nRow     := 0
	Local nNode    := 0
	Local nLevel   := 0

	For nRow := 1 To Len(aRows)
		WmCachePut(@aCache, ;
			{aRows[nRow, 7], aRows[nRow, 8], ;
			aRows[nRow, 9], aRows[nRow, 6]})

		If !Empty(aRows[nRow, 8]) .And. ;
				Upper(aRows[nRow, 8]) != Upper(aRows[nRow, 6])
			WmAddUnique(@aPending, aRows[nRow, 8])
		EndIf
	Next nRow

    // O limite protege contra dados ciclicos ou hierarquias corrompidas.
	While !Empty(aPending) .And. nLevel < 30
		nLevel++
		aLoaded := WmQryNodes(aPending)
		ASize(aPending, 0)

		For nNode := 1 To Len(aLoaded)
			WmCachePut(@aCache, aLoaded[nNode])
		Next nNode

		For nNode := 1 To Len(aLoaded)
			If !Empty(aLoaded[nNode, 2]) .And. ;
					Upper(aLoaded[nNode, 2]) != Upper(aLoaded[nNode, 4]) .And. ;
					WmCachePos(aCache, aLoaded[nNode, 2], ;
					aLoaded[nNode, 4]) == 0
				WmAddUnique(@aPending, aLoaded[nNode, 2])
			EndIf
		Next nNode
	EndDo

	For nRow := 1 To Len(aRows)
		aRows[nRow, 4] := WmPath(aRows[nRow, 6], ;
			aRows[nRow, 7], aCache)
	Next nRow
Return Nil

/*/{Protheus.doc} WmQryNodes
Busca os itens ancestrais e suas descricoes em portugues.
/*/
Static Function WmQryNodes(aItemIds)
	Local aArea  := GetArea()
	Local aNodes := {}
	Local cAlias := ""
	Local cQuery := ""
	Local cItem  := ""
	Local cMenu  := ""
	Local cKey   := ""
	Local nStart := 1
	Local nEnd   := 0

	While nStart <= Len(aItemIds)
		nEnd := Min(nStart + 499, Len(aItemIds))
		cQuery := " SELECT DISTINCT " + ;
			" I.I_ID WM_IID, I.I_FATHER WM_FATHER, " + ;
			" N.N_DESC WM_DESC, I.I_ID_MENU WM_MID " + ;
			" FROM MPMENU_ITEM I " + ;
			" LEFT JOIN MPMENU_I18N N ON " + ;
			" N.N_PAREN_TP = '2' AND N.N_PAREN_ID = I.I_ID " + ;
			" AND N.N_LANG = '1' AND N.D_E_L_E_T_ <> '*' " + ;
			" WHERE I.D_E_L_E_T_ <> '*' AND I.I_ID IN (" + ;
			WmSqlList(aItemIds, nStart, nEnd) + ") "

		cQuery := ChangeQuery(cQuery)
		cAlias := GetNextAlias()
		DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAlias, .T., .T.)

		While !(cAlias)->(EoF())
			cItem := WmDbChar((cAlias)->WM_IID)
			cMenu := WmDbChar((cAlias)->WM_MID)
			cKey := Upper(cItem + "|" + cMenu)
			If AScan(aNodes, {|x| ;
					Upper(x[1] + "|" + x[4]) == cKey}) == 0
				AAdd(aNodes, {cItem, ;
					WmDbChar((cAlias)->WM_FATHER), ;
					WmDbChar((cAlias)->WM_DESC), ;
					cMenu})
			EndIf
			(cAlias)->(DbSkip())
		EndDo

		(cAlias)->(DbCloseArea())
		nStart := nEnd + 1
	EndDo

	RestArea(aArea)
Return aNodes

/*/{Protheus.doc} WmPath
Monta o caminho do item da raiz ate a ocorrencia selecionavel.
/*/
Static Function WmPath(cMenuId, cItemId, aCache)
	Local aParts   := {}
	Local aVisited := {}
	Local cCurrent := cItemId
	Local cDesc    := ""
	Local cPath    := ""
	Local nPos     := 0
	Local nPart    := 0
	Local nLevel   := 0

	While !Empty(cCurrent) .And. ;
			Upper(cCurrent) != Upper(cMenuId) .And. nLevel < 30
		nLevel++
		If AScan(aVisited, {|x| Upper(x) == Upper(cCurrent)}) > 0
			Exit
		EndIf
		AAdd(aVisited, cCurrent)

		nPos := WmCachePos(aCache, cCurrent, cMenuId)
		If nPos == 0
			Exit
		EndIf

		cDesc := StrTran(AllTrim(aCache[nPos, 3]), "&", "")
		If !Empty(cDesc)
			AAdd(aParts, cDesc)
		EndIf

		If Upper(cCurrent) == Upper(aCache[nPos, 2])
			Exit
		EndIf
		cCurrent := aCache[nPos, 2]
	EndDo

	For nPart := Len(aParts) To 1 Step -1
		If !Empty(cPath)
			cPath += " > "
		EndIf
		cPath += aParts[nPart]
	Next nPart

	If Empty(cPath)
		cPath := "(localizacao nao encontrada)"
	EndIf
Return cPath

/*/{Protheus.doc} WmCachePut
Inclui ou complementa um item no cache de hierarquia.
/*/
Static Function WmCachePut(aCache, aNode)
	Local nPos := WmCachePos(aCache, aNode[1], aNode[4])

	If nPos == 0
		AAdd(aCache, aNode)
	ElseIf Empty(aCache[nPos, 3]) .And. !Empty(aNode[3])
		aCache[nPos] := aNode
	EndIf
Return Nil

/*/{Protheus.doc} WmCachePos
Retorna a posicao de um item no cache de hierarquia.
/*/
Static Function WmCachePos(aCache, cItemId, cMenuId)
Return AScan(aCache, {|x| ;
	Upper(x[1]) == Upper(AllTrim(cItemId)) .And. ;
	Upper(x[4]) == Upper(AllTrim(cMenuId))})

/*/{Protheus.doc} WmSqlList
Monta uma lista de literais SQL escapados para uso em clausula IN.
/*/
Static Function WmSqlList(aValues, nStart, nEnd)
	Local cList  := ""
	Local cValue := ""
	Local nValue := 0

	For nValue := nStart To nEnd
		cValue := StrTran(AllTrim(aValues[nValue]), "'", "''")
		If !Empty(cList)
			cList += ","
		EndIf
		cList += "'" + cValue + "'"
	Next nValue
Return cList

/*/{Protheus.doc} WmDbChar
Converte valores retornados pela query para caractere sem espacos laterais.
/*/
Static Function WmDbChar(uValue)
	If ValType(uValue) == "C"
		Return AllTrim(uValue)
	ElseIf ValType(uValue) == "U"
		Return ""
	EndIf
Return AllTrim(cValToChar(uValue))

/*/{Protheus.doc} WmAddUnique
Adiciona um valor nao vazio a um array sem duplicidade de caixa.
/*/
Static Function WmAddUnique(aValues, cValue)
	Local cText    := AllTrim(cValue)
	Local cCompare := Upper(cText)

	If !Empty(cText) .And. ;
			AScan(aValues, {|x| Upper(AllTrim(x)) == cCompare}) == 0
		AAdd(aValues, cText)
	EndIf
Return Nil

/*/{Protheus.doc} WmMarkBmp
Retorna a imagem de checkbox correspondente a linha atual.
/*/
Static Function WmMarkBmp(aMenus, oBrowse)
	Local nAt := WmBrwAt(aMenus, oBrowse)

	If nAt > 0 .And. aMenus[nAt, 1]
		Return "LBOK"
	EndIf
Return "LBNO"

/*/{Protheus.doc} WmToggle
Inverte a selecao da linha atual do browse.
/*/
Static Function WmToggle(aMenus, oBrowse)
	Local nAt := WmBrwAt(aMenus, oBrowse)

	If nAt > 0
		aMenus[nAt, 1] := !aMenus[nAt, 1]
		oBrowse:Refresh()
	EndIf
Return .T.

/*/{Protheus.doc} WmSetSel
Seleciona, deseleciona ou inverte todas as linhas do browse.
/*/
Static Function WmSetSel(aMenus, oBrowse, nAction)
	Local nRow := 0

	For nRow := 1 To Len(aMenus)
		Do Case
		Case nAction == 1
			aMenus[nRow, 1] := .T.
		Case nAction == 2
			aMenus[nRow, 1] := .F.
		Otherwise
			aMenus[nRow, 1] := !aMenus[nRow, 1]
		EndCase
	Next nRow

	If ValType(oBrowse) == "O"
		oBrowse:Refresh(.T.)
	EndIf
Return .T.

/*/{Protheus.doc} WmBrwVal
Retorna uma coluna da linha atual sem acessar posicoes invalidas.
/*/
Static Function WmBrwVal(aMenus, oBrowse, nColumn)
	Local nAt := WmBrwAt(aMenus, oBrowse)

	If nAt > 0
		Return aMenus[nAt, nColumn]
	EndIf
Return ""

/*/{Protheus.doc} WmBrwAt
Valida e retorna a posicao atual do browse.
/*/
Static Function WmBrwAt(aMenus, oBrowse)
	Local nAt := 0

	If ValType(oBrowse) == "O"
		nAt := oBrowse:At()
	EndIf

	If nAt < 1 .Or. nAt > Len(aMenus)
		nAt := 0
	EndIf
Return nAt

/*/{Protheus.doc} WmRefBrw
Substitui os dados e redesenha o browse do terceiro passo.
/*/
Static Function WmRefBrw(aMenus, oBrowse)
	If ValType(oBrowse) == "O"
		oBrowse:SetArray(aMenus)
		oBrowse:Refresh(.T.)
	EndIf
Return Nil

/*/{Protheus.doc} WmValOrig
Valida a origem escolhida antes de permitir o avanco do wizard.
/*/
Static Function WmValOrig(lReadFile, lManual, cFilePath, cProgram)
	Local cPath := AllTrim(cFilePath)
	Local cFunc := AllTrim(cProgram)

	If lReadFile == lManual
		MsgStop("Selecione somente uma origem: arquivo ou programa manual.", ;
			"Origem da pesquisa")
		Return .F.
	EndIf

	If lReadFile
		If Empty(cPath)
			MsgStop("Informe ou selecione o arquivo CSV/_contents.txt.", ;
                "Arquivo obrigatorio")
			Return .F.
		EndIf

        // nWhere = 0: caminho absoluto e verificado no SmartClient.
		If !File(cPath, 0, .F.)
            MsgStop("O arquivo informado nao foi encontrado:" + CRLF + cPath, ;
				"Arquivo inexistente")
			Return .F.
		EndIf
	Else
		If Empty(cFunc)
            MsgStop("Informe o nome do programa ou funcao.", ;
                "Programa obrigatorio")
			Return .F.
		EndIf

		If !WmHasFunc(cFunc)
            MsgStop("O programa informado nao esta disponivel no RPO atual:" + ;
                CRLF + Upper(cFunc), "Programa nao encontrado")
			Return .F.
		EndIf
	EndIf
Return .T.

/*/{Protheus.doc} WmHasFunc
Verifica se a funcao informada esta disponivel no RPO atual.
/*/
Static Function WmHasFunc(cProgram)
Return !Empty(WmResolve(cProgram))

/*/{Protheus.doc} WmResolve
Retorna o simbolo efetivamente publicado no RPO.
/*/
Static Function WmResolve(cProgram)
	Local cFunction := WmNormProg(cProgram)

	If Empty(cFunction)
		Return ""
	EndIf

	If FindFunction(cFunction, .T.)
		Return cFunction
	EndIf

    // User Function TESTE() e publicada no RPO como U_TESTE.
	If Left(cFunction, 2) != "U_" .And. ;
			FindFunction("U_" + cFunction, .T.)
		Return "U_" + cFunction
	EndIf
Return ""
