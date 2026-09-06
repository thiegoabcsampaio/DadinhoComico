class_name PunishmentSystem
extends Node
## Castigos cômicos estilo TV anos 90 (Etapa 6). Zero violência.
##
## [method castigar] recebe o personagem eliminado e monta o efeito em
## cena com tweens, partículas e SFX. Cada personagem tem o seu, definido no
## Game Bible, e ele vale também quando o personagem é o do jogador. Todos os
## efeitos são procedurais (sem assets extras) e se limpam sozinhos.

## Nave de papelão com o X gigante (Assets/Source/Personagens.blend).
const CENA_NAVE := preload("res://Assets/Models/Nave.glb")
const COR_GOSMA := Color(0.35, 0.9, 0.2)


## [chave]: seção do personagem em dialogues.json.
## [alvo]: nó do personagem na mesa (NPC ou o modelo do jogador).
## Regra do projeto: todo personagem tem um castigo aqui e um efeito de
## tela correspondente (rodada 3, item B1), sentido pelo jogador.
func castigar(chave: String, alvo: Node3D) -> void:
	if alvo == null:
		return
	match chave:
		"apresentadora":
			_nave_de_papelao(alvo)
		"bruxa":
			_pocao_de_gosma(alvo)
		"heroi":
			_pilula_encolhedora(alvo)
		"ciborgue":
			_curto_circuito(alvo)
		_:
			push_warning("PunishmentSystem: sem castigo para '%s'" % chave)


