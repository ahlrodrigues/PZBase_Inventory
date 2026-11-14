# PZBase Inventory: especificação

Mod de qualidade de vida para Project Zomboid (Build 42). Lista tudo o que o jogador tem à disposição (mochila, carro e contêineres de suas bases), com suporte a multijogador.

Status: especificação aprovada pelo autor. Pontos marcados como "a confirmar" dependem de verificação no código do jogo antes da implementação.

---

## 1. Conceitos

- **Base:** área desenhada pelo jogador, dentro de uma cidade. Tem um dono (quem a marcou).
- **Cidade:** nome dado pelo jogador ao marcar a base.
- **Contêiner:** qualquer objeto que guarda itens (armário, caixa, geladeira, estante). Tem identificador estável formado por coordenadas e tipo do objeto.
- **Dono de contêiner:** o dono da base em que o contêiner está. Contêiner fora de base não tem dono.
- **Inscrição:** vínculo entre um jogador e um contêiner. Faz o contêiner aparecer na lista do jogador e o mantém na lista de notificações.
- **Instantâneo:** última leitura do conteúdo do contêiner, com data.

---

## 2. Marcação da base

1. O jogador abre a ferramenta de base, dá um nome à cidade e desenha a área (por edifício ou por contorno livre).
2. O mod mostra o contorno no mapa e os contêineres encontrados dentro dele.
3. O jogador confirma. A base fica salva com o nome do jogador, o nome da cidade e a área.

**Regras:**
- Um jogador pode ter uma base por cidade.
- Uma área não pode se sobrepor a outra base. Vale quem marcou primeiro.
- Se a área cortar um edifício, só entram os contêineres dentro do contorno.
- O jogador pode editar ou remover a própria base.
- Ao remover a base, os contêineres perdem o dono e quem estava inscrito recebe notificação para refazer a área.

---

## 3. Contêineres

**Identidade:** coordenadas e tipo do objeto. Se o objeto for removido do mundo, o registro é marcado como "removido", e não como vazio. Quem estava inscrito recebe aviso.

**Inscrição:**
- Contêiner **sem dono** (fora de base): qualquer jogador se inscreve diretamente.
- Contêiner **com dono** (dentro de base): o jogador envia pedido, e o dono aprova ou recusa.
- Pedido pendente fica registrado até o dono responder no próximo login dele.
- Pedido recusado não gera inscrição.

**Perda de dono:** se a base for removida, os contêineres ficam sem dono. As inscrições permanecem até o contêiner desaparecer. Não há transferência automática de dono.

---

## 4. Carro

- O carro é marcado pelo identificador do veículo, não pela posição.
- O carro do próprio jogador entra na lista sem aprovação.
- Carro de outro jogador exige aprovação do dono do carro.
- Se o carro for destruído, o mod remove a marcação e avisa os inscritos.
- A identificação do veículo ao ser guardado ou movido precisa ser confirmada (a confirmar).

---

## 5. Atualização e notificação

**Gatilho:** ao fechar a interface de um contêiner, o cliente envia o conteúdo ao servidor. O servidor compara com o último estado e identifica entradas e saídas de itens.

**Regras:**
- Toda mudança é registrada, mesmo que quem mexeu não esteja inscrito.
- Todos os inscritos do contêiner são notificados, independentemente de quem mexeu.
- Saque não é bloqueado para ninguém. Ser dono afeta apenas inscrições, aprovações e notificações.

**Limitação conhecida:** mudanças que não passam pela interface (como comida estragando com o tempo) não aparecem até a próxima leitura. O painel mostra a data do último instantâneo para deixar isso evidente.

---

## 6. Inatividade do dono

- O dono precisa entrar no jogo pelo menos uma vez a cada 30 dias.
- A regra vale para todas as bases, independentemente da cidade.
- A contagem usa o último login registrado no servidor. No modo solo, o registro é o último acesso ao save.
- Se o dono ficar inativo, a base inteira é removida (ver seção 2). Os contêineres perdem o dono, e os inscritos são notificados.

---

## 7. Painel do jogador

- Lista agrupada por categoria (comida, ferramentas, munição, remédios etc.).
- Cada item mostra quantidade, peso total e onde está: mochila, carro, ou nome da base e do contêiner.
- Cada contêiner mostra a data do último instantâneo e o estado da inscrição (aberta, aprovação pendente, aprovada).
- Botão para exportar a lista em texto.

---

## 8. Arquitetura multijogador

**Cliente:**
- Interface de marcação, desenho da área e painel.
- Leitura dos contêineres ao fechá-los.
- Envia pedidos ao servidor. Não grava estado próprio.

**Servidor:**
- Guarda o estado: bases, contêineres, inscrições, instantâneos, notificações e último login.
- Valida cada pedido: quem pode marcar, quem pode se inscrever, se o contêiner ainda existe.
- Recebe instantâneos apenas de jogadores próximos ao contêiner (a confirmar), para evitar envio de dados falsos.

**Armazenamento:** ModData com identificador próprio do mod. A sincronização envia a tabela inteira, então os dados devem ser separados por base ou por contêiner.

**Estrutura de pastas:** `42/` com scripts em `media/lua/client`, `media/lua/server` e `media/lua/shared`.

---

## 9. Casos de borda

- **Dois jogadores marcam áreas sobrepostas ao mesmo tempo:** o servidor atende o primeiro pedido e recusa o segundo.
- **Dois jogadores mexem no mesmo contêiner quase ao mesmo tempo:** vale a gravação mais recente, com registro de quem alterou por último.
- **Dono inativo com pedidos pendentes:** os pedidos ficam pendentes e são descartados junto com a base.
- **Jogador tenta se inscrever em contêiner de base de outro:** o pedido vai ao dono. Não há inscrição direta.

---

## 10. Itens a confirmar no código do jogo

- Nome e funcionamento do evento de fechar contêiner.
- Como ler o conteúdo de um contêiner e a identidade de um objeto.
- Se o identificador de um veículo muda quando é guardado ou movido.
- Se o mod consegue ler ou criar zonas próprias, ou se deve desenhar o contorno da base por conta própria.
- Funcionamento real da sincronização de ModData, já que a documentação oficial de modding de Build 42 está incompleta.
- Como verificar o último login de um jogador no servidor.

---

## 11. Restrições técnicas levantadas na pesquisa

- ModData é a forma de guardar dados. A versão 42.20 restringiu a escrita de arquivos a `.ini`, `.cfg`, `.txt` e `.log`.
- A versão 42.20 corrigiu uma falha que permitia criar itens arbitrários via ModData. Por isso, o servidor valida todo pedido do cliente.
- Mods de Build 42 ficam em `42/` ou `common/`. Mods de Build 41 não funcionam sem adaptação.
