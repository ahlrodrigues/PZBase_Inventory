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
