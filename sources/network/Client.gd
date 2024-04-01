extends Node

#
func WarpPlayer(map : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.EmplaceMapNode(map)
		PushNotification(map, _rpcID)

	if Launcher.Player:
		Launcher.Player.entityVelocity = Vector2.ZERO

func EmotePlayer(playerID : int, emote : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.EmotePlayer(playerID, emote)

func AddEntity(agentID : int, entityType : ActorCommons.Type, entityID : String, entityName : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastName : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.AddEntity(agentID, entityType, entityID, entityName, velocity, position, orientation, state, skillCastName)

func RemoveEntity(agentID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.RemoveEntity(agentID)

func ForceUpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, orientation : Vector2, state : ActorCommons.State, skillCastName : String):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, orientation, state, skillCastName)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, orientation : Vector2, state : ActorCommons.State, skillCastName : String):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, orientation, state, skillCastName)

func ChatAgent(ridAgent : int, text : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity && entity.get_parent():
			if entity.type == ActorCommons.Type.PLAYER && Launcher.GUI:
				Launcher.GUI.chatContainer.AddPlayerText(entity.get_name(), text)
			if entity.interactive:
				entity.interactive.DisplaySpeech(text)

func TargetAlteration(ridAgent : int, targetID : int, value : int, alteration : ActorCommons.Alteration, skillName : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(targetID)
		var caller : Entity = Entities.Get(ridAgent)
		if caller && entity && entity.get_parent() and entity.interactive:
			entity.interactive.DisplayAlteration(entity, caller, value, alteration, skillName)

func TargetLevelUp(targetID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(targetID)
		if entity and entity.get_parent() and entity.interactive:
			entity.interactive.DisplayLevelUp()
			entity.stat.attributes_updated.emit()

func Morphed(ridAgent : int, morphID : String, morphed : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity:
			var morphData : EntityData = Instantiate.FindEntityReference(morphID)
			entity.stat.Morph(morphData)
			entity.SetVisual(morphData, morphed)

func UpdateActiveStats(ridAgent : int, level : int, experience : int, health : int, mana : int, stamina : int, weight : float, entityShape : String, spiritShape : String, morphed : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity and entity.get_parent() and entity.stat:
			var levelUp : bool = entity.stat.level != level
			entity.stat.level			= level
			entity.stat.experience		= experience
			entity.stat.health			= health
			entity.stat.mana			= mana
			entity.stat.stamina			= stamina
			entity.stat.weight			= weight
			entity.stat.morphed			= morphed
			entity.stat.entityShape		= entityShape
			entity.stat.spiritShape		= spiritShape
			if levelUp:
				PushNotification("Level %d reached.\nFeel the mana power growing inside you!" % (level))
				entity.stat.RefreshAttributes()
			else:
				entity.stat.RefreshActiveStats()

func UpdateAttributes(ridAgent : int, strength : int, vitality : int, agility : int, endurance : int, concentration : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity and entity.get_parent() and entity.stat:
			entity.stat.strength		= strength
			entity.stat.vitality		= vitality
			entity.stat.agility			= agility
			entity.stat.endurance		= endurance
			entity.stat.concentration	= concentration
			entity.stat.RefreshAttributes()

func PushNotification(notif : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.GUI:
		Launcher.GUI.notificationLabel.AddNotification(notif)

func DisconnectPlayer():
	if Launcher.Map:
		Launcher.Map.UnloadMapNode()
	if Launcher.Player:
		Launcher.Player = null
