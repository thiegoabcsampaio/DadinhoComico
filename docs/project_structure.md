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
│   │   └── Ciborgue.glb
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
│   ├── Menu.tscn
│   └── NPCs/
│       ├── Apresentadora.tscn
│       ├── Bruxa.tscn
│       ├── Heroi.tscn
│       └── Ciborgue.tscn
├── Scripts/
│   ├── GameManager.gd
│   ├── StateManager.gd
│   ├── TurnManager.gd
│   ├── DiceSystem.gd
│   ├── BetValidator.gd
│   ├── DialogueLoader.gd
│   ├── NpcAI.gd
│   ├── NpcController.gd
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
- Audio: .ogg (Godot nativo)
- Todos os textos em dialogues.json na raiz, nunca hardcoded
- Perfis de NPC como Resource (.tres) com campos: nome, agressividade, cautela, frequencia_tells