class_name FestaModifier
extends SkeletonModifier3D
## Braços para o alto e corpo balançando, por cima da animação (fim de
## partida). Mesmo esquema do OlharModifier: roda depois do AnimationPlayer
## e a engine mistura com a pose animada via [member influence].
##
## Cada braço é girado para que o eixo +Y do osso (que no export do Blender
## vai do ombro ao cotovelo) aponte para cima e um pouco para fora, num V.
## A coluna rola de um lado para o outro e os braços acenam em contra-fase.

## Ossos dos braços (Blender: upper_arm.L / upper_arm.R).
@export var braco_esquerdo := "upper_arm.L"
@export var braco_direito := "upper_arm.R"
@export var coluna := "spine"
## Abertura do V, em graus a partir da vertical.
@export var abertura := 22.0
## Balanço da coluna, em graus, e frequência em Hz.
@export var balanco := 10.0
@export var frequencia := 1.4
## Quanto os braços acenam (graus) em cima da abertura.
@export var aceno := 14.0

var _esq := -1
var _dir := -1
var _col := -1
var _tempo := 0.0


func _process_modification() -> void:
	var esqueleto := get_skeleton()
	if esqueleto == null:
		return
	if _esq < 0:
		_esq = esqueleto.find_bone(braco_esquerdo)
		_dir = esqueleto.find_bone(braco_direito)
		_col = esqueleto.find_bone(coluna)
	_tempo += get_process_delta_time()
	var fase := sin(_tempo * TAU * frequencia)

	if _col >= 0:
		var pose := esqueleto.get_bone_global_pose(_col)
		var animada := pose.basis.orthonormalized()
		# Rola em volta do eixo para a frente do osso (+Z, como o rosto).
		var giro := Basis(Vector3.FORWARD, deg_to_rad(balanco) * fase)
		esqueleto.set_bone_global_pose(_col, Transform3D(animada * giro, pose.origin))

	_levantar(esqueleto, _esq, -1.0, fase)
	_levantar(esqueleto, _dir, 1.0, -fase)


## Gira o osso [indice] para o eixo +Y dele apontar para cima e para o
## [lado] (-1 esquerda, +1 direita), com o aceno em [fase].
func _levantar(esqueleto: Skeleton3D, indice: int, lado: float, fase: float) -> void:
	if indice < 0:
		return
	var pose := esqueleto.get_bone_global_pose(indice)
	var animada := pose.basis.orthonormalized()
	var angulo := deg_to_rad(abertura + aceno * fase)
	# Alvo no espaço do esqueleto: para cima, aberto para o lado do braço.
	var alvo := Vector3(sin(angulo) * lado, cos(angulo), 0.05).normalized()
	var local := (animada.inverse() * alvo).normalized()
	var eixo := Vector3.UP.cross(local)
	if eixo.length_squared() < 0.000001:
		return
	var giro := Basis(eixo.normalized(), acos(clampf(Vector3.UP.dot(local), -1.0, 1.0)))
	esqueleto.set_bone_global_pose(indice, Transform3D(animada * giro, pose.origin))
