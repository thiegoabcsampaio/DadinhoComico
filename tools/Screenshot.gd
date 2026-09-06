extends Node
## Ferramenta de validação: instancia Main.tscn, espera alguns frames e salva
## um PNG da câmera fixa. Uso:
##   godot --path . tools/Screenshot.tscn -- <png> [modo] [frames]
## modo: "jogo" (padrão), "revelacao" (copos levantados com faces),
## "castigos" (dispara o castigo dos 4 NPCs)
## ou "espiar" (copo do jogador inclinado mostrando os dados).

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var destino: String = args[0] if args.size() > 0 else "screenshot.png"
	var modo: String = args[1] if args.size() > 1 else "jogo"
	var frames: int = int(args[2]) if args.size() > 2 else 30

	if modo == "menu":
		add_child(load("res://Scenes/Menu.tscn").instantiate())
		for i in frames:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(destino)
		print("screenshot salvo em ", destino)
		get_tree().quit()
		return

	# Modo "ver": 4º argumento é o personagem a examinar de perto. Ele senta
	# sempre no assento do fundo, de frente para a câmera.
	if modo == "ver" and args.size() > 3:
		Partida.personagem = args[3]

	var main: Node3D = load("res://Scenes/Main.tscn").instantiate()
	# Semente fixa nos modos de comparação, para o sorteio de assentos não
	# mudar entre uma captura e outra.
	if modo.begins_with("rosto") or modo == "ver":
		main.semente = 7777
	add_child(main)
	for i in 10:
		await get_tree().process_frame
	match modo:
		"revelacao":
			main.mesa.revelar({ 0: [1, 2, 3], 1: [4, 5, 6], 2: [6, 6], 3: [1], 4: [2, 3, 5] })
		"castigos":
			main.mesa.revelar({ 0: [1, 2, 3], 1: [4, 5, 6], 2: [6, 6], 3: [1], 4: [2, 3, 5] })
			for id in main._controladores:
				main._castigar(id)
		"espiar":
			main.mesa.espiar(main.JOGADOR_HUMANO, [2, 5, 6], true)
		"falas":
			# Painel de provocações aberto na vez do jogador.
			main.hud._botao_falar.pressed.emit()
		"narrador":
			main.hud.mostrar_balao(HudController.NARRADOR, DialogueLoader.get_random("narrador", "resultado", { "face": 4, "contagem": 3, "veredicto": "VERDADEIRA", "perdedor": "Bruxa" }), 6.0)
		"efeito":
			# Castigo do personagem do jogador: modelo + efeito de tela.
			main._castigar(main.JOGADOR_HUMANO)
		"log":
			main.hud._botao_log.button_pressed = true
			# Enche o log com uma sequência de falas e eventos.
			for id in main._controladores:
				main._falar(id, "apostas", { "aposta": "2 x face 4" })
				await get_tree().create_timer(0.05).timeout
			for id in main._controladores:
				main._falar(id, "reacoes")
				await get_tree().create_timer(0.05).timeout
			main.hud.registrar_evento("Face 4 apareceu 3 vezes: pedido VERDADEIRO.")
		"zoom":
			# Ver Dados pelo caminho real: HUD -> Main -> mesa + zoom na HUD.
			main.hud._botao_ver_dados.button_pressed = true
		"feel":
			# Mouse sobre Apostar e clique numa face: hover, som e faíscas.
			main.hud._botao_apostar.mouse_entered.emit()
			main.hud._faces.get_child(3).pressed.emit()
		"olhar":
			# Todos falam ao mesmo tempo: as cabeças devem virar para a câmera.
			for id in main._controladores:
				print(_angulo_cabeca(main, id, "antes"))
				main._falar(id, "apostas", { "aposta": "2 x face 4" })
			for i in 40:
				await get_tree().process_frame
			for id in main._controladores:
				print(_angulo_cabeca(main, id, "durante"))
		"ver", "rosto", "rosto_olhar":
			# Câmera junto da mesa, de frente para os dois NPCs do fundo.
			main.camera.position = Vector3(0.0, 1.45, 0.55)
			main.camera.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
			main.hud.visible = false
			if modo == "rosto_olhar":
				for id in main._controladores:
					main._controladores[id].olhar_para(main.camera, 6.0)
		"plateia":
			# Close na arquibancada da esquerda, para conferir os adereços.
			main.camera.position = Vector3(-2.6, 1.7, -0.4)
			main.camera.look_at(Vector3(-4.2, 1.0, -2.6), Vector3.UP)
			main.hud.visible = false
		"fps":
			# Custo real da cena: sem sincronia vertical, mede o pior quadro.
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			var amostras: Array[float] = []
			for i in maxi(60, frames):
				await get_tree().process_frame
				if i > 90:
					amostras.append(Engine.get_frames_per_second())
			var soma := 0.0
			var minimo := 9999.0
			for v in amostras:
				soma += v
				minimo = minf(minimo, v)
			print("FPS medio=%.0f  minimo=%.0f  amostras=%d" % [soma / maxf(1.0, amostras.size()), minimo, amostras.size()])
		"assentos":
			# Quem sentou em cada assento, para conferir o sorteio.
			for id in main._controladores:
				print("Assento%d = %s" % [id, main._controladores[id].name])
	for i in frames:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(destino)
	print("screenshot salvo em ", destino)
	get_tree().quit()


## Ângulo entre a direção do rosto (osso head) e a direção da câmera.
## Perto de 0 = olhando para o jogador.
func _angulo_cabeca(main: Node3D, id: int, quando: String) -> String:
	var npc: Node3D = main._controladores[id]
	var esqueleto := npc.find_child("Skeleton3D", true, false) as Skeleton3D
	var osso := esqueleto.find_bone("head")
	var pose := esqueleto.global_transform * esqueleto.get_bone_global_pose(osso)
	var frente: Vector3 = pose.basis.z.normalized()
	var para_camera: Vector3 = (main.camera.global_position - pose.origin).normalized()
	return "%-9s %-14s desvio da camera: %5.1f graus" % [quando, npc.name, rad_to_deg(frente.angle_to(para_camera))]
