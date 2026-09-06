# BLUEPRINT DE MELHORIAS — Rodada 3 (jogador na mesa, dialogos e visual)

Documento temporario. Cada item e riscado quando entra na main; quando todos
estiverem prontos, este arquivo pode ser apagado. A Etapa 7 (plateia,
estudio, menu com trilha) vem DEPOIS desta rodada e continua em blueprint.md.

Roteamento: [F] = Fable (Blender MCP, arquitetura, decisoes de look),
[O] = Opus (codigo Godot). Regra do revezamento: Fable primeiro (Bloco A),
depois Opus (Bloco B), depois Fable valida e fecha (Bloco C). Ao trocar de
modelo, colar o PONTO DE RETOMADA da sessao anterior.

Itens marcados [A CONFIRMAR] sao decisoes que precisam de resposta antes de
comecar o bloco correspondente.

---

## Decisoes de desenho (valem para os dois blocos)

- Mesa com 4 jogadores: o personagem escolhido pelo jogador + 3 NPCs. O
  assento da frente (vazio) deixa de existir. (confirmado)
- O jogador senta SEMPRE no assento do fundo (centro, oposto a camera); os 3
  NPCs ocupam esquerda, direita e frente-lateral, sorteados como hoje.
- A camera continua fixa e na mesma direcao, mas mais perto e com campo de
  visao menor, para mesa e personagens ocuparem mais tela.
- Balao, animacoes (Apostar, Dudo, Comemorar, Castigo) e castigo do jogador
  acontecem no modelo 3D do personagem escolhido, na mesa. A torta na cara
  SAI. No lugar, cada personagem tem um EFEITO DE TELA proprio no castigo
  (cor, tremor, luz), como se o jogador sentisse o que o boneco sente.
  Regra permanente: todo personagem novo nasce com castigo + efeito de tela.
  Efeitos definidos (Opus implementa em B1):
  - Apresentadora: flash branco, leve zoom-out e tremor de decolagem.
  - Bruxa: tela tinge de verde e ondula/escorre por 2 s.
  - Heroi: campo de visao abre (tudo parece encolher) e volta com quique.
  - Ciborgue: glitch: piscadas vermelhas, tremor curto e dessaturacao.
- A IA (NpcAI) do personagem escolhido e desligada; a HUD comanda esse
  jogador. Os perfis (.tres) e dialogues.json continuam valendo para ele
  (as falas de aposta, insulto e defesa saem do proprio personagem).
- O log de historico (chat) so existe durante uma partida: some e reinicia
  no Novo jogo. (confirmado)

---

## Bloco A — Fable (Blender + arquitetura; exige Blender conectado)

- [x] A1. Roupas e tons de pele, no .blend, reexportando os 4 .glb com as
      animacoes (NLA_TRACKS):
      - Apresentadora: pele parda; macacao brilhante estilo Xuxa/Elvis/Joelma
        (ombreiras, franjas ou cinto largo, cores saturadas).
      - Ciborgue (modelo original restaurado): jaqueta de couro preta e calca
        jeans; pele branca menos estourada; olho do lado robo PRETO por
        padrao, com material proprio ("Cib_OlhoRobo") para o codigo acender
        em vermelho quando ele perde um dado.
      - Heroi: pele menos branca (tom medio).
      - Bruxa: vestido de bruxa da cor do chapeu (roxo escuro/preto), com
        capa ou mangas, em vez do vestido liso atual.
- [x] A2. Iluminacao: rostos estao estourando. Baixar DirectionalLight e luz
      ambiente, revisar tonemap/exposicao no WorldEnvironment e validar com
      captura de perto (tools/Screenshot.tscn modo rosto). Deixar a base pronta
      para o Opus escurecer/aproximar dinamicamente no B7.
- [x] A3. Layout da mesa e camera: Main.tscn com 4 assentos (fundo = jogador,
      esquerda, direita, frente-lateral), rotacoes de cada um para o centro,
      copos reposicionados em Mesa.tscn, camera mais proxima/FOV menor.
      Validar por captura.
