extends Node3D
## Fluxo da partida na cena principal.
##
## Liga GameManager, HUD e NPCs: quando é a vez do humano libera a HUD;
## quando é a vez de um NPC espera um instante e aplica a decisão da
## NpcAI. Escolhe as falas dos NPCs (dialogues.json) a cada evento e as
## manda para os balões. Entre rodadas dá tempo para ler a revelação.

const JOGADOR_HUMANO := 0

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
@onready var celebracoes: CelebrationSystem = $Celebracoes
@onready var efeitos: EfeitoTela = $Efeitos
@onready var plateia: PlateiaController = $Plateia
@onready var ambiente: WorldEnvironment = $WorldEnvironment
## Onde o balão do narrador (revelação) se prende: o centro da mesa.
@onready var marcador_narrador: Marker3D = $MarcadorNarrador

## jogador_id -> NpcAI
var _ias := {}
## jogador_id -> NpcController (modelo animado no assento)
var _controladores := {}
## jogador_id -> NpcProfile do personagem que ocupa o assento
var _perfis := {}
## Dados de todos no momento do Dudo (DiceSystem remove um dado antes de
## emitir dudo_resolvido, então a foto é tirada em dudo_declarado).
var _revelacao := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if semente != 0:
		_rng.seed = semente
	else:
		_rng.randomize()
	_sortear_assentos()

	var ids: Array[int] = []
	var nomes := {}
	for assento in _controladores:
		var perfil: NpcProfile = _perfis[assento]
		ids.append(assento)
		nomes[assento] = perfil.nome
		# O jogador controla o próprio personagem: sem IA para ele.
		if assento != JOGADOR_HUMANO:
			var ia := NpcAI.new(perfil, semente + assento if semente != 0 else 0)
			# Cada NPC entra com um nível sorteado: a mesa nunca é a mesma.
			ia.nivel = _rng.randi_range(1, NpcAI.NIVEIS)
			_ias[assento] = ia
	ids = _ordem_da_mesa(ids)

	# Modo escolhido no menu: no "Dados mentirosos" o ás vale por qualquer face.
	jogo.validador.ases_curinga = Partida.ases_curinga
	jogo.iniciar_jogo(ids, DiceSystem.DADOS_INICIAIS, semente, nomes)

	efeitos.configurar(camera, ambiente.environment)
	plateia.acompanhar(jogo)

	var ancoras := {}
	for id in ids:
		ancoras[id] = assentos.get_node("Assento%d" % id)
	ancoras[HudController.NARRADOR] = marcador_narrador
	for id in ids:
		hud.cores_jogadores[id] = _perfis[id].cor
	hud.configurar(jogo, JOGADOR_HUMANO, camera, ancoras)
	hud.registrar_evento(DialogueLoader.get_fmt("ui", "log_modo",
		[DialogueLoader.get_text("ui", "modo_mentirosos" if Partida.ases_curinga else "modo_dadinho")]))
	for id in _ias:
		hud.registrar_evento(DialogueLoader.get_fmt("ui", "log_nivel",
			[jogo.nome(id), _ias[id].nivel, NpcAI.NIVEIS]))

	hud.aposta_solicitada.connect(_ao_humano_apostar)
	hud.dudo_solicitado.connect(_ao_humano_dudo)
	hud.acelerar_alternado.connect(_ao_alternar_aceleracao)
	hud.encerrar_solicitado.connect(_reiniciar_partida)
	hud.provocacao_escolhida.connect(_ao_provocar)
	jogo.aposta_feita.connect(_ao_apostar)
	jogo.dudo_declarado.connect(_ao_declarar_dudo)
	jogo.dudo_resolvido.connect(_ao_resolver_dudo)
	jogo.jogador_eliminado.connect(mesa.remover_copo)
	jogo.jogo_terminou.connect(_ao_terminar)

	_iniciar_rodada()


func _exit_tree() -> void:
	# Nunca deixar a aceleração vazar para outra cena.
	Engine.time_scale = 1.0


