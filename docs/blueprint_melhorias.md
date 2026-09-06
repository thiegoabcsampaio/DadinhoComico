# BLUEPRINT DE MELHORIAS — Rodada 2 (pos-blueprint)

Documento temporario. Cada item e riscado quando entra na main; quando
todos estiverem prontos, este arquivo pode ser apagado (o que for permanente
ja esta em blueprint.md, Etapa 7).

Roteamento: [F] = Fable (Blender MCP e arquitetura), [O] = Opus (codigo Godot).
Regra do revezamento: Fable primeiro (assets e docs), depois Opus (4 itens de
codigo). Ao trocar de modelo, colar o PONTO DE RETOMADA da sessao anterior.

---

## Bloco A — Fable (fazer primeiro, exige Blender conectado)

- [x] A1. Redesign do Ciborgue (REVERTIDO a pedido: o modelo original da Etapa 6 voltou; ver commit). O modelo atual parecia um pinguim (torso
      esferico, braços curtos, roupa preta). Refazer como humanoide
      cibernetico estilo Exterminador: ombros largos, torso reto, jaqueta,
      calça jeans, braço direito de endoesqueleto, metade do rosto metalica
      com olho vermelho. Regravar as 8 animacoes e reexportar Ciborgue.glb.
- [x] A2. Nave da Apresentadora vira disco voador (UFO) de papelao: prato,
      cupula, luzes na borda, pes. Exportar como Nave.glb (mesmo nome) e
      ajustar PunishmentSystem._nave_de_papelao para pairar, puxar a
      apresentadora num feixe e sumir girando.
- [x] A3. blueprint.md: adicionar Etapa 7 (Polimento Final e Ambientacao).
- [x] A4. Este documento e o bloco de retomada para o Opus.

## Bloco B — Opus (codigo Godot, apos o Bloco A)

- [x] B1. Olhar para o jogador ao falar.
      Gancho: Main._falar() -> hud.mostrar_balao(). DialogueLoader e uma
      classe estatica sem sinais; o evento de fala e a chamada de _falar.
      Implementar em NpcController: metodo olhar_para(alvo: Vector3, dur)
      que gira SO o osso "head" (Skeleton3D.set_bone_pose_rotation ou um
      SkeletonModifier3D LookAtModifier3D apontando o osso head) para a
      camera, mantendo o Idle no corpo; voltar ao normal quando o balao
      some (DURACAO_BALAO). Nao girar o no inteiro: o assento ja aponta
      para a mesa e look_at() no no viraria o corpo de costas para a mesa.
      Skeleton3D fica em Modelo/<Nome>_Armature/Skeleton3D.
- [x] B2. Troca de cadeiras a cada partida.
      Gancho: Main._ready() monta PERFIS por assento (const). Trocar por
      var perfis embaralhados (Array.shuffle()) e reparentar as instancias
      NpcController para os Assento1..4 sorteados (o Assento0 e sempre o
      humano). _ias, _controladores e as ancoras dos baloes devem usar o
      mesmo sorteio. Manter a rotacao do assento (esta no no do NPC, em
      Main.tscn: ao reparentar, copiar o transform do NPC que ocupava o
      assento). Reiniciar partida ja recarrega a cena, entao o sorteio em
      _ready basta.
- [x] B3. Zoom dos dados do jogador.
      Gancho: HudController.ver_dados_alternado + MesaController.espiar().
      Ao ligar Ver Dados: camera.unproject_position(Copo0.global_position)
      da o ponto de tela do copo; criar 3 icones 2D (TextureRect ou Label
      com a face) no CanvasLayer nesse ponto e tweenar posicao + escala ate
      o PainelDados (%LabelMeusDados). Ao desligar, o caminho inverso.
      O copo 3D continua inclinando (espiar) por baixo.
- [x] B4. Game feel do painel (HUD).
      Botoes: mouse_entered/exited -> tween de scale 1.0 <-> 1.08 com
      pivot_offset no centro; pressed -> Sfx.tocar("Clique") (gerar um
      .wav curto novo em Assets/Audio/SFX, ou reaproveitar "Tell") e uma
      CPUParticles2D one-shot de 8 particulas na posicao do botao.
      Manter tudo em HudController; nenhum texto novo hardcoded.

Criterio de conclusao do Bloco B: partida completa no F5 com NPCs olhando
para a camera ao falar, assentos diferentes a cada Novo jogo, dados
"voando" para o painel e botoes reagindo ao mouse.

## Bloco C — Etapa 7 (Fable + Opus, ver blueprint.md)

Depende do Bloco B pronto e validado.

---

## Notas do Bloco B (o que mudou em relacao ao planejado)

- B1: o LookAtModifier3D nativo do Godot 4.7.2 nao teve efeito (roda, resolve
  o osso e o alvo, mas nao altera a pose). Foi trocado por Scripts/OlharModifier.gd,
  um SkeletonModifier3D proprio que decompoe o giro em guinada e inclinacao,
  com limites separados, preservando o balanco do Idle. Verificado por medicao
  (residuo de 0 grau em relacao a camera) e por captura de perto.
- B2: o sorteio usa Fisher-Yates com o RNG de Main, e nao Array.shuffle(), para
  que o export `semente` continue reproduzindo a mesma partida, agora incluindo
  os lugares. PERFIS passou a ser indexado por nome de personagem.
- B3: os icones de dado e as particulas ficam numa camada "Efeitos" criada em
  tempo de execucao como ultimo filho da HUD. O no %Baloes e o primeiro filho e
  por isso desenha atras dos paineis, o que escondia os dados em voo.
- B4: o som de clique (Assets/Audio/SFX/Clique.wav) e gerado por sintese em
  tools/GerarSfx.tscn, sem depender do Blender.
