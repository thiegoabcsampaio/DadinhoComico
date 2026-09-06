extends Node
## Ferramenta de validação: instancia Main.tscn, espera alguns frames e salva
## um PNG da câmera fixa. Uso:
##   godot --path . tools/Screenshot.tscn -- <png> [modo] [frames]
## modo: "jogo" (padrão), "revelacao" (copos levantados com faces),
## "castigos" (dispara o castigo dos 4 NPCs) ou "torta" (castigo do humano).

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var destino: String = args[0] if args.size() > 0 else "screenshot.png"
	var modo: String = args[1] if args.size() > 1 else "jogo"
	var frames: int = int(args[2]) if args.size() > 2 else 30

	var main: Node3D = load("res://Scenes/Main.tscn").instantiate()
	add_child(main)
	for i in 10:
		await get_tree().process_frame
	match modo:
		"revelacao":
			main.mesa.revelar({ 0: [1, 2, 3], 1: [4, 5, 6], 2: [6, 6], 3: [1], 4: [2, 3, 5] })
		"castigos":
			main.mesa.revelar({ 0: [1, 2, 3], 1: [4, 5, 6], 2: [6, 6], 3: [1], 4: [2, 3, 5] })
			for id in main.PERFIS:
				main._castigar(id)
		"torta":
			main._castigar(main.JOGADOR_HUMANO)
	for i in frames:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(destino)
	print("screenshot salvo em ", destino)
	get_tree().quit()
