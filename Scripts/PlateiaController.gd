class_name PlateiaController
extends Node3D
## Plateia de auditório anos 90 (Etapa 7).
##
## Monta duas arquibancadas fora da mesa e as povoa com espectadores
## clonados de um único .glb. A diversidade é feita por código, não por
## malha: cada espectador sorteia tom de pele, roupa e cabelo (material
## duplicado por instância), um acessório (ou nenhum) e uma animação em
## loop com a fase deslocada, para ninguém bater palma junto.
##
## Depois reage ao jogo: murmura nas apostas, cala no Desconfio, aplaude
## na revelação e faz festa no castigo e no fim de jogo.

const CENA_ARQUIBANCADA := preload("res://Assets/Models/Arquibancada.glb")
const CENA_ESPECTADOR := preload("res://Assets/Models/Espectador.glb")

## Nomes dos materiais do .glb que podem ser recoloridos por instância.
const MAT_PELE := "Esp_Pele"
const MAT_ROUPA := "Esp_Roupa"
const MAT_CABELO := "Esp_Cabelo"

## Acessórios (nós dentro do Skeleton3D) e a animação que combina com cada um.
const ACESSORIOS := {
	"Acc_Plaquinha": "LevantarPlaquinha",
	"Acc_Frufru": "AgitarFrufru",
	"Acc_Oculos": "",
	"Acc_Bone": "",
}

## Tons de pele, do mais claro ao mais escuro. A plateia é diversa.
const PELES: Array[Color] = [
	Color(0.96, 0.80, 0.68), Color(0.90, 0.72, 0.58), Color(0.80, 0.60, 0.45),
	Color(0.66, 0.46, 0.32), Color(0.52, 0.34, 0.22), Color(0.36, 0.23, 0.15),
	Color(0.28, 0.17, 0.11),
]
## Cores de roupa saturadas, no tom do programa de auditório.
const ROUPAS: Array[Color] = [
	Color(0.90, 0.20, 0.30), Color(0.20, 0.55, 0.90), Color(0.95, 0.70, 0.15),
	Color(0.25, 0.70, 0.40), Color(0.75, 0.30, 0.80), Color(0.95, 0.45, 0.15),
	Color(0.15, 0.75, 0.75), Color(0.95, 0.35, 0.60),
]
const CABELOS: Array[Color] = [
	Color(0.08, 0.06, 0.05), Color(0.20, 0.12, 0.06), Color(0.42, 0.26, 0.12),
	Color(0.72, 0.55, 0.25), Color(0.85, 0.75, 0.45), Color(0.55, 0.55, 0.58),
	Color(0.85, 0.25, 0.35),
]

## Onde ficam as duas arquibancadas (a rotação é calculada para a mesa).
@export var posicoes_arquibancada: Array[Vector3] = [
	Vector3(-4.2, 0.0, -2.6),
	Vector3(4.2, 0.0, -2.6),
]
## Lugares por degrau e degraus por arquibancada (o modelo tem 3 degraus).
@export var lugares_por_degrau := 7
@export var degraus := 3
## Largura útil do degrau e recuo/altura entre degraus (do Arquibancada.glb).
@export var largura_degrau := 3.0
@export var recuo_degrau := 0.55
@export var altura_degrau := 0.34
## Altura do primeiro assento.
@export var altura_inicial := 0.32
## 0 = aleatório; outro valor repete a mesma plateia.
@export var semente: int = 0

## Todos os espectadores criados (AnimationPlayer + acessório de cada um).
var _espectadores: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if semente != 0:
		_rng.seed = semente
	else:
		_rng.randomize()
	_montar()


## Liga a plateia aos sinais da partida. Chamado por Main.
func acompanhar(jogo: GameManager) -> void:
	jogo.aposta_feita.connect(func(_aposta: BetValidator.Aposta) -> void: _murmurar())
	jogo.dudo_declarado.connect(func(_a: int, _b: int) -> void: _silenciar())
	jogo.dudo_resolvido.connect(func(_r: BetValidator.ResultadoDudo) -> void: _aplaudir())
	jogo.jogador_eliminado.connect(func(_id: int) -> void: _festejar())
	jogo.jogo_terminou.connect(func(_v: int) -> void: _festejar())


# ------------------------------------------------------------------ Montagem

