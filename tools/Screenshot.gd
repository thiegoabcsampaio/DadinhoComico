extends Node
## Ferramenta de validação: instancia Main.tscn, espera alguns frames e salva
## um PNG da câmera fixa. Uso:
##   godot --path . tools/Screenshot.tscn -- <caminho_do_png>

func _ready() -> void:
	var destino := "screenshot.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		destino = args[0]
	add_child(load("res://Scenes/Main.tscn").instantiate())
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(destino)
	print("screenshot salvo em ", destino)
	get_tree().quit()
