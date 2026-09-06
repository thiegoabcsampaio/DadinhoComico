extends Node
## Ferramenta de inspeção: imprime a árvore de uma cena, os ossos de cada
## Skeleton3D e as animações de cada AnimationPlayer. Útil para descobrir
## nomes de nós e de ossos dos .glb sem abrir o editor.
##
## Uso: godot --headless --path . tools/DumpTree.tscn -- <res://cena.tscn>
## Sem argumento, inspeciona a cena principal.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var caminho: String = args[0] if args.size() > 0 else "res://Scenes/Main.tscn"
	var raiz: Node = load(caminho).instantiate()
	add_child(raiz)
	# Alguns nós só se montam depois do primeiro quadro.
	await get_tree().process_frame
	_imprimir(raiz, 0)
	get_tree().quit()


func _imprimir(no: Node, nivel: int) -> void:
	print("  ".repeat(nivel), no.name, "  [", no.get_class(), "]")
	if no is Skeleton3D:
		var esqueleto := no as Skeleton3D
		var ossos := []
		for i in esqueleto.get_bone_count():
			ossos.append("%d:%s" % [i, esqueleto.get_bone_name(i)])
		print("  ".repeat(nivel + 1), "OSSOS: ", ", ".join(ossos))
	if no is AnimationPlayer:
		print("  ".repeat(nivel + 1), "ANIMACOES: ", (no as AnimationPlayer).get_animation_list())
	for filho in no.get_children():
		_imprimir(filho, nivel + 1)
