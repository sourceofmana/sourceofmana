extends Node

#
func WarpPlayer(map : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.EmplaceMapNode(map)
		PushNotification(map, _rpcID)

	if Launcher.Player:
		Launcher.Player.entityVelocity = Vector2.ZERO

func EmotePlayer(playerID : int, emoteID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.EmotePlayer(playerID, emoteID)

func AddEntity(agentID : int, entityType : EntityCommons.Type, entityID : String, entityName : String, velocity : Vector2, position : Vector2i, orientation : Vector2, entityState : EntityCommons.State, skillCastName : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.AddEntity(agentID, entityType, entityID, entityName, velocity, position, orientation, entityState, skillCastName)

func RemoveEntity(agentID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.RemoveEntity(agentID)

func ForceUpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, orientation : Vector2, entityState : EntityCommons.State, skillCastName : String):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, orientation, entityState, skillCastName)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, orientation : Vector2, entityState : EntityCommons.State, skillCastName : String):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, orientation, entityState, skillCastName)

func ChatAgent(ridAgent : int, text : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if entity && entity.get_parent():
			if entity is PlayerEntity && Launcher.GUI:
				Launcher.GUI.chatContainer.AddPlayerText(entity.get_name(), text)
			if entity.interactive:
				entity.interactive.DisplaySpeech(text)

func TargetAlteration(ridAgent : int, targetID : int, value : int, alteration : EntityCommons.Alteration, skillName : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(targetID)
		var caller : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if caller && entity && entity.get_parent() and entity.interactive:
			entity.interactive.DisplayAlteration(entity, caller, value, alteration, skillName)

func TargetLevelUp(targetID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(targetID)
		if entity and entity.get_parent() and entity.interactive:
			entity.interactive.DisplayLevelUp()

func Morphed(ridAgent : int, morphID : String, morphed : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : BaseEntity = Launcher.Map.entities.get(ridAgent)
		if entity:
			var morphData : EntityData = Instantiate.FindEntityReference(morphID)
			entity.SetVisual(morphData, morphed)


func UpdatePlayerVars(level : int, experience : float, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.stat.level			= level
		Launcher.Player.stat.experience		= experience

func UpdateActiveStats(health : int, mana : int, stamina : int, weight : float, morphed : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.stat.health			= health
		Launcher.Player.stat.mana			= mana
		Launcher.Player.stat.stamina		= stamina
		Launcher.Player.stat.weight			= weight
		Launcher.Player.stat.morphed		= morphed

func UpdatePersonalStats(strength : int, vitality : int, agility : int, endurance : int, concentration : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.stat.strength		= strength
		Launcher.Player.stat.vitality		= vitality
		Launcher.Player.stat.agility		= agility
		Launcher.Player.stat.endurance		= endurance
		Launcher.Player.stat.concentration	= concentration

func PushNotification(notif : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.GUI:
		Launcher.GUI.notificationLabel.AddNotification(notif)

func DisconnectPlayer():
	if Launcher.Map:
		Launcher.Map.UnloadMapNode()
	if Launcher.Player:
		Launcher.Player = null
