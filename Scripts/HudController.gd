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
## Modo espectador (humano eliminado): acelerar a partida ligado/desligado.
signal acelerar_alternado(ativo: bool)
## Encerrar a partida atual / começar um novo jogo.
signal encerrar_solicitado()
## Botão Ver Dados ligado/desligado (o copo do jogador espia na mesa 3D).
signal ver_dados_alternado(ativo: bool)
## O jogador escolheu uma provocação para dizer ao NPC [alvo].
signal provocacao_escolhida(texto: String, alvo: int)

const CENA_BALAO := preload("res://Scenes/BalaoDialogo.tscn")
const DURACAO_BALAO := 2.5

## Balão da revelação, preso ao centro da mesa (não é um jogador).
const NARRADOR := -1
## Espaço mínimo entre dois balões na tela.
const FOLGA_BALAO := 10.0

## Ver Dados: tempo do voo dos dados entre a mesa e o painel.
const DURACAO_ZOOM := 0.4
## Tamanho do ícone de dado que voa.
const TAMANHO_DADO := Vector2(44.0, 44.0)
## Botões crescem este tanto sob o mouse.
const ESCALA_HOVER := 1.08
const DURACAO_HOVER := 0.12

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
@onready var _painel_acoes: PanelContainer = %PainelAcoes
@onready var _painel_espectador: PanelContainer = %PainelEspectador
@onready var _botao_acelerar: Button = %BotaoAcelerar
@onready var _botao_encerrar: Button = %BotaoEncerrar
@onready var _camada_baloes: Control = %Baloes

var _jogo: GameManager
var _humano := 0
var _camera: Camera3D
## jogador_id -> BalaoDialogo
var _baloes := {}
var _vez_ativa := false
var _quantidade := 1
var _face := DiceSystem.FACE_MIN
## Ícones de dado em voo entre a mesa e o painel.
var _dados_voando: Array[Control] = []
## Camada acima dos painéis, para efeitos que não podem ficar escondidos.
var _camada_efeitos: Control
## Log de histórico da partida, à esquerda.
var _log: LogHistorico
## Ícone que abre e fecha o log.
var _botao_log: Button
## Botão Falar e o painel de provocações (falas dinâmicas).
var _botao_falar: Button
var _painel_falas: PanelContainer
## jogador_id -> Color, para o nome no log. Main preenche antes de configurar.
var cores_jogadores := {}
## Os dados ficam parados no painel enquanto Ver Dados está ligado.
var _dados_parados := false


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
	_botao_acelerar.text = _t("botao_acelerar")
	_botao_encerrar.text = _t("botao_encerrar")

	_botao_acelerar.toggled.connect(func(ativo: bool) -> void: acelerar_alternado.emit(ativo))
	_botao_encerrar.pressed.connect(func() -> void: encerrar_solicitado.emit())
	_painel_espectador.visible = false

	_botao_menos.pressed.connect(func() -> void: _definir_quantidade(_quantidade - 1))
	_botao_mais.pressed.connect(func() -> void: _definir_quantidade(_quantidade + 1))
	for i in _faces.get_child_count():
		var botao: Button = _faces.get_child(i)
		botao.pressed.connect(_definir_face.bind(i + DiceSystem.FACE_MIN))
	_botao_apostar.pressed.connect(func() -> void: aposta_solicitada.emit(_quantidade, _face))
	_botao_dudo.pressed.connect(func() -> void: dudo_solicitado.emit())
	_botao_ver_dados.toggled.connect(func(ativo: bool) -> void:
		_painel_dados.visible = ativo
		ver_dados_alternado.emit(ativo))
	_painel_dados.visible = false
	_label_status.text = ""
	_criar_camada_efeitos()
	_criar_log()
	_criar_falas()
	_preparar_game_feel()
	habilitar_vez(false)


# --------------------------------------------------------- Log da partida

