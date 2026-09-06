class_name TurnManager
extends Node
## Controle da ordem de turnos.
##
## Mantém a ordem fixa dos assentos e a lista de quem ainda está no jogo.
## Não conhece regras de aposta — só responde "de quem é a vez" e
## "quem vem depois".

signal turno_mudou(jogador_id: int)
signal jogador_eliminado(jogador_id: int)

## Ordem fixa dos assentos (nunca muda durante a partida).
var _ordem: Array[int] = []
## Jogadores ainda em jogo, preservando a ordem dos assentos.
var _ativos: Array[int] = []
## Índice em [_ativos] do jogador da vez.
var _indice: int = 0


func configurar(ids: Array[int]) -> void:
	_ordem = ids.duplicate()
	_ativos = ids.duplicate()
	_indice = 0


func jogador_atual() -> int:
	if _ativos.is_empty():
		return -1
	return _ativos[_indice]


## Jogador ativo imediatamente anterior ao atual.
func anterior() -> int:
	if _ativos.is_empty():
		return -1
	return _ativos[(_indice - 1 + _ativos.size()) % _ativos.size()]


## Passa a vez para o próximo jogador ativo e o retorna.
func avancar() -> int:
	if _ativos.is_empty():
		return -1
	_indice = (_indice + 1) % _ativos.size()
	turno_mudou.emit(jogador_atual())
	return jogador_atual()


## Força a vez para um jogador específico (início de rodada).
func definir_atual(jogador_id: int) -> bool:
	var idx := _ativos.find(jogador_id)
	if idx == -1:
		push_warning("TurnManager: jogador %d não está ativo" % jogador_id)
		return false
	_indice = idx
	turno_mudou.emit(jogador_id)
	return true


## Próximo jogador ativo depois de [jogador_id] na ordem dos assentos.
## Funciona mesmo se [jogador_id] já tiver sido eliminado.
func proximo_apos(jogador_id: int) -> int:
	var idx := _ordem.find(jogador_id)
	if idx == -1:
		return -1
	for passo in range(1, _ordem.size() + 1):
		var candidato := _ordem[(idx + passo) % _ordem.size()]
		if candidato in _ativos:
			return candidato
	return -1


func eliminar(jogador_id: int) -> void:
	var idx := _ativos.find(jogador_id)
	if idx == -1:
		return
	_ativos.remove_at(idx)
	# Mantém o índice apontando para o mesmo jogador (ou um válido).
	if idx < _indice:
		_indice -= 1
	if _indice >= _ativos.size():
		_indice = 0
	jogador_eliminado.emit(jogador_id)


func esta_ativo(jogador_id: int) -> bool:
	return jogador_id in _ativos


func ativos() -> Array[int]:
	return _ativos.duplicate()


func restantes() -> int:
	return _ativos.size()


## Retorna o vencedor se sobrou exatamente um jogador; senão -1.
func vencedor() -> int:
	return _ativos[0] if _ativos.size() == 1 else -1
