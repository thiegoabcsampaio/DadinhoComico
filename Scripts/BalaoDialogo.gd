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
const COR_FUNDO := Color(1, 1, 1, 1)
const COR_BORDA := Color(0.1, 0.1, 0.1, 1)
const ESPESSURA_BORDA := 4.0

var _alvo: Node3D
var _camera: Camera3D
var _restante := 0.0

@onready var _texto: Label = %Texto


func _ready() -> void:
	resized.connect(queue_redraw)
	hide()


func configurar(alvo: Node3D, camera: Camera3D) -> void:
	_alvo = alvo
	_camera = camera


func mostrar(texto: String, duracao: float) -> void:
	_texto.text = texto
	_restante = duracao
	show()
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
	position = tela - Vector2(size.x * 0.5, size.y + ALTURA_CAUDA)


## Cauda triangular desenhada abaixo do painel.
func _draw() -> void:
	var base := Vector2(size.x * 0.5, size.y - ESPESSURA_BORDA)
	var esquerda := base + Vector2(-LARGURA_CAUDA, 0.0)
	var direita := base + Vector2(LARGURA_CAUDA, 0.0)
	var ponta := base + Vector2(0.0, ALTURA_CAUDA + ESPESSURA_BORDA)
	draw_colored_polygon(PackedVector2Array([esquerda, direita, ponta]), COR_FUNDO)
	draw_polyline(PackedVector2Array([esquerda, ponta, direita]), COR_BORDA, ESPESSURA_BORDA)