## Log à esquerda, montado por código para não inchar HUD.tscn. Começa
## fechado atrás de um ícone: aberto o tempo todo, ele cobria os
## personagens da esquerda e os balões deles.
func _criar_log() -> void:
	_log = LogHistorico.new()
	_log.name = "Log"
	_log.visible = false
	add_child(_log)
	_log.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_log.offset_left = 12.0
	_log.offset_top = 148.0
	_log.offset_right = 292.0
	_log.offset_bottom = -276.0

	_botao_log = Button.new()
	_botao_log.name = "BotaoLog"
	_botao_log.toggle_mode = true
	_botao_log.tooltip_text = _t("titulo_log")
	_botao_log.custom_minimum_size = Vector2(48.0, 48.0)
	_botao_log.size = Vector2(48.0, 48.0)
	_botao_log.position = Vector2(12.0, 96.0)
	for estado in ["normal", "hover", "pressed"]:
		var caixa := StyleBoxFlat.new()
		caixa.bg_color = Color(1.0, 0.92, 0.45) if estado != "normal" else Color(0.98, 0.95, 0.85)
		caixa.border_color = Color(0.1, 0.1, 0.1)
		caixa.set_border_width_all(3)
		caixa.set_corner_radius_all(14)
		# Canto vivo embaixo à esquerda: a "rabicho" do balão de mensagem.
		caixa.corner_radius_bottom_left = 2
		_botao_log.add_theme_stylebox_override(estado, caixa)
	add_child(_botao_log)

	# Três pontinhos de "conversa", desenhados como texto: containers dentro
	# de Button não renderizavam os retângulos de forma confiável.
	var pontos := Label.new()
	pontos.text = "..."
	pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pontos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pontos.add_theme_font_size_override("font_size", 30)
	pontos.add_theme_color_override("font_color", Color(0.2, 0.16, 0.12))
	pontos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_botao_log.add_child(pontos)
	pontos.set_anchors_preset(Control.PRESET_FULL_RECT)
	# O "..." tipográfico senta na linha de base; sobe um pouco para centrar.
	pontos.offset_top = -6.0

	_botao_log.toggled.connect(func(aberto: bool) -> void: _log.visible = aberto)


## Uma fala vai para o log com o nome e a cor de quem falou.
func registrar_log(jogador_id: int, texto: String) -> void:
	if _log == null or _jogo == null:
		return
	var cor: Color = cores_jogadores.get(jogador_id, LogHistorico.COR_SISTEMA)
	_log.registrar(_jogo.nome(jogador_id), texto, cor)


func registrar_evento(texto: String) -> void:
	if _log != null:
		_log.registrar_evento(texto)


# ------------------------------------------------------- Falas dinâmicas

## Botão Falar ao lado dos outros e o painel com as opções de provocação.
func _criar_falas() -> void:
	_botao_falar = Button.new()
	_botao_falar.name = "BotaoFalar"
	_botao_falar.text = _t("botao_falar")
	_botao_apostar.get_parent().add_child(_botao_falar)
	_botao_falar.pressed.connect(_alternar_falas)

	_painel_falas = PanelContainer.new()
	_painel_falas.name = "PainelFalas"
	_painel_falas.visible = false
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.98, 0.95, 0.85, 0.97)
	fundo.border_color = Color(0.1, 0.1, 0.1)
	fundo.set_border_width_all(4)
	fundo.set_corner_radius_all(14)
	fundo.set_content_margin_all(10.0)
	_painel_falas.add_theme_stylebox_override("panel", fundo)
	add_child(_painel_falas)
	_painel_falas.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_painel_falas.offset_left = -330.0
	_painel_falas.offset_right = 330.0
	_painel_falas.offset_top = -420.0
	_painel_falas.offset_bottom = -230.0


## Preenche o painel com as opções do personagem do jogador. [alvo] é o NPC
## que vai ouvir (o nome dele entra na frase).
func preparar_falas(opcoes: Array, alvo: int) -> void:
	if _painel_falas == null:
		return
	for filho in _painel_falas.get_children():
		filho.queue_free()
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	_painel_falas.add_child(coluna)
	for opcao in opcoes:
		var botao := Button.new()
		botao.text = str(opcao)
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		botao.custom_minimum_size = Vector2(0.0, 46.0)
		botao.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
		botao.add_theme_color_override("font_hover_color", Color(0.12, 0.1, 0.08))
		botao.add_theme_font_size_override("font_size", 18)
		for estado in ["normal", "hover", "pressed"]:
			var caixa := StyleBoxFlat.new()
			caixa.bg_color = Color(1.0, 0.92, 0.45) if estado == "hover" else Color(1.0, 0.84, 0.2)
			caixa.border_color = Color(0.1, 0.1, 0.1)
			caixa.set_border_width_all(3)
			caixa.set_corner_radius_all(10)
			caixa.set_content_margin_all(8.0)
			botao.add_theme_stylebox_override(estado, caixa)
		coluna.add_child(botao)
		botao.pressed.connect(func() -> void:
			_painel_falas.visible = false
			provocacao_escolhida.emit(str(opcao), alvo))


