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

## Animação a tocar quando a atual terminar (em vez de voltar ao Idle).
var _proxima := ""
var _rng := RandomNumberGenerator.new()

@onready var _player: AnimationPlayer = find_child("AnimationPlayer", true, false)


func _ready() -> void:
	_rng.randomize()
	if _player == null:
		push_warning("NpcController: %s sem AnimationPlayer" % name)
		return
	if _player.has_animation(IDLE):
		_player.get_animation(IDLE).loop_mode = Animation.LOOP_LINEAR
		_player.play(IDLE)
	_player.animation_finished.connect(_ao_terminar)


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


## Deixa o modelo parado (usado quando o castigo o tira de cena).
func congelar() -> void:
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
