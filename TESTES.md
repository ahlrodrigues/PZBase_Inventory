# PZBase Inventory: roteiro de testes (v0.1.0)

Objetivo desta rodada: confirmar que o fluxo **fechar contêiner → envio → validação → gravação no ModData → log** funciona em jogo, em partida solo.

## Antes de começar

1. Use uma **partida nova de teste** (Novo jogo, sandbox qualquer), não o seu save principal. Assim, se algo corromper o save, o seu continua seguro. (Você também tem backups em `~/Zomboid/BackupsSaves`.)
2. O mod já está instalado em `~/Zomboid/mods/PZBaseInventory/42/`.
3. Abra o jogo, vá em **Mods** e marque **PZBase Inventory**. Reinicie o jogo depois de ativar.

## Como acompanhar o log

Abra um terminal e deixe rodando:

```
tail -f ~/Zomboid/console.txt | grep --line-buffered -i "PZBI\|error\|lua"
```

Qualquer linha que comece com `[PZBI]` é do mod. Linhas de erro de Lua também aparecem aí.

## Teste 1: carregamento sem erro

- **Passo:** entre na partida de teste.
- **Esperado:** nenhum erro de Lua ao carregar. Não deve aparecer `[PZBI]` ainda (só aparece ao fechar um contêiner).
- **Se der erro:** copie a linha do erro e me envie.

## Teste 2: primeiro instantâneo

- **Passo:** abra um armário ou uma caixa fora de qualquer base (por exemplo, um armário de cozinha). Pegue **um item** de dentro. Feche a janela do contêiner.
- **Esperado no log:**
  `[PZBI] instantâneo PZBaseInventory_<x>_<y>_<z>_<tipo> por <seu nome>: 1 mudança(s)`
  (A primeira leitura de um contêiner conta como mudanças de todos os itens que ele já tinha.)

## Teste 3: detecção de entrada e saída

- **Passo A:** reabra o mesmo contêiner, guarde **um item** nele e feche.
  **Esperado:** `1 mudança(s)` de novo.
- **Passo B:** reabra, não mexa em nada e feche.
  **Esperado:** `0 mudança(s)`.

## Teste 4: persistência

- **Passo:** depois do Teste 3, salve e saia do jogo. Entre de novo na mesma partida.
- **Verificação:** abra o mesmo contêiner e feche sem mexer. O log deve mostrar `0 mudança(s)`, o que indica que o estado anterior foi lido do ModData salvo.

## Teste 5: contêiner no chão e em outro objeto

- **Passo:** repita o Teste 2 com um contêiner diferente (por exemplo, uma geladeira). Depois compare as linhas de log.
- **Esperado:** duas chaves diferentes no log, uma por contêiner.

## O que me enviar depois

Para cada teste, mande:
1. As linhas `[PZBI]` e qualquer erro de Lua (de `~/Zomboid/console.txt`).
2. Se o resultado foi o esperado (sim/não). Se não, o que aconteceu.
3. O sistema de cada resultado: solo ou multijogador.

## Limitações desta rodada

- **Multijogador ainda não foi testado.** O teste de sincronização entre dois jogadores exige um servidor dedicado; pode ser o próximo passo.
- Contêineres de veículo e o inventário do jogador não são lidos ainda (fora do escopo desta versão).
- Se o log não mostrar nada no Teste 2, é provável que, em partida solo, o evento do servidor não dispare. Nesse caso, me avise: vamos ajustar o plano de testes.

## Teste 6 (v0.1.6): criar base em partida solo

- **Passo A:** clique com o botão direito num tile. Escolha "PZBI: marcar canto 1 da base". O personagem deve falar "Canto 1 marcado em x, y."
- **Passo B:** clique com o botão direito em outro tile, no mesmo andar, e escolha "PZBI: marcar canto 2 e criar base". O personagem deve falar "Pedido de base enviado (Base)."
- **Verificação:** no `console.txt`, a linha `[PZBI] base 1 criada por <seu nome> em 'Base'`.
- **Recusa esperada:** repita a área, ou uma área que cruze a primeira. O log deve mostrar `[PZBI] base recusada: overlap` (ou `duplicate_city`). O jogo não avisa a recusa.
- **Cancelamento:** marque o canto 1, escolha "cancelar marcação" e depois "marcar canto 2". Deve falar "Canto 1 pendente" (ou "Marque o canto 1 primeiro").

## Teste 7 (v0.1.7): marcação por arrasto

Substitui o teste 6. A marcação agora é feita arrastando sobre o chão, como na área dos animais.

- **Passo A:** clique com o botão direito num tile e escolha "PZBI: marcar base". Abre a janela com o campo de nome e os botões "Criar base" e "Fechar".
- **Passo B:** arraste sobre o chão, de um tile a outro. A área deve aparecer preenchida com a cor da área dos animais.
- **Passo C:** mantenha o nome "Base", clique em "Criar base". O personagem deve falar "Pedido de base enviado (Base)." e o log deve mostrar `[PZBI] base N criada por <seu nome> em 'Base'`.
- **Passo D (sobreposição):** abra a ferramenta de novo, com outro nome (ex.: "Outra"), e arraste uma área que cruze a primeira. O log deve mostrar `[PZBI] base recusada: overlap`.
- **Passo E (cidade duplicada):** repita o passo C com o mesmo nome "Base" e área diferente. O log deve mostrar `duplicate_city`.

## Teste 8 (v0.1.9): ver bases

- **Passo:** clique com o botão direito num tile e escolha "PZBI: ver bases".
- **Esperado:** o personagem fala o total e a lista (cidade e dono), e as áreas das bases aparecem destacadas por alguns segundos.
- **Sem bases:** o personagem fala "Nenhuma base marcada neste save."
- **Se não aparecer nada:** envie as linhas `[PZBI]` do `console.txt` e diga se a fala apareceu.

## Teste 9 (v0.2.0): submenu PZBase

Botão direito num tile → "PZBase" → submenus:

- **Criar área:** arraste sobre o chão. A área aparece preenchida enquanto você arrasta. Ao soltar, abre a janela para nomear. "Salvar" envia; "Cancelar" descarta.
- **Ver áreas:** lista as bases e destaca as áreas por alguns segundos.
- **Apagar área:** clique numa área **sua**. Confirme no diálogo. Se a área for de outro jogador, a fala deve ser "Só o dono pode apagar esta base.".
- **Cancelar:** aparece no submenu enquanto houver uma ação pendente.

Se o clique direito deixar de abrir o menu, anote e envie o log.

## Teste 10 (v0.2.4): rótulo do nome e inatividade do dono

- **Rótulo:** a janela de nome mostra "Nome da cidade" (ou "City name" em inglês).
- **Inatividade (tempo real, teste rápido):** temporariamente, em `42/media/lua/shared/PZBI/Config.lua`, troque `PZBI.INACTIVITY_DAYS = 30` por `0.001` (cerca de 1,5 minuto real). Crie uma base, saia do jogo e espere pelo menos 2 minutos. Entre de novo no mesmo save. Antes de registrar o seu login, o jogo verifica o login anterior e deve remover a base. O log deve mostrar `[PZBI] base N removida: dono sem login ha X dias`. **Restaure para 30 depois do teste.**
- **Atenção:** em solo, o dono é sempre o jogador que carrega o save. Então a remoção só deve acontecer ao voltar depois do prazo, como no passo acima.
- Se a base for removida enquanto o jogo roda normal, envie as linhas `[PZBI]` do `console.txt`.
