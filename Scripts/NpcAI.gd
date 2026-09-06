class_name NpcAI
extends RefCounted
## IA de NPC: probabilidade + personalidade (Etapa 4).
##
## Mesma interface de NpcRandom — [method decidir] devolve um Dictionary no
## formato de GameManager (ACAO_APOSTAR / ACAO_DUDO). Enxerga apenas os
## próprios dados; os demais são tratados como desconhecidos com
## distribuição uniforme, e a chance de uma aposta ser verdadeira é a
## cauda de uma binomial.
##
## Personalidade (NpcProfile):
## - cautela sobe o limiar abaixo do qual o NPC acusa (não deixa passar
##   apostas improváveis);
## - agressividade baixa o limiar para subir a aposta e pesa a favor do
##   blefe quando nenhum lance honesto é bom.

## Abaixo desta probabilidade, um blefe é "arriscado" e pode disparar
## um tell (Etapa 6).
const P_BLEFE_ARRISCADO := 0.25

## Quantos níveis de dificuldade existem, do mais fácil ao mais difícil.
const NIVEIS := 5
## Erro máximo de leitura no nível 1. Cada nível acima corta um quinto dele.
const ERRO_MAXIMO := 0.22

var perfil: NpcProfile
## 1 = fácil (erra muito a conta e blefa no susto), 5 = difícil (lê certo).
## Sorteado por partida em Main, para a mesa não ser sempre igual.
var nivel := 3
## true se a última jogada foi um blefe em aposta de alto risco.
var blefe_arriscado := false
## Números da última decisão, para debug e logs.
var ultima_analise := {}

var _rng := RandomNumberGenerator.new()


func _init(p_perfil: NpcProfile, semente: int = 0) -> void:
	perfil = p_perfil if p_perfil != null else NpcProfile.new()
	if semente == 0:
		_rng.randomize()
	else:
		_rng.seed = semente


func decidir(jogo: GameManager, jogador_id: int) -> Dictionary:
	blefe_arriscado = false
	var meus := jogo.ver_dados(jogador_id)
	var desconhecidos := jogo.dados.total_dados() - meus.size()
	var curinga := jogo.validador.ases_curinga
	var atual := jogo.aposta_atual

	if atual == null:
		return _abrir(meus, desconhecidos, curinga)

	# O nível entra aqui: um NPC fraco enxerga a probabilidade torta e decide
	# em cima da conta errada. Um NPC forte vê o número real.
	var p_atual := _com_erro(_prob_aposta(atual.quantidade, atual.face, meus, desconhecidos, curinga))
	var melhor := _melhor_lance(atual, meus, desconhecidos, curinga)
	var p_melhor: float = _com_erro(melhor["p"])

	var limiar_dudo := 0.30 + 0.25 * perfil.cautela
	var limiar_aposta := 0.35 + 0.25 * perfil.cautela - 0.15 * perfil.agressividade

	ultima_analise = {
		"p_atual": p_atual,
		"melhor": "%d x face %d" % [melhor["quantidade"], melhor["face"]],
		"p_melhor": p_melhor,
		"blefe": false,
	}

	# 1. Existe um lance honesto bom: sobe a aposta.
	if p_melhor >= limiar_aposta:
		return _apostar(melhor)

	# 2. A aposta na mesa é improvável: acusa.
	if p_atual < limiar_dudo:
		return _dudo()

	# 3. Aposta plausível e nenhum lance bom: blefar ou acusar, o que
	#    tiver menor risco (agressividade desconta o risco do blefe).
	if p_melhor <= 0.0:
		return _dudo()
	var risco_dudo := p_atual
	var risco_blefe := (1.0 - p_melhor) * (1.0 - 0.4 * perfil.agressividade)
	# Blefe de atrevimento: sai mesmo quando a conta não manda, e é o que dá
	# graça à mesa. Quem é agressivo blefa mais; nível baixo blefa no susto.
	var atrevimento := perfil.agressividade * (0.55 - 0.05 * nivel)
	if risco_blefe < risco_dudo or _rng.randf() < atrevimento:
		ultima_analise["blefe"] = true
		blefe_arriscado = p_melhor < P_BLEFE_ARRISCADO
		return _apostar(melhor)
	return _dudo()


