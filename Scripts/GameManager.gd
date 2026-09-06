class_name GameManager
extends Node
## Orquestrador da partida.
##
## Único ponto de entrada para jogadas: HUD (Etapa 3) e IA (Etapa 4) chamam
## [method fazer_aposta] e [method acusar_dudo]; tudo o mais é interno.
## Combina StateManager (estado), TurnManager (ordem), DiceSystem (dados)
## e BetValidator (regras). Não imprime nada — quem quiser log ouve os sinais.

signal rodada_iniciada(numero: int)
signal aposta_feita(aposta: BetValidator.Aposta)
signal dudo_declarado(acusador: int, acusado: int)
signal dudo_resolvido(resultado: BetValidator.ResultadoDudo)
signal jogador_eliminado(jogador_id: int)
signal jogo_terminou(vencedor: int)

## Formato de decisão devolvido por políticas de NPC (NpcRandom, NpcAI):
## { "acao": ACAO_APOSTAR, "quantidade": int, "face": int } ou { "acao": ACAO_DUDO }
const ACAO_APOSTAR := "apostar"
const ACAO_DUDO := "dudo"

var estado: StateManager
var turnos: TurnManager
var dados: DiceSystem
var validador: BetValidator

## Última aposta da rodada (null logo após agitar os dados).
var aposta_atual: BetValidator.Aposta = null
var numero_rodada: int = 0
## jogador_id -> nome de exibição (opcional; cai em "Jogador N").
var nomes: Dictionary = {}

## Quem abre a próxima rodada (perdedor do último Dudo, se ainda estiver vivo).
var _proximo_iniciante: int = -1


func _init() -> void:
	estado = StateManager.new()
	estado.name = "StateManager"
	add_child(estado)

	turnos = TurnManager.new()
	turnos.name = "TurnManager"
	add_child(turnos)

	dados = DiceSystem.new()
	dados.name = "DiceSystem"
	add_child(dados)

	validador = BetValidator.new()


func iniciar_jogo(ids: Array[int], dados_por_jogador: int = DiceSystem.DADOS_INICIAIS, semente: int = 0, p_nomes: Dictionary = {}) -> void:
	estado.reiniciar()
	turnos.configurar(ids)
	dados.configurar(ids, dados_por_jogador, semente)
	nomes = p_nomes
	numero_rodada = 0
	aposta_atual = null
	_proximo_iniciante = ids[0] if not ids.is_empty() else -1


## AGUARDANDO -> APOSTANDO. Agita todos os copos e define quem abre.
func iniciar_rodada() -> bool:
	if not estado.esta_em(StateManager.Estado.AGUARDANDO):
		push_warning("GameManager: iniciar_rodada fora de AGUARDANDO")
		return false
	numero_rodada += 1
	aposta_atual = null
	dados.agitar_todos()
	# Regra da casa: a primeira rodada é aberta por quem tirou o maior dado.
	# Das seguintes em diante, abre quem perdeu o dado na rodada anterior.
	if numero_rodada == 1:
		_proximo_iniciante = _maior_dado()
	turnos.definir_atual(_proximo_iniciante)
	estado.mudar_para(StateManager.Estado.APOSTANDO)
	rodada_iniciada.emit(numero_rodada)
	return true


## Jogada de aposta. Retorna false se não for a vez do jogador, se o estado
## não permitir ou se a aposta não subir em relação à anterior.
func fazer_aposta(jogador_id: int, quantidade: int, face: int) -> bool:
	if not _pode_jogar(jogador_id):
		return false
	var nova := BetValidator.Aposta.new(jogador_id, quantidade, face)
	var motivo := validador.motivo_invalida(nova, aposta_atual)
	if motivo != "":
		push_warning("GameManager: aposta rejeitada (%s): %s" % [nova, motivo])
		return false
	aposta_atual = nova
	aposta_feita.emit(nova)
	turnos.avancar()
	return true


## Jogada de acusação contra a última aposta. Resolve a rodada na hora.
func acusar_dudo(jogador_id: int) -> bool:
	if not _pode_jogar(jogador_id):
		return false
	if aposta_atual == null:
		push_warning("GameManager: Dudo sem nenhuma aposta na mesa")
		return false
	estado.mudar_para(StateManager.Estado.ACUSANDO)
	dudo_declarado.emit(jogador_id, aposta_atual.jogador)
	_resolver(jogador_id)
	return true


## Aplica uma decisão no formato de [const ACAO_APOSTAR] / [const ACAO_DUDO].
func executar_decisao(jogador_id: int, decisao: Dictionary) -> bool:
	match decisao.get("acao"):
		ACAO_APOSTAR:
			return fazer_aposta(jogador_id, decisao.get("quantidade", 0), decisao.get("face", 0))
		ACAO_DUDO:
			return acusar_dudo(jogador_id)
		_:
			push_warning("GameManager: decisão desconhecida %s" % decisao)
			return false


func jogador_atual() -> int:
	return turnos.jogador_atual()


func nome(jogador_id: int) -> String:
	return nomes.get(jogador_id, "Jogador %d" % jogador_id)


func ver_dados(jogador_id: int) -> Array[int]:
	return dados.revelar(jogador_id)


func jogo_acabou() -> bool:
	return estado.esta_em(StateManager.Estado.FIM_DE_JOGO)


func _pode_jogar(jogador_id: int) -> bool:
	if not estado.esta_em(StateManager.Estado.APOSTANDO):
		push_warning("GameManager: jogada fora de APOSTANDO (estado: %s)" % StateManager.nome(estado.estado_atual))
		return false
	if jogador_id != turnos.jogador_atual():
		push_warning("GameManager: não é a vez do jogador %d (vez de %d)" % [jogador_id, turnos.jogador_atual()])
		return false
	return true


## Quem tirou o dado mais alto. Empate fica com quem vem antes na ordem da
## mesa, que já é a ordem de quem joga depois de quem.
func _maior_dado() -> int:
	var escolhido := turnos.jogador_atual()
	var maior := -1
	for id in turnos.ativos():
		for dado in dados.revelar(id):
			if dado > maior:
				maior = dado
				escolhido = id
	return escolhido


## ACUSANDO -> REVELANDO -> (CASTIGO ->) AGUARDANDO | FIM_DE_JOGO
func _resolver(acusador: int) -> void:
	estado.mudar_para(StateManager.Estado.REVELANDO)

	var contagem := dados.contar_face(aposta_atual.face, validador.ases_curinga)
	var resultado := validador.resolver_dudo(aposta_atual, acusador, contagem)
	var restantes := dados.remover_dado(resultado.perdedor)
	dudo_resolvido.emit(resultado)

	# Regra clássica: quem perdeu o dado abre a próxima rodada.
	_proximo_iniciante = resultado.perdedor

	if restantes == 0:
		estado.mudar_para(StateManager.Estado.CASTIGO)
		turnos.eliminar(resultado.perdedor)
		jogador_eliminado.emit(resultado.perdedor)

		if turnos.restantes() <= 1:
			estado.mudar_para(StateManager.Estado.FIM_DE_JOGO)
			jogo_terminou.emit(turnos.vencedor())
			return

		_proximo_iniciante = turnos.proximo_apos(resultado.perdedor)

	estado.mudar_para(StateManager.Estado.AGUARDANDO)
