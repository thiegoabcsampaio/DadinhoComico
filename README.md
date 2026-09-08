# Dadinho Comico

Jogo de Liar's Dice (Dadinho) em 3D com tema de programa de auditorio anos 90.
Feito em **Godot 4.7.2** (GDScript, renderer Compatibility) com modelagem em **Blender 5.2**.

**Jogar agora:** https://thiegoabcsampaio.github.io/DadinhoComico/

---

## Indice

1. [Regras do jogo](#regras-do-jogo)
2. [Modos de jogo](#modos-de-jogo)
3. [Elenco de personagens](#elenco-de-personagens)
4. [Estrutura do projeto](#estrutura-do-projeto)
5. [Como rodar localmente](#como-rodar-localmente)
6. [Como exportar e publicar](#como-exportar-e-publicar)
7. [Deploy automatico (GitHub Actions)](#deploy-automatico-github-actions)
8. [Ferramentas de validacao](#ferramentas-de-validacao)
9. [Convencoes do projeto](#convencoes-do-projeto)
10. [Como criar um novo personagem](#como-criar-um-novo-personagem)

---

## Regras do jogo

Dadinho Comico e um jogo de blefe baseado no Liar's Dice classico. Quatro
personagens sentam em volta de uma mesa de programa de TV. O jogador escolhe
um deles no menu; os outros tres sao controlados pela IA.

### Preparacao

- Cada jogador comeca com **1 copo** e **3 dados**
- No inicio de cada rodada todos agitam e escondem os dados sob o copo
- Os dados do jogador ficam sempre visiveis no placar (canto inferior direito)

### Fluxo de uma rodada

1. O jogador da vez faz um **pedido**: "X dados com a face Y estao na mesa"
   (contando TODOS os copos, nao so o proprio)
2. O proximo jogador deve:
   - Fazer um pedido **maior** (quantidade ou face superiores), ou
   - Gritar **"Desconfio!"** para acusar o anterior de mentir
3. A rodada continua em circulo ate alguem desconfiar

### Resolucao do Desconfio

Todos revelam os dados:

- **Pedido verdadeiro** (a quantidade real e igual ou maior que o pedido):
  quem desconfiou perde 1 dado
- **Pedido mentiroso** (a quantidade real e menor que o pedido):
  quem fez o pedido perde 1 dado

### Eliminacao e castigo

- Jogador que perde todos os dados e **eliminado** e recebe um castigo comico
  (nunca violento — o tom e de programa de TV anos 90)
- Jogador humano eliminado vira espectador: pode acelerar a partida (3x) ou
  encerrar e comecar um novo jogo
- O **ultimo jogador** na mesa vence e faz sua comemoracao

---

## Modos de jogo

Escolhidos no menu antes da partida:

### Dadinho (padrao)

- O **as** (face 1) e **curinga**: conta para qualquer face pedida
- Trocar de uma face comum para ases: quantidade dividida por 2, arredondada
  para cima (ex.: 3x face 6 → 2 ases; 10x face 6 → 5 ases)
- Trocar de ases para uma face comum: quantidade vezes 2, mais 1
  (ex.: 2 ases → 5 de qualquer face)
- De ases para ases: sobe a quantidade normalmente

### Dados mentirosos

- Sem curinga — cada dado vale apenas a propria face

---

## Elenco de personagens

Todos sao parodias de personagens iconicos da TV. Cada um precisa ter
definidos os itens marcados com (**canonico**) ao ser criado ou modificado.

### Apresentadora (parodia Xuxa)

| Item | Valor | Onde esta |
|------|-------|-----------|
| **Personalidade** (canonico) | Otimista, chama todos de "baixinhos" | `dialogues.json` → `apresentadora` |
| **Castigo** (canonico) | Some numa nave espacial de papelao | `PunishmentSystem.gd` |
| **Celebracao** (canonico) | Sobe no feixe dourado da nave | `CelebrationSystem.gd` |
| **Visual** (canonico) | Vestido brilhante, cabelo loiro volumoso | `Assets/Models/Apresentadora.glb` |
| **Cor** (canonico) | Rosa `(1, 0.45, 0.72)` | `Resources/NPCProfiles/Apresentadora.tres` |
| **Efeito de tela** | Flash branco, zoom-out e tremor de decolagem | `EfeitoTela.gd` |
| Agressividade | 0.7 | `Resources/NPCProfiles/Apresentadora.tres` |
| Cautela | 0.3 | `Resources/NPCProfiles/Apresentadora.tres` |
| Frequencia de tells | 0.6 | `Resources/NPCProfiles/Apresentadora.tres` |
| Adereco da torcida | `Acc_OvniHaste` | `Resources/NPCProfiles/Apresentadora.tres` |
| Retrato do menu | 256x256, fundo transparente | `Assets/UI/Retratos/Apresentadora.png` |
| Modelo 3D | .glb com 8 animacoes + materiais | `Assets/Models/Apresentadora.glb` |
| Nave | Disco voador de papelao | `Assets/Models/Nave.glb` |

### Bruxa Jacare (parodia Cuca)

| Item | Valor | Onde esta |
|------|-------|-----------|
| **Personalidade** (canonico) | Sotaque interiorano, rimas de maldicao, bebe pocoes | `dialogues.json` → `bruxa` |
| **Castigo** (canonico) | Pocao explode em gosma verde, some em fumaca | `PunishmentSystem.gd` |
| **Celebracao** (canonico) | Monta na vassoura e sai voando com rastro verde | `CelebrationSystem.gd` |
| **Visual** (canonico) | Pele verde, chapeu pontudo, cauda de jacare | `Assets/Models/Bruxa.glb` |
| **Cor** (canonico) | Verde `(0.55, 0.85, 0.35)` | `Resources/NPCProfiles/Bruxa.tres` |
| **Efeito de tela** | Tela verde que ondula | `EfeitoTela.gd` |
| Agressividade | 0.6 | `Resources/NPCProfiles/Bruxa.tres` |
| Cautela | 0.5 | `Resources/NPCProfiles/Bruxa.tres` |
| Frequencia de tells | 0.4 | `Resources/NPCProfiles/Bruxa.tres` |
| Adereco da torcida | `Acc_ChapeuBruxa` | `Resources/NPCProfiles/Bruxa.tres` |
| Vassoura | Modelo separado | `Assets/Models/Vassoura.glb` |

### Heroi Desastrado (parodia Chapolin)

| Item | Valor | Onde esta |
|------|-------|-----------|
| **Personalidade** (canonico) | Proverbios misturados, martelo de plastico | `dialogues.json` → `heroi` |
| **Castigo** (canonico) | Encolhe com uma pilula | `PunishmentSystem.gd` |
| **Celebracao** (canonico) | Pula e dispara onda de choque | `CelebrationSystem.gd` |
| **Visual** (canonico) | Roupa vermelha com antenas, escudo pequeno | `Assets/Models/Heroi.glb` |
| **Cor** (canonico) | Vermelho `(1, 0.42, 0.35)` | `Resources/NPCProfiles/Heroi.tres` |
| **Efeito de tela** | Campo de visao abre e volta com quique | `EfeitoTela.gd` |
| Agressividade | 0.95 | `Resources/NPCProfiles/Heroi.tres` |
| Cautela | 0.2 | `Resources/NPCProfiles/Heroi.tres` |
| Frequencia de tells | 0.9 | `Resources/NPCProfiles/Heroi.tres` |
| Adereco da torcida | `Acc_Martelo` | `Resources/NPCProfiles/Heroi.tres` |

### Ciborgue (parodia Exterminador)

| Item | Valor | Onde esta |
|------|-------|-----------|
| **Personalidade** (canonico) | Frio, matematico ("Hasta la vista, dadinho") | `dialogues.json` → `ciborgue` |
| **Castigo** (canonico) | Curto-circuito, raiva, grita "EU VOLTAREI!" e derrete no fogo | `PunishmentSystem.gd` |
| **Celebracao** (canonico) | Inclina para a camera com olho vermelho pulsando | `CelebrationSystem.gd` |
| **Visual** (canonico) | Metade do rosto metalico, olho vermelho | `Assets/Models/Ciborgue.glb` |
| **Cor** (canonico) | Azul claro `(0.62, 0.78, 1)` | `Resources/NPCProfiles/Ciborgue.tres` |
| **Efeito de tela** | Glitch vermelho, tremor, dessaturacao | `EfeitoTela.gd` |
| Agressividade | 0.65 | `Resources/NPCProfiles/Ciborgue.tres` |
| Cautela | 0.65 | `Resources/NPCProfiles/Ciborgue.tres` |
| Frequencia de tells | 0.1 | `Resources/NPCProfiles/Ciborgue.tres` |
| Adereco da torcida | `Acc_RoboHaste` | `Resources/NPCProfiles/Ciborgue.tres` |
| Olho robotico | Preto no idle, acende vermelho ao perder dado | `NpcController.gd` |

---

## Estrutura do projeto

```
DadinhoComico/
├── project.godot               # Godot 4.7, GL Compatibility, autoload Partida
├── export_presets.cfg           # Preset "Web" (sem threads)
├── dialogues.json               # Todos os textos do jogo (data-driven)
│
├── Assets/
│   ├── Models/                  # .glb exportados do Blender
│   │   ├── Apresentadora.glb    # 8 animacoes: Idle, Apostar, Dudo, Comemorar,
│   │   ├── Bruxa.glb            #   Castigo, Tell_Olhar, Tell_Cocar, Tell_Bater
│   │   ├── Heroi.glb
│   │   ├── Ciborgue.glb
│   │   ├── Espectador.glb       # Plateia: corpo <600 tris, acessorios Acc_*
│   │   ├── Mesa.glb
│   │   ├── Copo.glb
│   │   ├── Dado.glb
│   │   ├── Nave.glb             # Castigo/celebracao da Apresentadora
│   │   ├── Vassoura.glb         # Celebracao da Bruxa
│   │   ├── Arquibancada.glb     # 3 degraus, ~4 lugares por degrau
│   │   └── Estudio.glb          # Chao, parede curva, painel do logo
│   ├── Source/
│   │   ├── .gdignore            # Godot nao importa esta pasta
│   │   └── Personagens.blend    # Fonte de todos os modelos
│   ├── Audio/
│   │   ├── SFX/                 # Sintetizados por GerarSfx.tscn (.wav)
│   │   │   ├── Dado_Agitar.wav
│   │   │   ├── Dado_Revelar.wav
│   │   │   ├── Dudo.wav
│   │   │   ├── Castigo_Nave/Gosma/Encolher/Choque/Torta.wav
│   │   │   ├── Vitoria.wav
│   │   │   ├── Tell.wav
│   │   │   ├── Clique.wav
│   │   │   └── Plateia_Murmurio/Aplauso/Ooh/Festa.wav
│   │   └── Music/
│   │       └── Tema_Menu.wav
│   └── UI/
│       ├── Retratos/            # 256x256 PNG, fundo transparente (render Workbench)
│       │   ├── Apresentadora.png
│       │   ├── Bruxa.png
│       │   ├── Heroi.png
│       │   └── Ciborgue.png
│       ├── Balao_Dialogo.png
│       ├── Botao_Dudo.png
│       ├── Botao_Apostar.png
│       └── Fonte_HQ.ttf
│
├── Scenes/
│   ├── Menu.tscn                # Escolha de personagem e modo de jogo
│   ├── Main.tscn                # Partida: mesa, camera, HUD, plateia, luzes
│   ├── Mesa.tscn
│   ├── HUD.tscn
│   ├── Plateia.tscn
│   └── NPCs/
│       ├── Apresentadora.tscn
│       ├── Bruxa.tscn
│       ├── Heroi.tscn
│       └── Ciborgue.tscn
│
├── Scripts/
│   ├── Partida.gd               # Autoload: personagem escolhido, atravessa cenas
│   ├── Menu.gd                  # Menu de selecao
│   ├── Main.gd                  # Orquestra rodadas, castigos e celebracoes
│   ├── GameManager.gd           # Logica do Liar's Dice (estado, dados, validacao)
│   ├── StateManager.gd          # Maquina de estados da partida
│   ├── TurnManager.gd           # Ordem dos turnos, eliminacoes
│   ├── DiceSystem.gd            # Lancamento e contagem de dados
│   ├── BetValidator.gd          # Validacao de pedidos (inclui regra do as)
│   ├── NpcAI.gd                 # IA com 5 niveis, probabilidade + personalidade
│   ├── NpcProfile.gd            # Resource: nome, agressividade, cautela, tells, cor
│   ├── NpcController.gd         # Animacoes, tells, olhar, festejar
│   ├── MesaController.gd        # Copos e dados fisicos: agitar, revelar
│   ├── HudController.gd         # Toda a UI: placar, painel, baloes, log, falas
│   ├── PunishmentSystem.gd      # Castigo de cada personagem (modelo + efeito)
│   ├── CelebrationSystem.gd     # Numero de vitoria de cada personagem
│   ├── EfeitoTela.gd            # Efeitos de tela (castigo, foco, confete)
│   ├── OlharModifier.gd         # SkeletonModifier3D: cabeca olha para alvo
│   ├── FestaModifier.gd         # SkeletonModifier3D: bracos em V + balanco
│   ├── DialogueLoader.gd        # Le e formata textos de dialogues.json
│   ├── Sfx.gd                   # Sfx.tocar("nome") → Assets/Audio/SFX/nome.wav
│   ├── PlateiaController.gd     # Monta e anima plateia com diversidade
│   ├── LogHistorico.gd          # Painel de historico da partida
│   └── CameraSetup.gd           # Camera estatica
│
├── Resources/
│   └── NPCProfiles/             # Um .tres por personagem (NpcProfile)
│       ├── Apresentadora.tres
│       ├── Bruxa.tres
│       ├── Heroi.tres
│       └── Ciborgue.tres
│
├── tools/
│   ├── Screenshot.tscn/.gd      # Validacao visual sem abrir o editor
│   ├── DumpTree.tscn            # Imprime arvore, ossos e animacoes
│   └── GerarSfx.tscn            # Sintetiza SFX curtos
│
├── Build/
│   ├── .gdignore                # Editor nao importa o build
│   └── Web/                     # Saida do export (git-ignored)
│
├── docs/
│   ├── game_bible.md            # Regras canonicas, direcao de arte, arquitetura
│   └── project_structure.md     # Descricao detalhada dos scripts e cenas
│
└── .github/
    └── workflows/
        └── deploy-web.yml       # CI: exporta e publica no GitHub Pages
```

---

## Como rodar localmente

### Requisitos

- **Godot 4.7.2** (Standard, nao .NET)
- Windows, Linux ou macOS

### Passos

1. Clone o repositorio:
   ```bash
   git clone https://github.com/thiegoabcsampaio/DadinhoComico.git
   ```
2. Abra o `project.godot` no editor do Godot
3. Aperte **F5** para rodar (a cena inicial e `Menu.tscn`)

---

## Como exportar e publicar

### Export manual (Web)

1. Instale os export templates para Godot 4.7.2 (menu Editor → Manage Export Templates)
2. No editor: Project → Export → Web → Export Project
3. Ou via linha de comando:
   ```bash
   godot --headless --path . --export-release Web Build/Web/index.html
   ```
4. Teste localmente servindo `Build/Web/` com headers COOP/COEP:
   ```
   Cross-Origin-Opener-Policy: same-origin
   Cross-Origin-Embedder-Policy: require-corp
   ```
   O preset usa `thread_support=false`, entao funciona mesmo sem esses headers
   (caso do GitHub Pages padrao)

### Push manual para gh-pages

Se preferir nao usar o Action automatico:

```bash
# Exportar
godot --headless --path . --export-release Web Build/Web/index.html

# Criar/atualizar branch gh-pages
git worktree add /tmp/gh-pages gh-pages 2>/dev/null || git worktree add /tmp/gh-pages --orphan gh-pages
cp -r Build/Web/* /tmp/gh-pages/
touch /tmp/gh-pages/.nojekyll
cd /tmp/gh-pages && git add -A && git commit -m "deploy" && git push origin gh-pages
cd - && git worktree remove /tmp/gh-pages
```

---

## Deploy automatico (GitHub Actions)

O workflow `.github/workflows/deploy-web.yml` exporta o jogo e publica no
GitHub Pages automaticamente a cada push na branch `main`.

### Como configurar

1. No repositorio GitHub, va em **Settings → Pages**
2. Em **Source**, selecione **GitHub Actions**
3. Pronto — qualquer push na `main` dispara o deploy

### Como acionar manualmente

- Va na aba **Actions** do repositorio
- Clique em **Deploy to GitHub Pages** na lista de workflows
- Clique em **Run workflow → Run workflow**

O workflow usa a imagem `barichello/godot-ci:4.7.2` que ja traz o Godot e os
export templates. O build sai em `Build/Web/` e e publicado via
`actions/deploy-pages`.

---

## Ferramentas de validacao

Na pasta `tools/` ha scripts para testar sem abrir o editor:

```bash
# Importar e validar scripts (sem janela)
godot --headless --path . --import

# Screenshot do jogo rodando
godot --path . tools/Screenshot.tscn -- captura.png [modo] [frames]
```

Modos disponiveis para Screenshot:
- `jogo` — vista padrao da partida (default)
- `revelacao` — copos levantados com faces visiveis
- `castigos` — dispara os 4 castigos ao mesmo tempo
- `vez` — painel de jogada aberto
- `zoom` — dados voando do copo ao placar
- `vitoria [assento]` — celebracao do vencedor
- `vitoria_perto [assento]` — close na celebracao
- `falas` — painel de provocacoes aberto
- `log` — historico da partida preenchido
- `plateia` — close na arquibancada
- `fps` — benchmark sem vsync
- `menu` / `menu_hover` — tela do menu

---

## Convencoes do projeto

| O que | Convencao |
|-------|-----------|
| Pastas | PascalCase (`Assets/`, `Scripts/`) |
| Arquivos de asset | PascalCase (`Mesa.glb`, `Dado_Diffuse.png`) |
| Documentacao | snake_case (`game_bible.md`) |
| Scripts GDScript | PascalCase (`StateManager.gd`) |
| Assets 3D | `.glb` (GLTF binary) do Blender |
| Audio | `.wav` sintetizado (`tools/GerarSfx.tscn`) |
| Textos | Todos em `dialogues.json`, nunca hardcoded |
| Perfis NPC | `Resources/NPCProfiles/*.tres` (NpcProfile) |
| Escala | Mesa a 0.75m, cabeca a ~1.2m, dados de 4cm |
| Personagens | Olham para +Z no .glb; rotacao no assento em Main.tscn |
| Assentos | 0=fundo (jogador), 1=esquerda, 2=direita, 3=frente-esquerda |
| Roupas | Malha propria com espessura (casca/manga/vestir), nunca corpo pintado |
| Materiais | Cor base sem textura; rugosidade define o tecido |

---

## Como criar um novo personagem

Para adicionar um 5o personagem ao jogo, defina cada item canonico:

### 1. Modelo 3D (`Assets/Models/<Nome>.glb`)

Crie no `Assets/Source/Personagens.blend` e exporte com
`export_animation_mode='NLA_TRACKS'`. O modelo precisa ter:

- Armature compativel (mesmos ossos: head, spine, upper_arm_L/R etc.)
- 8 animacoes: `Idle`, `Apostar`, `Dudo`, `Comemorar`, `Castigo`,
  `Tell_Olhar`, `Tell_Cocar`, `Tell_Bater`
- Roupas como malhas separadas com espessura (funcoes `casca`, `manga`, `vestir`)
- Materiais com rugosidade definindo o tecido (couro 0.32, cetim 0.16, etc.)

### 2. Retrato (`Assets/UI/Retratos/<Nome>.png`)

- 256x256, fundo transparente, render Workbench no Blender

### 3. Perfil de IA (`Resources/NPCProfiles/<Nome>.tres`)

Crie um NpcProfile com:
- `nome`: nome exibido na HUD
- `chave_dialogo`: chave em `dialogues.json`
- `agressividade`: 0.0 a 1.0
- `cautela`: 0.0 a 1.0
- `frequencia_tells`: 0.0 a 1.0
- `cor`: Color para o log e cartao do menu
- `adereco_torcida`: nome do acessorio em `Espectador.glb` (ex.: `"Acc_Martelo"`)

### 4. Dialogos (`dialogues.json`)

Adicione uma secao com a `chave_dialogo` contendo:
- `nome`, `apresentacao`, `provocacoes`, `reacoes_provocacao`
- `vitoria`, `derrota`
- `apostas`, `insultos`, `defesas`, `reacoes`, `castigos`

### 5. Castigo (`Scripts/PunishmentSystem.gd`)

Adicione um metodo `_castigo_<nome>(alvo, ao_gritar)` e registre no `match`.
Cada castigo tem tres atos: efeito visual, momento dramatico e desaparecimento.

### 6. Celebracao (`Scripts/CelebrationSystem.gd`)

Adicione um metodo `_celebracao_<nome>(alvo)` com o numero de vitoria do personagem.

### 7. Efeito de tela (`Scripts/EfeitoTela.gd`)

Adicione um metodo para o efeito que o jogador sente quando e eliminado como
esse personagem (ex.: flash, glitch, ondulacao).

### 8. Cena (`Scenes/NPCs/<Nome>.tscn`)

Crie a cena com o modelo .glb, AnimationPlayer e os modificadores de esqueleto.

### 9. Registro

- Adicione a cena ao `match` de instanciacao em `Main.gd`
- Adicione o assento (se a mesa crescer) ou ajuste o sorteio

---

## Licenca

Projeto pessoal de aprendizado. Todos os personagens sao parodias originais.
