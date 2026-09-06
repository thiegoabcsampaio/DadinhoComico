class_name EfeitoTela
extends CanvasLayer
## Efeitos de tela: o que o jogador "sente" (rodada 3).
##
## Duas famílias:
## - [method castigo]: quando o personagem do jogador é castigado, a tela
##   reage do jeito daquele personagem (regra do Game Bible: todo
##   personagem nasce com um castigo no modelo E um efeito de tela).
## - [method focar]: quando alguém fala, a cena escurece de leve e a câmera
##   dá um zoom curto, para o rosto e o balão ficarem mais legíveis.
##
## Nada aqui muda o jogo: é só apresentação, e tudo volta ao normal sozinho.

## Exposição normal da cena (WorldEnvironment do Main).
const EXPOSICAO := 0.85
## Exposição durante uma fala.
const EXPOSICAO_FALA := 0.62
## Campo de visão normal e durante uma fala.
const FOV := 58.0
const FOV_FALA := 52.0
const TRANSICAO_FOCO := 0.35

var _camera: Camera3D
var _ambiente: Environment
var _cor: ColorRect
var _tween_foco: Tween
var _tween_castigo: Tween
## Posição da câmera sem tremor, para o efeito nunca "vazar".
var _pos_camera := Vector3.ZERO


func _ready() -> void:
	layer = 30
	_cor = ColorRect.new()
	_cor.name = "Cor"
	_cor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cor.color = Color(0, 0, 0, 0)
	add_child(_cor)
	_cor.set_anchors_preset(Control.PRESET_FULL_RECT)


func configurar(camera: Camera3D, ambiente: Environment) -> void:
	_camera = camera
	_ambiente = ambiente
	_pos_camera = camera.position
	if _ambiente != null:
		_ambiente.adjustment_enabled = true
		_ambiente.adjustment_saturation = 1.0
		_ambiente.adjustment_brightness = 1.0


# ------------------------------------------------------------------ Falas

## Fala em foco: escurece de leve e aproxima. Volta sozinho em [duracao].
func focar(duracao: float) -> void:
	if _camera == null or _ambiente == null:
		return
	if _tween_foco != null and _tween_foco.is_valid():
		_tween_foco.kill()
	_tween_foco = create_tween().set_parallel()
	_tween_foco.tween_property(_camera, "fov", FOV_FALA, TRANSICAO_FOCO).set_trans(Tween.TRANS_SINE)
	_tween_foco.tween_property(_ambiente, "tonemap_exposure", EXPOSICAO_FALA, TRANSICAO_FOCO)
	var volta := _tween_foco.chain()
	volta.tween_interval(maxf(0.0, duracao - TRANSICAO_FOCO * 2.0))
	var fim := _tween_foco.chain().set_parallel()
	fim.tween_property(_camera, "fov", FOV, TRANSICAO_FOCO).set_trans(Tween.TRANS_SINE)
	fim.tween_property(_ambiente, "tonemap_exposure", EXPOSICAO, TRANSICAO_FOCO)


# ---------------------------------------------------------------- Castigos

## Efeito de tela do castigo de [chave] (seção do personagem em
## dialogues.json). Chamado só quando o castigado é o personagem do jogador.
func castigo(chave: String) -> void:
	if _camera == null:
		return
	if _tween_castigo != null and _tween_castigo.is_valid():
		_tween_castigo.kill()
	_restaurar()
	match chave:
		"apresentadora":
			_decolagem()
		"bruxa":
			_gosma()
		"heroi":
			_encolher()
		"ciborgue":
			_glitch()
		_:
			push_warning("EfeitoTela: sem efeito para '%s'" % chave)


## Apresentadora: flash branco, a câmera recua e treme como na decolagem.
func _decolagem() -> void:
	_cor.color = Color(1, 1, 1, 0)
	_tween_castigo = create_tween()
	_tween_castigo.tween_property(_cor, "color:a", 0.85, 0.12)
	_tween_castigo.parallel().tween_property(_camera, "fov", FOV + 10.0, 0.5).set_trans(Tween.TRANS_BACK)
	_tween_castigo.tween_property(_cor, "color:a", 0.0, 0.9)
	_tween_castigo.parallel().tween_callback(_tremer.bind(1.6, 0.05))
	_tween_castigo.tween_property(_camera, "fov", FOV, 0.6).set_trans(Tween.TRANS_SINE)


## Bruxa: a tela tinge de verde e ondula, como se a poção subisse à cabeça.
func _gosma() -> void:
	_cor.color = Color(0.25, 0.85, 0.2, 0.0)
	_tween_castigo = create_tween()
	_tween_castigo.tween_property(_cor, "color:a", 0.55, 0.3)
	if _ambiente != null:
		_tween_castigo.parallel().tween_property(_ambiente, "adjustment_saturation", 1.8, 0.3)
	# Ondula: o retângulo sobe e desce enquanto a cor está no ar.
	for i in 4:
		_tween_castigo.tween_property(_cor, "offset:y", 26.0, 0.28).set_trans(Tween.TRANS_SINE)
		_tween_castigo.tween_property(_cor, "offset:y", -26.0, 0.28).set_trans(Tween.TRANS_SINE)
	_tween_castigo.tween_property(_cor, "offset:y", 0.0, 0.2)
	_tween_castigo.parallel().tween_property(_cor, "color:a", 0.0, 0.6)
	if _ambiente != null:
		_tween_castigo.parallel().tween_property(_ambiente, "adjustment_saturation", 1.0, 0.6)


## Herói: o campo de visão abre (tudo parece encolher) e volta com quique.
func _encolher() -> void:
	_tween_castigo = create_tween()
	_tween_castigo.tween_property(_camera, "fov", FOV + 26.0, 1.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween_castigo.tween_interval(0.4)
	_tween_castigo.tween_property(_camera, "fov", FOV, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Ciborgue: glitch. Piscadas vermelhas, tremor curto e a cor se esvai.
func _glitch() -> void:
	_cor.color = Color(1, 0.1, 0.08, 0.0)
	_tween_castigo = create_tween()
	if _ambiente != null:
		_tween_castigo.tween_property(_ambiente, "adjustment_saturation", 0.15, 0.5)
	for i in 6:
		_tween_castigo.tween_property(_cor, "color:a", 0.5, 0.05)
		_tween_castigo.tween_property(_cor, "color:a", 0.0, 0.09)
	_tween_castigo.tween_callback(_tremer.bind(0.8, 0.04))
	_tween_castigo.tween_interval(0.8)
	if _ambiente != null:
		_tween_castigo.tween_property(_ambiente, "adjustment_saturation", 1.0, 0.8)


## Tremor de câmera por [duracao], com deslocamento máximo [forca].
func _tremer(duracao: float, forca: float) -> void:
	if _camera == null:
		return
	var tween := create_tween()
	var passos := int(duracao / 0.05)
	for i in passos:
		var queda := 1.0 - float(i) / maxf(1.0, float(passos))
		var desvio := Vector3(randf_range(-forca, forca), randf_range(-forca, forca), 0.0) * queda
		tween.tween_property(_camera, "position", _pos_camera + desvio, 0.05)
	tween.tween_property(_camera, "position", _pos_camera, 0.05)


func _restaurar() -> void:
	_cor.color.a = 0.0
	_cor.offset_top = 0.0
	_cor.offset_bottom = 0.0
	if _camera != null:
		_camera.position = _pos_camera
	if _ambiente != null:
		_ambiente.adjustment_saturation = 1.0
		_ambiente.adjustment_brightness = 1.0
