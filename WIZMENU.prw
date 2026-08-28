#Include "Protheus.ch"
#Include "Totvs.ch"

/*/{Protheus.doc} UWizMenu
Inicializa o ambiente do Configurador e executa o Wizard de Menus.

@type  User Function
@since 26/08/2026
/*/
User Function UWizMenu()
    Private oApp := MsApp():New("SIGACFG")

    oApp:CreateEnv()
    PtSetTheme("OCEAN")

    oApp:cStartProg := "U_WIZMENU"
    __lInternet := .T.

    oApp:Activate()
Return Nil

/*/{Protheus.doc} WIZMENU
Rotina principal do assistente de alteração de menus.

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

    oWizard := FWWizardControl():New(Nil, {650, 900})
    oWizard:ActiveUISteps()

    // Passo 1 - Apresentação
    oStep := oWizard:AddStep("INTRO", {|oPanel| WmIntro(oPanel)})
    oStep:SetStepDescription("Apresentação")
    oStep:SetNextTitle("Avançar")
    oStep:SetNextAction({|| .T.})
    oStep:SetCancelAction({|| .T.})

    // Passo 2 - Definição da origem da pesquisa
    oStep := oWizard:AddStep("ORIGIN", ;
        {|oPanel| WmOrigin(oPanel, @lReadFile, @lManual, ;
            @cFilePath, @cProgram)})
    oStep:SetStepDescription("Origem da pesquisa")
    oStep:SetNextTitle("Avançar")
    oStep:SetPrevTitle("Voltar")
    oStep:SetNextAction({|| WmValOrig(lReadFile, lManual, ;
        cFilePath, cProgram)})
    oStep:SetPrevAction({|| .T.})
    oStep:SetCancelAction({|| .T.})

    oWizard:Activate()
    oWizard:Destroy()
Return Nil

/*/{Protheus.doc} WmIntro
Constrói o passo de apresentação do assistente.

@type  Static Function
@param oPanel, object, painel disponibilizado pelo FWWizardControl
/*/
Static Function WmIntro(oPanel)
    Local oSay       := Nil
    Local oFontTitle := TFont():New("Arial",, -22, .T.)
    Local oFontBody  := TFont():New("Arial",, -14, .F.)
    Local oFontBold  := TFont():New("Arial",, -14, .T.)
    Local nWidth     := Max(400, oPanel:nClientWidth - 40)

    oSay := TSay():New(15, 20, ;
        {|| "Bem-vindo ao Assistente de Atualização de Menus"}, ;
        oPanel,, oFontTitle,,,, .T., CLR_BLUE,, nWidth, 30)
    oSay:lWordWrap := .T.

    oSay := TSay():New(55, 20, ;
        {|| "Esta ferramenta localiza e altera referências em múltiplos " + ;
            "menus do TOTVS Protheus de forma rápida, centralizada e " + ;
            "controlada."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, nWidth, 45)
    oSay:lWordWrap := .T.

    oSay := TSay():New(110, 20, ;
        {|| "A pesquisa pode partir de um arquivo CSV, de um arquivo " + ;
            "_contents.txt ou do nome de um programa informado " + ;
            "manualmente. Todas as ocorrências encontradas serão " + ;
            "apresentadas para seleção antes da alteração."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, nWidth, 65)
    oSay:lWordWrap := .T.

    oSay := TSay():New(185, 20, ;
        {|| "Tabelas de infraestrutura envolvidas:"}, ;
        oPanel,, oFontBold,,,, .T., CLR_BLACK,, nWidth, 20)

    oSay := TSay():New(210, 35, ;
        {|| "MPMENU_MENU - identificação e dados gerais dos menus" + CRLF + ;
            "MPMENU_ITEM - estrutura, hierarquia e propriedades dos itens" + CRLF + ;
            "MPMENU_FUNCTION - programas e funções associados aos itens" + CRLF + ;
            "MPMENU_I18N - descrições e traduções dos menus" + CRLF + ;
            "MPMENU_KEY_WORDS - palavras-chave de pesquisa, quando aplicável"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, nWidth - 15, 105)
    oSay:lWordWrap := .T.

    oSay := TSay():New(325, 20, ;
        {|| "Antes do processamento, será oferecida a opção de gerar um " + ;
            "backup completo das tabelas envolvidas, proporcionando " + ;
            "rastreabilidade e possibilidade de restauração."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, nWidth, 55)
    oSay:lWordWrap := .T.

    oSay := TSay():New(390, 20, ;
        {|| "Revise atentamente as ocorrências selecionadas antes de " + ;
            "confirmar qualquer atualização."}, ;
        oPanel,, oFontBold,,,, .T., CLR_BLACK,, nWidth, 35)
    oSay:lWordWrap := .T.

    oSay := TSay():New(450, 20, ;
        {|| "Desenvolvido pela Korus Consultoria e distribuído gratuitamente."}, ;
        oPanel,, oFontBold,,,, .T., CLR_BLUE,, nWidth, 25)
    oSay:lWordWrap := .T.
Return Nil

/*/{Protheus.doc} WmOrigin
Constrói o passo de escolha da origem da pesquisa.

