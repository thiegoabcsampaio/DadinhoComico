class_name NpcProfile
extends Resource
## Perfil de personalidade de um NPC (Resource editável no Inspector).
##
## Instâncias em Resources/NPCProfiles/*.tres. Os valores de 0.0 a 1.0
## alimentam a NpcAI; [member chave_dialogo] aponta a seção do personagem
## em dialogues.json.

## Nome exibido na HUD.
@export var nome: String = "NPC"
## Seção em dialogues.json (ex.: "bruxa").
@export var chave_dialogo: String = ""
## Tendência a blefar e subir apostas em vez de acusar.
@export_range(0.0, 1.0) var agressividade: float = 0.5
## Tendência a não deixar passar apostas improváveis (acusa mais cedo).
@export_range(0.0, 1.0) var cautela: float = 0.5
## Chance de exibir um tique nervoso ao blefar em aposta arriscada (Etapa 6).
@export_range(0.0, 1.0) var frequencia_tells: float = 0.5

## Cor do personagem no log da partida e no cartão do menu.
@export var cor: Color = Color(0.9, 0.9, 0.9)
## Nó de adereço no Espectador.glb que a plateia levanta por este
## personagem (ex.: "Acc_Martelo"). Vazio = a torcida não tem símbolo dele.
@export var adereco_torcida: String = ""
