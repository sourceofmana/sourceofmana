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
static func GetNearestTarget(source : Vector2, interactable : bool) -> Entity:
	var nearestDistance : float	= -1
	var target : Entity		= null
	for entityID in entities:
		var entity : Entity = Get(entityID)
		if entity and entity.state != ActorCommons.State.DEATH:
			if entity.type == ActorCommons.Type.MONSTER or (interactable and entity.type == ActorCommons.Type.NPC):
				var distance : float = source.distance_squared_to(entity.position)
				if nearestDistance == -1 or distance < nearestDistance:
					nearestDistance = distance
					target = entity
	return target
