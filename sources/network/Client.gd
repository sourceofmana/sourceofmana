extends Node

#
func WarpPlayer(map : String, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.ReplaceMapNode(map)

func EmotePlayer(playerID : int, emoteID : int, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.EmotePlayer(playerID, emoteID)

func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i, entitySitting : bool, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.AddEntity(agentID, entityType, entityID, entityName, entityPos, entitySitting)

func RemoveEntity(agentID : int, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.RemoveEntity(agentID)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, isSitting : bool):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, isSitting)

func SetVelocity(velocity : Vector2):
	if Launcher.Player:
		Launcher.Player.SetVelocity(velocity)

func ChatAgent(ridAgent : int, text : String, _rpcID : int = -1):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if entity && entity.get_parent():
			if entity is PlayerEntity && Launcher.GUI:
				Launcher.GUI.chatContainer.AddPlayerText(entity.entityName, text)
			if entity.interactive:
				entity.interactive.DisplaySpeech(text)

func DisconnectPlayer():
	if Launcher.Map:
		Launcher.Map.UnloadMapNode()
	if Launcher.Player:
		Launcher.Player = null
