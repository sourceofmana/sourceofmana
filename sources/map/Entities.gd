extends Object
class_name Entities

#
static var entities : Dictionary				= {}

#
static func Get(ridEntity : int) -> Entity:
	return entities.get(ridEntity)

static func Clear():
	entities.clear()

static func Add(entity : Entity, ridEntity : int):
	entities[ridEntity] = entity 

static func Erase(ridEntity : int):
	entities.erase(ridEntity)

#
static func GetNextTarget(source : Vector2, currentEntity : Entity, interactable : bool) -> Entity:
	var nearestDistance : float	= INF
	var minThreshold : float = 0
	var target : Entity = null
	if currentEntity:
		nearestDistance = source.distance_squared_to(currentEntity.position)
		minThreshold = nearestDistance
		target = currentEntity

	for entityID in entities:
		var entity : Entity = Get(entityID)
		if entity != currentEntity and entity.state != ActorCommons.State.DEATH:
			if entity.type == ActorCommons.Type.MONSTER or (interactable and entity.type == ActorCommons.Type.NPC):
				var distance : float = source.distance_squared_to(entity.position)
				if nearestDistance <= minThreshold:
					if distance < nearestDistance or distance > minThreshold:
						nearestDistance = distance
						target = entity
				else:
					if distance < nearestDistance and distance > minThreshold:
						nearestDistance = distance
						target = entity

	return target
