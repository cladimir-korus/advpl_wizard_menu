# WIZMENU — Assistente de Atualização de Menus

Assistente em AdvPL para localizar referências de programas em múltiplos menus do TOTVS Protheus e, futuramente, permitir a alteração controlada das ocorrências selecionadas.

O projeto é desenvolvido pela Korus Consultoria com a proposta de distribuição gratuita do código original.

> **Status: em desenvolvimento.** A versão atual implementa a interface inicial e a validação da origem da pesquisa. A leitura dos arquivos, a pesquisa nos menus, o backup e a atualização das tabelas ainda não foram implementados.

## Funcionalidades disponíveis

- Inicialização do ambiente do Configurador (`SIGACFG`).
- Interface em etapas baseada em `FWWizardControl`.
- Tela de apresentação do assistente.
- Escolha mutuamente exclusiva entre duas origens:
  - arquivo CSV ou `_contents.txt`;
  - programa ou função informada manualmente.
- Seleção de arquivo local ou localizado em unidade de rede pelo SmartClient.
- Validação da existência do arquivo informado.
- Validação do programa no RPO atual por meio de `FindFunction()`.
- Reconhecimento do nome com ou sem a extensão `.PRW` e tentativa automática com o prefixo `U_`.

## Funcionalidades planejadas

- Definir e documentar o formato aceito para CSV e `_contents.txt`.
- Ler e normalizar os programas encontrados no arquivo.
- Pesquisar ocorrências nas tabelas de menus.
- Exibir os menus e itens encontrados para seleção.
- Informar a nova referência que substituirá o programa atual.
- Gerar backup completo antes da alteração.
- Atualizar somente as ocorrências confirmadas.
- Executar as alterações de forma transacional.
- Registrar as mudanças e oferecer um procedimento de restauração.

## Fluxo atual

```text
U_UWIZMENU
└─ prepara o ambiente SIGACFG
   └─ executa U_WIZMENU
      ├─ Passo 1: apresentação
      └─ Passo 2: seleção e validação da origem
```

`UWizMenu()` funciona como inicializador. A rotina principal do assistente é `WIZMENU()`, publicada no RPO como `U_WIZMENU`.

## Requisitos

- Ambiente TOTVS Protheus devidamente licenciado.
- AppServer, SmartClient e RPO acessíveis.
- Ambiente de compilação AdvPL com os includes `Protheus.ch` e `Totvs.ch`.
- Framework compatível com `FWWizardControl`, disponível na documentação da TOTVS a partir da release 12.1.6.
- Permissão do SmartClient para acessar o arquivo local ou a unidade de rede selecionada.

Para as funcionalidades futuras de alteração, também serão necessários acesso autorizado às tabelas de menus, ambiente de homologação e uma estratégia de backup validada.

## Instalação e execução

1. Adicione `WIZMENU.prw` ao workspace AdvPL.
2. Compile o fonte no RPO do ambiente desejado.
3. Execute `U_UWIZMENU` para criar o ambiente `SIGACFG` e abrir o assistente.
4. Em um ambiente já preparado, a rotina principal pode ser chamada por `U_WIZMENU`.
5. Escolha exatamente uma origem e avance para validar a entrada.

Nesta versão, o processamento termina após a validação da origem. Nenhuma tabela é consultada ou alterada.

## Origens da pesquisa

### Arquivo

O seletor aceita:

- `*.csv`;
- `*_contents.txt`.

O caminho absoluto é validado no SmartClient. O esquema do CSV e a leitura efetiva dos arquivos ainda fazem parte do roadmap.

### Programa informado manualmente

O nome é normalizado em maiúsculas e pode ser informado com ou sem `.PRW`. A rotina verifica sua disponibilidade no RPO atual e, quando necessário, também procura a variante com o prefixo `U_`.

## Modelo de dados dos menus

O planejamento da ferramenta considera as seguintes tabelas de infraestrutura:

| Tabela | Papel no modelo |
| --- | --- |
| `MPMENU_MENU` | Identificação do menu, módulo e arquivo XNU. |
| `MPMENU_ITEM` | Itens, propriedades e hierarquia dos menus. |
| `MPMENU_FUNCTION` | Programas e funções associados aos itens. |
| `MPMENU_I18N` | Descrições e traduções de menus e itens. |
| `MPMENU_KEY_WORDS` | Palavras-chave opcionais de pesquisa. |
| `MPMENU_RESERVED_WORD` | Dados auxiliares relacionados aos idiomas. |

Relacionamentos principais observados:

- `MPMENU_ITEM.I_ID_MENU` → `MPMENU_MENU.M_ID`;
- `MPMENU_ITEM.I_FATHER` → item pai em `MPMENU_ITEM.I_ID`;
- `MPMENU_ITEM.I_ID_FUNC` → `MPMENU_FUNCTION.F_ID`;
- `MPMENU_I18N.N_PAREN_ID` → menu ou item, conforme `N_PAREN_TP`;
- `MPMENU_KEY_WORDS.K_ID_ITEM` → `MPMENU_ITEM.I_ID`.

A estrutura pode variar entre releases. Antes de implementar qualquer atualização direta, valide o dicionário do ambiente, ignore registros logicamente excluídos (`D_E_L_E_T_ = '*'`) e evite incluir menus de backup (`#BKP_%`) nos resultados normais.

## Segurança operacional

Alterações diretas nas tabelas de menu podem afetar o acesso dos usuários e a inicialização de rotinas. Quando essa etapa for implementada:

- valide primeiro em ambiente de homologação;
- mantenha backup externo e testado;
- use uma conta com somente as permissões necessárias;
- revise todas as ocorrências antes de confirmar;
- não interrompa a transação durante a atualização;
- valide o resultado no Configurador e no SmartClient.

## Arquivos do projeto

| Arquivo | Descrição |
| --- | --- |
| `WIZMENU.prw` | Fonte AdvPL do assistente. |
| `tabelas.rpt` | Exportação usada durante o estudo do modelo de menus; não é dependência de execução. |

### Atenção sobre `tabelas.rpt`

O relatório contém metadados extraídos de um ambiente Protheus, incluindo funções, traduções, hierarquia, caminhos XNU e menus de backup. Ele não deve fazer parte de uma distribuição pública até que sua procedência, titularidade e autorização de redistribuição tenham sido confirmadas. A licença do código original não concede direitos sobre dados ou materiais de terceiros.

## Referências técnicas

- [FWWizardControl — TOTVS TDN](https://tdn.totvs.com/display/framework/FWWizardControl)
- [cGetFile — TOTVS TDN](https://tdn.totvs.com/display/tec/cGetFile)
- [FindFunction — TOTVS TDN](https://tdn.totvs.com/display/tec/Findfunction)
- [Configurando Menus — TOTVS TDN](https://tdn.totvs.com/pages/viewpage.action?pageId=306855041)

## Aviso

O software é fornecido sem garantias. Faça testes completos e obtenha as autorizações técnicas e contratuais necessárias antes de utilizá-lo em um ambiente de produção.