## Monta a mesa com o elenco encontrado em Resources/NPCProfiles.
##
## O personagem escolhido no menu senta sempre no assento 0, o do fundo, de
## frente para a câmera; os demais são sorteados entre os outros assentos.
## Se houver mais personagens que assentos, os que sobram ficam de fora
## nesta partida, então acrescentar personagens novos não quebra a mesa.
## A rotação que vira cada um para o centro está no próprio assento.
## Preenche [_controladores] e [_perfis] (0 = o jogador, sem NpcAI).
func _sortear_assentos() -> void:
	var elenco := Elenco.nomes()
	if elenco.is_empty():
		push_error("Main: nenhum personagem em %s" % Elenco.PASTA_PERFIS)
		return
	var escolhido := Partida.personagem if elenco.has(Partida.personagem) else elenco[0]
	var outros := elenco.duplicate()
	outros.erase(escolhido)

	# Fisher-Yates com o RNG local, para a semente continuar reproduzindo
	# a mesma partida (dados, decisões e também os lugares).
	for i in range(outros.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var troca: String = outros[i]
		outros[i] = outros[j]
		outros[j] = troca

	var lugares := assentos.get_child_count()
	var escalados: Array[String] = [escolhido]
	escalados.append_array(outros.slice(0, maxi(0, lugares - 1)))
	for i in escalados.size():
		var nome := escalados[i]
		var assento: Node3D = assentos.get_node("Assento%d" % i)
		var personagem: NpcController = Elenco.cena(nome).instantiate()
		personagem.name = nome
		assento.add_child(personagem)
		_controladores[i] = personagem
		_perfis[i] = Elenco.perfil(nome)


## Ordena os jogadores como eles estão sentados, seguindo para a esquerda
## de quem joga. Sem isto a vez seguia a numeração dos assentos, que não é a
## volta da mesa: o assento 1 é a esquerda e o 3 é a frente.
##
## Cada jogador olha para o centro, então a esquerda dele é o sentido
## anti-horário visto de cima, ou seja, o ângulo do assento crescendo.
func _ordem_da_mesa(ids: Array[int]) -> Array[int]:
	var ordenados := ids.duplicate()
	ordenados.sort_custom(func(a: int, b: int) -> bool:
		return _angulo_do_assento(a) < _angulo_do_assento(b))
	return ordenados


func _angulo_do_assento(jogador_id: int) -> float:
	var assento := assentos.get_node_or_null("Assento%d" % jogador_id) as Node3D
	if assento == null:
		return 0.0
	return fposmod(atan2(assento.position.z, assento.position.x), TAU)


## Seção do personagem em dialogues.json, pelo modelo sentado no assento.
func _chave(jogador_id: int) -> String:
	if not _perfis.has(jogador_id):
		return ""
	return _perfis[jogador_id].chave_dialogo


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
	mesa.agitar()
	Sfx.tocar("Dado_Agitar")
	hud.animar_dados_para_placar(mesa.posicao_copo(JOGADOR_HUMANO), jogo.ver_dados(JOGADOR_HUMANO))
	_processar_turno()


## Espera a mesa terminar de falar. Sem isto, a jogada seguinte atropela o
## balão anterior e ninguém consegue ler.
func _esperar_baloes() -> void:
	if hud.falas_pendentes():
		await hud.fila_vazia


## Chamado após cada jogada. Para no humano (HUD liberada) ou encadeia NPCs.
func _processar_turno() -> void:
	if not jogo.estado.esta_em(StateManager.Estado.APOSTANDO):
		return
	var id := jogo.jogador_atual()
	if id == JOGADOR_HUMANO:
		await _esperar_baloes()
		if not jogo.estado.esta_em(StateManager.Estado.APOSTANDO) or jogo.jogador_atual() != id:
			return
		hud.habilitar_vez(true)
		# Provocações do personagem do jogador contra quem joga em seguida.
		var alvo := jogo.turnos.proximo_apos(JOGADOR_HUMANO)
		var opcoes: Array = []
		for frase in DialogueLoader.get_lines(_chave(JOGADOR_HUMANO), "provocacoes"):
			opcoes.append(str(frase).format({ "nome": jogo.nome(alvo) }))
		hud.preparar_falas(opcoes, alvo)
		return

	hud.habilitar_vez(false)
	await _esperar_baloes()
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
	# O jogador fala pela HUD (HudController) e pelas opções de fala (B4);
	# aqui só os NPCs.
	if not _ias.has(jogador_id):
		return
	hud.mostrar_balao(jogador_id, DialogueLoader.get_random(_chave(jogador_id), categoria, vars))
	_encarar(jogador_id)


## Quem fala olha para o jogador, e a cena fecha um pouco em volta da fala.
func _encarar(jogador_id: int) -> void:
	if not _controladores.has(jogador_id):
		return
	_controladores[jogador_id].olhar_para(camera, HudController.DURACAO_BALAO)
	efeitos.focar(HudController.DURACAO_BALAO)


## Provocação do jogador (não gasta a jogada): sai no balão do personagem
## dele e o alvo responde logo depois.
func _ao_provocar(texto: String, alvo: int) -> void:
	hud.mostrar_balao(JOGADOR_HUMANO, texto)
	if _controladores.has(JOGADOR_HUMANO):
		_controladores[JOGADOR_HUMANO].tocar("Apostar")
	# A resposta entra na fila logo atrás: sai quando a provocação sair.
	if _ias.has(alvo):
		_falar(alvo, "reacoes_provocacao")


func _ao_humano_apostar(quantidade: int, face: int) -> void:
	if jogo.fazer_aposta(JOGADOR_HUMANO, quantidade, face):
		# O personagem do jogador aposta na mesa como qualquer outro.
		if _controladores.has(JOGADOR_HUMANO):
			_controladores[JOGADOR_HUMANO].apostar(false)
		_encarar(JOGADOR_HUMANO)
		_processar_turno()


func _ao_humano_dudo() -> void:
	# A resolução dispara dudo_resolvido -> _ao_resolver_dudo.
	if _controladores.has(JOGADOR_HUMANO):
		_controladores[JOGADOR_HUMANO].tocar("Dudo")
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
	# Quem errou fica em alerta: no Ciborgue isso acende o olho vermelho.
	if _controladores.has(resultado.perdedor):
		_controladores[resultado.perdedor].acender_olho()
	_reagir_e_agendar(resultado)


func _reagir_e_agendar(resultado: BetValidator.ResultadoDudo) -> void:
	await get_tree().create_timer(atraso_reacao).timeout
	var eliminado := jogo.dados.quantidade_dados(resultado.perdedor) == 0
	if eliminado and jogo.jogo_acabou():
		_falar(resultado.perdedor, "derrota")
	else:
		_falar(resultado.perdedor, "castigos" if eliminado else "reacoes")
		if eliminado:
			_castigar(resultado.perdedor)
	await get_tree().create_timer(maxf(0.0, atraso_entre_rodadas - atraso_reacao)).timeout
	# A rodada nova só começa quando a mesa terminou de comentar a anterior.
	await _esperar_baloes()
	_iniciar_rodada()


## Castigo cômico do eliminado no modelo dele (PunishmentSystem). Vale
## também para o jogador: o personagem escolhido sofre o próprio castigo
## na mesa (e o efeito de tela dele, item B1 da rodada 3).
func _castigar(jogador_id: int) -> void:
	if not _controladores.has(jogador_id):
		return
	var controlador: NpcController = _controladores[jogador_id]
	controlador.tocar("Castigo")
	castigos.castigar(_chave(jogador_id), controlador)
	# Se o castigado é o personagem do jogador, a tela sente junto.
	if jogador_id == JOGADOR_HUMANO:
		efeitos.castigo(_chave(jogador_id))


func _ao_terminar(vencedor: int) -> void:
	Engine.time_scale = 1.0
	Sfx.tocar("Vitoria")
	mesa.recolher_copos()
	efeitos.vitoria()
	if _controladores.has(vencedor):
		_controladores[vencedor].tocar("Comemorar")
		var chave := _chave(vencedor)
		if chave == "ciborgue":
			_controladores[vencedor].acender_olho(8.0)
		celebracoes.celebrar(chave, _controladores[vencedor])
	var fala := DialogueLoader.get_random(_chave(vencedor), "vitoria")
	if fala != "":
		hud.mostrar_balao(vencedor, fala)
		if _controladores.has(vencedor):
			_controladores[vencedor].olhar_para(camera, HudController.DURACAO_BALAO)
