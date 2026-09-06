extends Control
## Tela inicial: escolha do personagem e início da partida (esqueleto).
##
## Um botão por personagem, com nome e frase de apresentação vindos de
## dialogues.json (categoria "apresentacao"). Jogar grava a escolha em
## Partida.personagem e abre Main.tscn. O Opus veste esta tela no item B1
## (cartões, retrato, animação); a estrutura e os textos já estão aqui.

const CENA_JOGO := "res://Scenes/Main.tscn"
## Trilha do menu (Assets/Audio/Music). O loop está ligado no import.
const TEMA := preload("res://Assets/Audio/Music/Tema_Menu.wav")
## Volume da trilha; abaixo dos SFX, para não brigar com os cliques.
const VOLUME_TEMA := -12.0
## Tempo para a música sumir ao entrar na partida.
const FADE := 0.5
## Ordem de exibição; as chaves são nós em Scenes/NPCs/ e Main.PERFIS.
const PERSONAGENS := ["Apresentadora", "Bruxa", "Heroi", "Ciborgue"]
## Cor do cartão de cada personagem (as mesmas do log em Main.CORES).
const COR_CARTAO := {
	"Apresentadora": Color(1.0, 0.55, 0.75),
	"Bruxa": Color(0.62, 0.85, 0.45),
	"Heroi": Color(1.0, 0.52, 0.45),
	"Ciborgue": Color(0.66, 0.8, 1.0),
}

var _escolhido := ""
var _musica: AudioStreamPlayer

@onready var _titulo: Label = %Titulo
@onready var _subtitulo: Label = %Subtitulo
@onready var _lista: HBoxContainer = %Lista
@onready var _apresentacao: Label = %Apresentacao
@onready var _botao_jogar: Button = %BotaoJogar

## Seletor de modo, montado por código logo abaixo dos personagens.
var _dica_modo: Label


func _ready() -> void:
	_titulo.text = DialogueLoader.get_text("ui", "titulo_menu")
	_subtitulo.text = DialogueLoader.get_text("ui", "titulo_escolha")
	_botao_jogar.text = DialogueLoader.get_text("ui", "botao_jogar")
	_botao_jogar.disabled = true
	_apresentacao.text = ""
	for nome in PERSONAGENS:
		var botao := Button.new()
		botao.text = DialogueLoader.get_text(nome.to_lower(), "nome")
		botao.toggle_mode = true
		botao.custom_minimum_size = Vector2(150.0, 64.0)
		_estilizar(botao, COR_CARTAO.get(nome, Color(1.0, 0.84, 0.2)))
		botao.pressed.connect(_escolher.bind(nome, botao))
		_lista.add_child(botao)
	_criar_modos()
	_estilizar(_botao_jogar, Color(1.0, 0.84, 0.2))
	_botao_jogar.pressed.connect(_jogar)

	_musica = AudioStreamPlayer.new()
	_musica.stream = TEMA
	_musica.volume_db = VOLUME_TEMA
	add_child(_musica)
	_musica.play()


## Mesmo estilo HQ da HUD: fundo saturado, borda grossa, cantos redondos.
## O estado pressionado fica mais claro, para a escolha atual saltar.
func _estilizar(botao: Button, cor: Color) -> void:
	botao.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	botao.add_theme_color_override("font_hover_color", Color(0.12, 0.1, 0.08))
	botao.add_theme_color_override("font_pressed_color", Color(0.12, 0.1, 0.08))
	botao.add_theme_color_override("font_disabled_color", Color(0.45, 0.42, 0.38))
	botao.add_theme_font_size_override("font_size", 20)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var caixa := StyleBoxFlat.new()
		match estado:
			"hover":
				caixa.bg_color = cor.lightened(0.18)
			"pressed":
				caixa.bg_color = cor.lightened(0.35)
			"disabled":
				caixa.bg_color = Color(0.8, 0.77, 0.7)
			_:
				caixa.bg_color = cor
		caixa.border_color = Color(0.1, 0.1, 0.1)
		caixa.set_border_width_all(4)
		caixa.set_corner_radius_all(12)
		caixa.set_content_margin_all(10.0)
		botao.add_theme_stylebox_override(estado, caixa)


## Seletor de modo: duas opções exclusivas, com uma linha explicando o que
## muda. Fica entre os personagens e o botão Jogar.
func _criar_modos() -> void:
	var coluna := _apresentacao.get_parent() as VBoxContainer
	var indice := _apresentacao.get_index() + 1

	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 24)
	coluna.add_child(linha)
	coluna.move_child(linha, indice)

	var rotulo := Label.new()
	rotulo.text = DialogueLoader.get_text("ui", "titulo_modo")
	rotulo.add_theme_font_size_override("font_size", 20)
	rotulo.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	linha.add_child(rotulo)

	var grupo := ButtonGroup.new()
	for curinga in [false, true]:
		var opcao := CheckBox.new()
		opcao.text = DialogueLoader.get_text("ui", "modo_mentirosos" if curinga else "modo_dadinho")
		opcao.button_group = grupo
		opcao.button_pressed = curinga == Partida.ases_curinga
		opcao.add_theme_font_size_override("font_size", 20)
		opcao.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
		opcao.add_theme_color_override("font_hover_color", Color(0.15, 0.12, 0.1))
		opcao.add_theme_color_override("font_pressed_color", Color(0.15, 0.12, 0.1))
		linha.add_child(opcao)
		opcao.pressed.connect(_definir_modo.bind(curinga))

	_dica_modo = Label.new()
	_dica_modo.add_theme_font_size_override("font_size", 16)
	_dica_modo.add_theme_color_override("font_color", Color(0.4, 0.33, 0.25))
	_dica_modo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_dica_modo)
	coluna.move_child(_dica_modo, indice + 1)
	_definir_modo(Partida.ases_curinga)


func _definir_modo(curinga: bool) -> void:
	Partida.ases_curinga = curinga
	if _dica_modo != null:
		_dica_modo.text = DialogueLoader.get_text("ui",
			"modo_mentirosos_dica" if curinga else "modo_dadinho_dica")


func _escolher(nome: String, botao: Button) -> void:
	_escolhido = nome
	for outro in _lista.get_children():
		(outro as Button).set_pressed_no_signal(outro == botao)
	_apresentacao.text = DialogueLoader.get_random(nome.to_lower(), "apresentacao")
	_botao_jogar.disabled = false


## A trilha sai devagar antes da mesa aparecer.
func _jogar() -> void:
	if _escolhido == "":
		return
	Partida.personagem = _escolhido
	_botao_jogar.disabled = true
	var tween := create_tween()
	tween.tween_property(_musica, "volume_db", -40.0, FADE)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
