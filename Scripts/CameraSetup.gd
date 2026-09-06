extends Camera3D
## Câmera estática de estúdio de TV.
##
## Fica acima e atrás do assento do jogador, inclinada para baixo (~34°),
## enquadrando o tampo (0.75 m) e os 4 NPCs sentados.
## Não recebe nenhum input do jogador e não executa nenhum movimento.

# Posição fixa da câmera: acima e um pouco à frente da mesa.
const CAMERA_POSITION := Vector3(0.0, 2.3, 2.5)
# Inclinação para baixo em aproximadamente 45°.
const CAMERA_PITCH_DEGREES := -34.0


func _ready() -> void:
	position = CAMERA_POSITION
	rotation_degrees = Vector3(CAMERA_PITCH_DEGREES, 0.0, 0.0)
	current = true

	# Garante que nada nesta câmera processe frames ou input.
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
