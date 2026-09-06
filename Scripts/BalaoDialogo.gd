class_name BalaoDialogo
extends PanelContainer
## Balão de fala estilo HQ, 2D sobre a cena 3D.
##
## Segue um Node3D (cabeça do personagem) via Camera3D.unproject_position,
## reposicionando a cada frame enquanto estiver visível. Some sozinho após
## a duração informada em [method mostrar].

## Altura acima da origem do alvo onde a ponta do balão encosta.
@export var deslocamento := Vector3(0.0, 1.3, 0.0)

const ALTURA_CAUDA := 16.0
const LARGURA_CAUDA := 10.0
## Largura fixa do texto. Sem isto o balão fica do tamanho da frase, chega a
## 600 pixels e escorre para fora da tela.
const LARGURA_TEXTO := 300.0
## O resultado da rodada é mais estreito, para quebrar em mais linhas e caber
## dentro do tampo da mesa.
const LARGURA_NARRADOR := 220.0
## Folga mínima entre o balão e a borda da tela.
const MARGEM_TELA := 10.0
const ESPESSURA_BORDA := 4.0

## Cores da cauda, que acompanham o painel. Trocadas em [method virar_narrador].
var cor_fundo := Color(1, 1, 1, 1)
var cor_borda := Color(0.1, 0.1, 0.1, 1)
## O balão do narrador é uma legenda, não uma fala: não tem cauda.
var com_cauda := true

## Quanto o balão sai do lugar para não cobrir outro balão nem o log. Quem
## decide é o HudController, que vê a tela inteira de uma vez; aqui o desvio
## só é aplicado e a cauda continua apontando o personagem.
var desvio := Vector2.ZERO
## Posição sem o empurrão, para o HUD comparar sobreposições sem realimentar.
var posicao_base := Vector2.ZERO

var _alvo: Node3D
var _camera: Camera3D
var _restante := 0.0

@onready var _texto: Label = %Texto


func _ready() -> void:
	resized.connect(queue_redraw)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size.x = LARGURA_TEXTO
	hide()


func configurar(alvo: Node3D, camera: Camera3D) -> void:
	_alvo = alvo
	_camera = camera


func mostrar(texto: String, duracao: float) -> void:
	_texto.text = texto
	_restante = duracao
	desvio = Vector2.ZERO
	show()
	# Sem isto o tamanho só valeria no quadro seguinte, e o HUD compararia
	# sobreposições com o tamanho da fala anterior.
	reset_size()
	_reposicionar()


func _process(delta: float) -> void:
	if not visible:
		return
	_restante -= delta
	if _restante <= 0.0:
		hide()
		return
	_reposicionar()


func _reposicionar() -> void:
	if _alvo == null or _camera == null:
		return
	var mundo := _alvo.global_position + deslocamento
	if _camera.is_position_behind(mundo):
		hide()
		return
	var tela := _camera.unproject_position(mundo)
	if com_cauda:
		# A ponta da cauda fica exatamente no ponto projetado.
		posicao_base = tela - Vector2(size.x * 0.5, size.y + ALTURA_CAUDA)
	else:
		# Legenda: fica centrada no ponto, dentro do tampo da mesa.
		posicao_base = tela - size * 0.5
	# Balão de quem está na beirada da mesa não pode sair da tela.
	var limite := get_viewport_rect().size.x - size.x - MARGEM_TELA
	posicao_base.x = clampf(posicao_base.x, MARGEM_TELA, maxf(MARGEM_TELA, limite))
	position = posicao_base + desvio
	if desvio != Vector2.ZERO:
		queue_redraw()


## Cauda triangular desenhada abaixo do painel. Quando o balão é empurrado
## para cima, a cauda estica para continuar apontando o personagem.
func _draw() -> void:
	if not com_cauda:
		return
	var base := Vector2(size.x * 0.5, size.y - ESPESSURA_BORDA)
	var esquerda := base + Vector2(-LARGURA_CAUDA, 0.0)
	var direita := base + Vector2(LARGURA_CAUDA, 0.0)
	# A ponta acompanha o personagem mesmo com o balão deslocado.
	var ponta := Vector2(size.x * 0.5, size.y + ALTURA_CAUDA + ESPESSURA_BORDA) - desvio
	draw_colored_polygon(PackedVector2Array([esquerda, direita, ponta]), cor_fundo)
	draw_polyline(PackedVector2Array([esquerda, ponta, direita]), cor_borda, ESPESSURA_BORDA)


## Transforma este balão na legenda do resultado da rodada: verde escuro,
## texto claro, mais estreito (quebra em mais linhas) e sem cauda, para ficar
## dentro do tampo da mesa sem se confundir com as falas dos personagens.
func virar_narrador() -> void:
	com_cauda = false
	cor_fundo = Color(0.06, 0.24, 0.15)
	cor_borda = Color(0.98, 0.86, 0.35)
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = cor_fundo
	caixa.border_color = cor_borda
	caixa.set_border_width_all(4)
	caixa.set_corner_radius_all(14)
	caixa.content_margin_left = 18.0
	caixa.content_margin_right = 18.0
	caixa.content_margin_top = 10.0
	caixa.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", caixa)
	_texto.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	_texto.custom_minimum_size.x = LARGURA_NARRADOR
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_size()