- [x] A4. Arquitetura da escolha de personagem: autoload "Partida.gd"
      (personagem escolhido, opcoes) + Scenes/Menu.tscn esqueleto (4 cartoes,
      botao Jogar) + contrato em Main: `personagem_humano: String`,
      `_controladores[JOGADOR_HUMANO]` aponta para o modelo escolhido, sem
      NpcAI para ele. Fable escreve o esqueleto e as docs; Opus implementa.
- [x] A5. dialogues.json: novas categorias por personagem, com textos:
      "provocacoes" (opcoes do jogador no turno, 3 por personagem),
      "reacoes_provocacao" (NPC responde), "resultado" (balao neutro da
      revelacao, secao "narrador"). Sem texto hardcoded.
- [x] A6. Atualizar game_bible.md (jogador na mesa, 4 jogadores, log, falas
      dinamicas) e project_structure.md (Partida.gd, Menu.tscn, novos scripts).

## Bloco B — Opus (codigo Godot, apos o Bloco A)

- [x] B1. Menu e selecao: Menu.tscn funcional (cartao por personagem com nome
      e frase de apresentacao de dialogues.json, botao Jogar), Partida guarda
      a escolha, Main coloca o escolhido no assento do fundo e liga a HUD a
      ele: aposta/desconfio disparam as animacoes Apostar/Dudo no modelo, o
      balao sai do modelo, castigo do personagem no modelo + EFEITO DE TELA
      do personagem (ver Decisoes de desenho).
      Ver Dados continua espiando o copo do jogador (agora no fundo).
- [x] B2. Baloes sem sobreposicao: BalaoDialogo/HudController com fila por
      tempo (um balao de cada vez, os demais esperam) ou deslocamento vertical
      quando dois falam juntos (insulto + defesa). Decidir pelo que ler melhor
      e registrar nas notas.
- [x] B3. Log de historico a esquerda (estilo app de mensagens): registra
      falas, apostas, Desconfio, revelacoes e castigos de todos, com nome e
      cor por personagem; rolagem automatica; some/limpa no Novo jogo.
- [x] B4. Falas dinamicas (dialogo estilo RPG): no turno do jogador, botao
      "Falar" abre 3 opcoes vindas de "provocacoes" do personagem dele; ao
      escolher, sai no balao dele e o NPC alvo (ou o proximo) responde com
      "reacoes_provocacao". Nao gasta a jogada.
- [x] B5. Dados no painel: os icones que voam ficam no painel no lugar dos
      numeros (nao somem); ao desligar Ver Dados voam de volta ao copo.
- [x] B6. Resultado da revelacao tambem num balao "narrador" ancorado no
      centro da mesa (alem do texto de status).
- [x] B7. Ao NPC olhar para a camera (fala): escurecer levemente a cena e dar
      um leve zoom (FOV) na camera, voltando ao normal ao fim do balao.
- [x] B8. Olho robotico do Ciborgue: preto por padrao; ao perder um dado,
      acende vermelho por alguns segundos (material "Cib_OlhoRobo").
- [x] B9. "Ao iniciar nova rodada": o usuario confirmou que o que ja existe
      basta - copos chacoalham, toca o som dos dados, o log abre a rodada e,
      se Ver Dados estiver ligado, os dados novos voltam ao painel. Nada a
      acrescentar.

Criterio de conclusao do Bloco B: partida no F5 escolhendo um personagem no
menu, jogando pelo modelo dele no fundo da mesa, com falas dinamicas, baloes
legiveis, log a esquerda, dados no painel e revelacao em balao.

## Bloco C — Fable (fechamento)

- [ ] C1. Validacao visual completa (capturas), ajustes finos de material e
      luz que o Opus tenha apontado, apagar este documento e gerar o ponto de
      retomada para a Etapa 7.

---

## Notas do Bloco A (o que ja esta pronto para o Opus usar)

