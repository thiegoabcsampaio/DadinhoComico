extends Node
## Gera efeitos sonoros curtos por síntese e salva em Assets/Audio/SFX/.
## Uso: godot --headless --path . tools/GerarSfx.tscn
## Rode de novo só se quiser recriar os arquivos; eles ficam versionados.

const TAXA := 22050
const PASTA := "res://Assets/Audio/SFX/%s.wav"


func _ready() -> void:
	_salvar("Clique", _clique())
	_salvar("Plateia_Murmurio", _murmurio())
	_salvar("Plateia_Aplauso", _aplauso())
	_salvar("Plateia_Ooh", _ooh())
	_salvar("Plateia_Festa", _festa())
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


# ------------------------------------------------------------- Plateia
# Uma plateia é muita gente fazendo a mesma coisa fora de sincronia. Todos
# os sons abaixo somam eventos curtos com início aleatório; o que muda é o
# timbre de cada evento e a densidade.

## Ruído com média móvel: quanto maior a [janela], mais grave e abafado.
func _ruido_filtrado(total: int, janela: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var cru := PackedFloat32Array()
	cru.resize(total)
	for i in total:
		cru[i] = rng.randfn(0.0, 1.0)
	var saida := PackedFloat32Array()
	saida.resize(total)
	var soma := 0.0
	for i in total:
		soma += cru[i]
		if i >= janela:
			soma -= cru[i - janela]
		saida[i] = soma / float(janela)
	return saida


## Murmúrio de fundo: grave, contínuo, sem picos. Feito para ficar em loop.
func _murmurio() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var total := int(TAXA * 2.5)
	var amostras := _ruido_filtrado(total, 90, rng)
	# Ondulação lenta, como conversa que sobe e desce.
	for i in total:
		var t := float(i) / TAXA
		amostras[i] *= 0.7 + 0.3 * sin(TAU * 0.7 * t) * sin(TAU * 0.31 * t)
	# Junta o fim com o começo, para o loop não estalar.
	var costura := int(TAXA * 0.15)
	for i in costura:
		var p := float(i) / costura
		amostras[i] = amostras[i] * p + amostras[total - costura + i] * (1.0 - p)
	return amostras


## Palma: estalo curto de ruído agudo.
func _palma(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(TAXA * 0.05)
	var ruido := _ruido_filtrado(n, 3, rng)
	for i in n:
		var t := float(i) / TAXA
		ruido[i] *= exp(-t * 85.0)
	return ruido


## Aplauso: muitas palmas em 2 s, densas no começo e ralas no fim.
func _aplauso() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var total := int(TAXA * 2.2)
	var amostras := PackedFloat32Array()
	amostras.resize(total)
	for k in 220:
		# Mais palmas no início: o público começa junto e vai soltando.
		var quando := pow(rng.randf(), 1.6) * 1.9
		var pos := int(quando * TAXA)
		var palma := _palma(rng)
		var forca := rng.randf_range(0.25, 1.0)
		for i in palma.size():
			if pos + i < total:
				amostras[pos + i] += palma[i] * forca
	# Um fundo de gente para as palmas não soarem soltas no vazio.
	var fundo := _ruido_filtrado(total, 70, rng)
	for i in total:
		amostras[i] += fundo[i] * 0.5
	return amostras


## "Oooh" de expectativa: vozes em uníssono desafinado, subindo e caindo.
func _ooh() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var total := int(TAXA * 1.6)
	var amostras := PackedFloat32Array()
	amostras.resize(total)
	# 14 "vozes" perto de 180 Hz, cada uma um pouco fora do tom.
	for voz in 14:
		var base := 180.0 * rng.randf_range(0.94, 1.07)
		var atraso := rng.randf_range(0.0, 0.12)
		var vol := rng.randf_range(0.3, 0.8)
		for i in total:
			var t := float(i) / TAXA - atraso
			if t <= 0.0:
				continue
			# Envelope de "ooh": entra, segura e sai.
			var env: float = clampf(t / 0.25, 0.0, 1.0) * clampf((1.5 - t) / 0.5, 0.0, 1.0)
			var f := base * (1.0 + 0.06 * t)
			amostras[i] += (sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.0 * t) * 0.25) * env * vol
	var ar := _ruido_filtrado(total, 60, rng)
	for i in total:
		amostras[i] += ar[i] * 0.25
	return amostras


## Festa: aplauso mais longo e brilhante, com assobios por cima.
func _festa() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	var total := int(TAXA * 3.0)
	var amostras := PackedFloat32Array()
	amostras.resize(total)
	for k in 320:
		var pos := int(rng.randf() * 2.7 * TAXA)
		var palma := _palma(rng)
		var forca := rng.randf_range(0.3, 1.0)
		for i in palma.size():
			if pos + i < total:
				amostras[pos + i] += palma[i] * forca
	# Assobios: senos agudos com vibrato, entrando em momentos diferentes.
	for a in 5:
		var inicio := rng.randf_range(0.1, 2.0)
		var dur := rng.randf_range(0.4, 0.9)
		var freq := rng.randf_range(1600.0, 2600.0)
		var n := int(dur * TAXA)
		var pos := int(inicio * TAXA)
		for i in n:
			if pos + i >= total:
				break
			var t := float(i) / TAXA
			var env: float = clampf(t / 0.08, 0.0, 1.0) * clampf((dur - t) / 0.15, 0.0, 1.0)
			amostras[pos + i] += sin(TAU * (freq + 60.0 * sin(TAU * 6.0 * t)) * t) * env * 0.22
	var fundo := _ruido_filtrado(total, 70, rng)
	for i in total:
		amostras[i] += fundo[i] * 0.6
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
