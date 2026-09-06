class_name Sfx
extends RefCounted
## Efeitos sonoros (Etapa 6). Uso: Sfx.tocar("Dado_Agitar").
##
## Cada chamada cria um AudioStreamPlayer descartável na raiz da árvore,
## para que sons se sobreponham sem cortar uns aos outros. Arquivos em
## Assets/Audio/SFX/<nome>.wav; um nome inexistente é ignorado com aviso.

const PASTA := "res://Assets/Audio/SFX/%s.wav"

static var _cache: Dictionary = {}


static func tocar(nome: String, volume_db: float = 0.0) -> void:
	var stream := _carregar(nome)
	if stream == null:
		return
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	# Pode ser chamado durante um _ready(): adiar evita "parent is busy".
	player.autoplay = true
	arvore.root.add_child.call_deferred(player)


static func _carregar(nome: String) -> AudioStream:
	if not _cache.has(nome):
		var caminho := PASTA % nome
		if ResourceLoader.exists(caminho):
			_cache[nome] = load(caminho)
		else:
			push_warning("Sfx: arquivo não encontrado: %s" % caminho)
			_cache[nome] = null
	return _cache[nome]
