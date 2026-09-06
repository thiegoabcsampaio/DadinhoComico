# PROJECT STRUCTURE — Liar's Dice

## Stack

- Engine: Godot 4.x (Renderer Compatibility para exportacao Web/HTML5)
- Linguagem: GDScript
- Modelagem: Blender (via Blender MCP)
- IDE: Google Antigravity (Opus 4.6 para iteracao)
- Agente master: Claude Code (Fable 5.1 para arquitetura e geracao)
- Versao: Git/GitHub

## Raiz do Projeto

C:\ThixBoxGames\DadinhoComico\

## Arvore de Pastas

```
DadinhoComico/
├── project.godot
├── dialogues.json
├── Assets/
│   ├── Models/
│   │   ├── Mesa.glb
│   │   ├── Copo.glb
│   │   ├── Dado.glb
│   │   ├── Apresentadora.glb
│   │   ├── Bruxa.glb
│   │   ├── Heroi.glb
│   │   ├── Ciborgue.glb
│   │   └── Nave.glb             (nave de papelao com X, castigo da Apresentadora)
│   ├── Source/
│   │   ├── .gdignore            (Godot nao importa esta pasta)
│   │   └── Personagens.blend    (fonte dos modelos; regenerado via Blender MCP)
│   ├── Textures/
│   │   ├── Mesa_Diffuse.png
│   │   ├── Dado_Diffuse.png
│   │   └── [por personagem]
│   ├── Audio/
│   │   ├── SFX/
│   │   │   ├── Dado_Agitar.ogg
│   │   │   ├── Dado_Revelar.ogg
│   │   │   ├── Castigo_Torta.ogg
│   │   │   └── Castigo_Choque.ogg
│   │   └── Music/
│   │       └── Tema_Menu.ogg
│   └── UI/
│       ├── Balao_Dialogo.png
│       ├── Botao_Dudo.png
│       ├── Botao_Apostar.png
│       └── Fonte_HQ.ttf
├── Scenes/
│   ├── Main.tscn
│   ├── Mesa.tscn
│   ├── HUD.tscn
│   ├── Menu.tscn            (escolha de personagem; cena inicial do projeto)
│   └── NPCs/
│       ├── Apresentadora.tscn
│       ├── Bruxa.tscn
│       ├── Heroi.tscn
│       └── Ciborgue.tscn
├── Scripts/
│   ├── GameManager.gd
│   ├── Partida.gd           (autoload: personagem escolhido, atravessa cenas)
│   ├── Menu.gd
│   ├── StateManager.gd
│   ├── TurnManager.gd
│   ├── DiceSystem.gd
│   ├── BetValidator.gd
│   ├── DialogueLoader.gd
│   ├── NpcAI.gd
│   ├── NpcController.gd     (animacoes do .glb: Idle, tells, Apostar, Dudo, Comemorar, Castigo)
│   ├── MesaController.gd    (copos e dados fisicos: agitar, revelar, esconder)
│   ├── Sfx.gd               (Sfx.tocar("nome") -> Assets/Audio/SFX/nome.wav)
│   ├── OlharModifier.gd     (gira so o osso da cabeca na direcao de um alvo)
│   ├── HudController.gd
│   ├── PunishmentSystem.gd
│   └── CameraSetup.gd
├── Resources/
│   ├── NPCProfiles/
│   │   ├── Apresentadora.tres
│   │   ├── Bruxa.tres
│   │   ├── Heroi.tres
│   │   └── Ciborgue.tres
│   └── Materials/
│       └── [materiais exportados do Blender]
├── Addons/
│   └── GodotMCP/
│       └── [plugin MCP]
├── tools/
│   ├── Screenshot.tscn          (valida a camera fixa sem abrir o editor)
│   ├── DumpTree.tscn            (imprime arvore, ossos e animacoes de uma cena)
│   ├── GerarSfx.tscn            (sintetiza SFX curtos, ex.: Clique.wav)
│   └── Screenshot.gd
└── docs/
    ├── system_prompt.md
    ├── game_bible.md
    ├── project_structure.md
    └── blueprint.md
```

## Convencoes

- Pastas: PascalCase (Assets/, Scenes/, Scripts/)
- Arquivos de asset: PascalCase (Mesa.glb, Dado_Diffuse.png)
- Arquivos de docs: snake_case (game_bible.md)
- Scripts GDScript: PascalCase (StateManager.gd)
- Assets 3D: exportar do Blender como .glb (GLTF binary)
- Texturas: .png para diffuse, normal, roughness
- Audio: SFX curtos em .wav sintetizados (Assets/Audio/SFX/); musica em .ogg
- Todos os textos em dialogues.json na raiz, nunca hardcoded
- Perfis de NPC como Resource (.tres) com campos: nome, agressividade, cautela, frequencia_tells- Modelos 3D: materiais so com cor base (sem texturas) enquanto o estilo PS2 nao pedir; o .blend fonte fica em Assets/Source/
- Personagens olham para +Z no proprio .glb; a rotacao para o centro da mesa fica no assento em Main.tscn
- Escala: tampo da mesa a 0.75 m, cabeca dos NPCs a ~1.2 m, dados de 4 cm
- Autoload "Partida" (Scripts/Partida.gd): unico estado que atravessa cenas; Menu grava, Main le
- Assentos em Main.tscn: Assento0 = fundo (sempre o personagem do jogador), 1 esquerda, 2 direita,
  3 frente-esquerda; os NPCs sao sorteados entre 1..3 e herdam a rotacao do assento
- Scripts/EfeitoTela.gd (CanvasLayer no Main): efeitos de tela do castigo do jogador e o
  foco (escurecer + zoom) durante as falas
- Scripts/LogHistorico.gd: painel do historico da partida, aberto pelo icone no canto
  superior esquerdo; vive so durante a partida