func _montar() -> void:
	var centro := Vector3.ZERO
	for posicao in posicoes_arquibancada:
		var arquibancada: Node3D = CENA_ARQUIBANCADA.instantiate()
		add_child(arquibancada)
		arquibancada.position = posicao
		# -Z aponta para a mesa, então os degraus sobem afastando-se dela.
		arquibancada.look_at(centro, Vector3.UP)
		_povoar(arquibancada, centro)


## Preenche os degraus de uma arquibancada com espectadores sorteados.
func _povoar(arquibancada: Node3D, centro: Vector3) -> void:
	for degrau in degraus:
		for lugar in lugares_por_degrau:
			var espectador: Node3D = CENA_ESPECTADOR.instantiate()
			arquibancada.add_child(espectador)
			var passo := largura_degrau / float(maxi(1, lugares_por_degrau - 1))
			var x := -largura_degrau * 0.5 + passo * lugar
			espectador.position = Vector3(
				x + _rng.randf_range(-0.04, 0.04),
				altura_inicial + altura_degrau * degrau,
				recuo_degrau * degrau)
			# O modelo olha para +Z; look_at aponta -Z, daí a meia-volta.
			espectador.look_at(centro, Vector3.UP)
			espectador.rotate_y(PI)
			espectador.rotate_y(_rng.randf_range(-0.25, 0.25))
			espectador.scale = Vector3.ONE * _rng.randf_range(0.92, 1.08)
			_vestir(espectador)


## Cor de pele, roupa e cabelo por instância, mais um acessório (ou nenhum).
func _vestir(espectador: Node3D) -> void:
	var corpo := espectador.find_child("Espectador", true, false) as MeshInstance3D
	if corpo != null:
		var cores := {
			MAT_PELE: PELES[_rng.randi() % PELES.size()],
			MAT_ROUPA: ROUPAS[_rng.randi() % ROUPAS.size()],
			MAT_CABELO: CABELOS[_rng.randi() % CABELOS.size()],
		}
		for i in corpo.mesh.get_surface_count():
			var original := corpo.get_active_material(i)
			if original == null:
				continue
			for nome in cores:
				if not original.resource_name.begins_with(nome):
					continue
				var proprio := original.duplicate() as StandardMaterial3D
				proprio.albedo_color = cores[nome]
				corpo.set_surface_override_material(i, proprio)
				break

	# Um acessório por espectador, ou nenhum (a plateia não é uniforme).
	var nomes := ACESSORIOS.keys()
	var escolhido: String = nomes[_rng.randi() % nomes.size()] if _rng.randf() < 0.75 else ""
	for nome in nomes:
		var acessorio := espectador.find_child(nome, true, false) as MeshInstance3D
		if acessorio != null:
			acessorio.visible = nome == escolhido

	var player := espectador.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		return
	for nome in player.get_animation_list():
		player.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	_espectadores.append({
		"player": player,
		# Animação de festa que combina com o acessório deste espectador.
		"festa": ACESSORIOS.get(escolhido, ""),
	})
	_tocar(_espectadores[-1], "Idle")


## Toca uma animação em ponto aleatório, para a plateia não ficar em bloco.
func _tocar(espectador: Dictionary, nome: String) -> void:
	var player: AnimationPlayer = espectador["player"]
	if not player.has_animation(nome):
		nome = "Idle"
	player.play(nome, 0.3)
	player.seek(_rng.randf() * player.get_animation(nome).length, true)
	player.speed_scale = _rng.randf_range(0.85, 1.15)


# ------------------------------------------------------------------ Reações

## Aposta: só uma parte da plateia se manifesta, como um murmúrio.
func _murmurar() -> void:
	for espectador in _espectadores:
		if _rng.randf() < 0.25:
			_tocar(espectador, "Aplaudir")
		elif _rng.randf() < 0.3:
			_tocar(espectador, "Idle")


## Desconfio: todo mundo para para ver no que dá.
func _silenciar() -> void:
	for espectador in _espectadores:
		_tocar(espectador, "Idle")


func _aplaudir() -> void:
	for espectador in _espectadores:
		_tocar(espectador, "Aplaudir")


## Castigo e fim de jogo: quem tem plaquinha levanta, quem tem frufru agita,
## o resto aplaude.
func _festejar() -> void:
	for espectador in _espectadores:
		var festa: String = espectador["festa"]
		_tocar(espectador, festa if festa != "" else "Aplaudir")
