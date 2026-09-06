extends Node3D
## Fluxo da partida na cena principal.
##
## Liga GameManager, HUD e NPCs: quando é a vez do humano libera a HUD;
## quando é a vez de um NPC espera um instante e aplica a decisão da
## NpcAI. Escolhe as falas dos NPCs (dialogues.json) a cada evento e as
## manda para os balões. Entre rodadas dá tempo para ler a revelação.

const JOGADOR_HUMANO := 0
## Perfil de NPC por assento; o assento 0 é o humano.
const PERFIS := {
	1: preload("res://Resources/NPCProfiles/Apresentadora.tres"),
	2: preload("res://Resources/NPCProfiles/Bruxa.tres"),
	3: preload("res://Resources/NPCProfiles/Heroi.tres"),
	4: preload("res://Resources/NPCProfiles/Ciborgue.tres"),
}

## Pausa antes de cada jogada de NPC, para o jogador acompanhar.
@export var atraso_npc: float = 1.2
## Pausa entre a revelação e a reação de quem perdeu o dado.
@export var atraso_reacao: float = 1.5
## Pausa total após a revelação, antes de agitar os dados de novo.
@export var atraso_entre_rodadas: float = 4.5
## 0 = aleatório. Outro valor reproduz a mesma partida (dados e NPCs).
@export var semente: int = 0
## Multiplicador de velocidade do modo espectador (humano eliminado).
@export var aceleracao_espectador: float = 3.0

@onready var jogo: GameManager = $GameManager
@onready var hud: HudController = $HUD
@onready var camera: Camera3D = $Camera3D
@onready var assentos: Node3D = $Assentos
@onready var mesa: MesaController = $Mesa
@onready var castigos: PunishmentSystem = $Castigos

## jogador_id -> NpcAI
var _ias := {}
## jogador_id -> NpcController (modelo animado no assento)
var _controladores := {}
## Dados de todos no momento do Dudo (DiceSystem remove um dado antes de
## emitir dudo_resolvido, então a foto é tirada em dudo_declarado).
var _revelacao := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var ids: Array[int] = [JOGADOR_HUMANO]
	var nomes := { JOGADOR_HUMANO: DialogueLoader.get_text("ui", "nome_jogador") }
	for assento in PERFIS:
		var perfil: NpcProfile = PERFIS[assento]
		ids.append(assento)
		nomes[assento] = perfil.nome
		_ias[assento] = NpcAI.new(perfil, semente + assento if semente != 0 else 0)
	ids.sort()

	jogo.iniciar_jogo(ids, DiceSystem.DADOS_INICIAIS, semente, nomes)

	_rng.randomize()
	var ancoras := {}
	for id in ids:
		var assento: Node3D = assentos.get_node("Assento%d" % id)
		ancoras[id] = assento
		for filho in assento.get_children():
			if filho is NpcController:
				_controladores[id] = filho
	hud.configurar(jogo, JOGADOR_HUMANO, camera, ancoras)

	hud.aposta_solicitada.connect(_ao_humano_apostar)
	hud.dudo_solicitado.connect(_ao_humano_dudo)
	hud.acelerar_alternado.connect(_ao_alternar_aceleracao)
	hud.encerrar_solicitado.connect(_reiniciar_partida)
	jogo.aposta_feita.connect(_ao_apostar)
	jogo.dudo_declarado.connect(_ao_declarar_dudo)
	jogo.dudo_resolvido.connect(_ao_resolver_dudo)
	jogo.jogador_eliminado.connect(mesa.remover_copo)
	jogo.jogo_terminou.connect(_ao_terminar)

	_iniciar_rodada()


func _exit_tree() -> void:
	# Nunca deixar a aceleração vazar para outra cena.
	Engine.time_scale = 1.0


## Modo espectador: os timers de jogada/rodada respeitam Engine.time_scale,
## então acelerar a engine acelera a partida inteira (balões inclusive).
func _ao_alternar_aceleracao(ativo: bool) -> void:
	Engine.time_scale = aceleracao_espectador if ativo else 1.0


## Encerra a partida atual e começa outra do zero (recarrega a cena).
func _reiniciar_partida() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _iniciar_rodada() -> void:
	if jogo.jogo_acabou():
		return
	jogo.iniciar_rodada()
	var quantidades := {}
	for id in _controladores.keys() + [JOGADOR_HUMANO]:
		quantidades[id] = jogo.dados.quantidade_dados(id)
	mesa.atualizar_contagens(quantidades)
	mesa.agitar()
	Sfx.tocar("Dado_Agitar")
	_processar_turno()


