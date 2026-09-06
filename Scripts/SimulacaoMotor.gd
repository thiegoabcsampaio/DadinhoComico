extends Node
## Simulação do motor lógico + IA — sem UI, só print().
##
## 5 jogadores controlados por NpcAI (os 4 perfis do elenco + um perfil
## neutro no assento 0). Roda uma partida inteira até sobrar um jogador e
## imprime, a cada decisão, as probabilidades que a IA calculou.
##
## Como rodar:
##   - No editor: abra Scenes/SimulacaoMotor.tscn e pressione F6.
##   - Terminal:  godot --headless --path . res://Scenes/SimulacaoMotor.tscn
##
## Os prints aqui são apenas de depuração; textos de jogo ficam em
## dialogues.json, nunca em scripts.

## 0 = aleatório. Qualquer outro valor reproduz exatamente a mesma partida.
@export var semente: int = 0
@export var sair_ao_terminar: bool = true

const PERFIS := {
	1: preload("res://Resources/NPCProfiles/Apresentadora.tres"),
	2: preload("res://Resources/NPCProfiles/Bruxa.tres"),
	3: preload("res://Resources/NPCProfiles/Heroi.tres"),
	4: preload("res://Resources/NPCProfiles/Ciborgue.tres"),
}
## Trava de segurança contra loop infinito numa rodada.
const MAX_ACOES_POR_RODADA := 200

var jogo: GameManager
## jogador_id -> NpcAI
var _ias := {}


func _ready() -> void:
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

	# Assento 0: perfil neutro fazendo as vezes do humano.
	var neutro := NpcProfile.new()
	neutro.nome = "Jogador"
	var ids: Array[int] = [0]
	var nomes := { 0: neutro.nome }
	_ias[0] = NpcAI.new(neutro, semente)
	for assento in PERFIS:
		var perfil: NpcProfile = PERFIS[assento]
		ids.append(assento)
		nomes[assento] = perfil.nome
		_ias[assento] = NpcAI.new(perfil, semente + assento if semente != 0 else 0)

	print("=== SIMULACAO MOTOR + IA — %d jogadores, semente %d ===" % [ids.size(), semente])
	jogo.iniciar_jogo(ids, DiceSystem.DADOS_INICIAIS, semente, nomes)

	while not jogo.jogo_acabou():
		jogo.iniciar_rodada()
		var acoes := 0
		while jogo.estado.esta_em(StateManager.Estado.APOSTANDO) and acoes < MAX_ACOES_POR_RODADA:
			var id := jogo.jogador_atual()
			var ia: NpcAI = _ias[id]
			var decisao := ia.decidir(jogo, id)
			_imprimir_analise(ia)
			jogo.executar_decisao(id, decisao)
			acoes += 1
		if acoes >= MAX_ACOES_POR_RODADA:
			push_error("Simulacao: rodada excedeu %d acoes, abortando" % MAX_ACOES_POR_RODADA)
			break

	print("=== FIM DA SIMULACAO ===")
	if sair_ao_terminar:
		get_tree().quit()


func _imprimir_analise(ia: NpcAI) -> void:
	var a := ia.ultima_analise
	if a.is_empty():
		return
	var extra := ""
	if a.get("blefe", false):
		extra = "  BLEFE" + (" ARRISCADO" if ia.blefe_arriscado else "")
	print("      analise: p_atual=%.2f  melhor=%s (p=%.2f)%s" % [a["p_atual"], a["melhor"], a["p_melhor"], extra])


func _ao_mudar_estado(anterior: StateManager.Estado, novo: StateManager.Estado) -> void:
	print("    [estado] %s -> %s" % [StateManager.nome(anterior), StateManager.nome(novo)])


func _ao_iniciar_rodada(numero: int) -> void:
	print("")
	print("--- RODADA %d — %d dados na mesa ---" % [numero, jogo.dados.total_dados()])
	for id in jogo.turnos.ativos():
		print("  copo de %-13s %s" % [jogo.nome(id) + ":", jogo.ver_dados(id)])
	print("  abre: %s" % jogo.nome(jogo.jogador_atual()))


func _ao_apostar(aposta: BetValidator.Aposta) -> void:
	print("  %s aposta %s" % [jogo.nome(aposta.jogador), aposta])


func _ao_declarar_dudo(acusador: int, acusado: int) -> void:
	print("  %s: DUDO! (acusa %s)" % [jogo.nome(acusador), jogo.nome(acusado)])


func _ao_resolver_dudo(r: BetValidator.ResultadoDudo) -> void:
	var veredicto := "VERDADEIRA" if r.aposta_verdadeira else "MENTIRA"
	print("  revelacao: face %d apareceu %d vez(es) -> aposta %s" % [r.aposta.face, r.contagem_real, veredicto])
	print("  %s perde 1 dado (restam %d)" % [jogo.nome(r.perdedor), jogo.dados.quantidade_dados(r.perdedor)])


func _ao_eliminar(id: int) -> void:
	print("  ** %s ficou sem dados -> CASTIGO **" % jogo.nome(id))


func _ao_terminar(vencedor: int) -> void:
	print("")
	print("=== VENCEDOR: %s (rodada %d) ===" % [jogo.nome(vencedor), jogo.numero_rodada])
