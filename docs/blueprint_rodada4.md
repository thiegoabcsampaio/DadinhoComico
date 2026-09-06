# BLUEPRINT DE MELHORIAS — Rodada 4 (leitura, linguagem, vitoria e plateia)

Documento temporario: apagar quando todos os itens estiverem na main.
Roteamento: [F] = Fable (Blender, assets, arquitetura), [O] = Opus (codigo Godot).
Ordem: Bloco B1..B4 (Opus, nao dependem de asset novo) -> Bloco A (Fable, assets)
-> Bloco C (Opus, integra os assets) -> Bloco D (Fable, fechamento).

---

## Decisoes de linguagem (valem para todo o projeto)

O jogo nao pode remeter a apostas. A acao deixa de ser "apostar":

| Antes | Agora |
| --- | --- |
| Apostar (botao) | Pedir |
| Aposta atual | Pedido atual |
| aposta VERDADEIRA / MENTIRA | pedido VERDADEIRO / MENTIRA |
| {perdedor} paga | {perdedor} perde um dado |
| "eu aposto 2 x face 4" (falas) | "eu peço 2 x face 4" |

Vale so para texto visivel. Os identificadores de codigo (BetValidator,
Aposta, aposta_feita, fazer_aposta) continuam como estao, do mesmo jeito que
"dudo" continuou quando o texto virou "Desconfio".

Castigo: o anuncio vira "Hora da/do <palavra>", sorteado entre 5 opcoes de
show de auditorio, em dialogues.json (ui.hora_castigo).

---

## Bloco B — Opus, primeira leva (sem asset novo)

- [x] B1. FILA DE BALOES. Hoje varios personagens falam ao mesmo tempo e nao
      da tempo de ler. Regra nova: um balao por vez, em fila; o proximo so
      aparece quando o anterior sai. E a jogada seguinte so acontece quando a
      fila esvazia (Main espera antes de chamar o proximo turno). Vale
      inclusive para a fala do jogador: entra na fila como as outras.
      Gancho: HudController.mostrar_balao vira enfileirar; sinal
      `fila_vazia` para Main aguardar. Some com o codigo de desvio/empurrao
      dos baloes, que existia so para dois baloes ao mesmo tempo.
- [x] B2. BALAO DO JOGADOR perto do painel de jogada, e nao sobre a cabeca do
      personagem no fundo da mesa (o jogador olha para os botoes, nao para o
      proprio boneco). Ancorar acima do PainelAcoes.
- [x] B3. LINGUAGEM: aplicar a tabela acima em dialogues.json e nos rotulos.
- [~] B4. HUD, quatro ajustes (3 de 4 prontos):
      - Ultimo pedido em destaque logo abaixo de "Sua vez!", em cor que nao
        seja branca, para o jogador saber o que precisa superar.
      - Dados de "Ver Dados": brancos com pintas pretas (cara de dado, nao
        botao amarelo), sempre dentro do painel, na mesma posicao a cada
        clique. Hoje estouram a moldura e caem em lugares diferentes.
      - Contornos do painel mais finos (bordas de 4 px estao grossas demais).
      - FALTA: rodada e pedido atual saem do topo e vao para um quadro fixo no canto
        inferior direito, no estilo do log, mas sempre visivel.
- [~] B5. BUGS do fim de partida:
      - FALTA: o copo continua na frente do rosto do personagem depois do castigo.
      - [x] Os dados de "Ver Dados" continuam na tela depois que o painel some.
- [ ] B6. IA: nivel de dificuldade sorteado por NPC a cada partida, sempre 5
      niveis (1 facil a 5 dificil) definidos por multiplicadores de
      agressividade/cautela sobre o perfil. Heroi e Ciborgue precisam blefar
      mais (hoje quase nao blefam). Mostrar o nivel de cada um no log ao
      comecar a partida.

## Bloco A — Fable (Blender e textos)

- [ ] A1. MINIATURAS dos 4 personagens para o menu: render de retrato
      (busto, fundo transparente, 256x256 PNG) em Assets/UI/Retratos/.
- [ ] A2. ADERECOS DA PLATEIA, um por personagem, como malhas separadas no
      Espectador.glb (mesmo esquema de Acc_*): martelo do Heroi, plaquinha
      com o rosto do robo, plaquinha com o disco voador, chapeu de bruxa.
      Criatividade liberada (bandeirinha, mao de espuma, etc.).
- [ ] A3. ESPECTADOR ROBO: variante de cabeca metalica para alguns lugares
      da plateia (o Ciborgue nao tem ninguem parecido com ele). A torcida
      continua sorteada: robo na plateia nao precisa torcer pelo Ciborgue.
- [ ] A4. VASSOURA para a Bruxa (vitoria) e o que mais os finais pedirem.
- [ ] A5. TEXTOS em dialogues.json: as 5 opcoes de "Hora da ...", as falas de
      vitoria e de derrota por personagem, e a linguagem nova da tabela.

## Bloco C — Opus, segunda leva (com os assets prontos)

- [ ] C1. MENU com as miniaturas (cartao = retrato + nome + frase).
- [ ] C2. FIM DE PARTIDA por personagem, com confete:
      - Vitoria do jogador: confetes na tela, o personagem levanta o braco e
        faz o numero dele. Bruxa: monta na vassoura, encolhe e sai voando com
        confetes atras. Ciborgue: levanta, aponta para a camera, olho vermelho
        aceso, "Game Over. Eu terminei com voce."
      - Apresentadora e Heroi: definir na mesma linha (nave e martelo).
      - Derrota do jogador: o vencedor faz o numero dele.
- [ ] C3. PLATEIA com os adereços novos e alguns espectadores robo.

## Bloco D — Fable (fechamento)

- [ ] D1. Validacao visual, ajustes finos, apagar este documento e gerar a
      retomada. Depois disso o jogo entra em fase de lancamento (export Web,
      que depende dos templates do Godot instalados na maquina).