## Chamado após cada jogada. Para no humano (HUD liberada) ou encadeia NPCs.
func _processar_turno() -> void:
	if not jogo.estado.esta_em(StateManager.Estado.APOSTANDO):
		return
	var id := jogo.jogador_atual()
	if id == JOGADOR_HUMANO:
		hud.habilitar_vez(true)
		return

	hud.habilitar_vez(false)
	await get_tree().create_timer(atraso_npc).timeout
	# A rodada pode ter terminado enquanto esperávamos.
	if not jogo.estado.esta_em(StateManager.Estado.APOSTANDO) or jogo.jogador_atual() != id:
		return
	var decisao: Dictionary = _ias[id].decidir(jogo, id)
	_animar_decisao(id, decisao)
	jogo.executar_decisao(id, decisao)
	_processar_turno()


## Animação do NPC para a jogada. Um blefe arriscado pode escapar num
## tell (tique nervoso) logo após a aposta, conforme frequencia_tells.
func _animar_decisao(id: int, decisao: Dictionary) -> void:
	if not _controladores.has(id):
		return
	var controlador: NpcController = _controladores[id]
	match decisao.get("acao"):
		GameManager.ACAO_APOSTAR:
			var ia: NpcAI = _ias[id]
			var com_tell: bool = ia.blefe_arriscado and _rng.randf() < ia.perfil.frequencia_tells
			controlador.apostar(com_tell)
		GameManager.ACAO_DUDO:
			controlador.tocar("Dudo")
			Sfx.tocar("Dudo")


## Balão com uma fala aleatória do personagem naquela categoria.
func _falar(jogador_id: int, categoria: String, vars: Dictionary = {}) -> void:
	if not _ias.has(jogador_id):
		return
	var chave: String = _ias[jogador_id].perfil.chave_dialogo
	hud.mostrar_balao(jogador_id, DialogueLoader.get_random(chave, categoria, vars))


func _ao_humano_apostar(quantidade: int, face: int) -> void:
	if jogo.fazer_aposta(JOGADOR_HUMANO, quantidade, face):
		_processar_turno()


func _ao_humano_dudo() -> void:
	# A resolução dispara dudo_resolvido -> _ao_resolver_dudo.
	if jogo.acusar_dudo(JOGADOR_HUMANO):
		Sfx.tocar("Dudo")


func _ao_apostar(aposta: BetValidator.Aposta) -> void:
	_falar(aposta.jogador, "apostas", { "aposta": str(aposta) })


func _ao_declarar_dudo(acusador: int, acusado: int) -> void:
	_revelacao = jogo.dados.revelar_todos()
	_falar(acusador, "insultos", { "nome": jogo.nome(acusado) })
	_falar(acusado, "defesas", { "nome": jogo.nome(acusador) })


func _ao_resolver_dudo(resultado: BetValidator.ResultadoDudo) -> void:
	hud.habilitar_vez(false)
	mesa.revelar(_revelacao)
	Sfx.tocar("Dado_Revelar")
	var vencedor := resultado.aposta.jogador if resultado.aposta_verdadeira else resultado.acusador
	if _controladores.has(vencedor):
		_controladores[vencedor].tocar("Comemorar")
	_reagir_e_agendar(resultado)


func _reagir_e_agendar(resultado: BetValidator.ResultadoDudo) -> void:
	await get_tree().create_timer(atraso_reacao).timeout
	var eliminado := jogo.dados.quantidade_dados(resultado.perdedor) == 0
	_falar(resultado.perdedor, "castigos" if eliminado else "reacoes")
	if eliminado:
		_castigar(resultado.perdedor)
	await get_tree().create_timer(maxf(0.0, atraso_entre_rodadas - atraso_reacao)).timeout
	_iniciar_rodada()


## Castigo cômico do eliminado (PunishmentSystem); o humano leva torta.
func _castigar(jogador_id: int) -> void:
	if _controladores.has(jogador_id):
		var controlador: NpcController = _controladores[jogador_id]
		controlador.tocar("Castigo")
		castigos.castigar(_ias[jogador_id].perfil.chave_dialogo, controlador)
	else:
		castigos.castigar("", null)


func _ao_terminar(vencedor: int) -> void:
	Engine.time_scale = 1.0
	Sfx.tocar("Vitoria")
	if _controladores.has(vencedor):
		_controladores[vencedor].tocar("Comemorar")
