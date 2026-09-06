class_name Elenco
extends RefCounted
## Catálogo de personagens, montado lendo a pasta de perfis.
##
## Nenhuma lista fixa no código: para entrar um personagem novo basta pôr os
## arquivos dele nas pastas certas, com o mesmo nome nos quatro lugares:
##
##   Resources/NPCProfiles/<Nome>.tres   perfil (nome, chave_dialogo, IA)
##   Scenes/NPCs/<Nome>.tscn             modelo com NpcController
##   Assets/UI/Retratos/<Nome>.png       retrato do menu (256x256)
##   dialogues.json                      seção com a chave_dialogo do perfil
##
## O passo a passo completo está em docs/blueprint.md, seção
## "Como acrescentar um personagem".

const PASTA_PERFIS := "res://Resources/NPCProfiles"
const CENA := "res://Scenes/NPCs/%s.tscn"
const RETRATO := "res://Assets/UI/Retratos/%s.png"


## Nomes de todos os personagens encontrados, em ordem alfabética.
static func nomes() -> Array[String]:
	var achados: Array[String] = []
	var pasta := DirAccess.open(PASTA_PERFIS)
	if pasta == null:
		push_error("Elenco: não consegui abrir %s" % PASTA_PERFIS)
		return achados
	for arquivo in pasta.get_files():
		# No projeto exportado os .tres viram .remap; o nome base é o mesmo.
		var nome := arquivo.get_basename() if not arquivo.ends_with(".remap") \
			else arquivo.get_basename().get_basename()
		if not arquivo.begins_with(".") and not achados.has(nome) and ResourceLoader.exists(CENA % nome):
			achados.append(nome)
	achados.sort()
	return achados


static func perfil(nome: String) -> NpcProfile:
	return load("%s/%s.tres" % [PASTA_PERFIS, nome]) as NpcProfile


static func cena(nome: String) -> PackedScene:
	return load(CENA % nome) as PackedScene


## Retrato do menu, ou null se o personagem ainda não tiver um.
static func retrato(nome: String) -> Texture2D:
	var caminho := RETRATO % nome
	return load(caminho) as Texture2D if ResourceLoader.exists(caminho) else null
