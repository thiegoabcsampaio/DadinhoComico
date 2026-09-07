class_name NpcController
extends Node3D
## Liga as animações embarcadas no .glb ao comportamento do NPC (Etapa 6).
##
## Vai na raiz de cada cena em Scenes/NPCs/. Toca "Idle" em loop e volta
## para ele ao fim de qualquer animação pontual. Os tells (tiques
## nervosos) são disparados por Main.gd quando a NpcAI blefa em aposta de
## alto risco e o perfil sorteia frequencia_tells.

const IDLE := "Idle"
const TELLS := ["Tell_Olhar", "Tell_Cocar", "Tell_Bater"]
const MISTURA := 0.15

## Osso da cabeça no Skeleton3D importado do .glb.
const OSSO_CABECA := "head"
## Limite de giro da cabeça, para o pescoço não se torcer sozinho.
const LIMITE_CABECA := 62.0
## Tempo de entrada e de saída do olhar.
const TRANSICAO_OLHAR := 0.35

## Animação a tocar quando a atual terminar (em vez de voltar ao Idle).
var _proxima := ""
var _rng := RandomNumberGenerator.new()
## Modificador que gira só o osso da cabeça, por cima da animação.
var _olhar: OlharModifier
var _tween_olhar: Tween

@onready var _player: AnimationPlayer = find_child("AnimationPlayer", true, false)


func _ready() -> void:
	_rng.randomize()
	_preparar_olhar()
	if _player == null:
		push_warning("NpcController: %s sem AnimationPlayer" % name)
		return
	if _player.has_animation(IDLE):
		_player.get_animation(IDLE).loop_mode = Animation.LOOP_LINEAR
		_player.play(IDLE)
	_player.animation_finished.connect(_ao_terminar)


## Cria o LookAtModifier3D no esqueleto. Ele roda depois da animação, então
## o corpo continua no Idle enquanto só a cabeça acompanha o alvo. A
## influência fica em 0 até alguém chamar [method olhar_para].
func _preparar_olhar() -> void:
	var esqueleto := find_child("Skeleton3D", true, false) as Skeleton3D
	if esqueleto == null or esqueleto.find_bone(OSSO_CABECA) < 0:
		push_warning("NpcController: %s sem osso '%s'" % [name, OSSO_CABECA])
		return
	_olhar = OlharModifier.new()
	_olhar.name = "OlharCabeca"
	_olhar.osso = OSSO_CABECA
	_olhar.limite_guinada = LIMITE_CABECA
	_olhar.influence = 0.0
	esqueleto.add_child(_olhar)


## Vira a cabeça para [alvo] (a câmera, quando o NPC fala) e volta ao
## normal depois de [duracao]. Só a cabeça gira: o assento já aponta o
## corpo para a mesa.
func olhar_para(alvo: Node3D, duracao: float) -> void:
	if _olhar == null or alvo == null:
		return
	_olhar.alvo = alvo
	if _tween_olhar != null and _tween_olhar.is_valid():
		_tween_olhar.kill()
	_tween_olhar = create_tween()
	_tween_olhar.tween_property(_olhar, "influence", 1.0, TRANSICAO_OLHAR)
	_tween_olhar.tween_interval(maxf(0.0, duracao - TRANSICAO_OLHAR * 2.0))
	_tween_olhar.tween_property(_olhar, "influence", 0.0, TRANSICAO_OLHAR)


## Toca uma animação pontual; ao terminar volta ao Idle.
func tocar(nome: String) -> void:
	if _player == null or not _player.has_animation(nome):
		return
	_proxima = ""
	_player.play(nome, MISTURA)


## Aposta e, se [com_tell], emenda um tique nervoso logo em seguida.
func apostar(com_tell: bool) -> void:
	tocar("Apostar")
	if com_tell:
		_proxima = TELLS[_rng.randi() % TELLS.size()]


func tell() -> void:
	tocar(TELLS[_rng.randi() % TELLS.size()])


## Acende o olho robótico (Ciborgue) por [duracao] segundos: preto em
## repouso, vermelho de alerta quando ele erra. Ignorado em quem não tem
## o material "OlhoRobo". O material é duplicado por instância para não
## acender o olho de outra cópia do mesmo modelo.
func acender_olho(duracao: float = 2.5) -> void:
	var malha := find_child("*", true, false) as MeshInstance3D
	for filho in find_children("*", "MeshInstance3D", true, false):
		malha = filho as MeshInstance3D
		if malha.mesh == null:
			continue
		for i in malha.mesh.get_surface_count():
			var material := malha.get_active_material(i)
			if material == null or not material.resource_name.contains("OlhoRobo"):
				continue
			var proprio := material.duplicate() as StandardMaterial3D
			proprio.emission_enabled = true
			proprio.emission = Color(1.0, 0.08, 0.06)
			proprio.emission_energy_multiplier = 0.0
			malha.set_surface_override_material(i, proprio)
			var tween := create_tween()
			tween.tween_property(proprio, "emission_energy_multiplier", 4.0, 0.15)
			for p in 3:
				tween.tween_property(proprio, "emission_energy_multiplier", 1.2, 0.2)
				tween.tween_property(proprio, "emission_energy_multiplier", 4.0, 0.2)
			tween.tween_interval(maxf(0.0, duracao - 1.6))
			tween.tween_property(proprio, "emission_energy_multiplier", 0.0, 0.4)
			return


## Deixa o modelo parado (usado quando o castigo o tira de cena).
func congelar() -> void:
	if _tween_olhar != null and _tween_olhar.is_valid():
		_tween_olhar.kill()
	if _olhar != null:
		_olhar.influence = 0.0
	if _player != null:
		_player.stop()


func _ao_terminar(nome: StringName) -> void:
	if _proxima != "":
		var proxima := _proxima
		_proxima = ""
		Sfx.tocar("Tell", -6.0)
		_player.play(proxima, MISTURA)
		return
	if nome != IDLE and _player.has_animation(IDLE):
		_player.play(IDLE, 0.3)
