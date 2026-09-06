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
## Folga mínima entre o balão e a borda da tela.
const MARGEM_TELA := 10.0
const COR_FUNDO := Color(1, 1, 1, 1)
const COR_BORDA := Color(0.1, 0.1, 0.1, 1)
const ESPESSURA_BORDA := 4.0

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
	# A ponta da cauda fica exatamente no ponto projetado.
	posicao_base = tela - Vector2(size.x * 0.5, size.y + ALTURA_CAUDA)
	# Balão de quem está na beirada da mesa não pode sair da tela.
	var limite := get_viewport_rect().size.x - size.x - MARGEM_TELA
	posicao_base.x = clampf(posicao_base.x, MARGEM_TELA, maxf(MARGEM_TELA, limite))
	position = posicao_base + desvio
	if desvio != Vector2.ZERO:
		queue_redraw()


## Cauda triangular desenhada abaixo do painel. Quando o balão é empurrado
## para cima, a cauda estica para continuar apontando o personagem.
func _draw() -> void:
	var base := Vector2(size.x * 0.5, size.y - ESPESSURA_BORDA)
	var esquerda := base + Vector2(-LARGURA_CAUDA, 0.0)
	var direita := base + Vector2(LARGURA_CAUDA, 0.0)
	# A ponta acompanha o personagem mesmo com o balão deslocado.
	var ponta := Vector2(size.x * 0.5, size.y + ALTURA_CAUDA + ESPESSURA_BORDA) - desvio
	draw_colored_polygon(PackedVector2Array([esquerda, direita, ponta]), COR_FUNDO)
	draw_polyline(PackedVector2Array([esquerda, ponta, direita]), COR_BORDA, ESPESSURA_BORDA)