@type  Static Function
@param oPanel, object, painel disponibilizado pelo FWWizardControl
@param lReadFile, logical, indica leitura de CSV ou _contents.txt
@param lManual, logical, indica informação manual do programa
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
    Local oFontTitle   := TFont():New("Arial",, -18, .T.)
    Local oFontBody    := TFont():New("Arial",, -14, .F.)
    Local nPanelWidth  := Max(500, oPanel:nClientWidth)
    Local nGetWidth    := Max(280, nPanelWidth - 220)
    Local nButtonLeft  := nPanelWidth - 150

    oSay := TSay():New(15, 20, ;
        {|| "Selecione a origem das informações"}, ;
        oPanel,, oFontTitle,,,, .T., CLR_BLUE,, nPanelWidth - 40, 25)

    oSay := TSay():New(42, 20, ;
        {|| "Escolha somente uma das opções abaixo."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, nPanelWidth - 40, 20)

    oCheckFile := TCheckBox():New(75, 20, ;
        "01 Ler arquivo CSV ou _contents.txt", ;
        bSetGet(lReadFile), oPanel, nPanelWidth - 40, 20, ;
        ,,,,,,,, .T.,,,)

    oSay := TSay():New(105, 40, {|| "Caminho do arquivo:"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 250, 20)

    @ 128, 40 GET oGetFile VAR cFilePath ;
        SIZE nGetWidth, 20 OF oPanel PIXEL

    oButton := TButton():New(128, nButtonLeft, "Selecionar...", ;
        oPanel, ;
        {|| WmSelFile(@cFilePath, oGetFile, @lReadFile, @lManual, ;
            oCheckFile, oCheckManual)}, ;
        120, 20,,,.F.,.T.,.F.,,.F.,,,.F.)

    oCheckManual := TCheckBox():New(190, 20, ;
        "02 Informar programa manualmente", ;
        bSetGet(lManual), oPanel, nPanelWidth - 40, 20, ;
        ,,,,,,,, .T.,,,)

    oSay := TSay():New(220, 40, {|| "Nome do programa ou função:"}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, 280, 20)

    @ 243, 40 GET oGetProgram VAR cProgram PICTURE "@!" ;
        SIZE 360, 20 OF oPanel PIXEL

    oSay := TSay():New(295, 20, ;
        {|| "Validações ao avançar:" + CRLF + ;
            "- Para a opção 01, o arquivo informado deve existir." + CRLF + ;
            "- Para a opção 02, o programa deve estar compilado no RPO atual."}, ;
        oPanel,, oFontBody,,,, .T., CLR_BLACK,, nPanelWidth - 40, 65)
    oSay:lWordWrap := .T.

    oCheckFile:bLClicked := ;
        {|| WmCheck(1, @lReadFile, @lManual, oCheckFile, oCheckManual)}
    oCheckManual:bLClicked := ;
        {|| WmCheck(2, @lReadFile, @lManual, oCheckFile, oCheckManual)}
Return Nil

/*/{Protheus.doc} WmCheck
Mantém as duas caixas de seleção mutuamente exclusivas.
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
                "Arquivo obrigatório")
            Return .F.
        EndIf

        // nWhere = 0: caminho absoluto é verificado no SmartClient.
        If !File(cPath, 0, .F.)
            MsgStop("O arquivo informado não foi encontrado:" + CRLF + cPath, ;
                "Arquivo inexistente")
            Return .F.
        EndIf
    Else
        If Empty(cFunc)
            MsgStop("Informe o nome do programa ou função.", ;
                "Programa obrigatório")
            Return .F.
        EndIf

        If !WmHasFunc(cFunc)
            MsgStop("O programa informado não está disponível no RPO atual:" + ;
                CRLF + Upper(cFunc), "Programa não encontrado")
            Return .F.
        EndIf
    EndIf
Return .T.

/*/{Protheus.doc} WmHasFunc
Verifica se a função informada está disponível no RPO atual.
/*/
Static Function WmHasFunc(cProgram)
    Local cFunction := Upper(AllTrim(cProgram))
    Local lFound    := .F.

    If Upper(Right(cFunction, 4)) == ".PRW"
        cFunction := Left(cFunction, Len(cFunction) - 4)
    EndIf

    If Empty(cFunction)
        Return .F.
    EndIf

    lFound := FindFunction(cFunction, .T.)

    // User Function TESTE() é publicada no RPO como U_TESTE.
    If !lFound .And. Left(cFunction, 2) != "U_"
        lFound := FindFunction("U_" + cFunction, .T.)
    EndIf
Return lFound