# ---------------------------------------------------------------- Apresentadora
## Um disco voador de papelão desce, paira sobre a apresentadora, puxa ela
## num feixe de luz e some girando.
func _nave_de_papelao(alvo: Node3D) -> void:
	Sfx.tocar("Castigo_Nave")
	# A nave fica no pai do alvo para não encolher junto com ele.
	var raiz: Node = alvo.get_parent() if alvo.get_parent() != null else alvo
	var nave: Node3D = CENA_NAVE.instantiate()
	raiz.add_child(nave)
	nave.global_position = alvo.global_position + Vector3(0.0, 5.0, 0.0)
	nave.scale = Vector3.ONE * 0.7

	# A nave paira logo acima da cabeça; o feixe vai do tampo até a nave.
	const ALTURA_PAIRAR := 1.7
	var feixe := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.28
	cil.bottom_radius = 0.5
	cil.height = ALTURA_PAIRAR - 0.5
	cil.radial_segments = 12
	feixe.mesh = cil
	var mat_feixe := _material(Color(1.0, 0.95, 0.4, 0.4), 0.5, true)
	mat_feixe.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	feixe.material_override = mat_feixe
	raiz.add_child(feixe)
	feixe.global_position = alvo.global_position + Vector3(0.0, 0.5 + cil.height * 0.5, 0.0)
	feixe.scale = Vector3(1.0, 0.01, 1.0)

	var altura_pairar := alvo.global_position.y + ALTURA_PAIRAR
	var tween := create_tween()
	tween.tween_property(nave, "global_position:y", altura_pairar, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(nave, "rotation:y", TAU, 1.0)
	# Feixe liga e a apresentadora é puxada para cima, girando e encolhendo.
	tween.tween_property(feixe, "scale:y", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(alvo, "position:y", alvo.position.y + 1.6, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(alvo, "rotation:y", alvo.rotation.y + TAU * 2.0, 1.0)
	tween.parallel().tween_property(alvo, "scale", Vector3.ONE * 0.15, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _esconder(alvo))
	tween.tween_property(feixe, "scale:y", 0.01, 0.2)
	tween.tween_callback(feixe.queue_free)
	# Foge girando para cima e para o lado.
	tween.tween_property(nave, "global_position", alvo.global_position + Vector3(3.0, 6.0, -2.0), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(nave, "rotation:y", TAU * 4.0, 1.0)
	tween.tween_callback(nave.queue_free)


# ------------------------------------------------------------------------ Bruxa
## A própria poção explode: chuva de gosma verde, ela vira uma bolha e some.
func _pocao_de_gosma(alvo: Node3D) -> void:
	Sfx.tocar("Castigo_Gosma")
	var gotas: Array[Node3D] = []
	for i in 14:
		var gota := _esfera(COR_GOSMA, randf_range(0.04, 0.09))
		alvo.add_child(gota)
		gota.position = Vector3(randf_range(-0.35, 0.35), randf_range(2.2, 3.2), randf_range(-0.35, 0.35))
		gotas.append(gota)

	var tween := create_tween()
	for gota in gotas:
		var chao := Vector3(gota.position.x, randf_range(0.5, 1.2), gota.position.z)
		var queda := tween.parallel().tween_property(gota, "position", chao, randf_range(0.5, 0.9))
		queda.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(randf_range(0.0, 0.6))
	tween.tween_interval(0.1)
	for gota in gotas:
		tween.parallel().tween_property(gota, "scale", Vector3(1.6, 0.35, 1.6), 0.15)

	var bolha := _esfera(COR_GOSMA, 0.55)
	bolha.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolha.material_override.albedo_color = Color(COR_GOSMA, 0.75)
	alvo.add_child(bolha)
	bolha.position.y = 0.85
	bolha.scale = Vector3.ONE * 0.01
	tween.tween_property(bolha, "scale", Vector3(1.0, 1.15, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void: _fumaca(alvo, Vector3(0.0, 0.9, 0.0), Color(0.6, 0.9, 0.5)))
	tween.tween_property(alvo, "scale", Vector3.ONE * 0.01, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(alvo, "rotation:y", alvo.rotation.y + TAU * 1.5, 0.35)
	tween.tween_callback(func() -> void:
		for gota in gotas:
			gota.queue_free()
		bolha.queue_free()
		_esconder(alvo))


# ------------------------------------------------------------------------ Herói
## Toma a pílula errada e encolhe até sumir, aos pulinhos.
func _pilula_encolhedora(alvo: Node3D) -> void:
	Sfx.tocar("Castigo_Encolher")
	var tween := create_tween()
	tween.tween_property(alvo, "scale", Vector3(1.3, 0.7, 1.3), 0.15)
	tween.tween_property(alvo, "scale", Vector3.ONE * 0.12, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for i in 4:
		tween.tween_property(alvo, "position:y", 0.15, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(alvo, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _fumaca(alvo, Vector3(0.0, 0.1, 0.0), Color(1.0, 0.9, 0.6)))
	tween.tween_property(alvo, "scale", Vector3.ONE * 0.01, 0.2)
	tween.tween_callback(func() -> void: _esconder(alvo))


# --------------------------------------------------------------------- Ciborgue
## Curto-circuito: faíscas, pisca-pisca vermelho e desliga tombando.
func _curto_circuito(alvo: Node3D) -> void:
	Sfx.tocar("Castigo_Choque")
	var faiscas := CPUParticles3D.new()
	faiscas.amount = 60
	faiscas.lifetime = 0.6
	faiscas.explosiveness = 0.3
	faiscas.mesh = _mesh_faisca()
	faiscas.direction = Vector3.UP
	faiscas.spread = 80.0
	faiscas.initial_velocity_min = 1.5
	faiscas.initial_velocity_max = 3.0
	faiscas.gravity = Vector3(0.0, -6.0, 0.0)
	faiscas.color = Color(1.0, 0.9, 0.3)
	faiscas.position = Vector3(0.0, 1.05, 0.0)
	alvo.add_child(faiscas)

	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.15, 0.1)
	luz.light_energy = 0.0
	luz.omni_range = 2.0
	luz.position = Vector3(0.0, 1.1, 0.3)
	alvo.add_child(luz)

	var tween := create_tween()
	for i in 7:
		tween.tween_property(luz, "light_energy", 4.0, 0.06)
		tween.tween_property(luz, "light_energy", 0.0, 0.1)
		tween.parallel().tween_property(alvo, "position:x", randf_range(-0.04, 0.04), 0.1)
	tween.tween_property(alvo, "position:x", 0.0, 0.05)
	tween.tween_callback(func() -> void: faiscas.emitting = false)
	tween.tween_callback(func() -> void: _fumaca(alvo, Vector3(0.0, 1.2, 0.0), Color(0.3, 0.3, 0.3)))
	# Desliga e tomba para trás, devagar, como um robô sem energia.
	tween.tween_property(alvo, "rotation:x", deg_to_rad(-75.0), 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.6)
	tween.tween_property(alvo, "scale", Vector3.ONE * 0.01, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		faiscas.queue_free()
		luz.queue_free()
		_esconder(alvo))


# -------------------------------------------------------------------- Utilidades
func _esconder(alvo: Node3D) -> void:
	alvo.visible = false
	if alvo.has_method("congelar"):
		alvo.congelar()


## Nuvem de fumaça curta, no pai do alvo (sobrevive ao sumiço dele).
func _fumaca(alvo: Node3D, pos: Vector3, cor: Color) -> void:
	var p := CPUParticles3D.new()
	p.amount = 24
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.95
	p.mesh = _mesh_faisca(0.09)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.4
	p.gravity = Vector3(0.0, 0.8, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	p.color = cor
	var raiz: Node = alvo.get_parent() if alvo.get_parent() != null else alvo
	raiz.add_child(p)
	p.global_position = alvo.global_position + pos
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.2).timeout.connect(p.queue_free)


func _mesh_faisca(tamanho: float = 0.03) -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3.ONE * tamanho
	m.material = _material(Color.WHITE, 1.0, true)
	return m


func _esfera(cor: Color, raio: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = raio
	esfera.height = raio * 2.0
	esfera.radial_segments = 12
	esfera.rings = 6
	mi.mesh = esfera
	mi.material_override = _material(cor, 0.4)
	return mi


func _material(cor: Color, rugosidade: float, sem_luz: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	if sem_luz:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
	return m
