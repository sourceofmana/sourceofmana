extends Object
class_name Modifier

#
static func GetRegenHealth(actor : Actor) -> int:
	var value : int = actor.stat.current.regenHealth
	if actor.state == ActorCommons.State.SIT:
		value *= 2
	return value

static func GetRegenMana(actor : Actor) -> int:
	var value : int = actor.stat.current.regenMana
	if actor.state == ActorCommons.State.SIT:
		value *= 2
	return value

static func GetRegenStamina(actor : Actor) -> int:
	var value : int = actor.stat.current.regenStamina
	if actor.state == ActorCommons.State.SIT:
		value *= 2
	return value
