extends Camera3D
## Câmera estática de estúdio de TV.
##
## Fica acima da mesa, levemente inclinada para baixo (~45°).
## Não recebe nenhum input do jogador e não executa nenhum movimento.

# Posição fixa da câmera: acima e um pouco à frente da mesa.
const CAMERA_POSITION := Vector3(0.0, 3.5, 3.5)
# Inclinação para baixo em aproximadamente 45°.
const CAMERA_PITCH_DEGREES := -45.0


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
