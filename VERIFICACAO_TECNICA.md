# PZBase Inventory: verificação técnica dos pontos "a confirmar"

Fonte: código Lua da instalação local do Project Zomboid (Build 42), em
`steamapps/common/ProjectZomboid/projectzomboid/media/lua`.

Legenda: **Confirmado** = existe e é usado no código do jogo. **Parcial** = existe, mas falta validar em jogo. **Não encontrado** = sem API localizada no Lua.

## Resultados

| # | Ponto (especificação, seção 10) | Status | Evidência | Decisão para implementação |
|---|---|---|---|---|
| 1 | Evento de fechar contêiner | **Parcial** | Não há evento global. O fechamento é o método `ISInventoryPage:close()` (`client/ISUI/ISInventoryPage.lua:720`). | Envolver (wrap) `ISInventoryPage.close` no cliente e ler o conteúdo ao fechar. |
| 2 | Ler conteúdo de contêiner | **Confirmado** | `container:getItems()` (`ISInventoryPage.lua:1393`); `vehiclePart:getItemContainer():getItems()` (`:1592`). | Usar `getItems()` do `ItemContainer`. |
| 3 | Identidade de objeto de contêiner | **Parcial** | Coordenadas via `getSourceGrid()` e `container:getSourceGrid()` (usado em `SpawnRateChecker.lua:70`). Tipo do objeto ainda a confirmar. | Chave = `x,y,z` + tipo do objeto. Validar o nome do tipo em jogo. |
| 4 | Identificador de veículo | **Confirmado** (base) | `vehicle:getId()` e `getVehicleById(id)` são usados em comandos de servidor (`server/Vehicles/VehicleCommands.lua`). | Identificar carro por `getId()`. |
| 5 | Identificador muda ao guardar/mover | **Não confirmado** | Nenhum código de "guardar" veículo localizado. | Validar em jogo antes de fechar a seção 4. |
| 6 | Criar zonas próprias | **Não encontrado** | Só leitura: `getWorld():getMetaGrid():getZonesAt(...)`. Não há criação de zona no Lua. | Desenhar o contorno da base por conta própria (opção já prevista na especificação). |
| 7 | Sincronização de ModData | **Parcial** | `ModData.getOrCreate(nome)`, `ModData.get(nome)`, `ModData.transmit(nome)` (ex.: `client/Foraging/forageClient.lua`); `Events.OnInitGlobalModData`. Não há uso de recebimento de ModData no Lua vanilla. | Prototipar a sincronização. Dividir dados por base e por contêiner, como previsto. |
| 8 | Último login no servidor | **Não encontrado** | Nenhuma API de último login no Lua. | Registrar um "visto por último" próprio do mod, enviado pelo cliente e validado pelo servidor. Fica a confirmar o evento de entrada. |
| 9 | Comunicação cliente → servidor | **Confirmado** | `sendClientCommand(player, módulo, comando, args)` no cliente; `Events.OnClientCommand` no servidor (`server/ClientCommands.lua`). | Usar esse canal para todos os pedidos. Servidor valida tudo. |
| 10 | Estrutura de pastas | **Confirmado** | Mod de exemplo instalado: `42/mod.info`, `42/media/lua/...` (`~/Zomboid/mods/PZBackup`). | Estrutura `42/` com `shared/`, `client/` e `server/`. |

## Pontos ainda abertos (validar em jogo)

- Evento de entrada do jogador (para o item 8).
- Identificador de veículo ao guardar/mover (item 5).
- Se o `ModData` chega ao cliente sem `ModData.request` explícito (item 7).
- Limite de distância para aceitar instantâneos (especificação, seção 8, "a confirmar").

## Próximo passo

Protótipo mínimo: (a) hook em `ISInventoryPage.close` que lê o contêiner e envia ao servidor; (b) servidor grava o instantâneo no ModData; (c) teste de sincronização entre dois jogadores.

