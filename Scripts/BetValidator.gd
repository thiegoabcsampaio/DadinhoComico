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
	var minima := quantidade_minima(nova.face, anterior)
	if nova.quantidade >= minima:
		return ""
	return "com a face %d o pedido começa em %d" % [nova.face, minima]


## Menor quantidade que ainda supera [anterior] para uma dada [face].
##
## Sem curinga, a regra é a de sempre: subir a quantidade ou, mantendo a
## quantidade, subir a face.
##
## Com o ás curinga valem as três regras do Perudo, porque um ás vale por
## qualquer face e portanto é bem mais forte:
## - trocar de uma face comum para ases custa METADE da quantidade,
##   arredondada para cima (3 x face 6 -> 2 ases; 10 x face 6 -> 5 ases);
## - sair dos ases para uma face comum custa o DOBRO mais um
##   (2 ases -> 5 de qualquer face);
## - de ases para ases, sobe a quantidade como de costume.
func quantidade_minima(face: int, anterior: Aposta) -> int:
	if anterior == null:
		return 1
	var subida := anterior.quantidade if face > anterior.face else anterior.quantidade + 1
	if not ases_curinga:
		return subida
	var nova_as := face == DiceSystem.FACE_MIN
	var antes_as := anterior.face == DiceSystem.FACE_MIN
	if nova_as and not antes_as:
		return int(ceil(anterior.quantidade / 2.0))
	if not nova_as and antes_as:
		return anterior.quantidade * 2 + 1
	if nova_as and antes_as:
		return anterior.quantidade + 1
	return subida


## A menor aposta que ainda é válida depois de [anterior].
## Base para NPCs burros (Etapa 3) e ponto de partida para a IA (Etapa 4).
func aposta_minima_seguinte(anterior: Aposta, jogador: int) -> Aposta:
	if anterior == null:
		return Aposta.new(jogador, 1, DiceSystem.FACE_MIN + 1 if ases_curinga else DiceSystem.FACE_MIN)
	# Procura a menor subida entre todas as faces, contando a regra do ás.
	var melhor: Aposta = null
	for face in range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX + 1):
		var candidata := Aposta.new(jogador, quantidade_minima(face, anterior), face)
		if melhor == null \
				or candidata.quantidade < melhor.quantidade \
				or (candidata.quantidade == melhor.quantidade and candidata.face < melhor.face):
			melhor = candidata
	return melhor


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