- Contrato do jogador: Partida.personagem (autoload) e o nome do no do personagem
  escolhido; Main._sortear_assentos() o senta no Assento0 e preenche
  _controladores[0] com o modelo dele; nao ha NpcAI para o id 0; _chave(id) da a
  secao de dialogues.json de qualquer assento. _castigar(0) ja roda o castigo do
  personagem no modelo. Falta (B1): animacoes Apostar/Dudo no modelo do jogador ao
  clicar na HUD, efeito de tela por personagem, e a apresentacao do menu.
- Menu.tscn/Menu.gd funcionam (botoes por personagem, frase de apresentacao, Jogar
  -> Main). Cena inicial do projeto passou a ser o Menu.
- dialogues.json ganhou, por personagem: "nome", "apresentacao", "provocacoes" (3),
  "reacoes_provocacao" (3); secao "narrador.resultado" com {face} {contagem}
  {veredicto} {perdedor}; ui: botao_falar, titulo_menu, titulo_escolha, botao_jogar.
- Material do olho robotico: "Cib_OlhoRobo" (preto, emissao vermelha com strength 0).
  Para acender: achar o material por nome nas superficies do MeshInstance3D do
  Ciborgue e animar emission_enabled/emission_energy_multiplier.
- Luz: DirectionalLight 0.8, ambiente 0.35, tonemap filmic exposure 0.85 / white 1.6.
  Para o B7, escurecer = animar tonemap_exposure do WorldEnvironment (0.85 -> 0.65)
  e o zoom = animar Camera3D.fov (58 -> 52).
- tools/Screenshot.tscn: modos jogo, revelacao, castigos, espiar, zoom, feel, olhar,
  assentos, rosto, rosto_olhar, menu.

---

## Notas do Bloco B (decisoes e desvios do planejado)

- B1: o modelo do jogador toca Apostar/Dudo/Castigo como qualquer outro; o balao
  dele ja saia do assento. Efeitos de tela em Scripts/EfeitoTela.gd (CanvasLayer
  no Main), um por personagem, disparados so quando o castigado e o jogador.
- B2: a causa da sobreposicao nao era so posicao. O balao nao tinha largura
  maxima: uma fala longa virava um retangulo de 600 px que saia da tela. Agora o
  texto quebra em 300 px, o balao e preso dentro da tela e o HudController
  resolve colisoes empurrando para cima; a cauda estica e continua apontando o
  personagem. O desvio e guardado no proprio balao (Vector2), senao ele era
  descartado no quadro seguinte, quando o balao recalcula a posicao.
- B3: o log (Scripts/LogHistorico.gd) comeca FECHADO atras de um icone no canto
  superior esquerdo (pedido do usuario durante o bloco): aberto o tempo todo ele
  cobria os personagens da esquerda. Quando esta aberto, os baloes que cairiam
  sobre ele deslizam para a direita. Some com a partida (a cena recarrega).
- B4: o botao Falar fica junto de Apostar/Desconfio, so na vez do jogador, e nao
  gasta a jogada. As 3 opcoes vem de "provocacoes" do personagem do jogador com
  o nome do proximo jogador; o alvo responde com "reacoes_provocacao".
- B5: os dados param no painel (sobre o LabelMeusDados, que fica vazio enquanto
  isso) e voltam voando ao copo quando Ver Dados desliga. Se a rodada virar com
  Ver Dados ligado, Main repoe os dados novos depois do agitar.
- B6: balao do narrador ancorado num Marker3D no centro da mesa, com
  deslocamento baixo (0,12 m) para nao sair pelo topo do quadro.
- B7: EfeitoTela.focar() anima tonemap_exposure (0.85 -> 0.62) e o fov
  (58 -> 52) enquanto o balao esta no ar.
- B8: NpcController.acender_olho() duplica o material "OlhoRobo" na superficie
  daquela instancia e anima a emissao; quem nao tem o material ignora.
- Novos modos em tools/Screenshot.tscn: falas, efeito, log, narrador.