func _alternar_falas() -> void:
	if _painel_falas == null:
		return
	_painel_falas.visible = not _painel_falas.visible


## Os balões ficam atrás dos painéis (nó %Baloes, primeiro filho). Dados em
## voo e faíscas precisam do contrário, então vão numa camada criada por
## último, que é desenhada por cima de tudo.
func _criar_camada_efeitos() -> void:
	_camada_efeitos = Control.new()
	_camada_efeitos.name = "Efeitos"
	_camada_efeitos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_camada_efeitos)
	_camada_efeitos.set_anchors_preset(Control.PRESET_FULL_RECT)


# ------------------------------------------------------ Game feel dos botões

## Todo botão cresce sob o mouse, afunda no clique, solta faíscas e toca um
## clique. Só reação visual: quem decide o que a jogada faz continua sendo
## quem ouve os sinais.
func _preparar_game_feel() -> void:
	for botao in _botoes():
		_centralizar_pivo(botao)
		botao.resized.connect(_centralizar_pivo.bind(botao))
		botao.mouse_entered.connect(_escalar_botao.bind(botao, ESCALA_HOVER))
		botao.mouse_exited.connect(_escalar_botao.bind(botao, 1.0))
		botao.pressed.connect(_ao_clicar_botao.bind(botao))


func _botoes() -> Array[Button]:
	var lista: Array[Button] = [
		_botao_menos, _botao_mais, _botao_apostar, _botao_dudo,
		_botao_ver_dados, _botao_acelerar, _botao_encerrar,
	]
	if _botao_falar != null:
		lista.append(_botao_falar)
	if _botao_log != null:
		lista.append(_botao_log)
	for face in _faces.get_children():
		lista.append(face as Button)
	return lista


## O botão precisa escalar a partir do centro, não do canto.
func _centralizar_pivo(botao: Control) -> void:
	botao.pivot_offset = botao.size * 0.5


func _escalar_botao(botao: Button, escala: float) -> void:
	if botao.disabled and escala > 1.0:
		return
	var tween := create_tween()
	tween.tween_property(botao, "scale", Vector2.ONE * escala, DURACAO_HOVER) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ao_clicar_botao(botao: Button) -> void:
	Sfx.tocar("Clique", -6.0)
	botao.scale = Vector2.ONE * 0.9
	var tween := create_tween()
	tween.tween_property(botao, "scale", Vector2.ONE * ESCALA_HOVER, 0.22) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_faiscas(botao.get_global_rect().get_center())


## Faíscas curtas no ponto do clique.
func _faiscas(posicao: Vector2) -> void:
	var particulas := CPUParticles2D.new()
	particulas.amount = 8
	particulas.lifetime = 0.5
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.direction = Vector2.UP
	particulas.spread = 180.0
	particulas.initial_velocity_min = 90.0
	particulas.initial_velocity_max = 170.0
	particulas.gravity = Vector2(0.0, 240.0)
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 4.0
	particulas.color = Color(1.0, 0.85, 0.25)
	_camada_efeitos.add_child(particulas)
	particulas.global_position = posicao
	particulas.emitting = true
	get_tree().create_timer(particulas.lifetime + 0.2).timeout.connect(particulas.queue_free)


# --------------------------------------------------- Zoom dos dados (Ver Dados)

