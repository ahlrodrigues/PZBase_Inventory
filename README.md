# PZBase Inventory

Mod de qualidade de vida para **Project Zomboid (Build 42)**. Lista os itens da mochila, dos contêineres de mundo e das bases marcadas pelo jogador, sem precisar abrir cada contêiner.

**Versão atual:** 0.2.13 (`42/mod.info`)
**Escopo atual:** single player. Multijogador está planejado, mas adiado (ver `TESTES_MULTIJOGADOR.md`).

## Funcionalidades

| Seção da especificação | Recurso | Versão | Status |
|---|---|---|---|
| 2 | Marcar base arrastando no chão, com nome da cidade | 0.1.x–0.2.x | Criar e apagar validados em jogo |
| 2 | Ver bases marcadas | 0.2.0 | Validado em jogo (teste 8) |
| 2 | Editar a própria base | — | Não iniciado |
| 3 | Snapshot de contêineres ao fechar a janela | 0.1.x | Validado em jogo (teste 4) |
| 3 | Inscrição em contêiner dentro da base (direta ou com pedido) | 0.2.6, 0.2.15 | Não testado em jogo (teste 11) |
| 3 | Dono aprova ou recusa pedidos | 0.2.8 | Não testado em jogo (teste 12) |
| 3 | Aviso de pedidos pendentes ao entrar | 0.2.9 | Não testado em jogo (teste 13) |
| 3 | Contêiner marcado como "removido" | — | Não iniciado |
| 4 | Carro (veículo) | — | Não iniciado |
| 5 | Notificar inscritos quando o contêiner muda | — | Não iniciado |
| 6 | Inatividade do dono: base removida após N dias sem login | 0.2.4–0.2.5 | Validado em jogo (teste 10, com 0.001 dia) |
| 7 | Painel do jogador: contêineres, itens por categoria, peso, busca, ordenação, exportação | 0.2.10–0.2.13 | Não testado em jogo (testes 14 a 16) |
| 7 | Botão "Bases" no inventário do personagem: lista os itens das bases (filtro por base) na janela padrão; duplo clique varre os contêineres carregados perto do personagem e os destaca | 0.2.17 | Não testado em jogo (teste 20) |
| — | Menus e textos em pt-BR e en (`IG_UI.json`) | 0.2.7 | Confirmação de carregamento pendente |

### Painel do jogador (seção 7)

- **Coluna esquerda:** botão "Todos os contêineres juntos" e uma barra vertical com todos os contêineres a que você tem acesso (dono da base ou inscrito). Clicar num contêiner filtra a coluna da direita. Abaixo, os detalhes de estado da inscrição e data do último instantâneo.
- **Coluna direita:** itens agrupados por categoria, com quantidade e peso. Campo de busca por nome e ordenação por nome ou quantidade.
- **Mochila:** entra no painel como local "Mochila".
- **Exportação:** grava a lista completa em `Zomboid/Lua/PZBI_inventario.txt`.

## Estrutura

```
42/
  mod.info
  media/lua/
    shared/PZBI/        regras puras e configuração (Config, BaseRules, InactivityRules,
                        ContainerRules, PlayerPanelRules)
    shared/Translate/   textos (EN e PTBR, IG_UI.json)
    client/PZBI/        interface: menu, criação de base, visualização, painel, snapshot, aviso de login
    server/PZBI/        validação e gravação: bases, instantâneos, inscrições, inatividade
tests/                  testes das regras puras, fora do jogo
TESTES.md               roteiro de testes em jogo (1 a 16)
TESTES_MULTIJOGADOR.md  plano de testes multijogador (adiado)
ESPECIFICACAO.md        especificação funcional
VERIFICACAO_TECNICA.md  verificação das APIs do jogo usadas
```

As regras que não dependem da API do jogo ficam em `shared/PZBI/` e são testadas com o interpretador Lua instalado no sistema.

## Testes

Fora do jogo, a partir da raiz do repositório:

```sh
lua tests/base_rules_test.lua
lua tests/inactivity_rules_test.lua
lua tests/container_rules_test.lua
lua tests/player_panel_rules_test.lua
```

Estado atual: 16, 7, 18 e 29 casos, todos passando.

Dentro do jogo, siga o `TESTES.md`. Para o teste de inatividade, use `PZBI.INACTIVITY_DAYS = 0.001` em `Config.lua` na cópia de teste e volte para 30 depois.

## Dados guardados (ModData)

- `PZBaseInventory_bases` e `PZBaseInventory_base_<id>`: bases marcadas (dono, cidade, área, data de criação em ms).
- `PZBaseInventory_players`: último login de cada jogador, em ms de tempo real.
- `PZBaseInventory_containers`: índice dos contêineres já lidos (posição e tipo).
- `PZBaseInventory_requests`: pedidos de inscrição pendentes.
- Um registro por contêiner, com os itens, o instante do último snapshot e as inscrições.

## Regras principais

- **Uma base por cidade, por jogador.** Bases não podem se sobrepor no mesmo nível.
- **Inatividade:** o relógio é o tempo real (`getTimestampMs`), porque o tempo do jogo para quando o jogo está fechado. O dono é checado com o último login anterior ao atual.
- **Escopo:** só contêineres dentro da área de uma base são lidos (instantâneos, inscrições e painel). Móveis fora de base não entram em nada.
- **Inscrição:** o dono da base se inscreve direto. Outro jogador faz um pedido, que fica pendente até o dono aprovar ou recusar.
- **Servidor não confia no cliente:** todo pedido é validado antes de ser gravado.

## Pendências

- Notificar os inscritos quando o contêiner muda (seção 5).
- Carro e veículos (seção 4).
- Editar a própria base (seção 2).
- Contêiner marcado como "removido" quando o móvel some do mundo (seção 3).
- Contêineres que já existiam antes da v0.2.10 só aparecem no painel após o primeiro snapshot.
- Itens do inventário do jogador e contêineres de veículo ainda não são lidos pelo snapshot.
- Confirmação em jogo das APIs de peso e categoria dos itens, e dos componentes de lista e texto do painel.

## Histórico de versões

Ver o `git log`. Principais marcos: 0.1.5 diagnósticos e persistência; 0.2.0 menu PZBase; 0.2.4 inatividade em tempo real; 0.2.6 inscrições; 0.2.7 traduções; 0.2.8 aprovação de pedidos; 0.2.9 aviso no login; 0.2.10–0.2.13 painel do jogador.
