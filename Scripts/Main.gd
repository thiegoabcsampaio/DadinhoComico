extends Node3D
## Fluxo da partida na cena principal (Etapa 3).
##
## Liga GameManager, HUD e NPCs: quando é a vez do humano libera a HUD;
## quando é a vez de um NPC espera um instante e aplica a decisão da
## política (NpcRandom agora, NpcAI na Etapa 4). Entre rodadas dá um
## tempo para o jogador ler a revelação.

const JOGADOR_HUMANO := 0
# TODO Etapa 4: nomes passam a vir dos NPC profiles (.tres).
const NOMES := {
	0: "Você",
	1: "Apresentadora",
	2: "Bruxa",
	3: "Herói",
	4: "Ciborgue",
}

## Pausa antes de cada jogada de NPC, para o jogador acompanhar.
@export var atraso_npc: float = 1.2
## Pausa após a revelação, antes de agitar os dados de novo.
@export var atraso_entre_rodadas: float = 3.5
## 0 = aleatório. Outro valor reproduz a mesma partida (dados e NPCs).
@export var semente: int = 0

@onready var jogo: GameManager = $GameManager
@onready var hud: HudController = $HUD
@onready var camera: Camera3D = $Camera3D
@onready var assentos: Node3D = $Assentos

var _npc: NpcRandom


func _ready() -> void:
	_npc = NpcRandom.new(semente)

	var ids: Array[int] = [0, 1, 2, 3, 4]
	jogo.iniciar_jogo(ids, DiceSystem.DADOS_INICIAIS, semente, NOMES)

	var ancoras := {}
	for id in ids:
		ancoras[id] = assentos.get_node("Assento%d" % id)
	hud.configurar(jogo, JOGADOR_HUMANO, camera, ancoras)

	hud.aposta_solicitada.connect(_ao_humano_apostar)
	hud.dudo_solicitado.connect(_ao_humano_dudo)
	jogo.dudo_resolvido.connect(_ao_resolver_dudo)

	_iniciar_rodada()


func _iniciar_rodada() -> void:
	if jogo.jogo_acabou():
		return
	jogo.iniciar_rodada()
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
	jogo.executar_decisao(id, _npc.decidir(jogo, id))
	_processar_turno()


func _ao_humano_apostar(quantidade: int, face: int) -> void:
	if jogo.fazer_aposta(JOGADOR_HUMANO, quantidade, face):
		_processar_turno()


func _ao_humano_dudo() -> void:
	# A resolução dispara dudo_resolvido -> _ao_resolver_dudo.
	jogo.acusar_dudo(JOGADOR_HUMANO)


func _ao_resolver_dudo(_resultado: BetValidator.ResultadoDudo) -> void:
	hud.habilitar_vez(false)
	_agendar_proxima_rodada()


func _agendar_proxima_rodada() -> void:
	await get_tree().create_timer(atraso_entre_rodadas).timeout
	_iniciar_rodada()