## Leva os dados do jogador do copo na mesa até o painel "Seus dados"
## ([entrando] verdadeiro) ou de volta ao copo. [origem] é a posição do copo
## no mundo; [faces] são as faces reais, as mesmas que o copo 3D mostra.
func animar_dados(origem: Vector3, faces: Array, entrando: bool) -> void:
	_limpar_dados_voando()
	if _camera == null or faces.is_empty() or origem == Vector3.ZERO:
		return
	if _camera.is_position_behind(origem):
		return

	var na_mesa := _camera.unproject_position(origem) - TAMANHO_DADO * 0.5
	var centro_painel := _label_meus_dados.get_global_rect().get_center()
	for i in faces.size():
		var icone := _criar_icone_dado(int(faces[i]))
		_camada_efeitos.add_child(icone)
		_dados_voando.append(icone)

		var lado := (float(i) - (faces.size() - 1) * 0.5) * (TAMANHO_DADO.x + 6.0)
		var no_painel := centro_painel + Vector2(lado, 0.0) - TAMANHO_DADO * 0.5
		icone.position = na_mesa if entrando else no_painel
		icone.scale = Vector2.ONE * (0.3 if entrando else 1.0)
		icone.modulate.a = 0.0

		var tween := create_tween()
		tween.tween_interval(i * 0.07)
		tween.tween_property(icone, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(icone, "position", no_painel if entrando else na_mesa, DURACAO_ZOOM) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(icone, "scale", Vector2.ONE * (1.0 if entrando else 0.3), DURACAO_ZOOM)
		# Indo para o painel os dados FICAM lá, no lugar dos números.
		# Voltando para o copo, somem ao chegar.
		if not entrando:
			tween.tween_property(icone, "modulate:a", 0.0, 0.18)
			tween.tween_callback(icone.queue_free)

	_dados_parados = entrando
	_atualizar_meus_dados()


func _limpar_dados_voando() -> void:
	for icone in _dados_voando:
		if is_instance_valid(icone):
			icone.queue_free()
	_dados_voando.clear()


## Dado desenhado como no seletor de faces: número escuro em ficha clara.
func _criar_icone_dado(face: int) -> Label:
	var icone := Label.new()
	icone.text = str(face)
	icone.size = TAMANHO_DADO
	icone.custom_minimum_size = TAMANHO_DADO
	icone.pivot_offset = TAMANHO_DADO * 0.5
	icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icone.add_theme_font_size_override("font_size", 26)
	icone.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Color(0.99, 0.86, 0.35)
	caixa.border_color = Color(0.15, 0.12, 0.1)
	caixa.set_border_width_all(3)
	caixa.set_corner_radius_all(9)
	icone.add_theme_stylebox_override("normal", caixa)
	return icone


## [ancoras]: jogador_id -> Node3D onde o balão de fala se prende.
func configurar(jogo: GameManager, humano: int, camera: Camera3D, ancoras: Dictionary) -> void:
	_jogo = jogo
	_humano = humano
	_camera = camera

	for id in ancoras:
		var balao: BalaoDialogo = CENA_BALAO.instantiate()
		_camada_baloes.add_child(balao)
		# Os balões dos personagens sobem até a cabeça; o do narrador fica
		# rente ao tampo, no meio da mesa, como legenda da revelação.
		if id == NARRADOR:
			# Logo acima do feltro: a legenda fica deitada dentro da mesa.
			balao.deslocamento = Vector3(0.0, -0.12, 0.0)
			balao.virar_narrador()
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
	# Provocar é opcional e só na própria vez; não gasta a jogada.
	if _botao_falar != null:
		_botao_falar.disabled = not ativa
	if not ativa and _painel_falas != null:
		_painel_falas.visible = false

	if ativa and _jogo != null:
		var minima := _jogo.validador.aposta_minima_seguinte(_jogo.aposta_atual, _humano)
		_quantidade = minima.quantidade
		_face = minima.face
		_label_status.text = _t("sua_vez")
	_atualizar_seletor()


## Mostra a fala no balão do personagem e registra no log da partida.
func mostrar_balao(jogador_id: int, texto: String, duracao: float = DURACAO_BALAO) -> void:
	if _baloes.has(jogador_id):
		_baloes[jogador_id].mostrar(texto, duracao)
	if jogador_id == NARRADOR:
		registrar_evento(texto)
	else:
		registrar_log(jogador_id, texto)


## Dois personagens falando ao mesmo tempo (insulto e defesa) deixavam os
## balões um por cima do outro. Aqui o de baixo fica no lugar e os que
## encostam nele sobem, na ordem de quem está mais ao fundo da mesa.
func _process(_delta: float) -> void:
	# A legenda do resultado ocupa o centro da mesa, onde também fica o texto
	# de status. Enquanto ela estiver no ar, o status sai da frente.
	if _baloes.has(NARRADOR):
		_label_status.visible = not _baloes[NARRADOR].visible

	var visiveis: Array[BalaoDialogo] = []
	for id in _baloes:
		var balao: BalaoDialogo = _baloes[id]
		if balao.visible:
			balao.desvio = Vector2.ZERO
			visiveis.append(balao)
	if visiveis.size() < 2:
		return
	# Quem está mais embaixo na tela (mais perto da câmera) mantém o lugar.
	visiveis.sort_custom(func(a: BalaoDialogo, b: BalaoDialogo) -> bool:
		return a.posicao_base.y > b.posicao_base.y)

	# Só desvia do log quando ele está aberto.
	var log_rect := _log.get_global_rect() if _log != null and _log.visible else Rect2()
	var largura := get_viewport().get_visible_rect().size.x
	var ocupados: Array[Rect2] = []
	for balao in visiveis:
		var retangulo := Rect2(balao.posicao_base, balao.size)
		# O log fica na coluna da esquerda: balão que cairia sobre ele
		# desliza para a direita, em vez de cobrir o histórico.
		if log_rect.has_area() and retangulo.intersects(log_rect):
			retangulo.position.x = minf(log_rect.end.x + FOLGA_BALAO, largura - retangulo.size.x - FOLGA_BALAO)
		var subiu := true
		while subiu:
			subiu = false
			for outro in ocupados:
				if retangulo.intersects(outro):
					retangulo.position.y = outro.position.y - retangulo.size.y - FOLGA_BALAO
					subiu = true
		balao.desvio = retangulo.position - balao.posicao_base
		balao.position = retangulo.position
		ocupados.append(retangulo)


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


## Enquanto os dados estão parados no painel, o número seria repetição.
func _atualizar_meus_dados() -> void:
	if _jogo == null:
		return
	if _dados_parados:
		_label_meus_dados.text = ""
		return
	var faces := PackedStringArray()
	for dado in _jogo.ver_dados(_humano):
		faces.append(str(dado))
	_label_meus_dados.text = "  ".join(faces)


## Ver Dados ligado? Main usa para repor os dados no painel a cada rodada.
func espiando() -> bool:
	return _botao_ver_dados.button_pressed


func _ao_iniciar_rodada(numero: int) -> void:
	_atualizar_info()
	_atualizar_meus_dados()
	registrar_evento(DialogueLoader.get_fmt("ui", "log_rodada", [numero]))


func _ao_mudar_turno(jogador_id: int) -> void:
	if jogador_id != _humano and not _jogo.jogo_acabou():
		_label_status.text = DialogueLoader.get_fmt("ui", "vez_de", [_jogo.nome(jogador_id)])


## Balões genéricos só para o humano; NPCs falam via Main.gd + dialogues.json.
func _ao_apostar(aposta: BetValidator.Aposta) -> void:
	if aposta.jogador == _humano:
		mostrar_balao(aposta.jogador, str(aposta))
	_atualizar_info()


func _ao_declarar_dudo(acusador: int, _acusado: int) -> void:
	if acusador == _humano:
		mostrar_balao(acusador, _t("dudo"))


## A revelação vira texto de status e também um balão do narrador, no
## centro da mesa, para o jogador não precisar olhar para o rodapé.
func _ao_resolver_dudo(r: BetValidator.ResultadoDudo) -> void:
	var veredicto := _t("verdadeira") if r.aposta_verdadeira else _t("mentira")
	# O resultado sai no balão do narrador; repetir no rodapé seria eco.
	_label_status.text = ""
	mostrar_balao(NARRADOR, DialogueLoader.get_random("narrador", "resultado", {
		"face": r.aposta.face,
		"contagem": r.contagem_real,
		"veredicto": veredicto,
		"perdedor": _jogo.nome(r.perdedor),
	}), DURACAO_BALAO + 0.8)
	_atualizar_info()
	_atualizar_meus_dados()


func _ao_eliminar(jogador_id: int) -> void:
	_label_status.text = DialogueLoader.get_fmt("ui", "eliminado", [_jogo.nome(jogador_id)])
	registrar_evento(_label_status.text)
	_atualizar_info()
	if jogador_id == _humano:
		_entrar_modo_espectador()


## Humano fora: some o painel de jogada, aparecem Acelerar / Encerrar.
func _entrar_modo_espectador() -> void:
	habilitar_vez(false)
	_painel_acoes.visible = false
	_painel_espectador.visible = true
	_botao_acelerar.visible = true
	_botao_acelerar.button_pressed = false


func _ao_terminar(vencedor: int) -> void:
	_label_status.text = DialogueLoader.get_fmt("ui", "vencedor", [_jogo.nome(vencedor)])
	registrar_evento(_label_status.text)
	habilitar_vez(false)
	# Fim de jogo: só resta começar outro.
	_painel_acoes.visible = false
	_painel_espectador.visible = true
	_botao_acelerar.button_pressed = false
	_botao_acelerar.visible = false
	_botao_encerrar.text = _t("botao_novo_jogo")
