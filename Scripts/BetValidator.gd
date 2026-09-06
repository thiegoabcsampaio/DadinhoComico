class_name BetValidator
extends RefCounted
## Regras de aposta e resolução do Dudo.
##
## Lógica pura, sem estado de partida: recebe apostas e contagens, devolve
## veredictos. Reutilizável pela IA (Etapa 4) para avaliar jogadas.

## Regra opcional: dados com face 1 valem como curinga na contagem.
## Desligado por padrão — o game_bible não menciona curingas.
var ases_curinga: bool = false


## Uma aposta: "existem pelo menos [quantidade] dados mostrando [face]
## somando todos os copos da mesa".
class Aposta:
	var jogador: int
	var quantidade: int
	var face: int

	func _init(p_jogador: int, p_quantidade: int, p_face: int) -> void:
		jogador = p_jogador
		quantidade = p_quantidade
		face = p_face

	func _to_string() -> String:
		return "%d x face %d" % [quantidade, face]


class ResultadoDudo:
	var aposta: Aposta
	var acusador: int
	var contagem_real: int
	var aposta_verdadeira: bool
	## Quem perde 1 dado: o acusador (aposta era verdadeira) ou o apostador (era mentira).
	var perdedor: int


func aposta_valida(nova: Aposta, anterior: Aposta) -> bool:
	return motivo_invalida(nova, anterior) == ""


## String vazia = válida. Caso contrário, o motivo (útil para debug e para
## a HUD desabilitar opções na Etapa 3).
func motivo_invalida(nova: Aposta, anterior: Aposta) -> String:
	if nova.face < DiceSystem.FACE_MIN or nova.face > DiceSystem.FACE_MAX:
		return "face fora do intervalo %d-%d" % [DiceSystem.FACE_MIN, DiceSystem.FACE_MAX]
	if nova.quantidade < 1:
		return "quantidade precisa ser pelo menos 1"
	if anterior == null:
		return ""
	if nova.quantidade > anterior.quantidade:
		return ""
	if nova.quantidade == anterior.quantidade and nova.face > anterior.face:
		return ""
	return "aposta precisa subir a quantidade ou, com a mesma quantidade, subir a face"


## A menor aposta que ainda é válida depois de [anterior].
## Base para NPCs burros (Etapa 3) e ponto de partida para a IA (Etapa 4).
func aposta_minima_seguinte(anterior: Aposta, jogador: int) -> Aposta:
	if anterior == null:
		return Aposta.new(jogador, 1, DiceSystem.FACE_MIN)
	if anterior.face < DiceSystem.FACE_MAX:
		return Aposta.new(jogador, anterior.quantidade, anterior.face + 1)
	return Aposta.new(jogador, anterior.quantidade + 1, DiceSystem.FACE_MIN)


## Decide quem perde o dado. [contagem_real] deve vir de
## DiceSystem.contar_face(aposta.face, ases_curinga).
func resolver_dudo(aposta: Aposta, acusador: int, contagem_real: int) -> ResultadoDudo:
	var r := ResultadoDudo.new()
	r.aposta = aposta
	r.acusador = acusador
	r.contagem_real = contagem_real
	r.aposta_verdadeira = contagem_real >= aposta.quantidade
	r.perdedor = acusador if r.aposta_verdadeira else aposta.jogador
	return r
