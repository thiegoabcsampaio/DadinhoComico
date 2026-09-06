class_name DialogueLoader
extends RefCounted
## Carrega e fornece textos de dialogues.json.
##
## Uso: DialogueLoader.get_text("ui", "sua_vez")
## Retorna a chave como fallback se categoria ou chave não existir.

const CAMINHO := "res://dialogues.json"

static var _dados: Dictionary = {}
static var _carregado: bool = false


static func _carregar() -> void:
	if _carregado:
		return
	var arquivo := FileAccess.open(CAMINHO, FileAccess.READ)
	if arquivo == null:
		push_error("DialogueLoader: falha ao abrir %s" % CAMINHO)
		_carregado = true
		return
	var json := JSON.new()
	var erro := json.parse(arquivo.get_as_text())
	arquivo.close()
	if erro != OK:
		push_error("DialogueLoader: parse error em %s: %s" % [CAMINHO, json.get_error_message()])
		_carregado = true
		return
	_dados = json.data
	_carregado = true


static func get_text(categoria: String, chave: String) -> String:
	_carregar()
	var cat: Variant = _dados.get(categoria)
	if cat == null:
		push_warning("DialogueLoader: categoria '%s' nao encontrada" % categoria)
		return chave
	if cat is Dictionary:
		var valor: Variant = cat.get(chave)
		if valor == null:
			push_warning("DialogueLoader: chave '%s.%s' nao encontrada" % [categoria, chave])
			return chave
		return str(valor)
	return chave


## Atalho: get_text com format aplicado.
static func get_fmt(categoria: String, chave: String, args: Array) -> String:
	return get_text(categoria, chave) % args


## Força recarga (útil se dialogues.json for editado em tempo de execução).
static func recarregar() -> void:
	_carregado = false
	_dados.clear()
	_carregar()
