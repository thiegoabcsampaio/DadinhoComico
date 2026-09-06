extends Node
## Gera efeitos sonoros curtos por síntese e salva em Assets/Audio/SFX/.
## Uso: godot --headless --path . tools/GerarSfx.tscn
## Rode de novo só se quiser recriar os arquivos; eles ficam versionados.

const TAXA := 22050
const PASTA := "res://Assets/Audio/SFX/%s.wav"


func _ready() -> void:
	_salvar("Clique", _clique())
	get_tree().quit()


## Clique seco de botão: dois senos curtos com queda rápida.
func _clique() -> PackedFloat32Array:
	var amostras := PackedFloat32Array()
	var total := int(TAXA * 0.06)
	amostras.resize(total)
	for i in total:
		var t := float(i) / TAXA
		var queda := exp(-t * 90.0)
		var onda := sin(TAU * 1400.0 * t) * 0.6 + sin(TAU * 2300.0 * t) * 0.4
		amostras[i] = onda * queda
	return amostras


func _salvar(nome: String, amostras: PackedFloat32Array) -> void:
	var pico := 0.0
	for v in amostras:
		pico = maxf(pico, absf(v))
	var ganho := 0.85 / maxf(pico, 0.0001)
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		var v := int(clampf(amostras[i] * ganho, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = TAXA
	audio.stereo = false
	audio.data = bytes
	var caminho := PASTA % nome
	var erro := audio.save_to_wav(caminho)
	print(nome, " -> ", caminho, " erro=", erro, " amostras=", amostras.size())
