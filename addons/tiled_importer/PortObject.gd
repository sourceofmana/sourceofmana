@tool
extends WarpObject
class_name PortObject

@export var sailingPos : Vector2				= Vector2.ZERO

#
func getDestinationPos(actor : Actor) -> Vector2:
	if actor and actor.stat and not actor.stat.IsSailing():
		return sailingPos
	else:
		return destinationPos
