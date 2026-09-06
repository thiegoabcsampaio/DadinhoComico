extends Node
## Estado que atravessa cenas (autoload "Partida").
##
## O Menu grava aqui o personagem escolhido; Main lê ao montar a mesa.
## Nada de lógica de jogo: só o que precisa sobreviver à troca de cena.

## Nome do nó do personagem que o jogador controla (Scenes/NPCs/<nome>.tscn).
## Precisa ser uma chave de Main.PERFIS.
var personagem: String = "Apresentadora"

## Modo de jogo escolhido no menu.
## true  = Dadinho (padrão): o ás (face 1) é curinga e conta para qualquer
##         face pedida, com as regras de troca do Perudo.
## false = Dados mentirosos: cada dado vale só a própria face.
var ases_curinga: bool = true
