class_name HudController
extends CanvasLayer
## HUD da mesa: seleção de aposta, botões Apostar / Dudo / Ver Dados,
## painel de informação e balões de fala.
##
## Só emite intenções ([signal aposta_solicitada], [signal dudo_solicitado]);
## quem valida e aplica é o GameManager, via Main.gd. Ouve os sinais do
## GameManager para se atualizar.

signal aposta_solicitada(quantidade: int, face: int)
signal dudo_solicitado()

const CENA_BALAO := preload("res://Scenes/BalaoDialogo.tscn")
const DURACAO_BALAO := 2.5

@onready var _label_info: Label = %LabelInfo
@onready var _label_mesa: Label = %LabelDadosMesa
@onready var _label_status: Label = %LabelStatus
@onready var _label_quantidade: Label = %LabelQuantidade
@onready var _botao_menos: Button = %BotaoMenos
@onready var _botao_mais: Button = %BotaoMais
@onready var _faces: HBoxContainer = %Faces
@onready var _botao_apostar: Button = %BotaoApostar
@onready var _botao_dudo: Button = %BotaoDudo
@onready var _botao_ver_dados: Button = %BotaoVerDados
@onready var _painel_dados: PanelContainer = %PainelDados
@onready var _label_meus_dados: Label = %LabelMeusDados
@onready var _label_titulo_dados: Label = %LabelTituloDados
@onready var _label_titulo_qtd: Label = %LabelTituloQtd
@onready var _label_titulo_face: Label = %LabelTituloFace
@onready var _camada_baloes: Control = %Baloes

var _jogo: GameManager
var _humano := 0
var _camera: Camera3D
## jogador_id -> BalaoDialogo
var _baloes := {}
var _vez_ativa := false
var _quantidade := 1
var _face := DiceSystem.FACE_MIN


func _t(chave: String) -> String:
	return DialogueLoader.get_text("ui", chave)


func _ready() -> void:
	_label_info.text = _t("info_inicial")
	_label_titulo_dados.text = _t("titulo_seus_dados")
	_label_titulo_qtd.text = _t("titulo_quantidade")
	_label_titulo_face.text = _t("titulo_face")
	_botao_apostar.text = _t("botao_apostar")
	_botao_dudo.text = _t("botao_dudo")
	_botao_ver_dados.text = _t("botao_ver_dados")

	_botao_menos.pressed.connect(func() -> void: _definir_quantidade(_quantidade - 1))
	_botao_mais.pressed.connect(func() -> void: _definir_quantidade(_quantidade + 1))
	for i in _faces.get_child_count():
		var botao: Button = _faces.get_child(i)
		botao.pressed.connect(_definir_face.bind(i + DiceSystem.FACE_MIN))
	_botao_apostar.pressed.connect(func() -> void: aposta_solicitada.emit(_quantidade, _face))
	_botao_dudo.pressed.connect(func() -> void: dudo_solicitado.emit())
	_botao_ver_dados.toggled.connect(func(ativo: bool) -> void: _painel_dados.visible = ativo)
	_painel_dados.visible = false
	_label_status.text = ""
	habilitar_vez(false)


## [ancoras]: jogador_id -> Node3D onde o balão de fala se prende.
func configurar(jogo: GameManager, humano: int, camera: Camera3D, ancoras: Dictionary) -> void:
	_jogo = jogo
	_humano = humano
	_camera = camera

	for id in ancoras:
		var balao: BalaoDialogo = CENA_BALAO.instantiate()
		_camada_baloes.add_child(balao)
		balao.configurar(ancoras[id], camera)
		_baloes[id] = balao

	jogo.rodada_iniciada.connect(_ao_iniciar_rodada)
	jogo.aposta_feita.connect(_ao_apostar)
	jogo.dudo_declarado.connect(_ao_declarar_dudo)
	jogo.dudo_resolvido.connect(_ao_resolver_dudo)
	jogo.jogador_eliminado.connect(_ao_eliminar)
	jogo.jogo_terminou.connect(_ao_terminar)
	jogo.turnos.turno_mudou.connect(_ao_mudar_turno)


