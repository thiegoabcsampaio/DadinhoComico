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

- Camera 100% estatica, visao fixa na mesa (visao de espectador, atras do lado vazio)
- O jogador ve o proprio personagem no fundo da mesa; baloes, animacoes e castigo dele saem desse modelo 3D
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

- 4 personagens na mesa: o jogador escolhe um deles no menu e os outros 3 sao NPCs
- O personagem do jogador senta sempre no assento do fundo, de frente para a camera
- Cada jogador tem 1 copo com 3 dados
- Jogador humano eliminado vira espectador: pode acelerar a partida (3x) ou encerrar e iniciar um novo jogo
- Inicio da rodada: todos agitam e escondem os dados
- Jogadores fazem apostas crescentes sobre a quantidade total de uma face entre todos os copos
- Apostas devem ser sempre maiores que a anterior (quantidade ou face)
- Qualquer jogador pode acusar o anterior de mentir ("Desconfio!"; no codigo a acao continua chamada de dudo)
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
  Heroi encolhe com a pilula; Ciborgue entra em curto e desliga
- Regra: todo personagem nasce com um castigo no modelo 3D E um efeito de tela proprio
  (cor, tremor, luz), sentido pelo jogador quando o personagem dele e castigado. Sem torta.
  Apresentadora: flash branco, zoom-out e tremor de decolagem. Bruxa: tela verde que ondula.
  Heroi: campo de visao abre e volta com quique. Ciborgue: glitch vermelho, tremor, dessaturacao
- Olho robotico do Ciborgue e preto; acende vermelho quando ele perde um dado

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

## HUD (rodada 3)

- Falas dinamicas: no turno do jogador, botao Falar com 3 provocacoes do proprio personagem
  (dialogues.json, "provocacoes"); o NPC alvo responde ("reacoes_provocacao"); nao gasta a jogada
- Baloes nunca se sobrepoem (fila ou deslocamento)
- Log de historico a esquerda, estilo app de mensagens, com falas, apostas, Desconfio, revelacoes
  e castigos; existe so durante a partida e reinicia no Novo jogo
- Resultado da revelacao aparece tambem num balao do "narrador", no centro da mesa
- Ver Dados: os dados voam do copo para o painel e FICAM la (nao viram numeros)

## Plateia (Etapa 7)

- Auditorio anos 90: duas arquibancadas ladeando a mesa, cerca de 40 pessoas
- Diversidade obrigatoria: tons de pele do mais claro ao mais escuro, roupas
  saturadas e cabelos variados, sorteados por espectador (nunca uma plateia igual)
- Acessorios: plaquinha, frufru, oculos, bone - ou nenhum
- Reacoes: murmurio na aposta, silencio no Desconfio, aplauso na revelacao,
  festa (plaquinhas e frufrus) no castigo e no fim de jogo
- A plateia tem som: murmurio de fundo continuo, que abaixa no Desconfio e da lugar a
  um "oooh" de expectativa, aplauso na revelacao e festa com assobios no castigo