## Embaralha a probabilidade conforme o nível: no 5 devolve o valor exato,
## no 1 pode errar bastante para mais ou para menos.
func _com_erro(p: float) -> float:
	if nivel >= NIVEIS:
		return p
	var escala := ERRO_MAXIMO * float(NIVEIS - nivel) / float(NIVEIS - 1)
	return clampf(p + _rng.randfn(0.0, escala), 0.0, 1.0)


## Primeira aposta da rodada: face mais frequente no próprio copo,
## quantidade em torno do valor esperado, puxada pela agressividade.
func _abrir(meus: Array[int], desconhecidos: int, curinga: bool) -> Dictionary:
	var melhor_face := DiceSystem.FACE_MIN
	var melhor_contagem := -1
	for face in range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX + 1):
		var c := _contar(meus, face, curinga)
		if c >= melhor_contagem:
			melhor_contagem = c
			melhor_face = face
	var esperado := melhor_contagem + desconhecidos * _p_face(melhor_face, curinga)
	var fator := 0.6 + 0.5 * perfil.agressividade
	var quantidade := maxi(1, int(round(esperado * fator)))
	ultima_analise = { "p_atual": 1.0, "melhor": "%d x face %d" % [quantidade, melhor_face], "p_melhor": 1.0, "blefe": false }
	return { "acao": GameManager.ACAO_APOSTAR, "quantidade": quantidade, "face": melhor_face }


## Entre todos os lances válidos de subida mínima (mesma quantidade com
## face maior, ou quantidade + 1 com qualquer face), o de maior chance.
func _melhor_lance(atual: BetValidator.Aposta, meus: Array[int], desconhecidos: int, curinga: bool) -> Dictionary:
	var melhor := { "quantidade": atual.quantidade + 1, "face": DiceSystem.FACE_MIN, "p": -1.0 }
	for face in range(DiceSystem.FACE_MIN, DiceSystem.FACE_MAX + 1):
		var candidatos: Array[int] = [atual.quantidade + 1]
		if face > atual.face:
			candidatos.append(atual.quantidade)
		for quantidade in candidatos:
			var p := _prob_aposta(quantidade, face, meus, desconhecidos, curinga)
			# Empate: prefere a menor quantidade (mais fácil de sustentar).
			if p > melhor["p"] or (is_equal_approx(p, melhor["p"]) and quantidade < melhor["quantidade"]):
				melhor = { "quantidade": quantidade, "face": face, "p": p }
	return melhor


## P(existem >= quantidade dados com esta face na mesa | meus dados).
func _prob_aposta(quantidade: int, face: int, meus: Array[int], desconhecidos: int, curinga: bool) -> float:
	var faltam := quantidade - _contar(meus, face, curinga)
	return _p_pelo_menos(faltam, desconhecidos, _p_face(face, curinga))


func _contar(meus: Array[int], face: int, curinga: bool) -> int:
	var total := 0
	for dado in meus:
		if dado == face or (curinga and dado == DiceSystem.FACE_MIN and face != DiceSystem.FACE_MIN):
			total += 1
	return total


func _p_face(face: int, curinga: bool) -> float:
	var faces := float(DiceSystem.FACE_MAX - DiceSystem.FACE_MIN + 1)
	if curinga and face != DiceSystem.FACE_MIN:
		return 2.0 / faces
	return 1.0 / faces


## Cauda da binomial: P(X >= k) com X ~ Bin(n, p).
static func _p_pelo_menos(k: int, n: int, p: float) -> float:
	if k <= 0:
		return 1.0
	if k > n:
		return 0.0
	var total := 0.0
	for i in range(k, n + 1):
		total += _binomial(n, i) * pow(p, i) * pow(1.0 - p, n - i)
	return clampf(total, 0.0, 1.0)


static func _binomial(n: int, k: int) -> float:
	if k < 0 or k > n:
		return 0.0
	var resultado := 1.0
	for i in range(1, k + 1):
		resultado *= float(n - k + i) / float(i)
	return resultado


func _apostar(lance: Dictionary) -> Dictionary:
	return { "acao": GameManager.ACAO_APOSTAR, "quantidade": lance["quantidade"], "face": lance["face"] }


func _dudo() -> Dictionary:
	return { "acao": GameManager.ACAO_DUDO }
