extends Object
class_name Entities

#
static var entities : Dictionary				= {}

#
static func Get(ridEntity : int) -> BaseEntity:
	return entities.get(ridEntity)

static func Clear():
	entities.clear()

static func Add(entity : BaseEntity, ridEntity : int):
	entities[ridEntity] = entity 

static func Erase(ridEntity : int):
	entities.erase(ridEntity)

#
static func GetNearestTarget(source : Vector2, interactable : bool) -> BaseEntity:
	var nearestDistance : float	= -1
	var target : BaseEntity		= null
	for entityID in entities:
		var entity : BaseEntity = Get(entityID)
		if entity and entity.entityState != EntityCommons.State.DEATH:
			if entity is MonsterEntity or (not interactable and entity is NpcEntity):
				var distance : float = source.distance_squared_to(entity.position)
				if nearestDistance == -1 or distance < nearestDistance:
					nearestDistance = distance
					target = entity
	return target
