# PZBase Inventory: roteiro de teste multijogador (v0.1.5)

Objetivo: confirmar que um instantâneo enviado por um jogador é validado no servidor e chega ao outro jogador via ModData.

Este roteiro ainda não foi executado. Os passos de configuração do servidor dedicado devem ser conferidos na documentação do Project Zomboid antes da primeira rodada.

## Pré-requisitos

1. Servidor dedicado de Build 42 instalado (SteamCMD, app 380870 ou equivalente).
2. Mod instalado no servidor: a linha `Mods=` do arquivo `servertest.ini` em `~/Zomboid/Server/` deve incluir `PZBaseInventory`. O `WorkshopItems=` fica vazio, pois o mod está local.
3. Dois clientes com o mesmo mod (jogador A e jogador B).
4. Terminal com o log do servidor acompanhado:

```
tail -f ~/Zomboid/Logs/*DebugLog*.txt | grep --line-buffered "PZBI"
```

## Teste M1: carregamento no servidor

- **Passo:** inicie o servidor e veja o log.
- **Esperado:** `[PZBI] server: SnapshotServer carregado` e `[PZBI] server: BaseServer carregado`, sem erro de Lua.

## Teste M2: instantâneo do jogador A

- **Passo:** o jogador A abre uma cômoda, pega um item e fecha.
- **Esperado no log do servidor:** `[PZBI] instantâneo PZBaseInventory_<x>_<y>_<z>_<tipo> por A ...` com a mudança listada.

## Teste M3: sincronização para o jogador B

- **Passo:** o jogador B, logado ao mesmo tempo, abre a mesma cômoda.
- **Esperado:** a tabela do contêiner chega ao jogador B. **Ponto em aberto:** não há código no cliente que leia o ModData recebido. Se o conteúdo não aparecer, o próximo passo é prototipar um leitor (`Events.OnReceiveGlobalModData`) e registrar o resultado aqui.

## Teste M4: validação do servidor

- **Passo:** não há cliente de teste pronto para enviar dados falsos. Este teste fica pendente até existir um comando de teste.
- **Esperado:** pedidos com tipos fora de `Config`, contagens acima de 10.000 ou mais de 500 tipos são recusados com a linha `snapshot rejeitado`.

## Teste M5: criação de base (pendente)

As bases (`createBase` / `removeBase`) estão implementadas no servidor, mas ainda sem interface no cliente. Este teste só pode começar quando houver o desenho da área.

## O que me enviar depois

Para cada teste: as linhas `[PZBI]` do servidor, o resultado (sim/não) e, se não deu certo, o erro completo.

## Atualização (v0.2.14–0.2.18)

- O registro de atividade agora vem do aviso do cliente (`ActivityPing.lua`), não do jogador local.
  Em servidor dedicado, o dono precisa ter entrado pelo menos uma vez com essa versão para a base não ser
  removida pelo critério de 30 dias. Incluir no roteiro M1: entrar com o dono, sair, e conferir o log do servidor
  com `[PZBI]` ao reentrar.
- Pedidos de inscrição (teste 12) e o aviso no login (teste 13) só podem ser feitos com dois jogadores.
- Botão "Bases" (teste 20) e o painel (testes 14 a 16): conferir se cada jogador vê só os contêineres
  das bases em que tem acesso.
