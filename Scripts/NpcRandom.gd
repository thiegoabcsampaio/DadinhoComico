class_name NpcRandom
extends RefCounted
## Política aleatória "burra" para NPCs (Etapa 3).
##
## Aposta o mínimo válido (às vezes um pouco mais) e grita Dudo com chance
## proporcional ao tamanho da aposta em relação ao total de dados na mesa.
## Não olha os próprios dados. A Etapa 4 substitui por NpcAI mantendo a
## mesma interface: [method decidir] -> Dictionary no formato de GameManager.

var _rng := RandomNumberGenerator.new()


## [semente] = 0 usa um seed aleatório.
func _init(semente: int = 0) -> void:
	if semente == 0:
		_rng.randomize()
	else:
		_rng.seed = semente


func decidir(jogo: GameManager, jogador_id: int) -> Dictionary:
	var atual := jogo.aposta_atual
	var total := jogo.dados.total_dados()

	if atual == null:
		return _apostar(_rng.randi_range(1, 2), _rng.randi_range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX))

	# Aposta acima do total de dados é impossível: Dudo garantido.
	# Fora isso, a chance de acusar cresce conforme a aposta "aperta".
	var pressao := float(atual.quantidade) / float(total)
	var chance_dudo := clampf(pressao - 0.15, 0.05, 0.95)
	if atual.quantidade > total or _rng.randf() < chance_dudo:
		return { "acao": GameManager.ACAO_DUDO }

	var nova := jogo.validador.aposta_minima_seguinte(atual, jogador_id)
	if _rng.randf() < 0.3:
		# Sobe a quantidade e escolhe qualquer face: continua válida.
		nova.quantidade += 1
		nova.face = _rng.randi_range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX)
	return _apostar(nova.quantidade, nova.face)


func _apostar(quantidade: int, face: int) -> Dictionary:
	return { "acao": GameManager.ACAO_APOSTAR, "quantidade": quantidade, "face": face }
