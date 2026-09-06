# BLUEPRINT — Liar's Dice (7 Etapas)

## Roteamento por Etapa

- [F] = Fable 5.1 via Claude Code (caro, usar apenas para geracao e arquitetura)
- [O] = Opus 4.6 via Antigravity (barato, usar para iteracao e debug)
- [B] = Blender MCP (geracao de assets 3D)
- [G] = Godot MCP (criacao de cenas e scripts)

---

## Etapa 1 — Ambiente Base

Agentes: [F] [B] [G]

Acoes:
- Criar projeto Godot com Renderer Compatibility
- Configurar camera 3D estatica (posicao fixa, sem input do jogador)
- Gerar via Blender MCP: mesa, 5 copos, 15 dados (3 por copo)
- Exportar assets como .glb para Assets/Models/
- Montar Mesa.tscn com assets posicionados
- Iluminacao direcional estilo estudio de TV

Outputs esperados:
- project.godot
- Scenes/Main.tscn
- Scenes/Mesa.tscn
- Scripts/CameraSetup.gd
- Assets/Models/Mesa.glb
- Assets/Models/Copo.glb
- Assets/Models/Dado.glb

Criterio de conclusao: cena roda no Godot, camera fixa mostra a mesa com 5 copos e 15 dados

---

## Etapa 2 — Motor Logico

Agentes: [F] para arquitetura inicial, [O] para iteracao

Acoes:
- Criar StateManager.gd (estados: AGUARDANDO, APOSTANDO, ACUSANDO, REVELANDO, CASTIGO)
- Criar TurnManager.gd (controle de ordem dos turnos, jogador + 4 NPCs)
- Criar DiceSystem.gd (RNG dos 5 dados por copo, funcao de revelar)
- Criar BetValidator.gd (validacao de apostas crescentes, resolucao de dudo)

Outputs esperados:
- Scripts/StateManager.gd
- Scripts/TurnManager.gd
- Scripts/DiceSystem.gd
- Scripts/BetValidator.gd

Criterio de conclusao: rodada completa funciona no terminal (print) sem UI, com 5 jogadores simulados

---

## Etapa 3 — UI e Controles

Agentes: [O] principal, [F] se travar

Acoes:
- Criar HUD.tscn com botoes: Apostar, Dudo, Ver Dados
- Implementar sistema de selecao de aposta (face + quantidade)
- Sistema de baloes de dialogo (Control node posicionado via unproject_position)
- Conectar HudController.gd ao StateManager.gd

Outputs esperados:
- Scenes/HUD.tscn
- Scripts/HudController.gd
- Assets/UI/Balao_Dialogo.png
- Assets/UI/Botao_Dudo.png
- Assets/UI/Botao_Apostar.png

Criterio de conclusao: jogador humano consegue jogar uma rodada completa contra 4 NPCs burros (random)

---

## Etapa 4 — IA e Data-Driven

Agentes: [F] para logica de probabilidade, [O] para dialogos

Acoes:
- Criar dialogues.json com todas as falas por personagem e categoria
- Criar DialogueLoader.gd (carrega e seleciona falas)
- Criar NpcAI.gd (calculo de probabilidade, decisao de blefar/apostar/acusar)
- Criar NPC profiles como Resource (.tres) com campos: agressividade, cautela, frequencia_tells
- Conectar IA ao TurnManager

Outputs esperados:
- dialogues.json
- Scripts/DialogueLoader.gd
- Scripts/NpcAI.gd
- Resources/NPCProfiles/Apresentadora.tres
- Resources/NPCProfiles/Bruxa.tres
- Resources/NPCProfiles/Heroi.tres
- Resources/NPCProfiles/Ciborgue.tres

Criterio de conclusao: NPCs tomam decisoes baseadas em probabilidade, falas aparecem nos baloes

---

## Etapa 5 — Assets Definitivos e Rigging

Agentes: [F] [B]

Acoes:
- Gerar modelos dos 4 NPCs estilo PS2 via Blender MCP
- Rigging basico: posicao sentada, bracos sobre a mesa
- Exportar como .glb com armature
- Criar cenas individuais por NPC (Scenes/NPCs/)
- Integrar na Mesa.tscn nas posicoes corretas

Outputs esperados:
- Assets/Models/Apresentadora.glb
- Assets/Models/Bruxa.glb
- Assets/Models/Heroi.glb
- Assets/Models/Ciborgue.glb
- Scenes/NPCs/Apresentadora.tscn
- Scenes/NPCs/Bruxa.tscn
- Scenes/NPCs/Heroi.tscn
- Scenes/NPCs/Ciborgue.tscn

Criterio de conclusao: 4 NPCs sentados na mesa, com armature funcional, visiveis na camera fixa

---

## Etapa 6 — Polimento (Tells e Castigos)

Agentes: [F] para animacoes Blender, [O] para integracao Godot

Acoes:
- Criar animacoes de tiques nervosos por NPC (olhar pro lado, cocar, bater na mesa)
- Conectar tells ao NpcAI.gd (ativa quando blefa em aposta de alto risco)
- Criar PunishmentSystem.gd (eventos comicos por personagem)
- Adicionar SFX para castigos e dados
- Polir transicoes entre estados

Outputs esperados:
- Scripts/PunishmentSystem.gd
- Scripts/NpcController.gd (conecta animacoes ao comportamento)
- Assets/Audio/SFX/[todos os efeitos]
- Animacoes embarcadas nos .glb dos NPCs

Criterio de conclusao: jogo completo jogavel — rodadas, IA com personalidade, tells visiveis, castigos comicos com som
---

## Etapa 7 — Polimento Final e Ambientacao

Agentes: [F] [B] para assets, [O] para integracao Godot

Pre-requisito: Bloco B de docs/blueprint_melhorias.md concluido.

Acoes:
- Gerar via Blender MCP duas arquibancadas de estudio (esquerda e direita da
  camera, fora da mesa) em .glb, low-poly
- Gerar 1 modelo base de espectador sentado, extremamente otimizado
  (< 600 tris), com 3 animacoes em loop: Aplaudir, LevantarPlaquinha,
  AgitarFrufru; acessorios (plaquinha, frufru, oculos, bone) como malhas
  separadas para ligar/desligar por instancia
- Diversidade por codigo, nao por malha: paleta de tons de pele, cabelos e
  roupas aplicada por instancia (material com albedo por instancia ou
  MultiMeshInstance3D com custom_data / cor por instancia)
- Godot: PlateiaController.gd popula as arquibancadas (~40 a 60 pessoas),
  sorteia cor/acessorio/animacao com fase aleatoria e reage aos sinais do
  GameManager (aposta = murmurio, Desconfio = "oooh", castigo = aplausos e
  plaquinhas)
- Pano de fundo de estudio (parede com luzes e logo do programa) no lugar do
  ceu procedural
- Trilha de menu (Assets/Audio/Music/Tema_Menu.ogg) e Menu.tscn
- Ajustar o "Sua vez!" que encosta na base da mesa

Outputs esperados:
- Assets/Models/Arquibancada.glb
- Assets/Models/Espectador.glb (com animacoes embarcadas)
- Assets/Models/Estudio.glb
- Scripts/PlateiaController.gd
- Scenes/Plateia.tscn
- Scenes/Menu.tscn
- Assets/Audio/Music/Tema_Menu.ogg

Criterio de conclusao: plateia diversa e animada visivel na camera fixa
reagindo as jogadas, sem queda de FPS no export Web; menu inicial funcional
