class_name OlharModifier
extends SkeletonModifier3D
## Gira um único osso (a cabeça) na direção de um alvo, por cima da animação.
##
## Filho de um Skeleton3D. Roda em [method _process_modification], depois da
## animação e antes do desenho, então o corpo continua no Idle enquanto só a
## cabeça acompanha o alvo. A mistura entre a pose animada e a pose girada é
## feita pela engine através de [member SkeletonModifier3D.influence]: 0 é a
## animação pura, 1 é a cabeça toda virada.
##
## O giro é decomposto em guinada (eixo Y do osso) e inclinação (eixo X),
## sem rolagem, e cada uma tem seu limite — é assim que um pescoço se move.
## Como o giro é aplicado por cima da pose animada, o balanço do Idle
## continua aparecendo enquanto o personagem olha.
##
## O LookAtModifier3D nativo não teve efeito neste projeto (Godot 4.7.2), daí
## este modificador próprio, que também deixa o eixo do rosto explícito.

## Osso a girar.
@export var osso := "head"
## Para onde olhar. Sem alvo, o modificador não faz nada.
@export var alvo: Node3D
## Giro horizontal máximo, em graus.
@export var limite_guinada := 62.0
## Giro vertical máximo, em graus (o pescoço sobe e desce menos que gira).
@export var limite_inclinacao := 34.0

var _indice := -1


func _process_modification() -> void:
	var esqueleto := get_skeleton()
	if esqueleto == null or alvo == null:
		return
	if _indice < 0:
		_indice = esqueleto.find_bone(osso)
		if _indice < 0:
			return

	var pose := esqueleto.get_bone_global_pose(_indice)
	# Alvo no espaço do esqueleto, para comparar com a pose do osso.
	var alvo_local: Vector3 = esqueleto.global_transform.affine_inverse() * alvo.global_position
	var direcao := (alvo_local - pose.origin).normalized()
	if direcao.length_squared() < 0.5:
		return

	# Direção do alvo no espaço do próprio osso: +Z é o rosto, +Y o topo
	# da cabeça, +X a orelha. O rosto aponta para +Z no export do Blender.
	var animada := pose.basis.orthonormalized()
	var local := animada.inverse() * direcao
	var guinada := clampf(atan2(local.x, local.z), -deg_to_rad(limite_guinada), deg_to_rad(limite_guinada))
	var inclinacao := clampf(-asin(clampf(local.y, -1.0, 1.0)), -deg_to_rad(limite_inclinacao), deg_to_rad(limite_inclinacao))
	var giro := Basis.from_euler(Vector3(inclinacao, guinada, 0.0))
	esqueleto.set_bone_global_pose(_indice, Transform3D(animada * giro, pose.origin))
