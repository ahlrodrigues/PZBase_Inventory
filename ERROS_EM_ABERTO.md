# Erros em aberto (v0.2.19)

Registro dos problemas reportados em jogo, para tratar depois. Nenhum foi corrigido ainda.

## 1. Casinha no canto errado

- **Esperado:** logo abaixo do botão do chaveiro, na coluna da direita do inventário do personagem.
- **Observado:** no canto inferior esquerdo.
- **Hipótese:** `keyringButton(page)` não encontrou o chaveiro em `page.backpacks` (ou a coluna ainda não existia quando o botão foi criado), e o código caiu no fallback do canto.
- **Onde:** `client/PZBI/BasesWindow.lua` (`keyringButton`, `ensureButton`).

## 2. Clique na casinha abre outra janela

- **Esperado:** tudo na mesma janela do inventário do personagem.
- **Observado:** abre uma janela separada com a lista dos itens das bases.
- **Onde:** `client/PZBI/BasesWindow.lua` (`openList`).

## 3. Contêineres da área não abrem automaticamente

- **Esperado (pelo relato):** ao estar perto da base, os contêineres dela são lidos como no Proximity Inventory.
- **Observado no log:** há leituras automáticas, com instantâneos "primeira leitura" para vários contêineres dentro da área (linhas 15 a 128 do log). Ou seja, a leitura por proximidade aconteceu, mas não aparece para o jogador como "abrir".
- **Ponto a esclarecer:** o que o jogador espera ver ao se aproximar: só a leitura (sem abrir nada) ou o contêiner aberto na tela?
- **Onde:** `client/PZBI/BaseProximity.lua`.

## 4. Itens dos contêineres não aparecem no inventário do personagem

- **Esperado:** os itens lidos aparecem no inventário do personagem e persistem.
- **Observado:** não aparecem no inventário do personagem nem na janela separada.
- **Hipótese:** a lista é montada só quando a janela de itens é aberta (`buildItemContainer`), e não há integração com o inventário do personagem. Ainda falta decidir o formato dessa exibição.
- **Onde:** `client/PZBI/BasesWindow.lua` (`buildItemContainer`, `openList`).

## 5. Layout da casinha

- **Esperado:** visual de acordo com os botões do jogo.
- **Observado:** a casinha desenhada com retângulos está feia.
- **Ação:** trocar por um ícone que siga o estilo dos botões do jogo (textura ou fonte do próprio jogo).
- **Onde:** `client/PZBI/BasesWindow.lua` (`drawHouse`).

## Ruído no log (fora do mod)

- `ERROR ... handleMannequinZone` e os avisos `can't find map objects file` são do próprio jogo e de mapas; não vêm do PZBase Inventory.
