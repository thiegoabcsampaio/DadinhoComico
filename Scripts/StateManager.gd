class_name StateManager
extends Node
## Máquina de estados da partida.
##
## Responsabilidade única: guardar o estado atual e validar transições.
## Quem decide QUANDO transicionar é o GameManager. HUD, IA e animações
## devem ouvir [signal estado_mudou] em vez de consultar o estado a cada frame.

enum Estado {
	AGUARDANDO,   ## Entre rodadas: dados ainda não foram agitados.
	APOSTANDO,    ## Rodada em curso: jogadores apostam em sequência.
	ACUSANDO,     ## Alguém gritou "Dudo!" — instante antes da revelação.
	REVELANDO,    ## Copos abertos, contagem e definição do perdedor.
	CASTIGO,      ## Um jogador ficou sem dados e recebe o castigo cômico.
	FIM_DE_JOGO,  ## Restou um único jogador.
}

signal estado_mudou(anterior: Estado, novo: Estado)

## Tabela de transições permitidas. Qualquer outra é rejeitada com aviso.
const TRANSICOES := {
	Estado.AGUARDANDO: [Estado.APOSTANDO],
	Estado.APOSTANDO: [Estado.ACUSANDO],
	Estado.ACUSANDO: [Estado.REVELANDO],
	Estado.REVELANDO: [Estado.CASTIGO, Estado.AGUARDANDO],
	Estado.CASTIGO: [Estado.AGUARDANDO, Estado.FIM_DE_JOGO],
	Estado.FIM_DE_JOGO: [Estado.AGUARDANDO],  # reiniciar partida
}

var estado_atual: Estado = Estado.AGUARDANDO


func esta_em(estado: Estado) -> bool:
	return estado_atual == estado


func pode_mudar_para(novo: Estado) -> bool:
	return novo in TRANSICOES[estado_atual]


## Tenta transicionar. Retorna false (e avisa) se a transição não for permitida.
func mudar_para(novo: Estado) -> bool:
	if not pode_mudar_para(novo):
		push_warning("StateManager: transição inválida %s -> %s" % [nome(estado_atual), nome(novo)])
		return false
	var anterior := estado_atual
	estado_atual = novo
	estado_mudou.emit(anterior, novo)
	return true


## Volta para AGUARDANDO sem validar (usado ao iniciar uma partida nova).
func reiniciar() -> void:
	estado_atual = Estado.AGUARDANDO


static func nome(estado: Estado) -> String:
	return Estado.keys()[estado]
