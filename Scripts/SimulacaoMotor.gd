extends Node
## Simulação do motor lógico (Etapa 2) — sem UI, só print().
##
## 5 jogadores simulados com política aleatória "burra": apostam o mínimo
## válido (às vezes um pouco mais) e gritam Dudo com chance proporcional
## ao tamanho da aposta em relação ao total de dados na mesa.
##
## Como rodar:
##   - No editor: abra Scenes/SimulacaoMotor.tscn e pressione F6.
##   - Terminal:  godot --headless --path . res://Scenes/SimulacaoMotor.tscn
##
## Os prints aqui são apenas de depuração; textos de jogo ficam em
## dialogues.json (Etapa 4), nunca em scripts.

## 0 = aleatório. Qualquer outro valor reproduz exatamente a mesma partida.
@export var semente: int = 0
@export var sair_ao_terminar: bool = true

const NOMES := {
	0: "Jogador",
	1: "Apresentadora",
	2: "Bruxa",
	3: "Heroi",
	4: "Ciborgue",
}
## Trava de segurança contra loop infinito numa rodada.
const MAX_ACOES_POR_RODADA := 200

var jogo: GameManager
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if semente == 0:
		_rng.randomize()
	else:
		_rng.seed = semente

	jogo = GameManager.new()
	jogo.name = "GameManager"
	add_child(jogo)

	jogo.estado.estado_mudou.connect(_ao_mudar_estado)
	jogo.rodada_iniciada.connect(_ao_iniciar_rodada)
	jogo.aposta_feita.connect(_ao_apostar)
	jogo.dudo_declarado.connect(_ao_declarar_dudo)
	jogo.dudo_resolvido.connect(_ao_resolver_dudo)
	jogo.jogador_eliminado.connect(_ao_eliminar)
	jogo.jogo_terminou.connect(_ao_terminar)

	var ids: Array[int] = [0, 1, 2, 3, 4]
	print("=== SIMULACAO DO MOTOR LOGICO — %d jogadores, semente %d ===" % [ids.size(), semente])
	jogo.iniciar_jogo(ids, DiceSystem.DADOS_INICIAIS, semente)

	while not jogo.jogo_acabou():
		jogo.iniciar_rodada()
		var acoes := 0
		while jogo.estado.esta_em(StateManager.Estado.APOSTANDO) and acoes < MAX_ACOES_POR_RODADA:
			_jogar_turno(jogo.jogador_atual())
			acoes += 1
		if acoes >= MAX_ACOES_POR_RODADA:
			push_error("Simulacao: rodada excedeu %d acoes, abortando" % MAX_ACOES_POR_RODADA)
			break

	print("=== FIM DA SIMULACAO ===")
	if sair_ao_terminar:
		get_tree().quit()


## Política aleatória de um jogador simulado.
func _jogar_turno(id: int) -> void:
	var atual := jogo.aposta_atual
	var total := jogo.dados.total_dados()

	if atual == null:
		jogo.fazer_aposta(id, _rng.randi_range(1, 2), _rng.randi_range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX))
		return

	# Aposta acima do total de dados é impossível: Dudo garantido.
	# Fora isso, a chance de acusar cresce conforme a aposta "aperta".
	var pressao := float(atual.quantidade) / float(total)
	var chance_dudo := clampf(pressao - 0.15, 0.05, 0.95)
	if atual.quantidade > total or _rng.randf() < chance_dudo:
		jogo.acusar_dudo(id)
		return

	var nova := jogo.validador.aposta_minima_seguinte(atual, id)
	if _rng.randf() < 0.3:
		# Sobe a quantidade e escolhe qualquer face: continua válida.
		nova.quantidade += 1
		nova.face = _rng.randi_range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX)
	jogo.fazer_aposta(id, nova.quantidade, nova.face)


func _nome(id: int) -> String:
	return NOMES.get(id, "Jogador %d" % id)


func _ao_mudar_estado(anterior: StateManager.Estado, novo: StateManager.Estado) -> void:
	print("    [estado] %s -> %s" % [StateManager.nome(anterior), StateManager.nome(novo)])


func _ao_iniciar_rodada(numero: int) -> void:
	print("")
	print("--- RODADA %d — %d dados na mesa ---" % [numero, jogo.dados.total_dados()])
	for id in jogo.turnos.ativos():
		print("  copo de %-13s %s" % [_nome(id) + ":", jogo.ver_dados(id)])
	print("  abre: %s" % _nome(jogo.jogador_atual()))


func _ao_apostar(aposta: BetValidator.Aposta) -> void:
	print("  %s aposta %s" % [_nome(aposta.jogador), aposta])


func _ao_declarar_dudo(acusador: int, acusado: int) -> void:
	print("  %s: DUDO! (acusa %s)" % [_nome(acusador), _nome(acusado)])


func _ao_resolver_dudo(r: BetValidator.ResultadoDudo) -> void:
	var veredicto := "VERDADEIRA" if r.aposta_verdadeira else "MENTIRA"
	print("  revelacao: face %d apareceu %d vez(es) -> aposta %s" % [r.aposta.face, r.contagem_real, veredicto])
	print("  %s perde 1 dado (restam %d)" % [_nome(r.perdedor), jogo.dados.quantidade_dados(r.perdedor)])


func _ao_eliminar(id: int) -> void:
	print("  ** %s ficou sem dados -> CASTIGO **" % _nome(id))


func _ao_terminar(vencedor: int) -> void:
	print("")
	print("=== VENCEDOR: %s (rodada %d) ===" % [_nome(vencedor), jogo.numero_rodada])
