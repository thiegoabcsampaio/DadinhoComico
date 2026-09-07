class_name MesaController
extends Node3D
## Copos e dados físicos da mesa (Etapa 6).
##
## Cada assento tem Copos/Copo<id> com o copo virado (Modelo) e três dados
## (Dado0..2). A lógica dos dados vive em DiceSystem; aqui só se reflete o
## que ela decide: agitar no início da rodada, levantar os copos e mostrar
## as faces reais na revelação, e esconder de novo. Dados removidos somem.

## Quanto o copo sobe na revelação.
const ALTURA_REVELACAO := 0.28
## Altura do copo virado (12 cm x escala 1.4 de Mesa.tscn).
const ALTURA_COPO := 0.168
## Tamanho dos dados na mesa (mesmo valor de Mesa.tscn).
const ESCALA_DADO := 1.2
## Meia aresta do modelo Dado.glb (4 cm, origem na base).
const MEIO_DADO := 0.02

## Faces do modelo Dado.glb: qual rotação deixa cada face virada para cima.
const ROTACAO_FACE := {
	1: Vector3(0.0, 0.0, 0.0),
	2: Vector3(PI / 2.0, 0.0, 0.0),
	3: Vector3(0.0, 0.0, PI / 2.0),
	4: Vector3(0.0, 0.0, -PI / 2.0),
	5: Vector3(-PI / 2.0, 0.0, 0.0),
	6: Vector3(PI, 0.0, 0.0),
}

var _rng := RandomNumberGenerator.new()
## nome do copo -> Tween em andamento (para interromper).
var _tweens := {}

@onready var _copos: Node3D = $Copos


func _ready() -> void:
	_rng.randomize()


## Início de rodada: dados somem sob o copo, copos descem e chacoalham.
## Os dados só voltam a aparecer em [method revelar] ou [method espiar].
func agitar() -> void:
	for copo in _copos.get_children():
		if not copo.visible:
			continue
		for i in 3:
			copo.get_node("Dado%d" % i).visible = false
		var modelo: Node3D = copo.get_node("Modelo")
		_parar(copo)
		var tween := create_tween()
		_tweens[copo.name] = tween
		tween.tween_property(modelo, "position:y", ALTURA_COPO, 0.25).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(modelo, "rotation", Vector3.ZERO, 0.25)
		for i in 5:
			var dx := _rng.randf_range(-0.02, 0.02)
			var dz := _rng.randf_range(-0.02, 0.02)
			tween.tween_property(modelo, "position", Vector3(dx, ALTURA_COPO + 0.01, dz), 0.07)
		tween.tween_property(modelo, "position", Vector3(0.0, ALTURA_COPO, 0.0), 0.08)


## Revelação: [faces] = jogador_id -> Array[int] (DiceSystem.revelar_todos).
func revelar(faces: Dictionary) -> void:
	for id in faces:
		var copo := _copo(id)
		if copo == null or not copo.visible:
			continue
		var dados: Array = faces[id]
		for i in 3:
			var dado: Node3D = copo.get_node("Dado%d" % i)
			dado.visible = i < dados.size()
			if i < dados.size():
				_virar_dado(dado, dados[i])
		var modelo: Node3D = copo.get_node("Modelo")
		_parar(copo)
		var tween := create_tween()
		_tweens[copo.name] = tween
		tween.tween_property(modelo, "position:y", ALTURA_COPO + ALTURA_REVELACAO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(modelo, "rotation", Vector3(0.0, 0.0, deg_to_rad(-20.0)), 0.35)


## Jogador eliminado: copo e dados somem da mesa.
func remover_copo(jogador_id: int) -> void:
	var copo := _copo(jogador_id)
	if copo == null or not copo.visible:
		return
	_parar(copo)
	var tween := create_tween()
	tween.tween_property(copo, "scale", Vector3.ONE * 0.01, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: copo.visible = false)


## Fim de partida: tira todos os copos da mesa. Sem isso o copo do vencedor
## fica entre a câmera e o rosto dele durante a comemoração.
func recolher_copos() -> void:
	for copo in _copos.get_children():
		remover_copo(int(str(copo.name).trim_prefix("Copo")))


## Onde o copo de um jogador está, para efeitos que saem da mesa e vão
## para a HUD. Vector3.ZERO quando o copo já saiu de cena.
func posicao_copo(jogador_id: int) -> Vector3:
	var copo := _copo(jogador_id)
	if copo == null or not copo.visible:
		return Vector3.ZERO
	return copo.global_position


func _copo(jogador_id: int) -> Node3D:
	return _copos.get_node_or_null("Copo%d" % jogador_id) as Node3D


func _parar(copo: Node3D) -> void:
	if _tweens.has(copo.name) and is_instance_valid(_tweens[copo.name]):
		_tweens[copo.name].kill()
	_tweens.erase(copo.name)


## Gira o dado em torno do próprio centro para mostrar [face] para cima,
## com um giro aleatório no eixo vertical para não ficarem todos alinhados.
func _virar_dado(dado: Node3D, face: int) -> void:
	var euler: Vector3 = ROTACAO_FACE.get(face, Vector3.ZERO)
	var giro := Basis.from_euler(Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0)) * Basis.from_euler(euler)
	var basis := giro.scaled(Vector3.ONE * ESCALA_DADO)
	var centro := Vector3(dado.position.x, MEIO_DADO * ESCALA_DADO, dado.position.z)
	var origem := centro - basis * Vector3(0.0, MEIO_DADO, 0.0)
	dado.transform = Transform3D(basis, origem)