## Estado do protótipo (v0.1.0)

Arquivos:
- `42/media/lua/client/PZBI/ContainerSnapshot.lua`: envolve `ISInventoryPage:close()` e envia o conteúdo do contêiner ao servidor.
- `42/media/lua/server/PZBI/SnapshotServer.lua`: valida o pedido, compara com o estado anterior, grava em ModData separado por contêiner e chama `ModData.transmit`.
- `42/media/lua/shared/PZBI/Config.lua`: constantes.

Verificação feita: sintaxe Lua checada com `luac -p` nos três arquivos (sem erros).

Ainda não feito: teste em jogo. Pontos que dependem do jogo e precisam de validação:
- `container:getSourceGrid()` e `container:getParent()` retornam a posição e o objeto corretos para contêineres de mundo (o código atual ignora contêineres sem posição, como o de veículo e o inventário do jogador).
- Nome do tipo do objeto via `getObjectName()`.
- Recebimento do ModData no cliente sem `ModData.request` explícito (item 7).
- Limites de sanidade (500 tipos, 10.000 por item) são palpites iniciais.

## Status das APIs usadas pelas funcionalidades novas (v0.2.18)

A instalação do jogo base não está nesta máquina; só estão disponíveis mods do Workshop (ProximityInventory, CleanUI). Por isso, nenhuma linha de código do jogo base foi citada como conferida. Os trechos abaixo vêm do mod ProximityInventory, que usa as mesmas chamadas, e da verificação em jogo registrada em TESTES.md.

| API | Onde aparece no mod | Fonte | Situação |
|---|---|---|---|
| `ISInventoryPage:new`, `setVisible`, `initialise`, `addToUIManager` | `client/PZBI/BasesWindow.lua`, `ContainerSnapshot.lua` | ProximityInventory (`client/ProximityInventory/ISInventoryPage.lua`) | Usada pelo outro mod; no PZBI, não testada em jogo (teste 20) |
| `ItemContainer.new(tipo, nil, nil)` + `setExplored(true)` | `BasesWindow.lua` | ProximityInventory (`ProximityInventory.lua`) | Usada pelo outro mod; no PZBI, não testada (teste 20) |
| `setOnlyAcceptCategory("none")`, `setCapacity(0)`, `instanceItem`, `AddItem` | `BasesWindow.lua` | Não localizados nos mods disponíveis | Não confirmada; teste 20 |
| `getCell():getGridSquare`, `sq:getObjects()`, `obj:getContainer()` | `BasesWindow.lua` (varredura) | ProximityInventory (`BaseInv.findOriginContainer`) | Usada pelo outro mod; PZBI não testada (teste 20) |
| `setHighlighted(player, on, false)`, `setHighlightColor`, `setOutlineHighlight` | `BasesWindow.lua` (destaque) | ProximityInventory (`setHighlighted`/`setHighlightColor`) | Usada pelo outro mod; PZBI não testada (teste 20) |
| `ScriptManager.instance:getItem`, `getActualWeight`, `getDisplayCategory` | `PlayerPanel.lua` (dentro de `pcall`) | Não localizados | Não confirmada; teste 14 |
| `ISScrollingListBox` (`addItem`, `setOnMouseDownFunction`) | `PlayerPanel.lua` | Não localizado | Não confirmada; teste 16 |
| `ISRichTextPanel`, `ISTextEntryBox:getText` | Painel e janela de nome | Não localizados | Não confirmada; testes 14 e 15 |
| `getFileWriter(name, true, false)` | Exportação do painel | Não localizado | Não confirmada; teste 14 |
| `getTimestampMs()` | Registro de criação e de atividade | Usado desde v0.2.5 | Confirmada em jogo (teste 10, com 0,001 dia) |

Antes de dar essas APIs como confirmadas, conferir os itens "Não confirmada" nos testes 14 a 16 e 20 e atualizar esta tabela com o resultado.
