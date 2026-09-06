extends Control
## Tela inicial: escolha do personagem e início da partida (esqueleto).
##
## Um botão por personagem, com nome e frase de apresentação vindos de
## dialogues.json (categoria "apresentacao"). Jogar grava a escolha em
## Partida.personagem e abre Main.tscn. O Opus veste esta tela no item B1
## (cartões, retrato, animação); a estrutura e os textos já estão aqui.

const CENA_JOGO := "res://Scenes/Main.tscn"
## Ordem de exibição; as chaves são nós em Scenes/NPCs/ e Main.PERFIS.
const PERSONAGENS := ["Apresentadora", "Bruxa", "Heroi", "Ciborgue"]

var _escolhido := ""

@onready var _titulo: Label = %Titulo
@onready var _subtitulo: Label = %Subtitulo
@onready var _lista: HBoxContainer = %Lista
@onready var _apresentacao: Label = %Apresentacao
@onready var _botao_jogar: Button = %BotaoJogar


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
		botao.pressed.connect(_escolher.bind(nome, botao))
		_lista.add_child(botao)
	_botao_jogar.pressed.connect(_jogar)


func _escolher(nome: String, botao: Button) -> void:
	_escolhido = nome
	for outro in _lista.get_children():
		(outro as Button).set_pressed_no_signal(outro == botao)
	_apresentacao.text = DialogueLoader.get_random(nome.to_lower(), "apresentacao")
	_botao_jogar.disabled = false


func _jogar() -> void:
	if _escolhido == "":
		return
	Partida.personagem = _escolhido
	get_tree().change_scene_to_file(CENA_JOGO)
