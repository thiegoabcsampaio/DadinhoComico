# GAME BIBLE — Liar's Dice

## Conceito

- Jogo de mesa 3D em primeira pessoa
- Mecanica central: blefe do Liar's Dice (Dadinho)
- Referencia de tensao: Liar's Bar
- Tom: punicoes comicas estilo TV anos 90 (torta na cara, gosma verde, choque, encolhimento)
- Proibido: qualquer tipo de violencia

## Direcao de Arte

- Estilo PS2: mid-poly, formas organicas, texturas definidas
- Proibido: estetica de blocos, Minecraft, Roblox
- Iluminacao: direcional, estilo estudio de TV
- Paleta: cores saturadas, sombras suaves

## Camera e Controles

- Camera 100% estatica, visao fixa na mesa (jogador sentado)
- Sem movimentacao de camera pelo jogador
- Interacao exclusivamente via UI:
  - Cliques em botoes
  - Menus radiais
  - Baloes de dialogo em HQ (2D renderizado sobre 3D via unproject_position)

## Elenco de Personagens

Todos sao parodias. 4 NPCs + jogador humano.

Apresentadora (parodia Xuxa):
- Personalidade: otimista, chama todos de "baixinhos"
- Castigo: some numa nave espacial de papelao
- Visual: vestido brilhante, cabelo loiro volumoso

Bruxa Jacare (parodia Cuca):
- Personalidade: sotaque interiorano, rimas de maldicao, bebe pocoes
- Castigo: a propria pocao explode em gosma verde e ela some numa nuvem de fumaca
- Visual: pele verde, chapeu pontudo, cauda de jacare

Heroi Desastrado (parodia Chapolin):
- Personalidade: proverbios misturados, martelo de plastico
- Castigo: encolhe com uma pilula
- Visual: roupa vermelha com antenas, escudo pequeno

Ciborgue (parodia Exterminador):
- Personalidade: frio, matematico ("Hasta la vista, dadinho")
- Castigo: curto-circuito revela o endoesqueleto
- Visual: metade rosto metalico, olho vermelho

## Regras do Liar's Dice

- 5 jogadores (1 humano + 4 NPCs)
- Cada jogador tem 1 copo com 3 dados
- Jogador humano eliminado vira espectador: pode acelerar a partida (3x) ou encerrar e iniciar um novo jogo
- Inicio da rodada: todos agitam e escondem os dados
- Jogadores fazem apostas crescentes sobre a quantidade total de uma face entre todos os copos
- Apostas devem ser sempre maiores que a anterior (quantidade ou face)
- Qualquer jogador pode acusar o anterior de mentir ("Dudo!")
- Resolucao: todos revelam os dados
  - Se a aposta era verdadeira: acusador perde 1 dado
  - Se a aposta era falsa: apostador perde 1 dado
- Jogador sem dados e eliminado (recebe castigo comico)
- Ultimo jogador vence

## Arquitetura Data-Driven

- Todos os textos, falas e dialogos ficam em dialogues.json
- Separados por personagem e por categoria: insultos, defesas, reacoes, castigos
- Nenhum texto hardcoded em scripts

## IA dos NPCs

- Cada NPC calcula probabilidade matematica baseada nos proprios dados
- Decisao de blefar, aumentar aposta ou acusar depende de:
  - Quantidade de dados proprios que batem com a aposta
  - Probabilidade estimada dos dados ocultos dos outros
  - Personalidade do NPC (agressividade, cautela)
- Tiques nervosos (tells) sao ativados quando o NPC blefa em aposta de alto risco
  (NpcAI.blefe_arriscado), com chance frequencia_tells do perfil; sao 3 animacoes
  embarcadas no .glb: Tell_Olhar, Tell_Cocar, Tell_Bater
- Castigos: Apresentadora some numa nave de papelao; Bruxa vira gosma e some em fumaca;
  Heroi encolhe com a pilula; Ciborgue entra em curto e desliga; humano leva torta na cara

## RETOMADA

Ao concluir cada etapa, o agente deve gerar este bloco:

---
PONTO DE RETOMADA — Etapa [N] concluida

Status:
- Arquivos gerados: [lista]
- Arquivos modificados: [lista]
- Decisoes tomadas: [lista]

Proximo passo:
- Etapa [N+1]: [nome]
- Primeira acao: [descricao]

Cole este bloco no inicio da proxima sessao.
---