## Liga/desliga os controles de jogada do humano.
func habilitar_vez(ativa: bool) -> void:
	_vez_ativa = ativa
	_botao_menos.disabled = not ativa
	_botao_mais.disabled = not ativa
	for botao in _faces.get_children():
		botao.disabled = not ativa
	_botao_dudo.disabled = not ativa or _jogo == null or _jogo.aposta_atual == null

	if ativa and _jogo != null:
		var minima := _jogo.validador.aposta_minima_seguinte(_jogo.aposta_atual, _humano)
		_quantidade = minima.quantidade
		_face = minima.face
		_label_status.text = _t("sua_vez")
	_atualizar_seletor()


func mostrar_balao(jogador_id: int, texto: String, duracao: float = DURACAO_BALAO) -> void:
	if _baloes.has(jogador_id):
		_baloes[jogador_id].mostrar(texto, duracao)


func mostrar_status(texto: String) -> void:
	_label_status.text = texto


func _definir_quantidade(valor: int) -> void:
	var maximo := maxi(1, _jogo.dados.total_dados()) if _jogo != null else 1
	_quantidade = clampi(valor, 1, maximo)
	_atualizar_seletor()


func _definir_face(face: int) -> void:
	_face = face
	_atualizar_seletor()


func _atualizar_seletor() -> void:
	_label_quantidade.text = str(_quantidade)
	for i in _faces.get_child_count():
		(_faces.get_child(i) as Button).set_pressed_no_signal(i + DiceSystem.FACE_MIN == _face)

	if not _vez_ativa or _jogo == null:
		_botao_apostar.disabled = true
		return
	var nova := BetValidator.Aposta.new(_humano, _quantidade, _face)
	_botao_apostar.disabled = _jogo.validador.motivo_invalida(nova, _jogo.aposta_atual) != ""


func _atualizar_info() -> void:
	var aposta_txt := _t("sem_aposta")
	if _jogo.aposta_atual != null:
		aposta_txt = DialogueLoader.get_fmt("ui", "info_aposta", [_jogo.aposta_atual, _jogo.nome(_jogo.aposta_atual.jogador)])
	_label_info.text = DialogueLoader.get_fmt("ui", "info_rodada", [_jogo.numero_rodada, aposta_txt])

	var partes := PackedStringArray()
	for id in _jogo.turnos.ativos():
		partes.append(DialogueLoader.get_fmt("ui", "dados_jogador", [_jogo.nome(id), _jogo.dados.quantidade_dados(id)]))
	_label_mesa.text = "   ·   ".join(partes)


func _atualizar_meus_dados() -> void:
	var faces := PackedStringArray()
	for dado in _jogo.ver_dados(_humano):
		faces.append(str(dado))
	_label_meus_dados.text = "  ".join(faces)


func _ao_iniciar_rodada(_numero: int) -> void:
	_atualizar_info()
	_atualizar_meus_dados()


func _ao_mudar_turno(jogador_id: int) -> void:
	if jogador_id != _humano and not _jogo.jogo_acabou():
		_label_status.text = DialogueLoader.get_fmt("ui", "vez_de", [_jogo.nome(jogador_id)])


func _ao_apostar(aposta: BetValidator.Aposta) -> void:
	mostrar_balao(aposta.jogador, str(aposta))
	_atualizar_info()


func _ao_declarar_dudo(acusador: int, _acusado: int) -> void:
	mostrar_balao(acusador, _t("dudo"))


func _ao_resolver_dudo(r: BetValidator.ResultadoDudo) -> void:
	var veredicto := _t("verdadeira") if r.aposta_verdadeira else _t("mentira")
	_label_status.text = DialogueLoader.get_fmt("ui", "revelacao", [r.aposta.face, r.contagem_real, veredicto, _jogo.nome(r.perdedor)])
	_atualizar_info()
	_atualizar_meus_dados()


func _ao_eliminar(jogador_id: int) -> void:
	_label_status.text = DialogueLoader.get_fmt("ui", "eliminado", [_jogo.nome(jogador_id)])
	_atualizar_info()


func _ao_terminar(vencedor: int) -> void:
	_label_status.text = DialogueLoader.get_fmt("ui", "vencedor", [_jogo.nome(vencedor)])
	habilitar_vez(false)
