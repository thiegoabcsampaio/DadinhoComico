class_name LogHistorico
extends PanelContainer
## Log da partida, à esquerda da tela, no formato de app de mensagens.
##
## Registra falas, apostas, acusações, revelações e castigos, com o nome de
## quem falou na cor do personagem. Rola sozinho para a última linha.
## Vive apenas durante a partida: [method limpar] zera tudo no Novo jogo.
##
## Montado por código (HudController._criar_log), sem cena própria.

## Máximo de linhas guardadas; as mais antigas somem.
const LIMITE := 60
## Cor de quem não é personagem (revelação, fim de jogo).
const COR_SISTEMA := Color(0.75, 0.72, 0.66)

var _linhas: VBoxContainer
var _rolagem: ScrollContainer


func _ready() -> void:
	custom_minimum_size = Vector2(300.0, 300.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.09, 0.07, 0.06, 0.72)
	fundo.border_color = Color(0.1, 0.1, 0.1, 0.9)
	fundo.set_border_width_all(3)
	fundo.set_corner_radius_all(14)
	fundo.set_content_margin_all(10.0)
	add_theme_stylebox_override("panel", fundo)

	_rolagem = ScrollContainer.new()
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rolagem)

	_linhas = VBoxContainer.new()
	_linhas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_linhas.add_theme_constant_override("separation", 6)
	_linhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rolagem.add_child(_linhas)


## Uma fala de personagem: "Nome" na cor dele e o texto embaixo.
func registrar(nome: String, texto: String, cor: Color) -> void:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 0)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var quem := Label.new()
	quem.text = nome
	quem.add_theme_font_size_override("font_size", 14)
	quem.add_theme_color_override("font_color", cor)
	caixa.add_child(quem)

	var fala := Label.new()
	fala.text = texto
	fala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fala.add_theme_font_size_override("font_size", 15)
	fala.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9))
	caixa.add_child(fala)

	_adicionar(caixa)


## Uma linha de sistema (revelação, eliminação, fim de jogo).
func registrar_evento(texto: String) -> void:
	var linha := Label.new()
	linha.text = "— %s" % texto
	linha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.add_theme_font_size_override("font_size", 14)
	linha.add_theme_color_override("font_color", COR_SISTEMA)
	_adicionar(linha)


## Zera o histórico (a cada partida nova).
func limpar() -> void:
	for filho in _linhas.get_children():
		filho.queue_free()


func _adicionar(no: Control) -> void:
	_linhas.add_child(no)
	while _linhas.get_child_count() > LIMITE:
		_linhas.get_child(0).free()
	# Só dá para rolar até o fim depois que o layout recalculou.
	await get_tree().process_frame
	_rolagem.scroll_vertical = int(_rolagem.get_v_scroll_bar().max_value)
