class_name CelebrationSystem
extends Node
## Celebrações de vitória por personagem (C2 da rodada 4).
##
## Espelho do PunishmentSystem: cada personagem tem um "número" triunfal
## com tweens, partículas e props procedurais. Bruxa voa de vassoura,
## Ciborgue ameaça a câmera, Apresentadora chama a nave e Herói faz o
## chão tremer.

const CENA_VASSOURA := preload("res://Assets/Models/Vassoura.glb")
const CENA_NAVE := preload("res://Assets/Models/Nave.glb")


func celebrar(chave: String, alvo: Node3D) -> void:
	if alvo == null:
		return
	match chave:
		"bruxa":
			_vassoura_voadora(alvo)
		"ciborgue":
			_game_over(alvo)
		"apresentadora":
			_nave_triunfal(alvo)
		"heroi":
			_martelo_heroico(alvo)
		_:
			push_warning("CelebrationSystem: sem celebração para '%s'" % chave)


# --------------------------------------------------------------------- Bruxa
## Monta na vassoura, encolhe e sai voando com confete verde atrás.
func _vassoura_voadora(alvo: Node3D) -> void:
	var raiz: Node = alvo.get_parent() if alvo.get_parent() != null else alvo
	var vassoura: Node3D = CENA_VASSOURA.instantiate()
	raiz.add_child(vassoura)
	vassoura.global_position = alvo.global_position + Vector3(0.0, 0.0, 0.15)
	vassoura.scale = Vector3.ONE * 0.6

	var rastro := _confete_rastro(Color(0.45, 0.9, 0.3))
	alvo.add_child(rastro)
	rastro.position = Vector3(0.0, 0.8, 0.0)
	rastro.emitting = false

	var pos_base := alvo.global_position
	var tween := create_tween()
	tween.tween_property(alvo, "position:y", alvo.position.y + 0.4, 0.7) \
		.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(vassoura, "global_position:y",
		pos_base.y + 0.4, 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: rastro.emitting = true)
	tween.tween_property(alvo, "scale", Vector3.ONE * 0.3, 1.0) \
		.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(vassoura, "scale", Vector3.ONE * 0.25, 1.0)
	tween.parallel().tween_property(alvo, "global_position",
		pos_base + Vector3(3.5, 5.5, -2.0), 1.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(vassoura, "global_position",
		pos_base + Vector3(3.5, 5.5, -1.85), 1.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(alvo, "rotation:y",
		alvo.rotation.y + TAU, 1.8)
	tween.tween_callback(vassoura.queue_free)


# ------------------------------------------------------------------ Ciborgue
## Olho vermelho, inclina para a câmera, luz vermelha pulsante.
func _game_over(alvo: Node3D) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.1, 0.05)
	luz.light_energy = 0.0
	luz.omni_range = 2.5
	luz.position = Vector3(0.0, 1.2, 0.3)
	alvo.add_child(luz)

	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(alvo, "scale", Vector3.ONE * 1.12, 0.6) \
		.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(alvo, "rotation:x",
		deg_to_rad(-8.0), 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(luz, "light_energy", 3.5, 0.4)
	for i in 3:
		tween.tween_property(luz, "light_energy", 1.0, 0.35)
		tween.tween_property(luz, "light_energy", 3.5, 0.35)


# -------------------------------------------------------------- Apresentadora
## A nave desce como charrete triunfal e a leva girando para o alto.
func _nave_triunfal(alvo: Node3D) -> void:
	var raiz: Node = alvo.get_parent() if alvo.get_parent() != null else alvo
	var nave: Node3D = CENA_NAVE.instantiate()
	raiz.add_child(nave)
	nave.global_position = alvo.global_position + Vector3(0.0, 5.5, 0.0)
	nave.scale = Vector3.ONE * 0.7

	var feixe := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.28
	cil.bottom_radius = 0.5
	cil.height = 1.2
	cil.radial_segments = 12
	feixe.mesh = cil
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.4, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	feixe.material_override = mat
	raiz.add_child(feixe)
	feixe.global_position = alvo.global_position + Vector3(0.0, 1.1, 0.0)
	feixe.scale = Vector3(1.0, 0.01, 1.0)

	var pos_base := alvo.global_position
	var altura_pairar := pos_base.y + 1.7
	var tween := create_tween()
	tween.tween_property(nave, "global_position:y", altura_pairar, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(nave, "rotation:y", TAU, 1.2)
	tween.tween_property(feixe, "scale:y", 1.0, 0.3) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(alvo, "position:y", alvo.position.y + 1.8, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(alvo, "rotation:y",
		alvo.rotation.y + TAU, 1.0)
	tween.tween_property(feixe, "scale:y", 0.01, 0.2)
	tween.tween_callback(feixe.queue_free)
	tween.tween_property(nave, "global_position",
		pos_base + Vector3(2.5, 7.0, -1.5), 1.2) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(nave, "rotation:y", TAU * 4.0, 1.2)
	tween.parallel().tween_property(alvo, "global_position",
		pos_base + Vector3(2.5, 6.8, -1.5), 1.2) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(nave.queue_free)


# -------------------------------------------------------------------- Herói
## Pula, cai e faz o chão tremer com uma onda de choque (martelada triunfal).
func _martelo_heroico(alvo: Node3D) -> void:
	var raiz: Node = alvo.get_parent() if alvo.get_parent() != null else alvo

	var onda := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.12
	torus.rings = 24
	torus.ring_segments = 12
	onda.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	onda.material_override = mat
	raiz.add_child(onda)
	onda.global_position = alvo.global_position + Vector3(0.0, 0.05, 0.0)
	onda.scale = Vector3.ONE * 0.01
	onda.rotation.x = deg_to_rad(90.0)

	var pos_y := alvo.position.y
	var tween := create_tween()
	tween.tween_property(alvo, "scale", Vector3(1.2, 0.85, 1.2), 0.15)
	tween.tween_property(alvo, "scale", Vector3(0.9, 1.3, 0.9), 0.2)
	tween.tween_property(alvo, "position:y", pos_y + 0.5, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(alvo, "position:y", pos_y, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(alvo, "scale",
		Vector3(1.15, 0.9, 1.15), 0.2)
	tween.tween_property(onda, "scale", Vector3.ONE * 2.5, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.8)
	tween.parallel().tween_property(alvo, "scale", Vector3.ONE * 1.08, 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(onda.queue_free)


# ----------------------------------------------------------------- Utilidades

func _confete_rastro(cor: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 30
	p.lifetime = 1.2
	p.explosiveness = 0.0
	p.mesh = _mesh_confete()
	p.direction = Vector3(-0.5, -1.0, 0.0)
	p.spread = 45.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.5
	p.gravity = Vector3(0.0, -2.0, 0.0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.color = cor
	return p


func _mesh_confete() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.04, 0.008, 0.025)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	return m
