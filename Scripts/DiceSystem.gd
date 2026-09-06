class_name DiceSystem
extends Node
## Copos e dados de todos os jogadores.
##
## Cada jogador tem um copo (Array de faces). Aqui vive o RNG, o agitar,
## o revelar e a contagem de faces usada na resolução do Dudo.
## Um copo vazio significa jogador eliminado — a entrada é mantida
## para que revelações e contagens continuem funcionando.

signal dados_agitados(jogador_id: int)
signal dado_removido(jogador_id: int, restantes: int)

const FACE_MIN := 1
const FACE_MAX := 6
const DADOS_INICIAIS := 5

## jogador_id -> Array[int] com as faces atuais.
var _copos: Dictionary = {}
var _rng := RandomNumberGenerator.new()


## [semente] = 0 usa um seed aleatório; qualquer outro valor torna a partida
## reproduzível (útil para testes e depuração).
func configurar(ids: Array[int], dados_por_jogador: int = DADOS_INICIAIS, semente: int = 0) -> void:
	if semente == 0:
		_rng.randomize()
	else:
		_rng.seed = semente
	_copos.clear()
	for id in ids:
		var copo: Array[int] = []
		copo.resize(dados_por_jogador)
		copo.fill(FACE_MIN)
		_copos[id] = copo


func agitar_todos() -> void:
	for id in _copos:
		agitar(id)


func agitar(jogador_id: int) -> void:
	var copo: Array[int] = _copos[jogador_id]
	for i in copo.size():
		copo[i] = _rng.randi_range(FACE_MIN, FACE_MAX)
	dados_agitados.emit(jogador_id)


## Cópia ordenada dos dados do jogador (o original nunca sai daqui).
func revelar(jogador_id: int) -> Array[int]:
	var copia: Array[int] = []
	copia.assign(_copos.get(jogador_id, []))
	copia.sort()
	return copia


## jogador_id -> Array[int] ordenado, para todos os copos.
func revelar_todos() -> Dictionary:
	var resultado := {}
	for id in _copos:
		resultado[id] = revelar(id)
	return resultado


## Quantas vezes [face] aparece somando todos os copos.
## Com [ases_curinga] ligado, dados com face 1 contam para qualquer face.
func contar_face(face: int, ases_curinga: bool = false) -> int:
	var total := 0
	for id in _copos:
		for dado in _copos[id]:
			if dado == face or (ases_curinga and dado == FACE_MIN and face != FACE_MIN):
				total += 1
	return total


func quantidade_dados(jogador_id: int) -> int:
	return _copos.get(jogador_id, []).size()


func total_dados() -> int:
	var total := 0
	for id in _copos:
		total += _copos[id].size()
	return total


## Remove um dado do jogador e retorna quantos restam.
func remover_dado(jogador_id: int) -> int:
	var copo: Array[int] = _copos[jogador_id]
	if not copo.is_empty():
		copo.pop_back()
	dado_removido.emit(jogador_id, copo.size())
	return copo.size()
