extends RefCounted
class_name Entities

#
static var entities : Dictionary[int, Entity]		= {}

#
static func Get(agentRID : int) -> Entity:
	return entities.get(agentRID, null)

static func Clear():
	var currentPlayerAgentRID : int = Launcher.Player.agentRID if Launcher.Player else NetworkCommons.PeerUnknownID
	entities.clear()
	if currentPlayerAgentRID != NetworkCommons.PeerUnknownID:
		entities[currentPlayerAgentRID] = Launcher.Player

static func Add(entity : Entity, agentRID : int):
	entities[agentRID] = entity

static func Erase(agentRID : int):
	entities.erase(agentRID)

#
static func GetNextTarget(source : Vector2, currentEntity : Entity, interactable : bool) -> Entity:
	var nearestDistance : float	= INF
	var minThreshold : float = 0
	var target : Entity = null
	if currentEntity:
		nearestDistance = source.distance_squared_to(currentEntity.position)
		minThreshold = nearestDistance
		target = currentEntity

	for entity in entities.values():
		if entity and entity != currentEntity:
			var isAliveMonster : bool = entity.type == ActorCommons.Type.MONSTER and entity.state != ActorCommons.State.DEATH
			var isNpc : bool = interactable and entity.type == ActorCommons.Type.NPC
			if isAliveMonster or isNpc:
				var entityData : EntityData = DB.EntitiesDB.get(entity.stat.currentShape, null)
				if entityData:
					# If is in a different state than the overridden one
					if entityData._state != ActorCommons.State.UNKNOWN and entity.state != entityData._state:
						continue
					# If the current quest state forbides the selection
					if entityData._questID != ProgressCommons.Quest.UNKNOWN:
						var questState : int = Launcher.Player.progress.GetQuest(entityData._questID) if Launcher.Player else ProgressCommons.UnknownProgress
						if entityData._questStateMax != ProgressCommons.UnknownProgress:
							if questState < entityData._questState or questState > entityData._questStateMax:
								continue
						else:
							if questState != entityData._questState:
								continue
				# If too far away
				var distance : float = source.distance_squared_to(entity.position)
				if distance > ActorCommons.TargetMaxSquaredDistance:
					continue

				if nearestDistance <= minThreshold:
					if distance < nearestDistance or distance > minThreshold:
						nearestDistance = distance
						target = entity
				else:
					if distance < nearestDistance and distance > minThreshold:
						nearestDistance = distance
						target = entity

	return target
